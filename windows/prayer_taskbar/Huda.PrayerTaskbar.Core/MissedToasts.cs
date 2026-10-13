using System.Globalization;
using NodaTime;

namespace Huda.PrayerTaskbar.Core;

/// <summary>A scheduled toast whose time passed without Windows showing it.</summary>
public sealed record MissedToast(string Tag, Instant DueAt, string? PrayerKey = null);

/// <summary>
/// Windows drops scheduled toasts whose time passed while it couldn't show
/// them: during sleep, while the PC was off, or when the clock moved forward.
/// They stay in the queue with a past time and never appear. When the
/// companion notices this, it shows a few of them late, once each:
/// <list type="bullet">
/// <item>the latest missed prayer, while its time is still current (Fajr until
/// sunrise, Dhuhr until Asr, and so on);</item>
/// <item>each missed reminder or calendar event, up to two hours late, one per
/// reminder;</item>
/// <item>no random Athkar: the next one follows on time.</item>
/// </list>
/// Every other missed toast is only removed from the queue.
/// </summary>
public static class MissedToastPolicy
{
    /// <summary>Windows may show a toast a few seconds late; younger ones are left to it.</summary>
    public static readonly Duration Settle = Duration.FromMinutes(1);

    public static readonly Duration ReminderLimit = Duration.FromHours(2);

    /// <summary>How long a missed prayer stays current when its end can't be calculated.</summary>
    public static readonly Duration PrayerFallback = Duration.FromHours(1);

    public static bool IsMissed(Instant dueAt, Instant now) => dueAt < now - Settle;

    /// <summary>The missed toasts to show now, oldest first.</summary>
    /// <param name="prayerEnd">When a missed prayer's time ends (the next
    /// prayer, or sunrise after Fajr), or null if unknown.</param>
    public static IReadOnlyList<MissedToast> ToShow(
        IEnumerable<MissedToast> missed, Instant now, Func<MissedToast, Instant?> prayerEnd)
    {
        MissedToast? prayer = null;
        var reminders = new Dictionary<long, MissedToast>();
        foreach (var toast in missed)
        {
            if (!IsMissed(toast.DueAt, now) ||
                !long.TryParse(toast.Tag, NumberStyles.None, CultureInfo.InvariantCulture, out var id)) continue;
            if (id is >= 300_000_000 and < 400_000_000)
            {
                if (prayer is null || toast.DueAt > prayer.DueAt) prayer = toast;
            }
            else if (!ReminderSchedule.IsAthkarId(id) && now - toast.DueAt <= ReminderLimit)
            {
                // A dated toast and an older one-time toast of the same reminder
                // (Kahf 1001 … Khatma 1006) count as one; calendar events and
                // the test notification each stand alone.
                var key = ReminderSchedule.WindowsReminderOf(id) ?? id;
                if (!reminders.TryGetValue(key, out var kept) || toast.DueAt > kept.DueAt) reminders[key] = toast;
            }
        }
        var shown = reminders.Values.ToList();
        if (prayer is not null && now < (prayerEnd(prayer) ?? prayer.DueAt + PrayerFallback)) shown.Add(prayer);
        return shown.OrderBy(item => item.DueAt).ToList();
    }
}
