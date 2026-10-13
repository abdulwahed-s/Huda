using System.Diagnostics;
using System.Numerics;
using System.Runtime.InteropServices;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Composition;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Hosting;
using Microsoft.UI.Xaml.Media;
using NodaTime;

namespace Huda.PrayerTaskbar;

internal sealed class PrayerFocus : IDisposable
{
    private readonly List<FocusWindow> _windows = [];
    private readonly Stopwatch _elapsed = new();
    private int _duration;
    private PrayerFocusPolicy _policy;
    public bool CanDismiss => !Visible || _policy.CanDismiss;
    private TaskbarConfiguration? _config;
    private string _prayer = "prayerTimes";
    private Instant _time;
    private nint _exitWindow;
    public bool EscapeRegistered { get; private set; }
    private PrayerCloseShortcut? _closeShortcut;
    public bool CloseShortcutRegistered => _closeShortcut?.Installed == true;
    public void UseExitWindow(nint window) => _exitWindow = window;
    public string? SessionId { get; private set; }
    public bool Visible => SessionId is not null;
    public int WindowCount => _windows.Count;
    public IReadOnlyList<long> Handles => _windows.Select(window => window.Handle.ToInt64()).ToArray();
    public int RemainingSeconds => Math.Max(0, _duration - (int)_elapsed.Elapsed.TotalSeconds);
    public event Action<string>? Ended;
    public event Action<string>? StopAudio;

    public bool Start(TaskbarConfiguration config, string prayer, Instant time, string sessionId, bool preview = false)
    {
        End();
        if (!InteractiveDesktop()) return false;
        _config = config; _prayer = prayer; _time = time; SessionId = sessionId;
        _policy = new PrayerFocusPolicy(config.PrayerExperience!.FocusPreventEarlyExit, preview);
        _duration = preview ? Math.Min(15, config.PrayerExperience!.FocusDurationSeconds)
            : config.PrayerExperience!.FocusDurationSeconds;
        // Windows can deny foreground activation for a background reminder.
        // Register Escape only while Focus is visible so exit remains immediate.
        EscapeRegistered = _exitWindow != 0 && NativeMethods.RegisterHotKey(_exitWindow, 0x4855, 0x4000, 0x1B);
        var dispatcher = DispatcherQueue.GetForCurrentThread();
        _closeShortcut = new PrayerCloseShortcut(() => !CanDismiss ||
            dispatcher.TryEnqueue(() => TryDismiss(sessionId)));
        _elapsed.Restart(); RebuildDisplays(); Update(config, false); return true;
    }

    public void Update(TaskbarConfiguration config, bool audioPlaying)
    {
        if (!Visible) return;
        if (!InteractiveDesktop() || RemainingSeconds == 0) { End(); return; }
        _config = config;
        foreach (var window in _windows) window.Update(config, _prayer, _time, RemainingSeconds, audioPlaying, CanDismiss);
    }

    public void RebuildDisplays()
    {
        if (!Visible || _config is null) return;
        var bounds = new List<NativeMethods.Rect>();
        NativeMethods.MonitorEnumeration callback = (nint monitor, nint dc, ref NativeMethods.Rect rect, nint data) => {
            bounds.Add(rect); return true;
        };
        NativeMethods.EnumDisplayMonitors(0, 0, callback, 0);
        if (bounds.Count == _windows.Count && bounds.Select((rect, i) => Same(rect, _windows[i].Bounds)).All(equal => equal)) return;
        foreach (var window in _windows) window.Close();
        _windows.Clear();
        var sessionId = SessionId!;
        foreach (var rect in bounds) {
            var window = new FocusWindow(rect, () => TryDismiss(sessionId), () => StopAudio?.Invoke(sessionId),
                _elapsed, _duration, _config.Presentation);
            _windows.Add(window);
            window.Update(_config, _prayer, _time, RemainingSeconds, false, CanDismiss);
            window.Show();
        }
        if (_windows.Count == 0) End(sessionId);
    }
    private static bool Same(NativeMethods.Rect a, NativeMethods.Rect b) =>
        a.Left == b.Left && a.Top == b.Top && a.Right == b.Right && a.Bottom == b.Bottom;

    public bool TryDismiss(string? sessionId = null)
    {
        if (!CanDismiss || (sessionId is not null && sessionId != SessionId)) return false;
        End(sessionId); return true;
    }

