using System.Text.Json;
using NodaTime;
using PrayerTimePlus;

namespace Huda.PrayerTaskbar.Core;

// This exchange is owned by Flutter. The companion never edits preferences.
public sealed record TaskbarConfiguration
{
    public const int SupportedSchemaVersion = 1;
    public required int SchemaVersion { get; init; }
    public required long Revision { get; init; }
    public required DateTimeOffset PublishedAtUtc { get; init; }
    public required TaskbarPreferences Preferences { get; init; }
    public required Presentation Presentation { get; init; }
    public PrayerLocation? Location { get; init; }
    public CalculationSettings? Calculation { get; init; }
    public PrayerExperience? PrayerExperience { get; init; }
    public DateTimeOffset? PrayerExperienceActiveFromUtc { get; init; }
    public PrayerNotificationContract? NotificationContract { get; init; }
    /// <summary>Repeating reminders whose toasts the companion keeps topped up.</summary>
    public IReadOnlyList<ReminderRule> ReminderRules { get; init; } = [];

    public static JsonSerializerOptions JsonOptions { get; } = new(JsonSerializerDefaults.Web);

    public static void ValidateReminders(IReadOnlyList<ReminderRule>? rules)
    {
        if (rules is null) throw new InvalidDataException("Missing reminder rules.");
        if (rules.Count > 200 || rules.Select(rule => rule.Id).Distinct().Count() != rules.Count)
            throw new InvalidDataException("Invalid reminder rules.");
        foreach (var rule in rules) rule.Validate();
    }

    public static TaskbarConfiguration Parse(string json)
    {
        var value = JsonSerializer.Deserialize<TaskbarConfiguration>(json, JsonOptions)
            ?? throw new InvalidDataException("Missing configuration.");
        value.Validate();
        return value;
    }

    public void Validate()
    {
        PrayerExperience?.Validate();
        if (PrayerExperienceActiveFromUtc is { Offset: var offset } && offset != TimeSpan.Zero)
            throw new InvalidDataException("Invalid reminder cutover instant.");
        NotificationContract?.Validate();
        ValidateReminders(ReminderRules);
        if (SchemaVersion != SupportedSchemaVersion || Revision is <= 0 or > 9007199254740991 ||
            PublishedAtUtc.Offset != TimeSpan.Zero || Preferences is null || Presentation is null)
            throw new InvalidDataException("Unsupported or incomplete configuration.");
        if (Preferences.Style is not ("iconOnly" or "iconNameCountdown" or "iconNameClock"))
            throw new InvalidDataException("Unknown taskbar style.");
        if (Preferences.TextColor is not ("automatic" or "light" or "dark" or "appColor") ||
            Preferences.TextSize is not ("small" or "medium" or "large"))
            throw new InvalidDataException("Unknown taskbar appearance.");
        if (Presentation.ThemeMode is not ("system" or "light" or "dark") ||
            Presentation.FontFamily is not ("system" or "Amiri") ||
            Presentation.Numerals is not ("western" or "arabic" or "easternArabic") ||
            string.IsNullOrWhiteSpace(Presentation.Locale) || Presentation.Strings is null ||
            RequiredLabels.Any(key => !Presentation.Strings.TryGetValue(key, out var label) ||
                string.IsNullOrWhiteSpace(label)))
            throw new InvalidDataException("Incomplete presentation.");
        if ((Location is null) != (Calculation is null))
            throw new InvalidDataException("Location and calculation must be published together.");
        if (Location is not { } location || Calculation is not { } settings) return;
        if (!double.IsFinite(location.Latitude) || location.Latitude is < -90 or > 90 ||
            !double.IsFinite(location.Longitude) || location.Longitude is < -180 or > 180 ||
            location.Altitude != 0 || DateTimeZoneProviders.Tzdb.GetZoneOrNull(location.TimeZoneId) is null ||
            location.Mode is not ("automatic" or "manual") || location.Revision <= 0 ||
            location.VerificationReasons is null)
            throw new InvalidDataException("Invalid prayer location.");
        if (CalculationMethods.FromKey(settings.MethodKey) is null ||
            string.IsNullOrEmpty(settings.MethodChoice) ||
            settings.Madhab is not ("shafi" or "hanafi") ||
            settings.HighLatitudeRule is not ("automatic" or "middle_of_night" or
                "seventh_of_night" or "twilight_angle" or "none") ||
            !ValidAngle(settings.FajrAngle, false) ||
            !ValidValue(settings.MaghribValue, settings.MaghribIsInterval, true) ||
            !ValidValue(settings.IshaValue, settings.IshaIsInterval, false) ||
            settings.ManualOffsets is null || settings.ManualOffsets.Count != PrayerKeys.Length || PrayerKeys.Any(key =>
                !settings.ManualOffsets.TryGetValue(key, out var offset) || Math.Abs((long)offset) > 10080))
            throw new InvalidDataException("Invalid prayer calculation settings.");
    }

