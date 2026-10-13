using System.Globalization;
using System.Security;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using NodaTime;
using Windows.Data.Xml.Dom;
using Windows.UI.Notifications;

namespace Huda.PrayerTaskbar;

/// Adds future events to the same OS queue. It never emits an immediate toast.
internal sealed class PrayerToastQueue
{
    private const string AppId = "awr.Huda-IslamicCompanionApp";
    private const string TestAppId = "Huda.SchedulingInvestigation.20261003";
    private Task _work = Task.CompletedTask;
    private Instant _nextCheck;
    private bool _suspended;
    private CancellationTokenSource? _cancellation;
    private readonly ScheduleCalculator _calculator = new(new RamadanCalendar());
    private sealed record Receipt(string? Error = null, DateTimeOffset? Coverage = null);
    private volatile Receipt _receipt = new();
    public string? Error => _receipt.Error;
    public DateTimeOffset? CoverageUntilUtc => _receipt.Coverage;
    public bool Busy => !_work.IsCompleted;
    public bool DeferredForOwner { get; private set; }

    public void RequestSuspend() { _suspended = true; _cancellation?.Cancel(); }
    public async Task Suspend() { RequestSuspend(); await _work; }
    public void Resume() { _suspended = false; _nextCheck = default; }
    public void Check(TaskbarConfiguration config, Instant now, bool prototype)
    {
        if ((prototype && !Paths.TestToastQueue) || _suspended || !_work.IsCompleted || now < _nextCheck ||
            !PrayersEligible(config) && config.ReminderRules.Count == 0) return;
        _nextCheck = now + Duration.FromHours(1);
        _cancellation?.Dispose();
        _cancellation = new CancellationTokenSource();
        var token = _cancellation.Token;
        _work = Task.Run(() => {
            try { Maintain(config, now, token); _receipt = _receipt with { Error = null }; }
            catch (OperationCanceledException) when (token.IsCancellationRequested) { _receipt = _receipt with { Error = null }; }
            catch (Exception error) { _receipt = _receipt with { Error = error.Message }; }
        });
    }
    private void Maintain(TaskbarConfiguration config, Instant now, CancellationToken token)
    {
        token.ThrowIfCancellationRequested();
        var appId = Paths.TestToastQueue ? TestAppId : AppId;
        using var owner = new Mutex(false, @"Local\Huda.PrayerToastQueue." + Paths.UserSid + "." + appId);
        bool acquired;
        try { acquired = owner.WaitOne(0); } catch (AbandonedMutexException) { acquired = true; }
        DeferredForOwner = !acquired;
        if (!acquired) { _nextCheck = now + Duration.FromMinutes(1); return; }
        try {
            token.ThrowIfCancellationRequested();
            // Reject a revision that changed while this task waited to execute.
            var store = new ConfigurationStore(Paths.TestToastQueue ? Paths.PrototypeConfiguration! : Paths.Configuration);
            if (!store.Reload() || store.Current?.Revision != config.Revision) return;
            var notifier = StartupRegistration.IsPackaged
                ? ToastNotificationManager.CreateToastNotifier() : ToastNotificationManager.CreateToastNotifier(appId);
            if (PrayersEligible(config)) MaintainPrayers(config, now, token, notifier);
            TopUpReminders(config, now, token, notifier);
        } finally { owner.ReleaseMutex(); }
    }
    /// Shows the toasts Windows dropped while the PC slept or was off, and
    /// removes every past-due toast from the queue (see MissedToastPolicy).
    /// Runs after any queued work, under the same queue mutex as Huda.
    public void CatchUp(Instant now, bool prototype, Func<MissedToast, Instant?> prayerEnd)
    {
        if (prototype && !Paths.TestToastQueue) return;
        var previous = _work;
        _work = Task.Run(async () => {
            await previous;
            try { CatchUpMissed(now, prayerEnd); }
            catch (Exception error) { _receipt = _receipt with { Error = error.Message }; }
        });
    }
    private static void CatchUpMissed(Instant now, Func<MissedToast, Instant?> prayerEnd)
    {
        var appId = Paths.TestToastQueue ? TestAppId : AppId;
        using var owner = new Mutex(false, @"Local\Huda.PrayerToastQueue." + Paths.UserSid + "." + appId);
        bool acquired;
        try { acquired = owner.WaitOne(TimeSpan.FromSeconds(30)); } catch (AbandonedMutexException) { acquired = true; }
        if (!acquired) return;
        try {
            var notifier = StartupRegistration.IsPackaged
                ? ToastNotificationManager.CreateToastNotifier() : ToastNotificationManager.CreateToastNotifier(appId);
            var due = notifier.GetScheduledToastNotifications()
                .Where(toast => toast.Group.Length == 0 &&
                    MissedToastPolicy.IsMissed(Instant.FromDateTimeOffset(toast.DeliveryTime), now))
                .OrderBy(toast => toast.DeliveryTime).ToArray();
            if (due.Length == 0) return;
            var show = MissedToastPolicy.ToShow(
                due.Select(toast => new MissedToast(toast.Tag, Instant.FromDateTimeOffset(toast.DeliveryTime), PrayerKey(toast))),
                now, prayerEnd).Select(item => item.Tag).ToHashSet();
            foreach (var toast in due) {
                try { notifier.RemoveFromSchedule(toast); }
                catch (Exception) { /* Shown or removed meanwhile. */ continue; }
                if (show.Remove(toast.Tag)) notifier.Show(new ToastNotification(toast.Content) { Tag = toast.Tag });
            }
        } finally { owner.ReleaseMutex(); }
    }
    private static string? PrayerKey(ScheduledToastNotification toast)
    {
        if (!IsPrayer(toast)) return null;
        try {
            using var payload = JsonDocument.Parse(toast.Content.DocumentElement.GetAttribute("launch"));
            return payload.RootElement.TryGetProperty("prayer", out var key) ? key.GetString() : null;
        } catch (JsonException) { return null; }
    }
    private static bool PrayersEligible(TaskbarConfiguration config) =>
        config.PrayerExperience is { Configured: true, Enabled: true } &&
        config.Location is { Verified: true } && config.NotificationContract is not null;
    private void MaintainPrayers(TaskbarConfiguration config, Instant now, CancellationToken token, ToastNotifier notifier)
    {
        var contract = config.NotificationContract!;
        if (contract.LocationRevision != config.Location!.Revision ||
            !contract.ConfigurationSignature.Contains(config.PrayerExperience!.DeliverySignature, StringComparison.Ordinal)) return;
        var pending = notifier.GetScheduledToastNotifications();
        var prayers = pending.Where(IsPrayer).ToArray();
        // Flutter may be committing a newer schedule before publishing its exchange.
        foreach (var toast in prayers.Where(item => item.DeliveryTime > now.ToDateTimeOffset().AddSeconds(30))) {
            using var payload = JsonDocument.Parse(toast.Content.DocumentElement.GetAttribute("launch"));
            if (payload.RootElement.GetProperty("configurationSignature").GetString() != contract.ConfigurationSignature) return;
        }
        _receipt = _receipt with { Coverage = prayers.Length == 0 ? null : prayers.Max(item => item.DeliveryTime) };
        if (CoverageUntilUtc is { } coverage && coverage > now.ToDateTimeOffset().AddDays(30)) return;
        var ids = pending.Where(item => item.Group.Length == 0).Select(item => item.Tag).ToHashSet();
        var zone = DateTimeZoneProviders.Tzdb[config.Location.TimeZoneId];
        var today = now.InZone(zone).Date;
        var through = now + Duration.FromDays(365);
        var events = new List<PrayerEvent>();
        for (var day = today; day <= through.InZone(zone).Date.PlusDays(1); day = day.PlusDays(1)) {
            token.ThrowIfCancellationRequested();
            var schedule = _calculator.Calculate(config, day);
            foreach (var (key, time) in schedule.Times)
                if (key != "sunrise" && time is { } instant && instant > now + Duration.FromSeconds(30))
                    events.Add(new PrayerEvent(key, day, instant));
        }
        events = events.OrderBy(item => item.Time).ToList();
        var count = pending.Count;
        var prayerCount = prayers.Length;
        for (var i = 0; i < events.Count && count < 4000 && prayerCount < 1825; i++) {
            token.ThrowIfCancellationRequested();
            var prayer = events[i];
            if (prayer.Time > through) break;
            // A prayer that is off has no toast (Huda's planner skips it too).
            if (!config.PrayerExperience!.For(prayer.Key).Enabled) continue;
            var id = PrayerOccurrence.Id(prayer, config.Location.TimeZoneId).ToString(CultureInfo.InvariantCulture);
            if (!ids.Add(id)) continue;
            var wall = prayer.Time.InZone(zone).LocalDateTime;
            var payload = JsonSerializer.Serialize(new {
                type = "prayer_time", schemaVersion = 3, occurrenceId = int.Parse(id, CultureInfo.InvariantCulture),
                locationRevision = contract.LocationRevision, scheduleRevision = contract.ScheduleRevision,
                configurationSignature = contract.ConfigurationSignature, prayer = prayer.Key,
                scheduledTime = wall.ToString("uuuu-MM-dd'T'HH:mm:ss.fff", CultureInfo.InvariantCulture),
                scheduledUtc = prayer.Time.ToDateTimeUtc().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture),
                timeZone = config.Location.TimeZoneId, windowsSilent = true,
            });
            var document = new XmlDocument();
            document.LoadXml(PrayerToastContent.Xml(config, prayer, payload));
            var scheduled = new ScheduledToastNotification(document, prayer.Time.ToDateTimeOffset()) { Tag = id };
            notifier.AddToSchedule(scheduled); count++; prayerCount++;
            _receipt = _receipt with { Coverage = scheduled.DeliveryTime };
        }
    }
    /// Keeps reminder toasts topped up from the rules Huda published, with the
    /// same expansion as Huda's own Windows backend: dated toasts for daily and
    /// weekly reminders, and the random Athkar series with random text each.
    private static void TopUpReminders(TaskbarConfiguration config, Instant now, CancellationToken token, ToastNotifier notifier)
    {
        if (config.ReminderRules.Count == 0) return;
        var pending = notifier.GetScheduledToastNotifications();
        var queued = new Dictionary<long, Instant>();
        foreach (var toast in pending)
            if (toast.Group.Length == 0 && long.TryParse(toast.Tag, NumberStyles.None, CultureInfo.InvariantCulture, out var id))
                queued[id] = Instant.FromDateTimeOffset(toast.DeliveryTime);
        var additions = ReminderToastPlan.Additions(config.ReminderRules, queued, now,
            DateTimeZoneProviders.Tzdb.GetSystemDefault(), Random.Shared, Math.Max(0, 4000 - pending.Count));
        foreach (var toast in additions) {
            token.ThrowIfCancellationRequested();
            var document = new XmlDocument();
            document.LoadXml(ReminderXml(toast));
            notifier.AddToSchedule(new ScheduledToastNotification(document, toast.At.ToDateTimeOffset())
                { Tag = toast.Id.ToString(CultureInfo.InvariantCulture) });
        }
    }
    /// Matches the reminder XML of Huda's notification worker: Windows' default
    /// duration, the launch payload for taps, title, body and default sound.
    internal static string ReminderXml(ReminderToast toast) =>
        $"<toast launch=\"{SecurityElement.Escape(toast.Payload)}\" useButtonStyle=\"true\">" +
        "<visual><binding template=\"ToastGeneric\">" +
        $"<text>{SecurityElement.Escape(toast.Title)}</text><text>{SecurityElement.Escape(toast.Body)}</text>" +
        "</binding></visual><actions/></toast>";
    private static bool IsPrayer(ScheduledToastNotification toast) => toast.Group.Length == 0 &&
        int.TryParse(toast.Tag, NumberStyles.None, CultureInfo.InvariantCulture, out var id) &&
        id is >= 300000000 and < 400000000 && id.ToString(CultureInfo.InvariantCulture) == toast.Tag;
}
