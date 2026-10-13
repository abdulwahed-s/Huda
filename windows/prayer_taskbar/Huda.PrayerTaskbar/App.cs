using System.Text.Json;
using System.Windows.Input;
using H.NotifyIcon;
using H.NotifyIcon.Core;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using NodaTime;
using Windows.UI.Notifications;
using Windows.UI.ViewManagement;

namespace Huda.PrayerTaskbar;

public sealed partial class App : Application
{
    private readonly ConfigurationStore _store;
    private readonly DispatcherQueue _dispatcher = DispatcherQueue.GetForCurrentThread();
    private readonly ScheduleCalculator _calculator = new(new RamadanCalendar());
    private PrayerPopup _popup = null!;
    private TaskbarSurface _taskbar = null!;
    private NativeWindow _events = null!;
    private TaskbarInspector _inspector = null!;
    private PipeServer _pipe = null!;
    private DispatcherQueueTimer _timer = null!;
    private readonly UISettings _systemTheme = new();
    private readonly bool _prototype;
    private readonly bool _smokeTest;
    private readonly string? _previewOutput;
    private TaskbarIcon? _tray;
    private System.Drawing.Icon? _icon;
    private ScheduleSnapshot? _schedule;
    private TaskbarConfiguration _configuration;
    private bool _stopping, _caughtUp;
    private Instant _previousTick;
    private string? _runtimeError;
    private PrayerPlayback _playback = null!;
    private readonly PrayerFocus _focus = new();
    private readonly PrayerNotificationPreview _notificationPreview = new();
    private readonly PrayerDueEvents _due = new();
    private readonly PrayerToastQueue _toastQueue = new();
    private PrayerOccurrenceLedger _ledger = null!;
    private MenuFlyoutItem? _stopAdhanItem, _dismissFocusItem, _quitItem;
    private PrayerEvent? _testPrayer;

    public App(ConfigurationStore store, bool prototype, bool smokeTest = false, string? previewOutput = null)
    {
        UnhandledException += (_, args) => Console.Error.WriteLine(args.Exception);
        InitializeComponent();
        _store = store; _prototype = prototype; _smokeTest = smokeTest; _previewOutput = previewOutput;
        _configuration = store.Current ?? Prototype.Configuration(prototype);
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _events = new NativeWindow();
        _focus.UseExitWindow(_events.Handle);
        _playback = new PrayerPlayback(_dispatcher);
        _ledger = new PrayerOccurrenceLedger(_prototype
            ? Path.Combine(Paths.PrototypeDirectory ?? AppContext.BaseDirectory, "prototype-prayer-history.json")
            : Path.Combine(Paths.DirectoryPath, "prayer-occurrences.json"));
        _popup = new PrayerPopup(PointerOverTrigger);
        _popup.StopAdhan += () => _playback.Stop(_playback.SessionId);
        _popup.DismissFocus += () => _focus.TryDismiss(_focus.SessionId);
        _playback.Changed += UpdatePlaybackControls;
        _focus.StopAudio += session => _playback.Stop(session);
        _focus.Ended += session => { _playback.Stop(session); UpdatePlaybackControls(); };
        _taskbar = new TaskbarSurface(TogglePopup);
        _events.Message += message => {
            if (message == NativeMethods.WM_HOTKEY && _focus.SessionId is { } focusSession)
                _dispatcher.TryEnqueue(() => _focus.TryDismiss(focusSession));
            if (message is NativeMethods.WM_TIMECHANGE or NativeMethods.WM_POWERBROADCAST or
                NativeMethods.WM_SETTINGCHANGE or NativeMethods.WM_DISPLAYCHANGE or NativeMethods.WM_DPICHANGED)
                _dispatcher.TryEnqueue(() => { _focus.RebuildDisplays(); Tick(force: true); });
        };
        _systemTheme.ColorValuesChanged += (_, _) => _dispatcher.TryEnqueue(() => Tick(force: true));
        _inspector = new TaskbarInspector(() => _taskbar.Width, layout =>
            _dispatcher.TryEnqueue(() => { if (!_stopping) _taskbar.Place(layout); }));
        _pipe = new PipeServer(_dispatcher, Command);
        _timer = _dispatcher.CreateTimer();
        _timer.Tick += (_, _) => Tick();
        Apply();
        _inspector.Start(); _pipe.Start(); _timer.Start();
        if (_previewOutput is not null) ShowPopup();
        if (_smokeTest)
        {
            var probe = _dispatcher.CreateTimer();
            probe.Interval = TimeSpan.FromSeconds(4); probe.IsRepeating = false;
            probe.Tick += async (_, _) => {
                try
                {
                    if (_previewOutput is not null)
                    {
                        await _popup.Export(_previewOutput);
                        await _taskbar.Export(Path.ChangeExtension(_previewOutput, "taskbar.png"));
                    }
                    Console.Write(await Command("status"));
                    Console.Out.Flush();
                }
                catch (Exception error) { Console.Error.Write(error); Environment.ExitCode = 1; }
                finally { Stop(); }
            };
            probe.Start();
        }
    }