    private static bool ValidAngle(double value, bool allowZero) => double.IsFinite(value) &&
        value <= 30 && (allowZero ? value >= 0 : value > 0);
    private static bool ValidValue(double value, bool interval, bool allowZero) => interval
        ? double.IsFinite(value) && value is >= 0 and <= 1440
        : ValidAngle(value, allowZero);

    public static readonly string[] PrayerKeys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"];
    private static readonly string[] RequiredLabels = [.. PrayerKeys, "prayerTimes", "prayerSettings",
        "openHuda", "quitHuda", "needsSetup", "verifyLocation", "calendarUnavailable", "noNextPrayer"];
}

public sealed record TaskbarPreferences
{
    [System.Text.Json.Serialization.JsonConverter(typeof(PrayerIqamahMinutesConverter))]
    public IReadOnlyDictionary<string, int> IqamahMinutes { get; init; } = PrayerIqamahWindows.Defaults;
    public required bool Enabled { get; init; }
    public required bool ShowTaskbarCountdown { get; init; }
    public required bool ShowTrayIcon { get; init; }
    public required bool StartWithWindows { get; init; }
    public required string Style { get; init; }
    public required bool ShowSeconds { get; init; }
    public bool TransparentBackground { get; init; } = true;
    public string TextColor { get; init; } = "automatic";
    public string TextSize { get; init; } = "medium";
    public bool ShowIcon { get; init; } = true;
}

public sealed record PrayerLocation
{
    public required long Revision { get; init; }
    public required double Latitude { get; init; }
    public required double Longitude { get; init; }
    public required double Altitude { get; init; }
    public required string TimeZoneId { get; init; }
    public required string CountryCode { get; init; }
    public required string Mode { get; init; }
    public required bool Verified { get; init; }
    public required string[] VerificationReasons { get; init; }
    public string? Locality { get; init; }
    public string? CountryName { get; init; }
}

public sealed record CalculationSettings
{
    public required string MethodChoice { get; init; }
    public required string MethodKey { get; init; }
    public required string Madhab { get; init; }
    public required string HighLatitudeRule { get; init; }
    public required double FajrAngle { get; init; }
    public required bool MaghribIsInterval { get; init; }
    public required double MaghribValue { get; init; }
    public required bool IshaIsInterval { get; init; }
    public required double IshaValue { get; init; }
    public required Dictionary<string, int> ManualOffsets { get; init; }
}

public sealed record Presentation
{
    public required string Locale { get; init; }
    public required bool Rtl { get; init; }
    public required string ThemeMode { get; init; }
    public required uint PrimaryColor { get; init; }
    public required string Numerals { get; init; }
    public required bool Use24HourClock { get; init; }
    // Schema 1 configurations from older Huda builds retain their native font.
    public string FontFamily { get; init; } = "system";
    public required Dictionary<string, string> Strings { get; init; }
    public string Label(string key) => Strings.GetValueOrDefault(key,
        key switch { "quran" => "Quran", "athkar" => "Athkar",
            "prayerStopAdhan" => "Stop Adhan", "prayerDismissFocus" => "Dismiss",
            "prayerFocusMessage" => "It is time to pray. Take a break.",
            "prayerFocusMode" => "Focus Mode",
            "prayerFocusVerseReference" => "An-Nisa · 4:103",
            "prayerFocusTimeRemaining" => "Time remaining",
            "prayerFocusExitHint" => "Dismiss or press Escape at any time.",
            "prayerFocusLockedHint" => "Focus ends when the timer reaches zero.",
            "prayerNotificationTitle" => "Time for {prayer}",
            "prayerNotificationBody" => "It is time for {prayer} prayer.",
            "prayerNextNotification" => "Next: {prayer} in {duration}",
            "prayerAdvanceBody" => "{prayer} in {minutes} minutes.",
            _ => key });
}
