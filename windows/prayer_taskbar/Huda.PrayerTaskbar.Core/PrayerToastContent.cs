using System.Security;
using NodaTime;

namespace Huda.PrayerTaskbar.Core;

/// Scheduled reminders and previews share content; playback remains independent.
public static class PrayerToastContent
{
    /// Each toast is about its own prayer only; nothing else is added to the body.
    public static string Xml(TaskbarConfiguration config, PrayerEvent prayer, string payload = "")
    {
        var name = config.Presentation.Label(prayer.Key);
        var title = config.Presentation.Label("prayerNotificationTitle").Replace("{prayer}", name);
        var zone = DateTimeZoneProviders.Tzdb[config.Location?.TimeZoneId ?? "UTC"];
        var wall = prayer.Time.InZone(zone).LocalDateTime;
        var body = config.Presentation.Label("prayerNotificationBody").Replace("{prayer}", name) +
            $" · {wall.Hour:00}:{wall.Minute:00}";
        return $"<toast duration=\"long\" launch=\"{Escape(payload)}\" useButtonStyle=\"true\"><visual><binding template=\"ToastGeneric\"><text>{Escape(title)}</text><text>{Escape(body)}</text></binding></visual><audio silent=\"true\"/><actions/></toast>";
    }
    /// A reminder some minutes before a prayer, shown while Huda runs.
    public static string AdvanceXml(TaskbarConfiguration config, PrayerEvent prayer, int minutes)
    {
        var name = config.Presentation.Label(prayer.Key);
        var digits = config.Presentation.Numerals switch {
            "arabic" => "٠١٢٣٤٥٦٧٨٩", "easternArabic" => "۰۱۲۳۴۵۶۷۸۹", _ => "0123456789" };
        var count = string.Concat(minutes.ToString(System.Globalization.CultureInfo.InvariantCulture)
            .Select(ch => digits[ch - '0']));
        var body = config.Presentation.Label("prayerAdvanceBody").Replace("{prayer}", name).Replace("{minutes}", count);
        return $"<toast><visual><binding template=\"ToastGeneric\"><text>{Escape(name)}</text><text>{Escape(body)}</text></binding></visual><audio silent=\"true\"/></toast>";
    }
    private static string Escape(string value) => SecurityElement.Escape(value)!;
}
