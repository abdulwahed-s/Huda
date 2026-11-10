using System.Diagnostics;
using System.Globalization;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Huda.PrayerTray.Core;
using NodaTime;
using Tmds.DBus.Protocol;
using ConfigurationStore = Huda.PrayerTray.Core.ConfigurationStore;

namespace Huda.PrayerTray;

internal sealed record ExperienceCommand(string Action, string SessionId, LinuxPrayerExperience? Settings = null,
    double? Volume = null);
internal sealed record ShellEnvironment(bool Unlocked, bool Available, IReadOnlyList<Dictionary<string, string>> Displays);
internal sealed record FocusAcknowledgment(string SessionId, long Revision, bool Presented, string? Error = null);
internal sealed class PrayerSession(string id, bool preview, string origin, PrayerEvent prayer, LinuxPrayerExperience settings,
    TrayConfiguration configuration)
{
    public string Id { get; } = id;
    public bool Preview { get; } = preview;
    public string Origin { get; } = origin;
    public PrayerEvent Prayer { get; } = prayer;
    public LinuxPrayerExperience Settings { get; } = settings;
    public TrayConfiguration Configuration { get; } = configuration;
    public Stopwatch Age { get; } = Stopwatch.StartNew();
    public Stopwatch? FocusTimer { get; set; }
    public string FocusState { get; set; } = "idle";
    public string? FocusError { get; set; }
    public int FocusSeconds => Preview ? 15 : Settings.FocusDurationSeconds;
}

