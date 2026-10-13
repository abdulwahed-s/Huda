using System.Runtime.InteropServices;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Hosting;
using Microsoft.UI.Xaml.Media;
using Microsoft.Win32;
using Windows.Foundation;
using Windows.Graphics;
using Windows.UI;
using Windows.UI.ViewManagement;

namespace Huda.PrayerTaskbar;

internal sealed class TaskbarSurface(Action click) : IDisposable
{
    private NativeWindow? _host;
    private DesktopWindowXamlSource? _source;
    private Button? _button;
    private TextBlock? _label;
    private BitmapIcon? _logo;
    private readonly SolidColorBrush _background = new(), _foreground = new(), _hover = new(), _pressed = new();
    private readonly UISettings _systemColors = new();
    private readonly AccessibilitySettings _accessibility = new();
    private TaskbarPreferences? _appearance;
    private ElementTheme _appearanceTheme;
    private bool _highContrast;
    private uint _primary;
    private readonly TextBlock _measurement = new() { FontSize = 13 };
    private int _width = 160;
    public int Width => Volatile.Read(ref _width);
    public string Placement { get; private set; } = "hidden";
    public NativeMethods.Rect? Anchor { get; private set; }
    private bool _enabled;
    private string? _text;
    private TaskbarConfiguration? _config;

    public void Update(TaskbarConfiguration config, string text)
    {
        _config = config;
        _enabled = LifecyclePolicy.ShowTaskbar(config.Preferences);
        if (!_enabled) { Volatile.Write(ref _width, 0); Hide(); Placement = "hidden"; return; }
        var iconOnly = config.Preferences.Style == "iconOnly";
        var showIcon = iconOnly || config.Preferences.ShowIcon;
        var fontSize = config.Preferences.TextSize switch { "small" => 11, "large" => 15, _ => 13 };
        // Measure the complete translated text at the native font size in DIPs.
        PresentationAssets.ApplyFont(_measurement, config.Presentation, fontSize);
        if (_measurement.Text != text) _measurement.Text = text;
        _measurement.Measure(new Size(double.PositiveInfinity, double.PositiveInfinity));
        Volatile.Write(ref _width, iconOnly ? 40 : Math.Clamp((int)Math.Ceiling(_measurement.DesiredSize.Width) + (showIcon ? 48 : 20), 56, 360));
        if (_label is not null && _text != text) _label.Text = text;
        if (_label is not null)
        {
            PresentationAssets.ApplyFont(_label, config.Presentation, fontSize);
            _label.MaxWidth = Math.Max(0, Width - (showIcon ? 45 : 16));
        }
        if (_label is not null) _label.Visibility = iconOnly ? Visibility.Collapsed : Visibility.Visible;
        if (_logo is not null) _logo.Visibility = showIcon ? Visibility.Visible : Visibility.Collapsed;
        if (_button is not null)
        {
            ApplyAppearance(config);
            _button.FlowDirection = config.Presentation.Rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
            var tooltip = config.Location is { Verified: false }
                ? text + "\n" + config.Presentation.Label("verifyLocation") : text;
            AutomationProperties.SetName(_button, tooltip);
            ToolTipService.SetToolTip(_button, tooltip);
        }
        _text = text;
    }

