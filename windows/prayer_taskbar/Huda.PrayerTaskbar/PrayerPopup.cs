using System.Globalization;
using System.Runtime.InteropServices;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using NodaTime;
using Windows.Graphics;
using Windows.Storage.Streams;
using Windows.UI.ViewManagement;

namespace Huda.PrayerTaskbar;

internal sealed class PrayerPopup
{
    public Window Window { get; } = new();
    private const double PopupWidth = 300;
    private readonly Border _root = new() { Padding = new Thickness(14) };
    private readonly TextBlock _heading = Text(15, semibold: true);
    private readonly TextBlock _weekday = Text(12, secondary: true);
    private readonly TextBlock _date = Text(13, secondary: true);
    private readonly TextBlock _countdown = Text(20, semibold: true);
    private readonly TextBlock _nextPrayer = Text(14, semibold: true);
    private readonly TextBlock _location = Text(11, secondary: true);
    private readonly Border _next = new() { Padding = new Thickness(12, 10, 12, 10),
        CornerRadius = new CornerRadius(8), Margin = new Thickness(0, 12, 0, 0) };
    private readonly InfoBar _verification = new() { Severity = InfoBarSeverity.Warning, IsClosable = false };
    private readonly Dictionary<string, (Border Surface, FontIcon Icon, TextBlock Label, TextBlock Time)> _rows = [];
    private readonly Button _settings = ActionButton("\uE713");
    private readonly Button _open = ActionButton("\uE8A7");
    private readonly Button _stopAdhan = new() { HorizontalAlignment = HorizontalAlignment.Stretch, Visibility = Visibility.Collapsed };
    private readonly Button _dismissFocus = new() { HorizontalAlignment = HorizontalAlignment.Stretch, Visibility = Visibility.Collapsed };
    public event Action? StopAdhan;
    public event Action? DismissFocus;
    private readonly AccessibilitySettings _accessibility = new();
    private NativeMethods.Rect? _anchor;
    private bool _closing;
    public bool Visible => Window.AppWindow.IsVisible;