    public void End(string? sessionId = null)
    {
        if (sessionId is not null && sessionId != SessionId) return;
        var ended = SessionId; SessionId = null; _elapsed.Stop();
        if (EscapeRegistered) NativeMethods.UnregisterHotKey(_exitWindow, 0x4855);
        _closeShortcut?.Dispose(); _closeShortcut = null;
        EscapeRegistered = false;
        foreach (var window in _windows) window.Close();
        _windows.Clear();
        if (ended is not null) Ended?.Invoke(ended);
    }
    public static bool InteractiveDesktop() => DesktopName().Equals("Default", StringComparison.OrdinalIgnoreCase);
    internal static string DesktopName()
    {
        // Query the input desktop's name without requesting object access.
        var desktop = NativeMethods.OpenInputDesktop(0, false, 0);
        if (desktop == 0) return "unavailable:" + Marshal.GetLastWin32Error();
        try {
            var name = new System.Text.StringBuilder(128);
            return NativeMethods.GetUserObjectInformation(desktop, 2, name, 256, out _)
                ? name.ToString() : "unavailable:" + Marshal.GetLastWin32Error();
        } finally { NativeMethods.CloseDesktop(desktop); }
    }
    public Task Export(string path, int displayIndex = 0) => displayIndex >= 0 && displayIndex < _windows.Count
        ? _windows[displayIndex].Export(path) : Task.CompletedTask;
    public void Dispose() => End();
}

