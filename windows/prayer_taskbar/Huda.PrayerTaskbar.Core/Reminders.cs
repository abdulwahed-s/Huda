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

/// <summary>When reminder rules fire. Shared by both companions.</summary>
public static class ReminderSchedule
{
    /// <summary>
    /// The first delivery strictly after <paramref name="after"/> and not before the rule's first planned
    /// delivery, or null once a one-time reminder has passed. Daily and weekly
    /// times are local to <paramref name="zone"/>, so they follow the device.
    /// </summary>
    public static Instant? Next(ReminderRule rule, Instant after, DateTimeZone zone)
    {
        if (rule.First > after) return rule.First;
        switch (rule.Kind)
        {
            case "once":
                return null;
            case "interval":
                var step = Duration.FromMinutes(rule.IntervalMinutes!.Value);
                var steps = (after - rule.First).BclCompatibleTicks / step.BclCompatibleTicks + 1;
                return rule.First + step * steps;
            default:
                var start = after.InZone(zone).Date;
                for (var day = 0; day <= 8; day++)
                {
                    var date = start.PlusDays(day);
                    if (rule.Kind == "weekly" && (int)date.DayOfWeek != rule.Weekday) continue;
                    var at = zone.AtLeniently(date.At(new LocalTime(rule.Hour!.Value, rule.Minute!.Value))).ToInstant();
                    if (at > after) return at;
                }
                throw new InvalidOperationException("No weekly occurrence within eight days.");
        }
    }

    /// <summary>
    /// How late a delivery may still be shown, e.g. after sleep. The same as Windows'
    /// <see cref="MissedToastPolicy"/>: reminders and calendar events up to two hours,
    /// random Athkar not late (the next one follows on time).
    /// </summary>
    public static Duration LateWindow(ReminderRule rule) =>
        rule.Kind == "interval" ? MissedToastPolicy.Settle : MissedToastPolicy.ReminderLimit;

    /// <summary>
    /// Windows tag of one dated reminder toast: 430000000 + (YYYYMMDD - 20000000) * 10 + slot,
    /// where slot = reminder ID - 1000. Matches Huda's <c>NotificationIds.windowsReminderOccurrence</c>.
    /// </summary>
    public static long WindowsOccurrenceId(long reminderId, LocalDate date) =>
        430_000_000L + (date.Year * 10000L + date.Month * 100L + date.Day - 20_000_000L) * 10 + (reminderId - 1000);

    public static long? WindowsReminderOf(long id)
    {
        if (id is < 430_000_000 or >= 440_000_000) return null;
        var slot = (id - 430_000_000) % 10;
        return slot == 0 ? null : 1000 + slot;
    }

    public static bool IsAthkarId(long id) => id is > 1100 and <= 1550;
}

/// <summary>A toast the Windows queue should hold.</summary>
public sealed record ReminderToast(long Id, Instant At, string Title, string Body, string Payload);

/// <summary>
/// Which reminder toasts Windows needs added so each repeating rule keeps
/// <see cref="DatedHorizon"/> of daily or weekly dates and Athkar keep up to
/// <see cref="AthkarLimit"/> toasts within <see cref="AthkarHorizon"/>.
/// The same expansion as Huda's Dart Windows backend, so toasts added by
/// either one look identical to the other. One-time rules need no renewal.
/// </summary>
public static class ReminderToastPlan
{
    public static readonly Duration DatedHorizon = Duration.FromDays(60);
    public static readonly Duration AthkarHorizon = Duration.FromDays(30);
    public const int AthkarLimit = 450;

    /// <param name="queued">Tags and delivery times of toasts already queued.</param>
    public static IReadOnlyList<ReminderToast> Additions(IEnumerable<ReminderRule> rules,
        IReadOnlyDictionary<long, Instant> queued, Instant now, DateTimeZone zone, Random random, int capacity)
    {
        var additions = new List<ReminderToast>();
        foreach (var rule in rules)
        {
            if (additions.Count >= capacity) break;
            if (rule.Kind is "daily" or "weekly")
            {
                var end = now + DatedHorizon;
                for (var at = ReminderSchedule.Next(rule, now, zone); at is { } instant && instant <= end;
                    at = ReminderSchedule.Next(rule, instant, zone))
                {
                    var id = ReminderSchedule.WindowsOccurrenceId(rule.Id, instant.InZone(zone).Date);
                    if (!queued.ContainsKey(id) && additions.Count < capacity)
                        additions.Add(new(id, instant, rule.Title, rule.Body, rule.Payload));
                }
            }
            else if (rule.Kind == "interval")
            {
                var existing = queued.Where(pair => ReminderSchedule.IsAthkarId(pair.Key) && pair.Value > now)
                    .ToDictionary(pair => pair.Key, pair => pair.Value);
                var free = Enumerable.Range(1101, AthkarLimit).Select(id => (long)id)
                    .Where(id => !existing.ContainsKey(id)).ToList();
                var times = AthkarTimes(rule, existing.Values, now, Math.Min(free.Count, capacity - additions.Count));
                for (var index = 0; index < times.Count; index++)
                    additions.Add(new(free[index], times[index], rule.Title,
                        rule.Texts[random.Next(rule.Texts.Count)], rule.Payload));
            }
        }
        return additions;
    }

    /// <summary>
    /// Continues the Athkar series: gaps before the last queued Athkar are
    /// filled, then times follow every interval up to the horizon. Matches
    /// Huda's Dart <c>missingAthkarTimes</c>.
    /// </summary>
    public static IReadOnlyList<Instant> AthkarTimes(ReminderRule rule, IEnumerable<Instant> existing,
        Instant now, int count)
    {
        var interval = Duration.FromMinutes(rule.IntervalMinutes!.Value);
        var end = now + AthkarHorizon;
        var future = existing.Where(time => time > now).Distinct().OrderBy(time => time).ToList();
        var missing = new List<Instant>();
        var remaining = Math.Min(count, AthkarLimit - future.Count);
        var cursor = rule.First > now ? rule.First : now + interval;
        foreach (var scheduled in future.Where(time => time < end))
        {
            while (remaining > 0 && cursor < scheduled - Duration.FromMinutes(1))
            {
                missing.Add(cursor); remaining--; cursor += interval;
            }
            cursor = scheduled + interval;
        }
        while (remaining > 0 && cursor < end)
        {
            missing.Add(cursor); remaining--; cursor += interval;
        }
        return missing;
    }
}
