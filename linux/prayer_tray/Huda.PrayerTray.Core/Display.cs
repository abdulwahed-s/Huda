using Huda.PrayerTaskbar.Core;
using NodaTime;

namespace Huda.PrayerTray.Core;

public sealed record DisplayRow(string Key, long? UtcMs);
public sealed record DisplayNext(string Key, string CivilDate, long UtcMs);
public sealed record DisplaySnapshot(int SchemaVersion, long AppliedRevision, string State,
    long GeneratedAtUtcMs, long ValidUntilUtcMs, string? CivilDate, string? TimeZoneId,
    IReadOnlyList<DisplayRow> Rows, DisplayNext? Next, TrayPreferences? Preferences,
    TrayPresentation? Presentation, string LocationLabel, bool Provisional, string? Error)
{
    public DisplayNext? Current { get; init; }
    public long? CurrentUntilUtcMs { get; init; }
    public ulong ChangeSerial { get; init; }
}

// The injected clock is used by tests only; the shipped service uses SystemClock.
public sealed class DisplayEngine(IClock clock)
{
    private readonly ScheduleCalculator _calculator = new(new RamadanCalendar());
    private ScheduleSnapshot? _schedule;
    private long _revision;
    public int CalculationCount { get; private set; }

    public DisplaySnapshot Snapshot(TrayConfiguration? config, string? error = null)
    {
        var now = clock.GetCurrentInstant();
        var state = config is null || config.Location is null ? "needsSetup" : "ready";
        if (config is { Preferences.Enabled: false }) state = "disabled";
        if (config?.Location is { } location && state == "ready")
        {
            var today = now.InZone(DateTimeZoneProviders.Tzdb[location.TimeZoneId]).Date;
            if (_revision != config.Revision || _schedule?.Today != today)
            {
                try
                {
                    _schedule = _calculator.Snapshot(config.ToCalculationConfiguration(), now);
                    _revision = config.Revision; CalculationCount++;
                }
                catch (Exception failure) when (failure is ArgumentException or InvalidOperationException)
                { _schedule = null; error = failure.Message; }
            }
            if (_schedule is null || _schedule.Error is not null || _schedule.Next(now) is null ||
                _schedule.Daily.Times.Values.Any(time => time is null)) state = "calculationUnavailable";
        }
        else _schedule = null;
        var next = _schedule?.Next(now);
        var moment = _schedule?.Moment(now, config?.Preferences.IqamahMinutes);
        var current = moment is { IsElapsed: true } ? moment.Prayer : null;
        Instant? currentUntil = current is null ? null : moment!.StateEnd;
        var midnight = config?.Location is { } loc
            ? LocationClock.Resolve(now.InZone(DateTimeZoneProviders.Tzdb[loc.TimeZoneId]).Date
                .PlusDays(1).AtMidnight(), DateTimeZoneProviders.Tzdb[loc.TimeZoneId])
            : now + Duration.FromHours(1);
        // A disconnected extension expires its display; cached schedules never remain authoritative forever.
        var expiry = new[] { midnight, next?.Time ?? midnight, currentUntil ?? midnight, now + Duration.FromMinutes(2) }.Min();
        return new DisplaySnapshot(1, config?.Revision ?? 0, state, now.ToUnixTimeMilliseconds(),
            expiry.ToUnixTimeMilliseconds(), _schedule?.Today.ToString("yyyy-MM-dd", null),
            config?.Location?.TimeZoneId,
            TaskbarConfiguration.PrayerKeys.Select(key => new DisplayRow(key,
                _schedule?.Daily.Times[key]?.ToUnixTimeMilliseconds())).ToArray(),
            next is null ? null : new DisplayNext(next.Key, next.CivilDate.ToString("yyyy-MM-dd", null),
                next.Time.ToUnixTimeMilliseconds()), config?.Preferences, config?.Presentation,
            string.Join(" · ", new[] { config?.Location?.Locality, config?.Location?.CountryName }
                .Where(part => !string.IsNullOrWhiteSpace(part))), config?.Location?.Verified == false,
            error ?? _schedule?.Error)
        {
            Current = current is null ? null : new DisplayNext(current.Key,
                current.CivilDate.ToString("yyyy-MM-dd", null), current.Time.ToUnixTimeMilliseconds()),
            CurrentUntilUtcMs = currentUntil?.ToUnixTimeMilliseconds(),
        };
    }
}
