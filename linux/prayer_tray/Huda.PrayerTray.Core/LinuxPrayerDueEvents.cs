using Huda.PrayerTaskbar.Core;
using NodaTime;

namespace Huda.PrayerTray.Core;

// All modes use one selected-zone calculation, independently of panel visibility.
public sealed class LinuxPrayerDueEvents
{
    private readonly ScheduleCalculator _calculator = new(new RamadanCalendar());
    private ScheduleSnapshot? _schedule;
    private long _revision;
    private Instant? _previous;
    private Instant? _advancePrevious;
    private Instant _activeFrom;
    public ScheduleSnapshot? Schedule => _schedule;
    public void Reset(Instant now) { _previous = now; _advancePrevious = now; _activeFrom = now; }

    /// <summary>
    /// After a gap (sleep, or the clock moved forward), the latest prayer missed in it while its
    /// time is still current, as Windows' <see cref="MissedToastPolicy"/>: Fajr until sunrise,
    /// Dhuhr until Asr, and so on. Call it before <see cref="Reset"/>.
    /// </summary>
    public PrayerEvent? Missed(TrayConfiguration? config, Instant now)
    {
        if (_previous is not { } from || now <= from || config?.Location is not { Verified: true } ||
            config.Calculation is null || config.Experience is not { Configured: true, Enabled: true }) return null;
        var schedule = _calculator.Snapshot(config.ToCalculationConfiguration(), now);
        if (schedule.Error is not null) return null;
        var missed = schedule.Events.Where(item => item.Key != "sunrise" && item.Time > from &&
            item.Time >= _activeFrom && item.Time <= now && config.Experience.For(item.Key).Enabled).MaxBy(item => item.Time);
        if (missed is null) return null;
        // Its time ends at the next of the day's six times, sunrise included, as on Windows.
        var calculation = config.ToCalculationConfiguration();
        Instant? end = null;
        foreach (var day in new[] { missed.CivilDate.PlusDays(-1), missed.CivilDate, missed.CivilDate.PlusDays(1) })
            foreach (var time in _calculator.Calculate(calculation, day).Times.Values)
                if (time is { } value && value > missed.Time && (end is null || value < end)) end = value;
        return now < (end ?? missed.Time + MissedToastPolicy.PrayerFallback) ? missed : null;
    }
    public IReadOnlyList<PrayerEvent> Poll(TrayConfiguration? config, Instant now, bool mayDeliver)
    {
        var previous = _previous;
        _previous = now;
        if (config?.Location is not { Verified: true } location || config.Calculation is null)
        { _schedule = null; return []; }
        var today = now.InZone(DateTimeZoneProviders.Tzdb[location.TimeZoneId]).Date;
        if (_revision != config.Revision || _schedule?.Today != today)
        {
            _schedule = _calculator.Snapshot(config.ToCalculationConfiguration(), now);
            if (_revision != config.Revision)
            {
                _activeFrom = config.CutoverInstantUtc is { } cutover
                    ? Instant.FromDateTimeOffset(cutover) : now;
                // Presentation changes do not replay prior events. Cold starts never catch up.
                if (previous is null) _activeFrom = now;
            }
            _revision = config.Revision;
        }
        if (!mayDeliver || config.Experience is not { Configured: true, Enabled: true } ||
            _schedule.Error is not null || previous is null || now <= previous ||
            now - previous > Duration.FromSeconds(60)) return [];
        return _schedule.Events.Where(item => item.Key != "sunrise" && item.Time > previous &&
            item.Time >= _activeFrom && item.Time <= now && now - item.Time <= Duration.FromSeconds(60) &&
            config.Experience.For(item.Key).Enabled).ToArray();
    }

    /// Reminders due before a prayer (its own minutes, or the default), with the same
    /// window as prayers: call it after <see cref="Poll"/>, never replaying old ones.
    public IReadOnlyList<(PrayerEvent Prayer, int Minutes)> PollAdvance(TrayConfiguration? config, Instant now, bool mayDeliver)
    {
        var previous = _advancePrevious;
        _advancePrevious = now;
        if (!mayDeliver || _schedule is not { Error: null } schedule ||
            config?.Experience is not { Configured: true, Enabled: true } experience ||
            previous is null || now <= previous || now - previous > Duration.FromSeconds(60)) return [];
        return schedule.Events.Where(item => item.Key != "sunrise")
            .Select(item => (Prayer: item, Settings: experience.For(item.Key)))
            .Where(item => item.Settings is { Enabled: true, AdvanceMinutes: > 0 })
            .Select(item => (item.Prayer, Minutes: item.Settings.AdvanceMinutes,
                At: item.Prayer.Time - Duration.FromMinutes(item.Settings.AdvanceMinutes)))
            .Where(item => item.At > previous && item.At >= _activeFrom && item.At <= now &&
                now - item.At <= Duration.FromSeconds(60))
            .Select(item => (item.Prayer, item.Minutes)).ToArray();
    }
}