    public PrayerPopup(Func<bool> pointerOverTrigger)
    {
        _root.Style = (Style)Application.Current.Resources["PrayerPopupSurfaceStyle"];
        var content = new StackPanel();
        _root.Child = content;
        var header = new Grid { ColumnSpacing = 10 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var mark = PresentationAssets.Logo(20);
        mark.Style = (Style)Application.Current.Resources["PrayerPopupBrandStyle"];
        _heading.VerticalAlignment = VerticalAlignment.Center;
        _heading.TextTrimming = TextTrimming.CharacterEllipsis;
        Grid.SetColumn(_heading, 1);
        var actions = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 2 };
        actions.Children.Add(_settings); actions.Children.Add(_open);
        Grid.SetColumn(actions, 2);
        header.Children.Add(mark); header.Children.Add(_heading); header.Children.Add(actions);
        content.Children.Add(header);

        var date = new StackPanel { Spacing = 3, Margin = new Thickness(0, 10, 0, 12) };
        _weekday.HorizontalAlignment = _date.HorizontalAlignment = HorizontalAlignment.Center;
        date.Children.Add(_weekday); date.Children.Add(_date);
        content.Children.Add(date);
        _verification.Margin = new Thickness(0, 0, 0, 10);
        content.Children.Add(_verification);
        var list = new StackPanel { Spacing = 2 };
        foreach (var key in TaskbarConfiguration.PrayerKeys)
        {
            var row = new Grid { ColumnSpacing = 10 };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(18) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var icon = Icon(((char)Symbol.Clock).ToString(), 14);
            var label = Text(14);
            var time = Text(14);
            time.FlowDirection = FlowDirection.LeftToRight;
            label.VerticalAlignment = time.VerticalAlignment = VerticalAlignment.Center;
            label.TextTrimming = TextTrimming.CharacterEllipsis;
            Grid.SetColumn(label, 1); Grid.SetColumn(time, 2);
            row.Children.Add(icon); row.Children.Add(label); row.Children.Add(time);
            var surface = new Border { Child = row, Padding = new Thickness(10, 6, 10, 6),
                CornerRadius = new CornerRadius(6), BorderThickness = new Thickness(1) };
            list.Children.Add(surface);
            _rows[key] = (surface, icon, label, time);
        }
        content.Children.Add(list);
        _next.Style = (Style)Application.Current.Resources["PrayerPopupFooterStyle"];
        var next = new Grid { ColumnSpacing = 12 };
        next.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        next.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        _nextPrayer.VerticalAlignment = _countdown.VerticalAlignment = VerticalAlignment.Center;
        _nextPrayer.TextWrapping = TextWrapping.Wrap;
        _countdown.FlowDirection = FlowDirection.LeftToRight;
        Grid.SetColumn(_countdown, 1);
        next.Children.Add(_nextPrayer); next.Children.Add(_countdown);
        _next.Child = next;
        content.Children.Add(_next);
        _location.Margin = new Thickness(8, 10, 8, 0);
        _location.HorizontalAlignment = HorizontalAlignment.Center;
        _location.TextTrimming = TextTrimming.CharacterEllipsis;
        _location.MaxLines = 1;
        content.Children.Add(_location);
        content.Children.Add(_stopAdhan); content.Children.Add(_dismissFocus);
        _stopAdhan.Click += (_, _) => StopAdhan?.Invoke();
        _dismissFocus.Click += (_, _) => DismissFocus?.Invoke();
        _settings.Click += (_, _) => { Hide(); HudaActivation.Open(true); };
        _open.Click += (_, _) => { Hide(); HudaActivation.Open("home"); };
        Window.Content = new ScrollViewer { Content = _root, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            HorizontalContentAlignment = HorizontalAlignment.Stretch };
        Window.Title = "Huda";
        Window.AppWindow.IsShownInSwitchers = false;
        var presenter = OverlappedPresenter.CreateForDialog();
        presenter.SetBorderAndTitleBar(true, false);
        presenter.IsAlwaysOnTop = true; presenter.IsResizable = false;
        presenter.IsMaximizable = false; presenter.IsMinimizable = false;
        Window.AppWindow.SetPresenter(presenter);
        _root.KeyDown += (_, args) => {
            if (args.Key == Windows.System.VirtualKey.Escape) { args.Handled = true; Hide(); }
        };
        Window.Activated += (_, args) => {
            // Explorer takes focus before Button.Click / tray mouse-up. Keep the
            // visible state until that trigger's toggle can close the popup.
            if (args.WindowActivationState == WindowActivationState.Deactivated && !pointerOverTrigger()) Hide();
        };
        Window.AppWindow.Closing += (_, args) => { if (!_closing) { args.Cancel = true; Hide(); } };
    }

