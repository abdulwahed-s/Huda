using System.Globalization;
using NodaTime;

namespace Huda.PrayerTaskbar.Core;

public static class CountdownFormatter
{
    public static string Countdown(Instant target, Instant now, bool seconds)
    {
        var total = Math.Max(0, (long)(target - now).TotalSeconds);
        return seconds ? $"{total / 3600:00}:{total / 60 % 60:00}:{total % 60:00}"
            : $"{total / 3600:00}:{total / 60 % 60:00}";
    }

    public static string Counter(PrayerMoment moment, Instant now, bool seconds) => moment.IsElapsed
        ? "+" + Countdown(now, moment.Prayer.Time, seconds)
        : Countdown(moment.Prayer.Time, now, seconds);

    public static string Clock(Instant? instant, string zoneId, Presentation presentation)
    {
        if (instant is null) return "—";
        var wall = instant.Value.InZone(DateTimeZoneProviders.Tzdb[zoneId]);
        CultureInfo culture;
        try { culture = CultureInfo.GetCultureInfo(presentation.Locale.Replace('_', '-')); }
        catch (CultureNotFoundException) { culture = CultureInfo.InvariantCulture; }
        return Digits(wall.ToDateTimeUnspecified().ToString(
            presentation.Use24HourClock ? "HH:mm" : "h:mm tt", culture), presentation.Numerals);
    }

    public static string Text(TaskbarConfiguration config, ScheduleSnapshot? snapshot, Instant now)
    {
        var p = config.Presentation;
        if (config.Location is null) return p.Label("needsSetup");
        if (snapshot?.Error is { } error) return p.Label(error);
        if (snapshot?.Moment(now) is not { } moment) return p.Label("noNextPrayer");
        var time = config.Preferences.Style == "iconNameClock"
            ? Clock(moment.Prayer.Time, config.Location.TimeZoneId, p)
            : Digits(Counter(moment, now, config.Preferences.ShowSeconds), p.Numerals);
        // Direction isolates keep the timer's ordering in an RTL prayer label.
        var caption = $"{p.Label(moment.Prayer.Key)} · \u2066{time}\u2069";
        return config.Location.Verified ? caption : "⚠ " + caption;
    }

    public static string Digits(string value, string numerals)
    {
        var digits = numerals switch { "arabic" => "٠١٢٣٤٥٦٧٨٩", "easternArabic" => "۰۱۲۳۴۵۶۷۸۹", _ => "0123456789" };
        return string.Concat(value.Select(c => c is >= '0' and <= '9' ? digits[c - '0'] : c));
    }
}
