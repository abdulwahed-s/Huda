using NodaTime;

namespace Huda.PrayerTaskbar.Core;

/// <summary>
/// One reminder rule Huda's Flutter orchestrator publishes: a one-time
/// reminder, a daily or weekly repeat, or random Athkar every
/// <see cref="IntervalMinutes"/> with one of <see cref="Texts"/> each time.
/// The Linux companion delivers these; the Windows companion keeps their
/// toasts topped up. Field names match the Dart and Android rule format.
/// </summary>
public sealed record ReminderRule
{
    public required long Id { get; init; }
    /// <summary><c>once</c>, <c>daily</c>, <c>weekly</c> or <c>interval</c>.</summary>
    public required string Kind { get; init; }
    public required string Style { get; init; }
    public required string Title { get; init; }
    public string Body { get; init; } = "";
    public required string Payload { get; init; }
    /// <summary>The first delivery Huda planned; nothing earlier is delivered.</summary>
    public required long UtcMillis { get; init; }
    public int? Hour { get; init; }
    public int? Minute { get; init; }
    /// <summary>ISO weekday, Monday = 1.</summary>
    public int? Weekday { get; init; }
    public int? IntervalMinutes { get; init; }
    public IReadOnlyList<string> Texts { get; init; } = [];
    public long? Color { get; init; }

    public Instant First => Instant.FromUnixTimeMilliseconds(UtcMillis);

    public void Validate()
    {
        var valid = Kind switch
        {
            "once" => true,
            "daily" => Hour is >= 0 and < 24 && Minute is >= 0 and < 60,
            "weekly" => Hour is >= 0 and < 24 && Minute is >= 0 and < 60 && Weekday is >= 1 and <= 7,
            "interval" => IntervalMinutes is >= 1 and <= 1440 && Texts.Count > 0 &&
                Texts.All(text => !string.IsNullOrWhiteSpace(text) && text.Length <= 2048),
            _ => false,
        };
        if (!valid || Id is < 0 or > int.MaxValue || Style is not ("dailyReminder" or "weeklyReminder" or "athkar" or "calendar") ||
            string.IsNullOrWhiteSpace(Title) || Title.Length > 2048 || Body.Length > 4096 || Payload.Length > 4096)
            throw new InvalidDataException("Invalid reminder rule.");
    }
}