    private void Apply()
    {
        _schedule = null;
        _runtimeError = null;
        _due.Apply(SystemClock.Instance.GetCurrentInstant(), _configuration.PrayerExperienceActiveFromUtc);
        if (_configuration.PrayerExperience is not { Configured: true, Enabled: true } experience ||
            experience.Mode == "silent") { _focus.TryDismiss(); _playback.Stop(); }
        else {
            if (experience.Mode != "focus") _focus.TryDismiss();
            if (!experience.PlaysAudio) _playback.Stop();
            _playback.SetVolume(experience.Volume);
        }
        if (!LifecyclePolicy.ShowTray(_configuration.Preferences)) DisposeTray();
        else
        {
            if (_tray is null)
            {
                _icon = new System.Drawing.Icon(Path.Combine(AppContext.BaseDirectory, "Assets", "app.ico"));
                _tray = new TaskbarIcon { Icon = _icon, LeftClickCommand = new ActionCommand(TogglePopup),
                    DoubleClickCommand = new ActionCommand(() => _popup.Hide()),
                    RightClickCommand = new ActionCommand(() => _popup.Hide()),
                    NoLeftClickDelay = true, MenuActivation = PopupActivationMode.RightClick };
                if (_prototype && Paths.InstanceSuffix.Length > 0)
                    _tray.Id = Guid.Parse(Paths.InstanceSuffix[1..]);
                _tray.ForceCreate(enablesEfficiencyMode: false);
            }
            var menu = new MenuFlyout();
            // The tray menu is H.NotifyIcon's PopupMenu emulation, which runs each
            // item's Command and never raises MenuFlyoutItem.Click.
            MenuFlyoutItem Item(string key, Action action)
            {
                var item = new MenuFlyoutItem {
                    Text = _configuration.Presentation.Label(key), Command = new ActionCommand(action),
                    FontFamily = PresentationAssets.Font(_configuration.Presentation.FontFamily),
                    FontSize = PresentationAssets.FontSize(_configuration.Presentation.FontFamily, 14) };
                menu.Items.Add(item);
                return item;
            }
            Item("prayerTimes", ShowPopup);
            Item("quran", () => OpenPage("quran"));
            Item("athkar", () => OpenPage("athkar"));
            Item("openHuda", () => OpenPage("home"));
            _stopAdhanItem = Item("prayerStopAdhan", () => _playback.Stop(_playback.SessionId));
            _dismissFocusItem = Item("prayerDismissFocus", () => _focus.TryDismiss(_focus.SessionId));
            menu.Items.Add(new MenuFlyoutSeparator());
            _quitItem = Item("quitHuda", Quit);
            _tray.ContextFlyout = menu;
            _tray.FlowDirection = _configuration.Presentation.Rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
            _tray.RequestedTheme = TaskbarSurface.Theme(_configuration.Presentation.ThemeMode);
        }
        _timer.Interval = _configuration.Preferences.ShowTaskbarCountdown || _tray is not null
            ? TimeSpan.FromSeconds(1) : TimeSpan.FromSeconds(30);
        Tick(force: true);
        UpdatePlaybackControls();
    }

