using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Huda.PrayerTaskbar;

// Each Focus window has its own brushes. Updating the app color changes the
// existing brushes, so an active reminder recolors without rebuilding its UI.
internal sealed class FocusTheme
{
    private sealed class ThemePalette
    {
        public ResourceDictionary Resources { get; } = new();
        // ResourceDictionary lookups can fall back to shared WinUI brushes.
        // Track only the mutable brushes owned by this Focus window.
        public Dictionary<string, Brush> Brushes { get; } = new();
    }
    private readonly ThemePalette _light = new(), _dark = new();
    private uint? _primary;

    public FocusTheme(FrameworkElement root, uint primary)
    {
        root.Resources.ThemeDictionaries["Light"] = _light.Resources;
        root.Resources.ThemeDictionaries["Default"] = _dark.Resources;
        var highContrast = new ResourceDictionary();
        var system = (ResourceDictionary)Application.Current.Resources.ThemeDictionaries["HighContrast"];
        foreach (var key in system.Keys.OfType<string>().Where(key => key.StartsWith("PrayerFocus")))
            highContrast[key] = system[key];
        ButtonStates(highContrast, (Brush)system["PrayerFocusPrimaryBrush"],
            (Brush)system["PrayerFocusPrimaryTextBrush"], (Brush)system["PrayerFocusBorderBrush"]);
        root.Resources.ThemeDictionaries["HighContrast"] = highContrast;
        Apply(primary);
    }

    public void Apply(uint primary)
    {
        if (_primary == primary) return;
        var color = Color.FromArgb(255, (byte)(primary >> 16), (byte)(primary >> 8), (byte)primary);
        Palette(_light, color, dark: false);
        Palette(_dark, color, dark: true);
        _primary = primary;
    }

    private static void Palette(ThemePalette palette, Color primary, bool dark)
    {
        var neutral = dark ? Rgb(0x111317) : Rgb(0xFFFDF7);
        var start = Mix(neutral, primary, dark ? .22 : .035);
        var end = Mix(neutral, primary, dark ? .42 : .09);
        var card = Mix(end, Rgb(0xFFFFFF), dark ? .035 : .82);
        var text = dark ? Rgb(0xF8FAFC) : Rgb(0x2C2C2C);
        var secondary = Mix(text, end, .25);
        var accent = Readable(primary, card);
        var border = Mix(card, accent, .28);
        var primaryText = Contrast(primary, Rgb(0xFFFFFF)) >= Contrast(primary, Rgb(0x111111))
            ? Rgb(0xFFFFFF) : Rgb(0x111111);
        if (palette.Brushes.TryGetValue("PrayerFocusBackgroundBrush", out var existing))
        {
            var gradient = (LinearGradientBrush)existing;
            gradient.GradientStops[0].Color = start;
            gradient.GradientStops[1].Color = end;
        }
        else
        {
            var gradient = new LinearGradientBrush { StartPoint = new Windows.Foundation.Point(0, 0),
                EndPoint = new Windows.Foundation.Point(1, 1) };
            gradient.GradientStops.Add(new GradientStop { Color = start, Offset = 0 });
            gradient.GradientStops.Add(new GradientStop { Color = end, Offset = 1 });
            palette.Brushes["PrayerFocusBackgroundBrush"] = gradient;
            palette.Resources["PrayerFocusBackgroundBrush"] = gradient;
        }
        Set(palette, "PrayerFocusCardBrush", card);
        Set(palette, "PrayerFocusBorderBrush", border);
        Set(palette, "PrayerFocusTextBrush", text);
        Set(palette, "PrayerFocusSecondaryBrush", secondary);
        Set(palette, "PrayerFocusAccentBrush", accent);
        Set(palette, "PrayerFocusPrimaryBrush", primary);
        Set(palette, "PrayerFocusPrimaryTextBrush", primaryText);
        Set(palette, "PrayerFocusTrackBrush", Mix(card, accent, .2));
        // Keep native hover/press states in the same local palette.
        Set(palette, "ButtonBackgroundPointerOver", Mix(primary, primaryText, .1));
        Set(palette, "ButtonBackgroundPressed", Mix(primary, primaryText, .18));
        Set(palette, "ButtonForegroundPointerOver", primaryText);
        Set(palette, "ButtonForegroundPressed", primaryText);
        Set(palette, "ButtonBorderBrushPointerOver", accent);
        Set(palette, "ButtonBorderBrushPressed", accent);
    }

    private static void ButtonStates(ResourceDictionary resources, Brush background, Brush foreground, Brush border)
    {
        foreach (var state in new[] { "PointerOver", "Pressed" })
        {
            resources["ButtonBackground" + state] = background;
            resources["ButtonForeground" + state] = foreground;
            resources["ButtonBorderBrush" + state] = border;
        }
    }

    private static SolidColorBrush Set(ThemePalette palette, string key, Color color)
    {
        if (palette.Brushes.TryGetValue(key, out var existing))
        {
            var brush = (SolidColorBrush)existing;
            brush.Color = color; return brush;
        }
        var added = new SolidColorBrush(color);
        palette.Brushes[key] = added;
        palette.Resources[key] = added; return added;
    }

    private static Color Readable(Color primary, Color surface)
    {
        var target = Contrast(Rgb(0xFFFFFF), surface) > Contrast(Rgb(0x111111), surface)
            ? Rgb(0xFFFFFF) : Rgb(0x111111);
        var result = primary;
        for (var step = 1; step <= 20 && Contrast(result, surface) < 4.5; step++)
            result = Mix(primary, target, step / 20d);
        return result;
    }
    private static Color Rgb(uint value) => Color.FromArgb(255, (byte)(value >> 16), (byte)(value >> 8), (byte)value);
    private static Color Mix(Color from, Color to, double amount) => Color.FromArgb(255,
        (byte)Math.Round(from.R + (to.R - from.R) * amount),
        (byte)Math.Round(from.G + (to.G - from.G) * amount),
        (byte)Math.Round(from.B + (to.B - from.B) * amount));
    private static double Contrast(Color a, Color b)
    {
        static double Channel(byte value) { var n = value / 255d; return n <= .04045 ? n / 12.92 : Math.Pow((n + .055) / 1.055, 2.4); }
        static double Luminance(Color c) => .2126 * Channel(c.R) + .7152 * Channel(c.G) + .0722 * Channel(c.B);
        var first = Luminance(a); var second = Luminance(b);
        return (Math.Max(first, second) + .05) / (Math.Min(first, second) + .05);
    }
}
