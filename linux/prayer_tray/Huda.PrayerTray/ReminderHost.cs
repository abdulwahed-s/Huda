using Huda.PrayerTray.Core;
using NodaTime;
using Tmds.DBus.Protocol;

namespace Huda.PrayerTray;

/// <summary>
/// Shows the reminders, random Athkar and calendar events Huda publishes in
/// its configuration. Linux has no scheduled-notification queue, so this
/// companion delivers them while the user session runs, with Huda closed.
/// </summary>
internal sealed class ReminderHost(DBusConnection connection, ConfigurationStore store, string directory) : IDisposable
{
    private readonly PrayerNotificationDelivery _delivery = new(connection);
    private readonly ReminderDispatcher _dispatcher = new(Path.Combine(directory, "reminder-state.json"));
    private bool _initialized;

    public string? Error { get; private set; }

    public async Task Tick()
    {
        var config = store.Current;
        if (config is null || config.ReminderRules.Count == 0) return;
        var due = _dispatcher.Due(config.ReminderRules, SystemClock.Instance.GetCurrentInstant(),
            DateTimeZoneProviders.Tzdb.GetSystemDefault(), Random.Shared);
        if (due.Count == 0) return;
        try
        {
            if (!_initialized) { await _delivery.Initialize(); _initialized = true; }
            await _delivery.Refresh();
            var open = config.Presentation.Strings.GetValueOrDefault("openHuda", "Open Huda");
            // Each occurrence is already recorded: a failure loses it rather
            // than repeating it later.
            foreach (var reminder in due)
                await _delivery.NotifyReminder(reminder.Rule.Title, reminder.Body, open, config, reminder.Rule.Payload);
            Error = null;
        }
        catch (Exception error) when (error is DBusExceptionBase or IOException or TimeoutException)
        {
            Error = error.Message;
        }
    }

    public void Dispose() => _delivery.Dispose();
}