    public void Update(TaskbarConfiguration config, ScheduleSnapshot? schedule, Instant now)
    {
        var p = config.Presentation;
        _root.RequestedTheme = TaskbarSurface.Theme(p.ThemeMode);
        _root.FlowDirection = p.Rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        PresentationAssets.ApplyFont(_heading, p, 15);
        PresentationAssets.ApplyFont(_weekday, p, 12);
        PresentationAssets.ApplyFont(_date, p, 13);
        PresentationAssets.ApplyFont(_countdown, p, 20);
        PresentationAssets.ApplyFont(_nextPrayer, p, 14);
        PresentationAssets.ApplyFont(_location, p, 11);
        _verification.FontFamily = PresentationAssets.Font(p.FontFamily);
        Set(_heading, p.Label("prayerTimes"));
        CultureInfo culture;
        try { culture = (CultureInfo)CultureInfo.GetCultureInfo(p.Locale.Replace('_', '-')).Clone(); }
        catch (CultureNotFoundException) { culture = (CultureInfo)CultureInfo.InvariantCulture.Clone(); }
        // The date belongs to the prayer location, even when the PC is in another zone.
        // Display the civil date explicitly, without applying a second Hijri calendar policy.
        culture.DateTimeFormat.Calendar = new GregorianCalendar();
        var day = config.Location is { } selected
            ? now.InZone(DateTimeZoneProviders.Tzdb[selected.TimeZoneId]).Date.ToDateTimeUnspecified()
            : now.ToDateTimeUtc().ToLocalTime().Date;
        Set(_weekday, day.ToString("dddd", culture));
        Set(_date, CountdownFormatter.Digits(day.ToString("d MMMM yyyy", culture), p.Numerals));
        Set(_location, config.Location is { } location
            ? string.Join(" · ", new[] { location.Locality, location.CountryName }
                .Where(value => !string.IsNullOrEmpty(value))) : "");
        _location.Visibility = config.Location is null ? Visibility.Collapsed : Visibility.Visible;
        if (config.Location is { } zone)
        {
            if (string.IsNullOrEmpty(_location.Text)) Set(_location, zone.TimeZoneId);
            ToolTipService.SetToolTip(_location, string.Join(" · ", new[] { _location.Text, zone.TimeZoneId }));
        }
        else ToolTipService.SetToolTip(_location, null);
        _verification.Title = p.Label("verifyLocation");
        _verification.IsOpen = config.Location is { Verified: false };
        _verification.Visibility = _verification.IsOpen ? Visibility.Visible : Visibility.Collapsed;
        var primary = Windows.UI.Color.FromArgb((byte)(p.PrimaryColor >> 24), (byte)(p.PrimaryColor >> 16),
            (byte)(p.PrimaryColor >> 8), (byte)p.PrimaryColor);
        var highContrast = _accessibility.HighContrast;
        var accent = highContrast ? _heading.Foreground : new SolidColorBrush(ReadableAccent(primary,
            _root.RequestedTheme == ElementTheme.Dark));
        var moment = config.Location is not null && schedule?.Error is null ? schedule?.Moment(now, config.Preferences.IqamahMinutes) : null;
        Set(_nextPrayer, moment is { } current ? p.Label(current.Prayer.Key)
            : CountdownFormatter.Text(config, schedule, now));
        Set(_countdown, moment is { } target ? CountdownFormatter.Digits(
            CountdownFormatter.Counter(target, now, config.Preferences.ShowSeconds), p.Numerals) : "");
        _countdown.Visibility = moment is null ? Visibility.Collapsed : Visibility.Visible;
        _countdown.Foreground = accent;
        AutomationProperties.SetName(_countdown, _nextPrayer.Text + " " + _countdown.Text);
        foreach (var (key, row) in _rows)
        {
            Set(row.Label, p.Label(key));
            var instant = schedule?.Daily.Times.GetValueOrDefault(key);
            Set(row.Time, config.Location is null ? "—" : CountdownFormatter.Clock(instant, config.Location.TimeZoneId, p));
            // Tomorrow's Fajr must not make today's completed Fajr look upcoming.
            var isNext = moment is not null && key == moment.Prayer.Key && instant == moment.Prayer.Time;
            var upcoming = isNext && !moment!.IsElapsed;
            row.Icon.Glyph = ((char)(upcoming ? Symbol.Forward : instant <= now ? Symbol.Accept : Symbol.Clock)).ToString();
            row.Icon.MirroredWhenRightToLeft = upcoming;
            row.Label.FontWeight = row.Time.FontWeight = isNext
                ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
            PresentationAssets.ApplyFont(row.Label, p, 14);
            PresentationAssets.ApplyFont(row.Time, p, 14);
            var padding = p.FontFamily == "Amiri" ? 4 : 6;
            row.Surface.Padding = new Thickness(10, padding, 10, padding);
            if (isNext)
            {
                row.Label.Foreground = row.Time.Foreground = row.Icon.Foreground = accent;
                row.Surface.Background = highContrast ? null : new SolidColorBrush(Windows.UI.Color.FromArgb(
                    22, primary.R, primary.G, primary.B));
                row.Surface.BorderBrush = highContrast ? accent : null;
            }
            else
            {
                row.Label.ClearValue(TextBlock.ForegroundProperty);
                row.Time.ClearValue(TextBlock.ForegroundProperty);
                row.Icon.ClearValue(FontIcon.ForegroundProperty);
                row.Surface.Background = row.Surface.BorderBrush = null;
            }
            AutomationProperties.SetName(row.Time, p.Label(key) + " " + row.Time.Text);
        }
        NameAction(_settings, p.Label("prayerSettings"));
        NameAction(_open, p.Label("openHuda"));
        // Match the native frame to the content and let Windows provide rounded corners/shadow.
        var handle = WinRT.Interop.WindowNative.GetWindowHandle(Window);
        var dark = _root.RequestedTheme == ElementTheme.Dark ? 1 : 0;
        NativeMethods.DwmSetWindowAttribute(handle, 20, ref dark, sizeof(int));
        var corners = 2;
        NativeMethods.DwmSetWindowAttribute(handle, 33, ref corners, sizeof(int));
        if (Visible) Place(_anchor);
    }

