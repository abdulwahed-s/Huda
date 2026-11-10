using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using NodaTime;

namespace Huda.PrayerTray.Core;

/// <summary>A reminder due now, with the text to show.</summary>
public sealed record DueReminder(ReminderRule Rule, string Body, Instant Occurrence);

/// <summary>
/// Decides which published reminders to show. Each occurrence is recorded
/// before it is returned, so a crash never shows it twice. An occurrence
/// missed while the session was asleep is still shown within its late window;
/// one already delivered is never repeated, even when the clock moves back.
/// </summary>
public sealed class ReminderDispatcher(string statePath)
{
    private readonly Dictionary<long, long> _delivered = Load(statePath);

    public IReadOnlyList<DueReminder> Due(IReadOnlyList<ReminderRule> rules, Instant now,
        DateTimeZone zone, Random random)
    {
        var due = new List<DueReminder>();
        var changed = false;
        foreach (var rule in rules)
        {
            var after = now - ReminderSchedule.LateWindow(rule);
            if (_delivered.TryGetValue(rule.Id, out var last) && Instant.FromUnixTimeMilliseconds(last) > after)
                after = Instant.FromUnixTimeMilliseconds(last);
            // Only the latest missed occurrence is shown.
            Instant? latest = null;
            for (var next = ReminderSchedule.Next(rule, after, zone); next is { } at && at <= now;
                next = ReminderSchedule.Next(rule, at, zone))
                latest = at;
            if (latest is not { } occurrence) continue;
            _delivered[rule.Id] = occurrence.ToUnixTimeMilliseconds();
            changed = true;
            var body = rule.Kind == "interval" ? rule.Texts[random.Next(rule.Texts.Count)] : rule.Body;
            due.Add(new(rule, body, occurrence));
        }
        // Forget removed reminders, so a later rule with the same ID starts fresh.
        foreach (var id in _delivered.Keys.Where(id => rules.All(rule => rule.Id != id)).ToList())
        {
            _delivered.Remove(id);
            changed = true;
        }
        if (changed) DurableFile.Write(statePath, JsonSerializer.Serialize(_delivered));
        return due;
    }

    /// <summary>When the next reminder is due, so the companion can sleep until then.</summary>
    public Instant? NextDue(IReadOnlyList<ReminderRule> rules, Instant now, DateTimeZone zone) =>
        rules.Select(rule =>
        {
            var after = _delivered.TryGetValue(rule.Id, out var last) &&
                Instant.FromUnixTimeMilliseconds(last) > now
                    ? Instant.FromUnixTimeMilliseconds(last) : now;
            return ReminderSchedule.Next(rule, after, zone);
        }).Where(next => next is not null).Min();

    private static Dictionary<long, long> Load(string path)
    {
        try
        {
            return File.Exists(path)
                ? JsonSerializer.Deserialize<Dictionary<long, long>>(File.ReadAllText(path)) ?? []
                : [];
        }
        catch (Exception error) when (error is IOException or JsonException or UnauthorizedAccessException)
        {
            // Unreadable state shows at most one late delivery per reminder.
            return [];
        }
    }
}