    private void Tick(bool force = false)
    {
        if (_stopping) return;
        var now = SystemClock.Instance.GetCurrentInstant();
        var shifted = _previousTick != default && Math.Abs((now - _previousTick).TotalSeconds) >
            _timer.Interval.TotalSeconds + 5;
        _previousTick = now;
        // Windows drops toasts that fell due while the PC slept or was off.
        // Catch up once at start and after every clock gap (resume, clock change).
        if (!_caughtUp || shifted)
        {
            _caughtUp = true;
            var configuration = _configuration;
            _toastQueue.CatchUp(now, _prototype, missed => PrayerEnd(configuration, missed));
        }
        if (_configuration.Location is { } location)
        {
            var today = now.InZone(DateTimeZoneProviders.Tzdb[location.TimeZoneId]).Date;
            if (force || shifted || _schedule?.Today != today)
            {
                try { _schedule = _calculator.Snapshot(_configuration, now); _runtimeError = null; }
                catch (Exception error) when (error is ArgumentException or InvalidDataException)
                { _schedule = null; _runtimeError = error.Message; }
            }
        }
        var text = CountdownFormatter.Text(_configuration, _schedule, now);
        _taskbar.Update(_configuration, text);
        var tooltip = _configuration.Location is { Verified: false }
            ? text + "\n" + _configuration.Presentation.Label("verifyLocation") : text;
        if (_tray is not null && _tray.ToolTipText != tooltip) _tray.ToolTipText = tooltip;
        if (_popup.Visible || force) _popup.Update(_configuration, _schedule, now);
        var deliverySchedule = _prototype && _testPrayer is { } test && _schedule is not null
            ? _schedule with { Events = [test] } : _schedule;
        foreach (var prayer in _due.Poll(_configuration, deliverySchedule, now)) {
            try {
                if (_ledger.Claim(PrayerOccurrence.Id(prayer, _configuration.Location!.TimeZoneId), now))
                    _ = Deliver(prayer);
            } catch (Exception error) { _runtimeError = error.Message; }
        }
        foreach (var (prayer, minutes) in _due.PollAdvance(_configuration, deliverySchedule, now)) {
            try {
                // Before-prayer reminders: the prayer's occurrence id plus 140,000,000.
                if (_ledger.Claim(PrayerOccurrence.Id(prayer, _configuration.Location!.TimeZoneId) + 140_000_000, now))
                    ShowAdvance(prayer, minutes);
            } catch (Exception error) { _runtimeError = error.Message; }
        }
        _focus.Update(_configuration, _playback.Playing);
        _toastQueue.Check(_configuration, now, _prototype);
    }

    /// When a missed prayer's time ends: the next of Fajr, Sunrise, Dhuhr, Asr,
    /// Maghrib and Isha after it (Fajr ends at sunrise, Isha at the next Fajr).
    private Instant? PrayerEnd(TaskbarConfiguration config, MissedToast prayer)
    {
        if (config.Location is not { } location || config.Calculation is null) return null;
        try
        {
            var date = prayer.DueAt.InZone(DateTimeZoneProviders.Tzdb[location.TimeZoneId]).Date;
            Instant? end = null;
            foreach (var day in new[] { date.PlusDays(-1), date, date.PlusDays(1) })
                foreach (var time in _calculator.Calculate(config, day).Times.Values)
                    // Huda and the companion may differ by seconds for the same prayer.
                    if (time is { } value && value > prayer.DueAt + NodaTime.Duration.FromMinutes(1) && (end is null || value < end))
                        end = value;
            return end;
        }
        catch (Exception error) when (error is ArgumentException or InvalidDataException or KeyNotFoundException
            or NodaTime.TimeZones.DateTimeZoneNotFoundException) { return null; }
    }

    private async Task Deliver(PrayerEvent prayer)
    {
        var settings = _configuration.PrayerExperience!.For(prayer.Key);
        if (_focus.Visible && !_focus.CanDismiss) return;
        var session = Guid.NewGuid().ToString();
        _notificationPreview.Clear();
        _focus.End(); _playback.Stop();
        if (settings.Mode == "focus" && !_focus.Start(_configuration with { PrayerExperience = settings },
            prayer.Key, prayer.Time, session)) return;
        UpdatePlaybackControls();
        if (settings.PlaysAudio) {
            if (!_prototype) _ = Task.Run(() => HudaActivation.Send("prayer-audio"));
            await _playback.Start(settings, session, false);
        }
    }