internal sealed class PrayerExperienceHost : IPathMethodHandler, IAsyncDisposable
{
    public const string Interface = "com.aw.huda.PrayerExperience1";
    public string Path => "/com/aw/huda/PrayerExperience";
    public bool HandlesChildPaths => false;
    private readonly DBusConnection _bus;
    private readonly ConfigurationStore _store;
    private readonly string _directory, _legacyDirectory, _configPath;
    private readonly CancellationToken _shutdown;
    private readonly IClock _clockSource;
    private readonly SemaphoreSlim _gate = new(1);
    private readonly LinuxPrayerDueEvents _due = new();
    private readonly LinuxOccurrenceLedger? _ledger;
    private readonly string? _ledgerError;
    private readonly PrayerAudioStore _audio;
    private readonly PrayerPlayback _player = new();
    private readonly PrayerSessionObservation _session = new();
    private readonly PrayerNotificationDelivery _notifications;
    private readonly Stopwatch _clock = Stopwatch.StartNew();
    private long _lastTick, _lastWall, _shellSeen = -60000;
    private bool? _locked;
    private string? _appOwner, _pending, _error, _audioError;
    private TrayConfiguration? _prepared;
    private string? _shellOwner;
    private string _owner = "legacy", _notificationState = "idle", _focusFallback = "";
    private ShellEnvironment _environment = new(false, false, []);
    private PrayerSession? _live, _preview;
    private PrayerSession? _audioPending;
    private long _audioRequestedAt;
    private string? _lastAudioState;
    private string _json = "{}";
    private ulong _serial;
    private TaskCompletionSource<string> _changed = new(TaskCreationOptions.RunContinuationsAsynchronously);
    private static readonly byte[] Schema = ReadSchema();
    private static byte[] ReadSchema()
    {
        using var input = typeof(PrayerExperienceHost).Assembly.GetManifestResourceStream("com.aw.huda.PrayerExperience1.xml")!;
        using var buffer = new MemoryStream(); input.CopyTo(buffer); return buffer.ToArray();
    }
    public PrayerExperienceHost(DBusConnection bus, ConfigurationStore store, string directory, string legacyDirectory,
        CancellationToken shutdown, IClock? clockSource = null)
    {
        _bus = bus; _store = store; _directory = directory; _legacyDirectory = legacyDirectory;
        _configPath = System.IO.Path.Combine(directory, "configuration.json"); _shutdown = shutdown;
        _clockSource = clockSource ?? SystemClock.Instance;
        _audio = new PrayerAudioStore(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(directory)!, "prayer-audio"));
        try { _ledger = new LinuxOccurrenceLedger(System.IO.Path.Combine(directory, "occurrences-v1.json")); }
        catch (Exception error) when (error is IOException or JsonException or InvalidDataException)
        { _ledgerError = error.Message; }
        _notifications = new PrayerNotificationDelivery(bus);
        _notifications.Action = (action, session) => SerializedCommand(new(action, session), "notification");
        _store.Reload();
        var ownerPath = System.IO.Path.Combine(legacyDirectory, "delivery-owner.json");
        if (File.Exists(ownerPath))
        {
            try {
                var saved = JsonSerializer.Deserialize<DeliveryOwner>(File.ReadAllText(ownerPath), TrayConfiguration.JsonOptions);
                _owner = saved?.Owner == "native" && _store.Current?.Experience?.Configured == true ? "native" : "recoveryRequired";
                RecoverApply(saved);
            } catch (Exception error) when (error is IOException or JsonException or InvalidDataException)
            { _owner = "recoveryRequired"; _error = error.Message; }
        }
        else
        {
            try { RecoverApply(null); }
            catch (Exception error) when (error is IOException or JsonException or InvalidDataException)
            { _owner = "recoveryRequired"; _error = error.Message; }
        }
        _due.Reset(_clockSource.GetCurrentInstant());
    }
    private void RecoverApply(DeliveryOwner? owner)
    {
        var path = System.IO.Path.Combine(_directory, "apply-journal.json");
        if (!File.Exists(path)) return;
        using var journal = JsonDocument.Parse(File.ReadAllText(path));
        if (journal.RootElement.GetProperty("phase").GetString() != "prepared") return;
        var intended = TrayConfiguration.Parse(journal.RootElement.GetProperty("intended").GetRawText());
        var current = _store.Current;
        if (owner?.Owner == "native" && owner.Revision == intended.Revision && current?.Revision >= intended.Revision)
        {
            // The ownership decision was committed but its reply/journal completion was lost.
            DurableFile.Write(path, JsonSerializer.Serialize(new { phase = "committed", revision = current.Revision,
                recovered = true }, TrayConfiguration.JsonOptions));
            return;
        }
        if (current?.Revision == intended.Revision && journal.RootElement.GetProperty("previous").ValueKind == JsonValueKind.Object)
        {
            var previous = TrayConfiguration.Parse(journal.RootElement.GetProperty("previous").GetRawText()) with {
                Revision = intended.Revision + 1, PublishedAtUtc = DateTimeOffset.UtcNow };
            var json = JsonSerializer.Serialize(previous, TrayConfiguration.JsonOptions);
            if (!_store.Accept(json)) throw new IOException(_store.Error);
            DurableFile.Write(_configPath, json);
            DurableFile.Write(path, JsonSerializer.Serialize(new { phase = "rolledBack", revision = previous.Revision }, TrayConfiguration.JsonOptions));
        }
    }
    public async Task Initialize()
    {
        _session.Interrupt = InterruptSession;
        await _session.Initialize(); await _notifications.Initialize(); await Tick();
    }
    private async Task InterruptSession()
    {
        try
        {
            await _gate.WaitAsync(_shutdown);
            try { await EndAll(); _due.Reset(_clockSource.GetCurrentInstant()); Publish(); }
            finally { _gate.Release(); }
        }
        catch (OperationCanceledException) when (_shutdown.IsCancellationRequested) { }
    }
    public async Task Tick()
    {
        await _gate.WaitAsync(_shutdown);
        try
        {
            _store.Reload();
            var now = _clockSource.GetCurrentInstant();
            var wall = now.ToUnixTimeMilliseconds();
            var elapsed = _clock.ElapsedMilliseconds;
            // Wall/monotonic divergence or a missed dispatcher interval is a resume/clock boundary.
            var discontinuity = _lastTick != 0 && (elapsed - _lastTick > 5000 ||
                Math.Abs((wall - _lastWall) - (elapsed - _lastTick)) > 5000);
            _lastWall = wall; _lastTick = elapsed;
            PrayerEvent? missed = null;
            if (_session.ConsumeBoundary() || discontinuity)
            { missed = _due.Missed(_store.Current, now); await EndAll(); _due.Reset(now); }
            await _notifications.Refresh();
            var shellOwner = await BusCalls.Owner(_bus, "org.gnome.Shell");
            if (_shellOwner is not null && _shellOwner != shellOwner)
            { _environment = new(false, false, []); await EndFocus(); }
            _shellOwner = shellOwner;
            var previousApp = _appOwner;
            _appOwner = await BusCalls.Owner(_bus, "com.aw.huda");
            if (_preview is { } preview && _appOwner != preview.Origin && _shellOwner != preview.Origin) await End(preview);
            if (previousApp != _appOwner) _due.Reset(now);
            try
            {
                _locked = await _bus.CallMethodAsync(BusCalls.Message(_bus, "org.gnome.ScreenSaver",
                    "/org/gnome/ScreenSaver", "org.gnome.ScreenSaver", "GetActive"),
                    static (message, _) => message.GetBodyReader().ReadBool()).WaitAsync(TimeSpan.FromSeconds(1));
            }
            catch (Exception error) when (error is DBusExceptionBase or TimeoutException) { _locked = null; }
            var config = _store.Current;
            var settings = config?.Experience;
            var mayDeliver = _ledger is not null && _owner == "native" && settings is { Configured: true, Enabled: true } &&
                !_session.Sleeping && (settings.BackgroundEnabled || _appOwner is not null);
            if (!mayDeliver && _owner != "legacy" && _live is { } stoppedLive) { await End(stoppedLive); _live = null; }
            var current = _preview ?? _live;
            if (current is not null)
            {
                if (!current.Preview && settings is { Configured: true } && (!settings.Enabled || settings.Quiet || settings.Mode == "silent") ||
                    _locked != false || _clock.ElapsedMilliseconds - _shellSeen > 35000 && current.FocusState is "pending" or "presented")
                    await End(current);
                else if (current.FocusState == "pending" && current.Age.Elapsed.TotalSeconds > 5)
                { current.FocusState = "fallback"; current.FocusError = "Focus presentation was not acknowledged."; _focusFallback = current.FocusError; Record(current); }
                else if (current.FocusTimer is { } timer && timer.Elapsed.TotalSeconds >= current.FocusSeconds) await End(current);
            }
            if (_audioPending is { } pending && (_appOwner is null || elapsed - _audioRequestedAt > 3000))
            {
                _audioPending = null;
                if (_appOwner is null && _locked == false && (pending.Preview || mayDeliver)) await StartPlayer(pending);
                else _audioError = "Frontend audio handoff was not acknowledged.";
            }
            // A prayer missed during sleep is shown once, silently: no late adhan or Focus.
            if (missed is not null && mayDeliver && config is not null)
            {
                using var dispatch = new DispatchLock(System.IO.Path.Combine(_legacyDirectory, "dispatch.lock"));
                var id = PrayerOccurrence.Id(missed, config.Location!.TimeZoneId);
                if (_ledger?.Claim(id, now) == true)
                {
                    _live = new($"prayer:{id}:{Guid.NewGuid():N}", false, "scheduler", missed,
                        config.Experience! with { Mode = "silent" }, config);
                    await Deliver(_live, "previewNotification");
                }
            }
            foreach (var prayer in _due.Poll(config, now, mayDeliver))
            {
                if (config is null) break;
                using var dispatch = new DispatchLock(System.IO.Path.Combine(_legacyDirectory, "dispatch.lock"));
                var id = PrayerOccurrence.Id(prayer, config.Location!.TimeZoneId);
                if (_ledger?.Claim(id, now) != true) continue;
                await EndAll();
                _live = new($"prayer:{id}:{Guid.NewGuid():N}", false, "scheduler", prayer,
                    config.Experience!.For(prayer.Key), config);
                await Deliver(_live, "previewNotification");
            }
            foreach (var (prayer, minutes) in _due.PollAdvance(config, now, mayDeliver))
            {
                if (config is null) break;
                using var dispatch = new DispatchLock(System.IO.Path.Combine(_legacyDirectory, "dispatch.lock"));
                // Before-prayer reminders: the prayer's occurrence id plus 140,000,000.
                var id = PrayerOccurrence.Id(prayer, config.Location!.TimeZoneId) + AdvanceIdOffset;
                if (_ledger?.Claim(id, now) != true) continue;
                await DeliverAdvance(prayer, minutes, config);
            }
            var audio = _player.Status;
            if (_lastAudioState != $"{audio.SessionId}:{audio.State}")
            {
                _lastAudioState = $"{audio.SessionId}:{audio.State}";
                if (audio.SessionId is { } session && audio.State is "ended" or "cutoff" or "stopped" or "failed")
                    await _notifications.RetireActions(session,
                        _preview?.Id == session && _preview.FocusState is "pending" or "presented" ||
                        _live?.Id == session && _live.FocusState is "pending" or "presented");
                if (_live is { } live && live.Id == audio.SessionId) Record(live);
            }
            Publish();
        }
        catch (Exception error) when (error is IOException or DBusExceptionBase or JsonException or InvalidDataException or TimeoutException)
        { _error = error.Message; Publish(); }
        finally { _gate.Release(); }
    }
    private void Publish()
    {
        var config = _store.Current;
        var audio = _player.Status;
        var focus = _preview?.FocusState is "pending" or "presented" ? _preview : _live?.FocusState is "pending" or "presented" ? _live : null;
        var remaining = focus is null ? 0 : Math.Max(0, focus.FocusSeconds - (focus.FocusTimer?.Elapsed.TotalSeconds ?? 0));
        var status = new {
            // 2: per-prayer settings and reminders before prayers.
            version = 1, experienceVersion = 2, changeSerial = ++_serial, appliedRevision = config?.Revision ?? 0,
            locationRevision = config?.NotificationContract?.LocationRevision ?? 0,
            scheduleRevision = config?.NotificationContract?.ScheduleRevision ?? 0,
            configurationSignature = config?.NotificationContract?.ConfigurationSignature ?? "",
            deliveryOwner = _owner, experience = config?.Experience ?? new LinuxPrayerExperience(),
            applyState = _prepared is null ? "idle" : "prepared", preparedRevision = _prepared?.Revision,
            ready = _ledger is not null && _owner == "native" && config?.Location?.Verified == true && _error is null,
            effectiveStartAtLogin = config?.Preferences.StartAtLogin ?? false,
            frontendPresent = _appOwner is not null, locked = _locked,
            suspendObservation = new { source = _session.Source, sleeping = _session.Sleeping, error = _session.Error },
            // Locked playback remains unavailable until strict-profile transition tests verify it.
            supportsLockedAudio = false, focusAvailable = _environment.Available && _environment.Unlocked &&
                _locked == false && _clock.ElapsedMilliseconds - _shellSeen <= 35000,
            displays = _environment.Displays, presentation = config?.Presentation,
            timeZoneId = config?.Location?.TimeZoneId, error = _error ?? _ledgerError ?? _store.Error,
            notificationServer = new { state = _notifications.State, information = _notifications.ServerInformation,
                capabilities = _notifications.Capabilities, silentSupported = _notifications.SilentSupported, error = _notifications.Error },
            notificationState = _notificationState, notificationPresentation = "unknownDesktopPolicy",
            audioState = audio.State, audioSession = audio.State is "loading" or "playing" ? audio.SessionId : null,
            audioRequestSession = _audioPending?.Id,
            audioPosition = audio.Position, audioDuration = audio.Duration, audioFallback = audio.Fallback,
            audioError = _audioError ?? audio.Error,
            previewSession = _preview?.Id,
            focusSession = focus?.Id, focusCanDismiss = focus is null || focus.Preview || !focus.Settings.FocusCommitment,
            focusFallback = _focusFallback,
            focus = focus is null ? null : new { sessionId = focus.Id, revision = focus.Configuration.Revision,
                state = focus.FocusState, preview = focus.Preview, prayerKey = focus.Prayer.Key,
                prayerUtcMs = focus.Prayer.Time.ToUnixTimeMilliseconds(), remainingSeconds = remaining,
                durationSeconds = focus.FocusSeconds, settings = focus.Settings,
                deadlineUtcMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() + (long)(remaining * 1000) }
        };
        _json = JsonSerializer.Serialize(status, TrayConfiguration.JsonOptions);
        var waiting = _changed; _changed = new(TaskCreationOptions.RunContinuationsAsynchronously); waiting.TrySetResult(_json);
    }
    public ValueTask HandleMethodAsync(MethodContext context)
    {
        if (context.IsDBusIntrospectRequest) { context.ReplyIntrospectXml([Schema]); return default; }
        var request = context.Request;
        if (request.InterfaceAsString != Interface) return default;
        var member = request.MemberAsString;
        if (member == "WaitForExperience" && request.SignatureAsString == "t")
        {
            var serial = request.GetBodyReader().ReadUInt64();
            context.DisposesAsynchronously = true; _ = Watch(context, serial); return default;
        }
        if (member == "GetStatus" && request.SignatureAsString == "" ||
            member is "Prepare" or "Activate" or "Command" or "ReportEnvironment" or "AcknowledgeFocus" && request.SignatureAsString == "s")
        {
            var json = member == "GetStatus" ? "" : request.GetBodyReader().ReadString();
            context.DisposesAsynchronously = true; _ = Request(context, member!, json);
        }
        return default;
    }
    private async Task Watch(MethodContext context, ulong serial)
    {
        using (context)
        {
            await _gate.WaitAsync();
            Task<string> next;
            try { next = serial != _serial ? Task.FromResult(_json) : _changed.Task; }
            finally { _gate.Release(); }
            try { Reply(context, await next.WaitAsync(TimeSpan.FromSeconds(25), _shutdown)); }
            catch (Exception error) when (error is TimeoutException or OperationCanceledException)
            { context.ReplyError(Interface + ".Unavailable", "Prayer service stopped or heartbeat expired."); }
        }
    }
    private static void Reply(MethodContext context, string json)
    { using var writer = context.CreateReplyWriter("s"); writer.WriteString(json); context.Reply(writer.CreateMessage()); }
    private async Task Request(MethodContext context, string member, string json)
    {
        using (context)
        {
            await _gate.WaitAsync();
            try
            {
                if (json.Length > 262144) throw new InvalidDataException("Request too large.");
                var sender = context.Request.SenderAsString;
                var shell = await BusCalls.Owner(_bus, "org.gnome.Shell");
                var app = await BusCalls.Owner(_bus, "com.aw.huda");
                if (member != "GetStatus" && (sender is null ||
                    (member is "ReportEnvironment" or "AcknowledgeFocus" ? sender != shell :
                        member is "Prepare" or "Activate" ? sender != app : sender != app && sender != shell)))
                    throw new UnauthorizedAccessException("The current Huda or GNOME Shell connection is required.");
                switch (member)
                {
                    case "Prepare":
                        if (_ledger is null) throw new IOException("Prayer occurrence history could not be verified.");
                        var proposed = TrayConfiguration.Parse(json);
                        if (_store.Current is { } accepted && proposed.Revision <= accepted.Revision)
                            throw new InvalidDataException("A fresh configuration revision is required.");
                        await _notifications.Refresh();
                        if (proposed.Experience is not { Configured: true }) throw new InvalidDataException("Missing reminder preferences.");
                        if (proposed.Experience.AllowLockedAudio) throw new InvalidDataException("Locked playback has not been verified on this desktop.");
                        if (proposed.Experience.Enabled && !_notifications.SilentSupported) throw new IOException("Silent desktop notification capability unavailable.");
                        if (proposed.Experience.Enabled)
                            foreach (var effective in proposed.Experience.Effective
                                .Where(item => item.Enabled && item.NeedsAudio)
                                .DistinctBy(item => (item.ReciterId, item.AudioVersion)))
                                await _audio.Resolve(effective, false);
                        _pending = json;
                        _prepared = proposed;
                        DurableFile.Write(System.IO.Path.Combine(_directory, "apply-journal.json"), JsonSerializer.Serialize(new {
                            phase = "prepared", previous = _store.Current, intended = proposed }, TrayConfiguration.JsonOptions));
                        _error = null;
                        break;
                    case "Activate":
                        if (_pending != json) throw new InvalidDataException("Prepared revision does not match activation.");
                        var next = TrayConfiguration.Parse(json);
                        // Unpackaged, Huda stops the legacy helper first, which frees its lifetime lock.
                        // The Snap can't stop its own daemon: there the dispatch lock alone guards the
                        // handover, because the helper re-reads the owner under it before every delivery
                        // and exits once native owns delivery (its script always comes from this Snap).
                        using (var legacy = Environment.GetEnvironmentVariable("SNAP") is null
                            ? new DispatchLock(System.IO.Path.Combine(_legacyDirectory, "helper.lock")) : null)
                        using (var dispatch = new DispatchLock(System.IO.Path.Combine(_legacyDirectory, "dispatch.lock")))
                        {
                            var history = System.IO.Path.Combine(_legacyDirectory, "last-delivered");
                            var imported = next.HandledOccurrenceIds.ToList();
                            if (File.Exists(history) && int.TryParse(File.ReadAllText(history).Trim(), out var id)) imported.Add(id);
                            _ledger?.ImportMany(imported, _clockSource.GetCurrentInstant());
                            // Native dispatch is still standby. Persist configuration first, then owner.
                            if (!_store.Accept(json)) throw new IOException(_store.Error);
                            DurableFile.Write(_configPath, json);
                            DurableFile.Write(System.IO.Path.Combine(_legacyDirectory, "delivery-owner.json"),
                                JsonSerializer.Serialize(new DeliveryOwner("native", next.Revision,
                                    DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()), TrayConfiguration.JsonOptions));
                            _owner = "native"; _pending = null; _prepared = null; _error = null;
                            // Applying a draft cleans its previews in Flutter. An unrelated live
                            // prayer retains its original policy unless live effects are disabled.
                            if (next.Experience is { Enabled: false } or { Quiet: true } or { Mode: "silent" })
                                await EndAll();
                            _due.Reset(_clockSource.GetCurrentInstant());
                            DurableFile.Write(System.IO.Path.Combine(_directory, "apply-journal.json"),
                                JsonSerializer.Serialize(new { phase = "committed", revision = next.Revision }, TrayConfiguration.JsonOptions));
                        }
                        break;
                    case "Command":
                        await Command(JsonSerializer.Deserialize<ExperienceCommand>(json, TrayConfiguration.JsonOptions)
                            ?? throw new InvalidDataException("Missing command."), sender!);
                        break;
                    case "ReportEnvironment":
                        var environment = JsonSerializer.Deserialize<ShellEnvironment>(json, TrayConfiguration.JsonOptions)
                            ?? throw new InvalidDataException("Missing Shell environment.");
                        if (environment.Displays.Count > 32 || environment.Displays.Any(item =>
                            !item.TryGetValue("id", out var id) || !System.Text.RegularExpressions.Regex.IsMatch(id, @"\Amonitor-[0-9]+\z")))
                            throw new InvalidDataException("Invalid display list.");
                        _environment = environment; _shellSeen = _clock.ElapsedMilliseconds;
                        if (!environment.Unlocked) await EndAll();
                        else if (!environment.Available) await EndFocus();
                        break;
                    case "AcknowledgeFocus":
                        var acknowledgment = JsonSerializer.Deserialize<FocusAcknowledgment>(json, TrayConfiguration.JsonOptions)!;
                        var focus = _preview ?? _live;
                        if (focus is null || focus.Id != acknowledgment.SessionId ||
                            focus.Configuration.Revision != acknowledgment.Revision || focus.FocusState != "pending")
                            throw new InvalidDataException("Stale Focus acknowledgment.");
                        if (!acknowledgment.Presented || _locked != false || !_environment.Unlocked)
                        { focus.FocusState = "fallback"; focus.FocusError = acknowledgment.Error ?? "Focus unavailable."; _focusFallback = focus.FocusError; }
                        else
                        {
                            focus.FocusState = "presented"; focus.FocusTimer = Stopwatch.StartNew();
                            if (focus.Settings.FocusAudio) await Play(focus);
                        }
                        Record(focus);
                        break;
                }
                Publish(); Reply(context, _json);
            }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException or JsonException or
                InvalidDataException or ArgumentException or DBusExceptionBase or TimeoutException)
            { _error = error.Message; Publish(); context.ReplyError(Interface + ".Rejected", error.Message); }
            finally { _gate.Release(); }
        }
    }
    private async Task SerializedCommand(ExperienceCommand command, string origin)
    {
        await _gate.WaitAsync();
        try { await Command(command, origin); Publish(); }
        finally { _gate.Release(); }
    }
    private async Task Command(ExperienceCommand command, string origin)
    {
        if (string.IsNullOrWhiteSpace(command.SessionId) || command.SessionId.Length > 160)
            throw new InvalidDataException("A session identity is required.");
        var session = _preview?.Id == command.SessionId ? _preview : _live?.Id == command.SessionId ? _live : null;
        if (command.Action is "previewNotification" or "previewAdhan" or "previewFocus")
        {
            if (!command.SessionId.StartsWith("preview:", StringComparison.Ordinal) || command.Settings is null)
                throw new InvalidDataException("Invalid preview identity.");
            if (_live is { FocusState: "pending" or "presented" } || _player.Status is { State: "loading" or "playing", SessionId: var liveAudio } && liveAudio == _live?.Id)
                throw new InvalidDataException("A scheduled prayer takes precedence over previews.");
            command.Settings.Validate();
            if (_locked != false || _session.Sleeping) throw new IOException("An unlocked active desktop is required for previews.");
            if (_preview is { } old) await End(old);
            var config = _store.Current ?? throw new IOException("Committed prayer settings unavailable.");
            var now = _clockSource.GetCurrentInstant();
            _preview = new(command.SessionId, true, origin, new("dhuhr",
                now.InZone(DateTimeZoneProviders.Tzdb[config.Location?.TimeZoneId ?? "UTC"]).Date, now), command.Settings,
                config with { Experience = command.Settings });
            await Deliver(_preview, command.Action); return;
        }
        if (session is null) throw new InvalidDataException("Stale prayer session.");
        if (command.Action == "stopPreview" && (!session.Preview || session.Origin != origin))
            throw new UnauthorizedAccessException("Preview belongs to another connection.");
        switch (command.Action)
        {
            case "acknowledgeAudio":
                if (_audioPending?.Id != session.Id || origin != await BusCalls.Owner(_bus, "com.aw.huda"))
                    throw new InvalidDataException("Stale frontend audio acknowledgment.");
                _audioPending = null; await StartPlayer(session); break;
            case "stopAudio":
                if (_audioPending?.Id == session.Id) _audioPending = null;
                await _player.Stop(session.Id); Record(session); break;
            case "setVolume":
                if (command.Volume is not { } volume || !_player.SetVolume(session.Id, volume))
                    throw new InvalidDataException("Playback session or volume unavailable.");
                break;
            case "stopPreview": await End(session); break;
            case "dismissFocus":
                if (session.Settings.FocusCommitment && !session.Preview) throw new InvalidDataException("Use emergency exit for a committed Focus session.");
                await End(session); break;
            case "emergencyExit": await End(session); break;
            default: throw new InvalidDataException("Unknown prayer action.");
        }
    }
    private async Task Deliver(PrayerSession session, string action)
    {
        _audioError = null; _focusFallback = "";
        var labels = session.Configuration.Presentation.Strings;
        string clock(Instant instant)
        {
            var text = instant.InZone(DateTimeZoneProviders.Tzdb[session.Configuration.Location?.TimeZoneId ?? "UTC"])
                .ToDateTimeOffset().ToString(session.Configuration.Presentation.Use24HourClock ? "HH:mm" : "h:mm tt",
                    CultureInfo.GetCultureInfo(session.Configuration.Presentation.Locale));
            var digits = session.Configuration.Presentation.Numerals switch {
                "arabic" => "٠١٢٣٤٥٦٧٨٩", "easternArabic" => "۰۱۲۳۴۵۶۷۸۹", _ => "0123456789" };
            return string.Concat(text.Select(ch => ch is >= '0' and <= '9' ? digits[ch - '0'] : ch));
        }
        var name = labels[session.Prayer.Key];
        var title = labels.GetValueOrDefault(session.Prayer.Key + "Title", name);
        var body = $"{labels.GetValueOrDefault(session.Prayer.Key + "Body", name)} · \u2068{clock(session.Prayer.Time)}\u2069";
        var quiet = session.Settings.Quiet && (!session.Preview || action == "previewNotification");
        var focus = action == "previewFocus" || action == "previewNotification" && session.Settings.Mode == "focus";
        var audio = action == "previewAdhan" || action == "previewNotification" && session.Settings.Mode == "adhan";
        if (action != "previewAdhan")
        {
            try { await _notifications.Notify(session.Id, title, body, session.Configuration, !quiet && (audio || focus && session.Settings.FocusAudio), focus); _notificationState = "transportAccepted"; }
            catch (Exception error) when (error is IOException or DBusExceptionBase or TimeoutException)
            { _notificationState = "failed"; _error = error.Message; }
        }
        if (focus && !quiet)
        {
            if (_locked == false && _environment is { Available: true, Unlocked: true } && _clock.ElapsedMilliseconds - _shellSeen <= 35000)
                session.FocusState = "pending";
            else { session.FocusState = "fallback"; session.FocusError = "An enabled compatible GNOME extension and unlocked desktop are required."; _focusFallback = session.FocusError; }
        }
        else if (audio && !quiet && _locked == false) await Play(session);
        Record(session);
    }
    public const int AdvanceIdOffset = 140_000_000;

    /// A quiet notification some minutes before a prayer; no adhan or Focus.
    private async Task DeliverAdvance(PrayerEvent prayer, int minutes, TrayConfiguration config)
    {
        var labels = config.Presentation.Strings;
        var digits = config.Presentation.Numerals switch {
            "arabic" => "٠١٢٣٤٥٦٧٨٩", "easternArabic" => "۰۱۲۳۴۵۶۷۸۹", _ => "0123456789" };
        var count = string.Concat(minutes.ToString(CultureInfo.InvariantCulture).Select(ch => digits[ch - '0']));
        var name = labels[prayer.Key];
        var body = labels.GetValueOrDefault("prayerAdvanceBody", "{prayer} in {minutes} minutes")
            .Replace("{prayer}", name).Replace("{minutes}", count);
        try
        {
            await _notifications.Notify($"advance:{prayer.Key}:{Guid.NewGuid():N}", name, body, config, false, false);
            _notificationState = "transportAccepted";
        }
        catch (Exception error) when (error is IOException or DBusExceptionBase or TimeoutException)
        { _notificationState = "failed"; _error = error.Message; }
    }
    private async Task Play(PrayerSession session)
    {
        if (await BusCalls.Owner(_bus, "com.aw.huda") is not null)
        { _audioPending = session; _audioRequestedAt = _clock.ElapsedMilliseconds; }
        else await StartPlayer(session);
    }
    private async Task StartPlayer(PrayerSession session)
    {
        try { await _player.Start(session.Id, await _audio.Resolve(session.Settings, !session.Preview), session.Settings); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or JsonException or InvalidOperationException)
        { _audioError = error.Message; }
    }
    private void Record(PrayerSession session)
    {
        if (session.Preview) return;
        _ledger?.Record(PrayerOccurrence.Id(session.Prayer, session.Configuration.Location!.TimeZoneId),
            notification: _notificationState, audio: _audioError is null ? _player.Status.SessionId == session.Id ? _player.Status.State : "notRequested" : "failed",
            focus: session.FocusState);
    }
    private async Task End(PrayerSession session)
    {
        if (_audioPending?.Id == session.Id) _audioPending = null;
        await _player.Stop(session.Id);
        if (session.FocusState is "pending" or "presented") session.FocusState = "ended";
        Record(session);
        if (session.Preview) { await _notifications.Close(session.Id); if (_preview == session) _preview = null; }
        else await _notifications.RetireActions(session.Id, false);
    }
    private async Task EndAll()
    { if (_preview is { } preview) await End(preview); if (_live is { } live) { await End(live); _live = null; } }
    private async Task EndFocus()
    {
        if (_preview is { FocusState: "pending" or "presented" } preview) await End(preview);
        if (_live is { FocusState: "pending" or "presented" } live) await End(live);
    }
    public async ValueTask DisposeAsync()
    { _session.Dispose(); await EndAll(); await _player.DisposeAsync(); _notifications.Dispose(); }
}