    public void Show(NativeMethods.Rect? anchor)
    {
        _anchor = anchor;
        Place(anchor);
        Window.AppWindow.Show(); Window.Activate();
    }

    public void UpdatePlayback(TaskbarConfiguration config, bool audioPlaying, bool focusActive)
    {
        _stopAdhan.Content = config.Presentation.Label("prayerStopAdhan");
        _dismissFocus.Content = config.Presentation.Label("prayerDismissFocus");
        _stopAdhan.FontFamily = _dismissFocus.FontFamily = PresentationAssets.Font(config.Presentation.FontFamily);
        _stopAdhan.Visibility = audioPlaying ? Visibility.Visible : Visibility.Collapsed;
        _dismissFocus.Visibility = focusActive ? Visibility.Visible : Visibility.Collapsed;
        NameAction(_stopAdhan, config.Presentation.Label("prayerStopAdhan"));
        NameAction(_dismissFocus, config.Presentation.Label("prayerDismissFocus"));
        if (Visible) Place(_anchor);
    }

    private void Place(NativeMethods.Rect? anchor)
    {
        NativeMethods.GetCursorPos(out var cursor);
        var point = anchor is { } bounds
            ? new NativeMethods.Point { X = bounds.Left + bounds.Width / 2, Y = bounds.Top }
            : cursor;
        var monitor = NativeMethods.MonitorFromPoint(point, 2);
        var info = new NativeMethods.MonitorInfo { Size = Marshal.SizeOf<NativeMethods.MonitorInfo>() };
        NativeMethods.GetMonitorInfo(monitor, ref info);
        // A hidden popup can retain the DPI of the monitor where it last
        // opened. Measure against its destination before moving it there.
        var dpi = NativeMethods.GetDpiForMonitor(monitor, 0, out var monitorDpi, out _) == 0
            ? monitorDpi : NativeMethods.GetDpiForWindow(WinRT.Interop.WindowNative.GetWindowHandle(Window));
        if (dpi == 0) dpi = 96;
        var handle = WinRT.Interop.WindowNative.GetWindowHandle(Window);
        NativeMethods.GetWindowRect(handle, out var outer);
        NativeMethods.GetClientRect(handle, out var client);
        var windowDpi = NativeMethods.GetDpiForWindow(handle);
        if (windowDpi == 0) windowDpi = 96;
        var frameWidth = Math.Max(0, outer.Width - client.Width) * (double)dpi / windowDpi;
        var frameHeight = Math.Max(0, outer.Height - client.Height) * (double)dpi / windowDpi;
        var width = Math.Min((int)(PopupWidth * dpi / 96), info.Work.Width);
        _root.Measure(new Windows.Foundation.Size((width - frameWidth) * 96.0 / dpi, double.PositiveInfinity));
        var height = Math.Min((int)Math.Ceiling(_root.DesiredSize.Height * dpi / 96 + frameHeight), info.Work.Height);
        var center = anchor is { } rect ? rect.Left + rect.Width / 2 : cursor.X;
        var bottom = anchor?.Top ?? info.Work.Bottom;
        var destination = new RectInt32(
            Math.Clamp(center - width / 2, info.Work.Left, info.Work.Right - width),
            Math.Clamp(bottom - height - 8, info.Work.Top, info.Work.Bottom - height), width, height);
        if (outer.Left != destination.X || outer.Top != destination.Y ||
            outer.Width != destination.Width || outer.Height != destination.Height)
            Window.AppWindow.MoveAndResize(destination);
    }