    /// A silent toast some minutes before a prayer; it goes away after half an hour.
    private void ShowAdvance(PrayerEvent prayer, int minutes)
    {
        if (_prototype && !Paths.TestToastQueue) return;
        var appId = Paths.TestToastQueue ? "Huda.SchedulingInvestigation.20261003" : "awr.Huda-IslamicCompanionApp";
        var notifier = StartupRegistration.IsPackaged ? ToastNotificationManager.CreateToastNotifier()
            : ToastNotificationManager.CreateToastNotifier(appId);
        var document = new Windows.Data.Xml.Dom.XmlDocument();
        document.LoadXml(PrayerToastContent.AdvanceXml(_configuration, prayer, minutes));
        notifier.Show(new ToastNotification(document) {
            Tag = $"advance{prayer.Key}", Group = "HudaPrayerAdvance",
            ExpirationTime = DateTimeOffset.UtcNow.AddMinutes(30),
        });
    }

    private void UpdatePlaybackControls()
    {
        if (_stopAdhanItem is not null) _stopAdhanItem.Visibility = _playback.Playing ? Visibility.Visible : Visibility.Collapsed;
        if (_dismissFocusItem is not null) _dismissFocusItem.Visibility = _focus.Visible && _focus.CanDismiss ? Visibility.Visible : Visibility.Collapsed;
        if (_quitItem is not null) _quitItem.IsEnabled = _focus.CanDismiss;
        _popup.UpdatePlayback(_configuration, _playback.Playing, _focus.Visible && _focus.CanDismiss);
        _focus.Update(_configuration, _playback.Playing);
    }

    private void ShowPopup()
    {
        Tick(); _popup.Update(_configuration, _schedule, SystemClock.Instance.GetCurrentInstant());
        _popup.Show(_taskbar.Anchor);
    }

    private void TogglePopup()
    {
        if (_popup.Visible) _popup.Hide();
        else ShowPopup();
    }

    private void OpenPage(string page) { _popup.Hide(); HudaActivation.Open(page); }

    private bool PointerOverTrigger()
    {
        if (!NativeMethods.GetCursorPos(out var point)) return false;
        static bool Contains(NativeMethods.Rect bounds, NativeMethods.Point position) =>
            position.X >= bounds.Left && position.X < bounds.Right &&
            position.Y >= bounds.Top && position.Y < bounds.Bottom;
        if (_taskbar?.Anchor is { } anchor && Contains(anchor, point)) return true;
        if (_tray is not { IsCreated: true }) return false;
        var icon = new NativeMethods.NotifyIconIdentifier {
            Size = (uint)System.Runtime.InteropServices.Marshal.SizeOf<NativeMethods.NotifyIconIdentifier>(),
            Guid = _tray.TrayIcon.Id,
        };
        return NativeMethods.Shell_NotifyIconGetRect(ref icon, out var trayBounds) == 0 && Contains(trayBounds, point);
    }