internal sealed class FocusWindow
{
    // The closing passage of An-Nisa 4:103, from Huda's bundled Quran text.
    private const string PrayerVerse = "إِنَّ ٱلصَّلَوٰةَ كَانَتۡ عَلَى ٱلۡمُؤۡمِنِينَ كِتَٰبٗا مَّوۡقُوتٗا";
    private readonly Window _window = new();
    private readonly Border _root = new();
    private readonly Grid _shell = new() { Padding = new Thickness(48, 32, 48, 24) };
    private readonly TextBlock _mode = Text("PrayerFocusAccentTextStyle");
    private readonly FontIcon _modeIcon = new() { FontSize = 13, Glyph = "\uE708" };
    private readonly TextBlock _prayer = Text("PrayerFocusTextStyle", semibold: true);
    private readonly TextBlock _time = Text("PrayerFocusSecondaryTextStyle");
    private readonly TextBlock _message = Text("PrayerFocusSecondaryTextStyle");
    private readonly TextBlock _verse = Text("PrayerFocusAccentTextStyle");
    private readonly TextBlock _reference = Text("PrayerFocusSecondaryTextStyle");
    private readonly Border _verseCard = new() { Padding = new Thickness(40, 24, 40, 24),
        CornerRadius = new CornerRadius(24), BorderThickness = new Thickness(1), Margin = new Thickness(0, 26, 0, 26) };
    private readonly TextBlock _counter = Text("PrayerFocusTextStyle");
    private readonly TextBlock _remaining = Text("PrayerFocusSecondaryTextStyle");
    private readonly Border _progress = new() { Width = 180, Height = 6, CornerRadius = new CornerRadius(3),
        HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 10, 0, 0) };
    private readonly Border _progressFill = new() { Width = 180, Height = 6, CornerRadius = new CornerRadius(3),
        HorizontalAlignment = HorizontalAlignment.Left };
    private readonly Stopwatch _sessionElapsed;
    private readonly int _sessionDuration;
    private readonly FocusTheme _theme;
    private Visual? _progressVisual;
    private ScalarKeyFrameAnimation? _progressAnimation;
    private readonly TextBlock _hint = Text("PrayerFocusSecondaryTextStyle");
    private readonly StackPanel _actions = new() { Orientation = Orientation.Horizontal, Spacing = 12,
        HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 22, 0, 0) };
    private readonly Button _dismiss = new() { Width = 220, MinHeight = 48, CornerRadius = new CornerRadius(12),
        Padding = new Thickness(20, 12, 20, 12) };
    private readonly Button _stop = new() { Width = 220, MinHeight = 48, CornerRadius = new CornerRadius(12),
        Padding = new Thickness(20, 12, 20, 12) };
    private readonly TextBlock _dismissLabel = new() { TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center };
    private readonly TextBlock _stopLabel = new() { TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center };
    private Presentation? _presentation;
    private bool _compact;
    private bool _closing;
    public NativeMethods.Rect Bounds { get; }
    public nint Handle => WinRT.Interop.WindowNative.GetWindowHandle(_window);

    public FocusWindow(NativeMethods.Rect bounds, Action dismiss, Action stop,
        Stopwatch sessionElapsed, int sessionDuration, Presentation presentation)
    {
        Bounds = bounds;
        _sessionElapsed = sessionElapsed; _sessionDuration = sessionDuration;
        _theme = new FocusTheme(_root, presentation.PrimaryColor);
        _root.RequestedTheme = TaskbarSurface.Theme(presentation.ThemeMode);
        _root.Style = Style("PrayerFocusSurfaceStyle");
        var backdrop = new Grid();
        backdrop.Children.Add(Motif(HorizontalAlignment.Right, VerticalAlignment.Top));
        backdrop.Children.Add(Motif(HorizontalAlignment.Left, VerticalAlignment.Bottom));
        _shell.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        _shell.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var header = new Grid { ColumnSpacing = 16 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var brand = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10,
            VerticalAlignment = VerticalAlignment.Center };
        var logo = PresentationAssets.Logo(28);
        logo.Style = Style("PrayerFocusBrandStyle");
        var brandName = Text("PrayerFocusTextStyle", semibold: true);
        brandName.Text = "Huda"; brandName.FontFamily = new FontFamily("Segoe UI"); brandName.FontSize = 17;
        brandName.VerticalAlignment = VerticalAlignment.Center;
        brand.Children.Add(logo); brand.Children.Add(brandName);
        _modeIcon.Style = Style("PrayerFocusIconStyle");
        AutomationProperties.SetAccessibilityView(_modeIcon, AccessibilityView.Raw);
        var modeContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
        _mode.VerticalAlignment = VerticalAlignment.Center;
        modeContent.Children.Add(_modeIcon); modeContent.Children.Add(_mode);
        var modeBadge = new Border { Child = modeContent, CornerRadius = new CornerRadius(20),
            Padding = new Thickness(14, 7, 14, 7), BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center, Style = Style("PrayerFocusCardStyle") };
        Grid.SetColumn(modeBadge, 1);
        header.Children.Add(brand); header.Children.Add(modeBadge);
        _shell.Children.Add(header);

        var stack = new StackPanel { MaxWidth = 900,
            HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        var heading = new StackPanel { Spacing = 6 };
        heading.Children.Add(_prayer); heading.Children.Add(_time);
        _message.Margin = new Thickness(0, 12, 0, 0); heading.Children.Add(_message);
        stack.Children.Add(heading);
        _verse.Text = "﴿ " + PrayerVerse + " ﴾";
        _verse.FontFamily = PresentationAssets.Font("Amiri");
        _verse.FlowDirection = FlowDirection.RightToLeft; _verse.Language = "ar-SA";
        _verse.LineStackingStrategy = LineStackingStrategy.BlockLineHeight;
        AutomationProperties.SetName(_verse, PrayerVerse);
        var verseContent = new StackPanel { Spacing = 8 };
        verseContent.Children.Add(Ornament()); verseContent.Children.Add(_verse); verseContent.Children.Add(_reference);
        _verseCard.Style = Style("PrayerFocusCardStyle"); _verseCard.Child = verseContent;
        stack.Children.Add(_verseCard);
        _counter.FontFamily = new FontFamily("Segoe UI");
        _counter.FlowDirection = FlowDirection.LeftToRight;
        _progress.FlowDirection = FlowDirection.LeftToRight;
        _progress.Style = Style("PrayerFocusProgressStyle");
        _progressFill.Style = Style("PrayerFocusProgressFillStyle");
        _progress.Child = _progressFill;
        _progressFill.Loaded += (_, _) => StartCountdownAnimation();
        AutomationProperties.SetAccessibilityView(_progress, AccessibilityView.Raw);
        var timer = new StackPanel { Spacing = 4 };
        timer.Children.Add(_counter); timer.Children.Add(_remaining); timer.Children.Add(_progress);
        stack.Children.Add(timer);
        _dismiss.Style = Style("PrayerFocusPrimaryButtonStyle");
        _stop.Style = Style("PrayerFocusSecondaryButtonStyle");
        _dismiss.Content = _dismissLabel; _stop.Content = _stopLabel;
        _actions.Children.Add(_dismiss); _actions.Children.Add(_stop); stack.Children.Add(_actions);
        _hint.MaxWidth = 650; _hint.Margin = new Thickness(0, 14, 0, 0); stack.Children.Add(_hint);
        var scroll = new ScrollViewer { Content = stack, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, Padding = new Thickness(0, 28, 0, 12),
            VerticalContentAlignment = VerticalAlignment.Center, HorizontalContentAlignment = HorizontalAlignment.Stretch };
        Grid.SetRow(scroll, 1); _shell.Children.Add(scroll);
        backdrop.Children.Add(_shell); _root.Child = backdrop;
        _root.SizeChanged += (_, args) => {
            // Keep decorative geometry inside the monitor and exported surface.
            _root.Clip = new RectangleGeometry { Rect = new Windows.Foundation.Rect(0, 0, args.NewSize.Width, args.NewSize.Height) };
            _compact = args.NewSize.Width < 680 || args.NewSize.Height < 760;
            _shell.Padding = _compact ? new Thickness(20, 18, 20, 16) : new Thickness(48, 32, 48, 24);
            _actions.Orientation = args.NewSize.Width < 580 ? Orientation.Vertical : Orientation.Horizontal;
            _verseCard.Padding = _compact ? new Thickness(22, 18, 22, 18) : new Thickness(40, 24, 40, 24);
            _verseCard.Margin = _compact ? new Thickness(0, 18, 0, 18) : new Thickness(0, 26, 0, 26);
            if (_presentation is { } presentation) ApplyTypography(presentation);
        };
        _window.Content = _root; _window.Title = "Huda";
        var presenter = OverlappedPresenter.Create();
        presenter.SetBorderAndTitleBar(false, false); presenter.IsAlwaysOnTop = true;
        presenter.IsResizable = presenter.IsMinimizable = presenter.IsMaximizable = false;
        _window.AppWindow.SetPresenter(presenter); _window.AppWindow.IsShownInSwitchers = false;
        _dismiss.Click += (_, _) => dismiss(); _stop.Click += (_, _) => stop();
        var escape = new Microsoft.UI.Xaml.Input.KeyboardAccelerator {
            Key = Windows.System.VirtualKey.Escape, ScopeOwner = _root };
        escape.Invoked += (_, args) => { args.Handled = true; dismiss(); };
        _root.KeyboardAccelerators.Add(escape);
        _root.KeyDown += (_, args) => {
            if (args.Key == Windows.System.VirtualKey.Escape) { args.Handled = true; dismiss(); }
        };
        _window.AppWindow.Closing += (_, args) => { if (!_closing) { args.Cancel = true; dismiss(); } };
    }
    public void Show()
    {
        var handle = WinRT.Interop.WindowNative.GetWindowHandle(_window);
        _window.AppWindow.MoveAndResize(new Windows.Graphics.RectInt32(Bounds.Left, Bounds.Top, Bounds.Width, Bounds.Height));
        _window.AppWindow.Show();
        NativeMethods.SetWindowPos(handle, -1, Bounds.Left, Bounds.Top, Bounds.Width, Bounds.Height, NativeMethods.SWP_SHOWWINDOW);
        _window.Activate();
        if (_dismiss.Visibility == Visibility.Visible) _dismiss.Focus(FocusState.Programmatic);
    }
    public void Update(TaskbarConfiguration config, string prayer, Instant time, int remaining, bool audioPlaying, bool canDismiss)
    {
        var p = config.Presentation;
        _presentation = p;
        _theme.Apply(p.PrimaryColor);
        _root.RequestedTheme = TaskbarSurface.Theme(p.ThemeMode);
        _root.FlowDirection = p.Rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        _mode.Text = p.Label("prayerFocusMode");
        _modeIcon.Glyph = canDismiss ? "\uE708" : "\uE72E";
        _prayer.Text = p.Label(prayer);
        _time.Text = config.Location is { } location ? CountdownFormatter.Clock(time, location.TimeZoneId, p) : "";
        _message.Text = p.Label("prayerFocusMessage");
        _reference.Text = p.Label("prayerFocusVerseReference");
        _counter.Text = CountdownFormatter.Digits($"{remaining / 60:00}:{remaining % 60:00}", p.Numerals);
        _remaining.Text = p.Label("prayerFocusTimeRemaining");
        _hint.Text = p.Label(canDismiss ? "prayerFocusExitHint" : "prayerFocusLockedHint");
        _dismiss.Visibility = canDismiss ? Visibility.Visible : Visibility.Collapsed;
        _dismissLabel.Text = p.Label("prayerDismissFocus");
        _stopLabel.Text = p.Label("prayerStopAdhan");
        _stop.Visibility = audioPlaying ? Visibility.Visible : Visibility.Collapsed;
        _actions.Visibility = canDismiss || audioPlaying ? Visibility.Visible : Visibility.Collapsed;
        ApplyTypography(p);
        AutomationProperties.SetName(_dismiss, p.Label("prayerDismissFocus"));
        AutomationProperties.SetName(_stop, p.Label("prayerStopAdhan"));
        AutomationProperties.SetName(_counter, _remaining.Text + " " + _counter.Text);
    }
    private void ApplyTypography(Presentation p)
    {
        PresentationAssets.ApplyFont(_mode, p, 12);
        PresentationAssets.ApplyFont(_prayer, p, _compact ? 34 : 44);
        PresentationAssets.ApplyFont(_time, p, 17);
        PresentationAssets.ApplyFont(_message, p, 17);
        PresentationAssets.ApplyFont(_reference, p, 13);
        PresentationAssets.ApplyFont(_remaining, p, 13);
        PresentationAssets.ApplyFont(_hint, p, 12);
        PresentationAssets.ApplyFont(_dismissLabel, p, 15);
        PresentationAssets.ApplyFont(_stopLabel, p, 15);
        _verse.FontSize = _compact ? 30 : 40;
        _verse.LineHeight = _compact ? 54 : 72;
        _counter.FontSize = _compact ? 44 : 52;
    }
    private static Style Style(string key) => (Style)Application.Current.Resources[key];
    private static TextBlock Text(string style, bool semibold = false) => new() {
        Style = Style(style), TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center,
        HorizontalAlignment = HorizontalAlignment.Center,
        FontWeight = semibold ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal };
    private static Grid Motif(HorizontalAlignment horizontal, VerticalAlignment vertical)
    {
        var motif = new Grid { Width = 300, Height = 300, HorizontalAlignment = horizontal,
            VerticalAlignment = vertical, Opacity = .32, IsHitTestVisible = false };
        foreach (var size in new[] { 120d, 200d })
            foreach (var angle in new[] { 0d, 45d })
                motif.Children.Add(new Microsoft.UI.Xaml.Shapes.Rectangle { Width = size, Height = size,
                    HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center,
                    RenderTransformOrigin = new Windows.Foundation.Point(.5, .5),
                    RenderTransform = new RotateTransform { Angle = angle }, Style = Style("PrayerFocusMotifStyle") });
        AutomationProperties.SetAccessibilityView(motif, AccessibilityView.Raw);
        return motif;
    }
    private static Grid Ornament()
    {
        var ornament = new Grid { Width = 132, Height = 16, Margin = new Thickness(0, 0, 0, 4), IsHitTestVisible = false };
        foreach (var alignment in new[] { HorizontalAlignment.Left, HorizontalAlignment.Right })
            ornament.Children.Add(new Border { Width = 48, Height = 1, HorizontalAlignment = alignment,
                VerticalAlignment = VerticalAlignment.Center, Style = Style("PrayerFocusRuleStyle") });
        ornament.Children.Add(new Microsoft.UI.Xaml.Shapes.Rectangle { Width = 7, Height = 7,
            HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center,
            RenderTransformOrigin = new Windows.Foundation.Point(.5, .5),
            RenderTransform = new RotateTransform { Angle = 45 }, Style = Style("PrayerFocusMotifStyle") });
        AutomationProperties.SetAccessibilityView(ornament, AccessibilityView.Raw);
        return ornament;
    }
    private void StartCountdownAnimation()
    {
        if (_closing || _progressAnimation is not null) return;
        var remaining = Math.Max(0, _sessionDuration - _sessionElapsed.Elapsed.TotalSeconds);
        var fraction = (float)Math.Clamp(remaining / _sessionDuration, 0, 1);
        _progressVisual = ElementCompositionPreview.GetElementVisual(_progressFill);
        _progressVisual.CenterPoint = Vector3.Zero;
        _progressVisual.Scale = new Vector3(fraction, 1, 1);
        if (remaining <= 0) return;
        var compositor = _progressVisual.Compositor;
        _progressAnimation = compositor.CreateScalarKeyFrameAnimation();
        _progressAnimation.InsertKeyFrame(0, fraction);
        _progressAnimation.InsertKeyFrame(1, 0, compositor.CreateLinearEasingFunction());
        _progressAnimation.Duration = TimeSpan.FromSeconds(remaining);
        _progressAnimation.StopBehavior = AnimationStopBehavior.SetToFinalValue;
        // Run once against the captured session deadline. Label/audio/theme
        // updates never restart this continuous compositor animation.
        _progressVisual.StartAnimation("Scale.X", _progressAnimation);
    }
    public void Close()
    {
        _closing = true;
        _progressVisual?.StopAnimation("Scale.X");
        _progressAnimation?.Dispose();
        _window.Close();
    }
    public Task Export(string path) => PrayerPopup.ExportElement(_root, path);
}
