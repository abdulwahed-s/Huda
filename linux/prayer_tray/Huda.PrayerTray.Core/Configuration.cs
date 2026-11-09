using System.Text.Json;
using System.Text.RegularExpressions;
using Huda.PrayerTaskbar.Core;

namespace Huda.PrayerTray.Core;

// Flutter owns this exchange. Windows preferences never enter the Linux wire contract.
public sealed record TrayConfiguration
{
    public required int SchemaVersion { get; init; }
    public required long Revision { get; init; }
    public required DateTimeOffset PublishedAtUtc { get; init; }
    public required TrayPreferences Preferences { get; init; }
    public required TrayPresentation Presentation { get; init; }
    public PrayerLocation? Location { get; init; }
    public CalculationSettings? Calculation { get; init; }
    public LinuxPrayerExperience? Experience { get; init; }
    public PrayerNotificationContract? NotificationContract { get; init; }
    public DateTimeOffset? CutoverInstantUtc { get; init; }
    public IReadOnlyList<int> HandledOccurrenceIds { get; init; } = [];
    /// <summary>Reminders, random Athkar and calendar events this companion delivers.</summary>
    public IReadOnlyList<ReminderRule> ReminderRules { get; init; } = [];
    public static JsonSerializerOptions JsonOptions { get; } = new(JsonSerializerDefaults.Web);
    public static readonly string[] Locales = ["ar", "bn", "de", "en", "es", "fr", "ms", "ru", "tr", "ur"];
    public static readonly string[] RequiredLabels = [.. TaskbarConfiguration.PrayerKeys,
        "prayerTimes", "prayerSettings", "openHuda", "quitHuda", "quitExplanation", "needsSetup",
        "verifyLocation", "calendarUnavailable", "noNextPrayer", "serviceUnavailable",
        "calculationUnavailable", "nameCountdown", "hourUnit", "minuteUnit"];

    public static TrayConfiguration Parse(string json)
    {
        if (json.Length > 262144) throw new InvalidDataException("Configuration too large.");
        var next = JsonSerializer.Deserialize<TrayConfiguration>(json, JsonOptions)
            ?? throw new InvalidDataException("Missing configuration.");
        next.Validate();
        return next;
    }

    public void Validate()
    {
        TaskbarConfiguration.ValidateReminders(ReminderRules);
        if (SchemaVersion != 1 || Preferences is null || Presentation is null ||
            !Locales.Contains(Presentation.Locale) ||
            Presentation.Rtl != (Presentation.Locale is "ar" or "ur") ||
            !double.IsFinite(Presentation.TextScale) || Presentation.TextScale is < 0.5 or > 2 ||
            RequiredLabels.Any(key => !Presentation.Strings.TryGetValue(key, out var value) ||
                string.IsNullOrWhiteSpace(value) || value.Length > 2048) ||
            !Presentation.Strings["nameCountdown"].Contains("{prayer}") ||
            !Presentation.Strings["nameCountdown"].Contains("{time}") ||
            Presentation.Tokens is null || !Presentation.Tokens.ContainsKey("light") ||
            !Presentation.Tokens.ContainsKey("dark"))
            throw new InvalidDataException("Incomplete Linux presentation.");
        foreach (var mode in new[] { "light", "dark" })
            foreach (var key in new[] { "surface", "card", "primary", "ink", "muted", "faint",
                         "border", "divider", "highlight", "warning", "error", "success" })
                if (!Presentation.Tokens[mode].TryGetValue(key, out var token) ||
                    !Regex.IsMatch(token, "^#[0-9a-fA-F]{8}$"))
                    throw new InvalidDataException("Invalid presentation token.");
        ToCalculationConfiguration().Validate();
        Experience?.Validate();
        NotificationContract?.Validate();
        if (HandledOccurrenceIds.Count > 2048 || HandledOccurrenceIds.Any(id => id < 300000000 || id >= 400000000))
            throw new InvalidDataException("Invalid imported prayer occurrence history.");
        if (Experience is { Configured: true } && (NotificationContract is null ||
            Location?.Revision != NotificationContract.LocationRevision))
            throw new InvalidDataException("Reminder configuration must identify its committed location and schedule.");
    }

    public TaskbarConfiguration ToCalculationConfiguration() => new()
    {
        SchemaVersion = SchemaVersion, Revision = Revision, PublishedAtUtc = PublishedAtUtc,
        Location = Location, Calculation = Calculation,
        Preferences = new TaskbarPreferences
        {
            Enabled = Preferences.Enabled, ShowTaskbarCountdown = true, ShowTrayIcon = true,
            StartWithWindows = false, Style = Preferences.Style, ShowSeconds = false,
        },
        Presentation = new Presentation
        {
            Locale = Presentation.Locale, Rtl = Presentation.Rtl, ThemeMode = Presentation.ThemeMode,
            PrimaryColor = 0, Numerals = Presentation.Numerals, Use24HourClock = Presentation.Use24HourClock,
            FontFamily = Presentation.FontFamily, Strings = Presentation.Strings,
        },
    };
}

public sealed record TrayPreferences
{
    public required bool Enabled { get; init; }
    public required bool StartAtLogin { get; init; }
    public required string Style { get; init; }
}

public sealed record TrayPresentation
{
    public required string Locale { get; init; }
    public required bool Rtl { get; init; }
    public required string ThemeMode { get; init; }
    public required string FontFamily { get; init; }
    public required string Numerals { get; init; }
    public required bool Use24HourClock { get; init; }
    public required double TextScale { get; init; }
    public required Dictionary<string, string> Strings { get; init; }
    public required Dictionary<string, Dictionary<string, string>> Tokens { get; init; }
    public string MethodLabel { get; init; } = "";
}