    private async Task<string> Command(string verb, JsonElement arguments = default)
    {
        if (verb == "shutdown")
        {
            _configuration = _configuration with { Preferences = _configuration.Preferences with { Enabled = false } };
            _timer.Stop(); DisposeTray(); _taskbar.Update(_configuration, ""); _popup.Hide();
            _focus.End(); _playback.Stop(); await _toastQueue.Suspend();
            // Send the acknowledgement before exiting the IPC server/message loop.
            var delay = _dispatcher.CreateTimer();
            delay.Interval = TimeSpan.FromMilliseconds(200); delay.IsRepeating = false;
            delay.Tick += (_, _) => Stop(); delay.Start();
            return "{\"stopped\":true}";
        }
        if (verb == "reload")
        {
            if (_store.Reload() && _store.Current is { } current)
            { _configuration = current; Apply(); }
            if (!_configuration.Preferences.Enabled) DisposeTray();
        }
        if (verb == "suspendRenewal") _toastQueue.RequestSuspend();
        if (verb == "resumeRenewal") _toastQueue.Resume();
        if (verb == "scheduleTestPrayer" && _prototype) {
            var key = arguments.GetProperty("prayer").GetString()!;
            var delay = arguments.GetProperty("secondsFromNow").GetInt32();
            if (key is not ("fajr" or "dhuhr" or "asr" or "maghrib" or "isha") || delay is < 1 or > 60)
                throw new InvalidDataException("Invalid prototype prayer.");
            var instant = SystemClock.Instance.GetCurrentInstant() + NodaTime.Duration.FromSeconds(delay);
            _testPrayer = new PrayerEvent(key, instant.InUtc().Date, instant);
        }
        if (verb == "exportFocus" && _prototype && Paths.PrototypeDirectory is { } directory) {
            var destination = Path.GetFullPath(arguments.GetProperty("path").GetString()!);
            if (!destination.StartsWith(Path.GetFullPath(directory) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) ||
                Path.GetExtension(destination) != ".png") throw new InvalidDataException("Invalid prototype export path.");
            var displayIndex = arguments.TryGetProperty("displayIndex", out var display) ? display.GetInt32() : 0;
            await _focus.Export(destination, displayIndex);
        }
        if (verb is "previewAdhan" or "previewFocus" or "previewNotification") {
            if (_focus.Visible && !_focus.CanDismiss)
                throw new InvalidOperationException("Focus ends when its timer reaches zero.");
            var settings = JsonSerializer.Deserialize<PrayerExperience>(arguments.GetProperty("settings"), TaskbarConfiguration.JsonOptions)
                ?? throw new InvalidDataException("Missing preview settings.");
            settings.Validate();
            var session = SessionArgument(arguments);
            _focus.End(); _playback.Stop(); _notificationPreview.Clear();
            if (verb == "previewNotification") {
                var now = SystemClock.Instance.GetCurrentInstant();
                var events = _schedule?.Events.Where(item => item.Time >= now).OrderBy(item => item.Time).ToArray() ?? [];
                var prayer = events.FirstOrDefault() ?? new PrayerEvent("fajr", now.InUtc().Date, now);
                _notificationPreview.Show(_configuration, prayer, session, _prototype);
            }
            if (verb == "previewFocus") {
                var preview = _configuration with { PrayerExperience = settings };
                var now = SystemClock.Instance.GetCurrentInstant();
                var prayer = _schedule?.Events.Where(item => item.Time >= now).OrderBy(item => item.Time).FirstOrDefault()
                    ?? new PrayerEvent("fajr", now.InUtc().Date, now);
                if (!_focus.Start(preview, prayer.Key, prayer.Time, session, true))
                    throw new InvalidDataException("An unlocked desktop is required for a Focus preview. " +
                        (_prototype ? PrayerFocus.DesktopName() : ""));
            }
            if (verb == "previewAdhan" || (verb == "previewFocus" && settings.FocusAudio) ||
                (verb == "previewNotification" && settings.Mode == "adhan")) {
                if (!_prototype) _ = Task.Run(() => HudaActivation.Send("prayer-audio"));
                await _playback.Start(settings, session, true);
            }
            UpdatePlaybackControls();
        }
        if (verb == "stopAdhan") _playback.Stop(SessionArgument(arguments));
        if (verb == "dismissFocus") _focus.TryDismiss(SessionArgument(arguments));
        if (verb == "clearPreviewNotification") _notificationPreview.Clear(SessionArgument(arguments));
        if (verb == "setPrayerVolume") {
            var session = SessionArgument(arguments);
            var volume = arguments.GetProperty("volume").GetDouble();
            if (!double.IsFinite(volume) || volume is < 0 or > 1) throw new InvalidDataException("Invalid prayer volume.");
            if (session == _playback.SessionId) _playback.SetVolume(volume);
        }
        if (verb is not ("reload" or "status" or "suspendRenewal" or "resumeRenewal" or
            "previewAdhan" or "previewFocus" or "previewNotification" or "clearPreviewNotification" or
            "stopAdhan" or "dismissFocus" or "setPrayerVolume") &&
            !(_prototype && (verb is "scheduleTestPrayer" or "exportFocus")))
            throw new InvalidDataException("Unknown IPC command.");
        string startup;
        try { startup = await StartupRegistration.State(); }
        catch (Exception error) { startup = "unavailable"; _runtimeError = error.Message; }
        return JsonSerializer.Serialize(new {
            helperAvailable = true, running = true, appliedRevision = _store.Current?.Revision ?? 0,
            trayVisible = _tray is { IsCreated: true },
            taskbarPlacement = _taskbar.Placement, startupState = startup,
            tzdbVersion = LocationClock.DatabaseVersion,
            error = (_prototype && _store.Current is null ? null : _store.Error) ?? _runtimeError,
            prayerAudioPlaying = _playback.Playing, prayerFocusActive = _focus.Visible,
            // 3: per-prayer settings and reminders before prayers.
            prayerExperienceVersion = 3,
            prayerFocusCanDismiss = _focus.CanDismiss,
            prayerFocusRemainingSeconds = _focus.RemainingSeconds,
            prayerPreviewToastSessionId = _notificationPreview.SessionId,
            prayerPreviewToastXml = _prototype ? _notificationPreview.Content : null,
            prayerSessionId = _focus.SessionId ?? _playback.SessionId,
            prayerAudioSessionId = _playback.SessionId,
            prayerPreview = _playback.IsPreview,
            prayerPlaybackState = _playback.PlaybackState, prayerPlaybackDurationMs = _playback.DurationMs,
            prayerFocusWindowCount = _focus.WindowCount, prayerFocusWindowHandles = _prototype ? _focus.Handles : null,
            prayerPrototypeDesktop = _prototype ? PrayerFocus.DesktopName() : null,
            prayerFocusEscapeRegistered = _focus.EscapeRegistered,
            prayerFocusCloseShortcutRegistered = _focus.CloseShortcutRegistered,
            prayerAudioError = _playback.Error, prayerQueueError = _toastQueue.Error,
            prayerQueueBusy = _toastQueue.Busy, prayerQueueDeferredForOwner = _toastQueue.DeferredForOwner,
            prayerToastCoverageUntilUtc = _toastQueue.CoverageUntilUtc,
        });
    }