    public void Place(TaskbarLayout? layout)
    {
        if (!_enabled) return;
        if (layout is null || !NativeMethods.IsWindow(layout.Handle))
        { Hide(); Placement = "unavailable"; return; }
        try
        {
            if (_host is null || !NativeMethods.IsWindow(_host.Handle) ||
                NativeMethods.GetParent(_host.Handle) != layout.Handle)
            {
                DisposeHost();
                _host = new NativeWindow();
                // Avoid SetParent's cross-process DPI reset on an incompatible Explorer.
                if (!NativeMethods.AreDpiAwarenessContextsEqual(
                    NativeMethods.GetWindowDpiAwarenessContext(_host.Handle),
                    NativeMethods.GetWindowDpiAwarenessContext(layout.Handle)))
                    throw new InvalidOperationException("Explorer DPI context differs.");
                // Initialize the island while its host still belongs to our
                // top-level window tree. WinUI cannot initialize through an
                // Explorer ancestor owned by another process.
                _source = new DesktopWindowXamlSource();
                _source.Initialize(Microsoft.UI.Win32Interop.GetWindowIdFromWindow(_host.Handle));
                _label = new TextBlock { Text = _text ?? "", FontSize = 13,
                    VerticalAlignment = VerticalAlignment.Center, TextTrimming = TextTrimming.CharacterEllipsis };
                var content = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 7,
                    VerticalAlignment = VerticalAlignment.Center };
                _logo = PresentationAssets.Logo(18);
                content.Children.Add(_logo);
                content.Children.Add(_label);
                _button = new Button { Content = content, Padding = new Thickness(8, 0, 8, 0),
                    BorderThickness = new Thickness(0), HorizontalAlignment = HorizontalAlignment.Stretch,
                    VerticalAlignment = VerticalAlignment.Stretch, CornerRadius = new CornerRadius(6),
                    Background = _background, Foreground = _foreground };
                foreach (var state in new[] { "", "PointerOver", "Pressed", "Disabled" })
                {
                    _button.Resources["ButtonBackground" + state] = state switch {
                        "PointerOver" => _hover, "Pressed" => _pressed, _ => _background };
                    _button.Resources["ButtonForeground" + state] = _foreground;
                    _button.Resources["ButtonBorderBrush" + state] = new SolidColorBrush(Microsoft.UI.Colors.Transparent);
                }
                _label.Foreground = _foreground;
                _logo.Foreground = _foreground;
                _button.Click += (_, _) => click();
                _source.Content = _button;
                _source.SystemBackdrop = new TaskbarBackdrop();
                NativeMethods.SetWindowLongPtr(_host.Handle, -16,
                    (nint)(NativeMethods.WS_CHILD | NativeMethods.WS_CLIPCHILDREN));
                NativeMethods.SetParent(_host.Handle, layout.Handle);
                if (NativeMethods.GetParent(_host.Handle) != layout.Handle)
                    throw new InvalidOperationException("Explorer attachment failed.");
                Update(_config!, _text!);
            }
            var x = layout.X - layout.Bounds.Left;
            NativeMethods.SetWindowPos(_host.Handle, 0, x, 0, layout.Width, layout.Bounds.Height,
                NativeMethods.SWP_NOACTIVATE);
            _source!.SiteBridge.MoveAndResize(new RectInt32(0, 0, layout.Width, layout.Bounds.Height));
            _source.SiteBridge.Show();
            NativeMethods.ShowWindow(_host.Handle, layout.Visible ? 4 : 0);
            Anchor = new NativeMethods.Rect { Left = layout.X, Top = layout.Bounds.Top,
                Right = layout.X + layout.Width, Bottom = layout.Bounds.Bottom };
            Placement = "attached";
        }
        catch (Exception error) when (error is COMException or InvalidOperationException or System.ComponentModel.Win32Exception)
        { Console.Error.WriteLine(error); DisposeHost(); Placement = "unavailable"; }
    }

    internal static ElementTheme Theme(string theme) => theme switch {
        "light" => ElementTheme.Light, "dark" => ElementTheme.Dark,
        _ => SystemTheme(),
    };
    private void ApplyAppearance(TaskbarConfiguration config)
    {
        var preferences = config.Preferences;
        // The transparent caption sits on Windows' taskbar, which can use a
        // different theme from both Huda and Windows application windows.
        var theme = preferences.TransparentBackground ? TaskbarTheme() : Theme(config.Presentation.ThemeMode);
        var highContrast = _accessibility.HighContrast;
        _button!.RequestedTheme = theme;
        if (!highContrast && _appearance == preferences && _appearanceTheme == theme &&
            _highContrast == highContrast && _primary == config.Presentation.PrimaryColor) return;
        _appearance = preferences; _appearanceTheme = theme;
        _highContrast = highContrast; _primary = config.Presentation.PrimaryColor;
        var dark = theme == ElementTheme.Dark;
        _foreground.Color = highContrast ? _systemColors.GetColorValue(UIColorType.Foreground)
            : preferences.TextColor switch {
                "light" => Rgb(0xF5F5F5), "dark" => Rgb(0x202020),
                "appColor" => Rgb(config.Presentation.PrimaryColor),
                _ => dark ? Rgb(0xF5F5F5) : Rgb(0x202020) };
        _background.Color = highContrast ? _systemColors.GetColorValue(UIColorType.Background)
            : preferences.TransparentBackground ? Microsoft.UI.Colors.Transparent
            : dark ? Rgb(0x2D2D2D) : Rgb(0xF0F0F0);
        _hover.Color = highContrast ? _background.Color : InteractionBackground(_background.Color, dark, 24);
        _pressed.Color = highContrast ? _background.Color : InteractionBackground(_background.Color, dark, 40);
    }
    private static Color InteractionBackground(Color background, bool dark, byte alpha)
    {
        var channel = dark ? (byte)255 : (byte)0;
        if (background.A == 0) return Color.FromArgb(alpha, channel, channel, channel);
        byte Mix(byte value) => (byte)Math.Round(value + (channel - value) * alpha / 255d);
        return Color.FromArgb(255, Mix(background.R), Mix(background.G), Mix(background.B));
    }
    private static Color Rgb(uint value) => Color.FromArgb(255, (byte)(value >> 16), (byte)(value >> 8), (byte)value);
    private static ElementTheme TaskbarTheme()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            if (key?.GetValue("SystemUsesLightTheme") is int light)
                return light == 0 ? ElementTheme.Dark : ElementTheme.Light;
        }
        catch (Exception error) when (error is System.Security.SecurityException or UnauthorizedAccessException or IOException) { }
        return SystemTheme();
    }
    private static ElementTheme SystemTheme()
    {
        var color = new Windows.UI.ViewManagement.UISettings().GetColorValue(
            Windows.UI.ViewManagement.UIColorType.Background);
        return color.R + color.G + color.B < 384 ? ElementTheme.Dark : ElementTheme.Light;
    }
    private void Hide() { if (_host is not null) NativeMethods.ShowWindow(_host.Handle, 0); Anchor = null; }
    private void DisposeHost()
    {
        if (_source is not null) _source.SystemBackdrop = null;
        _source?.Dispose(); _source = null; _button = null; _label = null; _logo = null; _appearance = null;
        _host?.Dispose(); _host = null; Anchor = null;
    }
    public async Task Export(string path)
    {
        if (_button is not null && Placement == "attached") await PrayerPopup.ExportElement(_button, path);
    }
    public void Dispose() => DisposeHost();
}