    public void Hide() { if (Visible) Window.AppWindow.Hide(); }
    public void Close() { _closing = true; Window.Close(); }
    public Task Export(string path) => ExportElement(_root, path);
    internal static async Task ExportElement(FrameworkElement element, string path)
    {
        var renderer = new RenderTargetBitmap();
        await renderer.RenderAsync(element);
        var buffer = await renderer.GetPixelsAsync();
        var bytes = new byte[buffer.Length];
        using (var reader = DataReader.FromBuffer(buffer)) reader.ReadBytes(bytes);
        using var bitmap = new System.Drawing.Bitmap(renderer.PixelWidth, renderer.PixelHeight,
            System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        var data = bitmap.LockBits(new System.Drawing.Rectangle(0, 0, bitmap.Width, bitmap.Height),
            System.Drawing.Imaging.ImageLockMode.WriteOnly, bitmap.PixelFormat);
        try { Marshal.Copy(bytes, 0, data.Scan0, bytes.Length); }
        finally { bitmap.UnlockBits(data); }
        bitmap.Save(path, System.Drawing.Imaging.ImageFormat.Png);
    }
    private static void Set(TextBlock block, string text) { if (block.Text != text) block.Text = text; }

    private static TextBlock Text(double size, bool secondary = false, bool semibold = false) => new()
    {
        FontSize = size,
        FontWeight = semibold ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal,
        Style = (Style)Application.Current.Resources[secondary ? "PrayerPopupSecondaryTextStyle" : "PrayerPopupTextStyle"],
    };

    private static FontIcon Icon(string glyph, double size)
    {
        var icon = new FontIcon { Glyph = glyph, FontSize = size, FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Style = (Style)Application.Current.Resources["PrayerPopupIconStyle"] };
        AutomationProperties.SetAccessibilityView(icon, AccessibilityView.Raw);
        return icon;
    }

    private static Button ActionButton(string glyph) => new()
    {
        Content = Icon(glyph, 15), Style = (Style)Application.Current.Resources["PrayerPopupActionStyle"],
    };

    private static void NameAction(Button button, string name)
    {
        AutomationProperties.SetName(button, name);
        ToolTipService.SetToolTip(button, name);
    }

    private static Windows.UI.Color ReadableAccent(Windows.UI.Color color, bool dark)
    {
        // User colors can be too dark on a dark popup (or too pale on a light one).
        // Keep their hue, moving toward the text color until small text reaches 4.5:1.
        static double Channel(byte value) => value <= 10 ? value / 3294.6 : Math.Pow((value / 255.0 + 0.055) / 1.055, 2.4);
        static double Luminance(Windows.UI.Color value) => 0.2126 * Channel(value.R) +
            0.7152 * Channel(value.G) + 0.0722 * Channel(value.B);
        var background = dark ? 0.045 : 0.92; // Includes the next-row tint and footer.
        color.A = 255;
        for (var step = 0; step < 30; step++)
        {
            var luminance = Luminance(color);
            if ((Math.Max(luminance, background) + 0.05) / (Math.Min(luminance, background) + 0.05) >= 4.5) break;
            byte Adjust(byte value) => (byte)Math.Round(value * 0.9 + (dark ? 255 : 0) * 0.1);
            color.R = Adjust(color.R); color.G = Adjust(color.G); color.B = Adjust(color.B);
        }
        return color;
    }
}