    private static string SessionArgument(JsonElement arguments)
    {
        var session = arguments.GetProperty("sessionId").GetString();
        if (!Guid.TryParseExact(session, "D", out _)) throw new InvalidDataException("Invalid prayer session.");
        return session!;
    }

    private void Quit() { if (!_focus.CanDismiss) return; HudaActivation.Send("quit"); Stop(); }
    private void Stop()
    {
        if (_stopping) return;
        _toastQueue.RequestSuspend();
        _stopping = true; _timer.Stop(); _pipe.Dispose(); _inspector.Dispose();
        _focus.Dispose(); _playback.Dispose();
        _notificationPreview.Dispose();
        DisposeTray(); _taskbar.Dispose(); _popup.Close();
        _events.Dispose(); Exit();
    }
    private void DisposeTray() { _tray?.Dispose(); _tray = null; _icon?.Dispose(); _icon = null; }
}

internal sealed class ActionCommand(Action action) : ICommand
{
    public bool CanExecute(object? parameter) => true;
    public void Execute(object? parameter) => action();
    public event EventHandler? CanExecuteChanged { add { } remove { } }
}

internal static class Prototype
{
    public static TaskbarConfiguration Configuration(bool sample) => new() {
        SchemaVersion = 1, Revision = 1, PublishedAtUtc = DateTimeOffset.UtcNow,
        Preferences = new TaskbarPreferences { Enabled = true, ShowTaskbarCountdown = true, ShowTrayIcon = true,
            StartWithWindows = false, Style = "iconNameCountdown", ShowSeconds = true },
        Presentation = new Presentation { Locale = "en", Rtl = false, ThemeMode = "system", PrimaryColor = 0xFF3A5C95,
            FontFamily = "Amiri",
            Numerals = "western", Use24HourClock = true, Strings = new() {
                ["fajr"] = "Fajr", ["sunrise"] = "Sunrise", ["dhuhr"] = "Dhuhr", ["asr"] = "Asr",
                ["maghrib"] = "Maghrib", ["isha"] = "Isha", ["prayerTimes"] = "Prayer Times",
                ["prayerSettings"] = "Prayer Settings", ["openHuda"] = "Open Huda", ["quitHuda"] = "Exit",
                ["quran"] = "Quran", ["athkar"] = "Athkar",
                ["needsSetup"] = "Set up prayer times in Huda", ["verifyLocation"] = "Verify your location in Huda",
                ["calendarUnavailable"] = "Ramadan calendar data unavailable", ["noNextPrayer"] = "No upcoming prayer available",
            } },
        Location = !sample ? null : new PrayerLocation { Revision = 1, Latitude = 23.588, Longitude = 58.3829,
            Altitude = 0, TimeZoneId = "Asia/Muscat", CountryCode = "OM", Mode = "manual", Verified = true,
            VerificationReasons = [], Locality = "Muscat (prototype)" },
        Calculation = !sample ? null : new CalculationSettings { MethodChoice = "oman", MethodKey = "oman", Madhab = "shafi",
            HighLatitudeRule = "automatic", FajrAngle = 18, MaghribIsInterval = false, MaghribValue = 0,
            IshaIsInterval = false, IshaValue = 17, ManualOffsets = TaskbarConfiguration.PrayerKeys.ToDictionary(key => key, _ => 0) },
    };
}
