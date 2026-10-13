using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace Huda.PrayerTaskbar;

internal static class PresentationAssets
{
    private static readonly FontFamily SystemFont = new("Segoe UI");
    private static readonly FontFamily AmiriRegular = new(AssetUri("Assets/Fonts/Amiri-Regular.ttf") + "#Amiri");
    private static readonly FontFamily AmiriBold = new(AssetUri("Assets/Fonts/Amiri-Bold.ttf") + "#Amiri");

    private static Uri AssetUri(string path)
    {
        // WinUI resolves these through this executable's PRI resource map.
        // Its Files/Assets entries stay the same inside Huda's MSIX subfolder.
        return new Uri("ms-appx:///" + path);
    }

    public static FontFamily Font(string family, bool bold = false) => family == "Amiri"
        ? bold ? AmiriBold : AmiriRegular : SystemFont;

    public static double FontSize(string family, double size) => family == "Amiri" ? size * 1.2 : size;

    public static void ApplyFont(TextBlock block, Presentation presentation, double size)
    {
        block.FontFamily = Font(presentation.FontFamily, block.FontWeight.Weight >= 600);
        block.FontSize = FontSize(presentation.FontFamily, size);
        // Amiri's generous font metrics otherwise add large gaps to compact rows.
        // Block line height preserves a consistent baseline while allowing text scaling.
        if (presentation.FontFamily == "Amiri")
        {
            block.LineHeight = Math.Ceiling(block.FontSize * 1.4);
            block.LineStackingStrategy = LineStackingStrategy.BlockLineHeight;
        }
        else
        {
            block.ClearValue(TextBlock.LineHeightProperty);
            block.ClearValue(TextBlock.LineStackingStrategyProperty);
        }
    }

    public static BitmapIcon Logo(double size)
    {
        var icon = new BitmapIcon { UriSource = AssetUri("Assets/huda-logo.png"),
            ShowAsMonochrome = true, Width = size, Height = size,
            VerticalAlignment = VerticalAlignment.Center };
        AutomationProperties.SetAccessibilityView(icon, AccessibilityView.Raw);
        return icon;
    }
}
