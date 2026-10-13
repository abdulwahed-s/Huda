using NodaTime;
using PrayerTimePlus;

namespace Huda.PrayerTaskbar.Core;

public sealed record PrayerEvent(string Key, LocalDate CivilDate, Instant Time);
public sealed record PrayerMoment(PrayerEvent Prayer, bool IsElapsed);
public sealed record DailySchedule(LocalDate Date, IReadOnlyDictionary<string, Instant?> Times);
public sealed record ScheduleSnapshot(LocalDate Today, DailySchedule Daily,
    IReadOnlyList<PrayerEvent> Events, string? Error)
{
    public PrayerEvent? Next(Instant now) => Events.FirstOrDefault(item => item.Time > now);

    // Match the Prayer Times page's PrayerMomentResolver, including its
    // 25-minute elapsed state after a prayer and at exact prayer boundaries.
    public PrayerMoment? Moment(Instant now)
    {
        var started = Events.LastOrDefault(item => item.Time <= now);
        if (started is not null && now < started.Time + Duration.FromMinutes(25))
            return new PrayerMoment(started, true);
        return Next(now) is { } next ? new PrayerMoment(next, false) : null;
    }
}

public sealed class ScheduleCalculator(RamadanCalendar calendar)
{
    public DailySchedule Calculate(TaskbarConfiguration config, LocalDate date)
    {
        var location = config.Location ?? throw new InvalidDataException("Prayer location missing.");
        var settings = config.Calculation ?? throw new InvalidDataException("Calculation settings missing.");
        var zone = DateTimeZoneProviders.Tzdb[location.TimeZoneId];
        var offset = zone.GetUtcOffset(LocationClock.Resolve(date.At(new LocalTime(12, 0)), zone));
        var method = CalculationMethods.FromKey(settings.MethodKey)!.Value;
        var ramadan = settings.MethodKey == "makkah" && calendar.IsRamadan(date);
        var parameters = method.GetParameters() with
        {
            Madhab = settings.Madhab == "hanafi" ? Madhab.Hanafi : Madhab.Shafi,
            HighLatitudeRule = settings.HighLatitudeRule switch
            {
                "middle_of_night" => HighLatitudeRule.MiddleOfTheNight,
                "seventh_of_night" => HighLatitudeRule.SeventhOfTheNight,
                "twilight_angle" => HighLatitudeRule.TwilightAngle,
                "none" => HighLatitudeRule.None,
                _ => HighLatitudeRule.Automatic,
            },
            FajrAngle = settings.FajrAngle,
            MaghribIsInterval = settings.MaghribIsInterval,
            MaghribValue = settings.MaghribValue,
            IshaIsInterval = settings.IshaIsInterval,
            IshaValue = ramadan && location.CountryCode != "SA" ? 120 : settings.IshaValue,
            IsRamadan = ramadan,
        };
        var raw = new PrayerTimes(new Coordinates(location.Latitude, location.Longitude, location.Altitude),
            new DateComponents(date.Year, date.Month, date.Day), parameters,
            TimeSpan.FromSeconds(offset.Seconds), countryCode: location.CountryCode);
        DateTimeOffset?[] values = [raw.Fajr, raw.Sunrise, raw.Dhuhr, raw.Asr, raw.Maghrib, raw.Isha];
        var times = new Dictionary<string, Instant?>();
        for (var index = 0; index < values.Length; index++)
        {
            var key = TaskbarConfiguration.PrayerKeys[index];
            // Engine outputs wall components at the supplied noon offset. Resolve each
            // component in the IANA zone before applying Huda's independent manual offset.
            times[key] = values[index] is { } wall
                ? LocationClock.Resolve(LocalDateTime.FromDateTime(wall.DateTime), zone) +
                    Duration.FromMinutes(settings.ManualOffsets[key])
                : null;
        }
        return new DailySchedule(date, times);
    }

    public ScheduleSnapshot Snapshot(TaskbarConfiguration config, Instant now)
    {
        var zone = DateTimeZoneProviders.Tzdb[config.Location!.TimeZoneId];
        var today = now.InZone(zone).Date;
        var events = new List<PrayerEvent>();
        DailySchedule? daily = null;
        string? error = null;
        // Huda allows manual offsets up to seven days. Include enough civil days to
        // preserve yesterday/tomorrow selection even at those offset limits.
        var reach = 1 + (int)Math.Ceiling(config.Calculation!.ManualOffsets.Values
            .Max(value => Math.Abs((long)value)) / 1440.0);
        for (var offset = -reach; offset <= reach; offset++)
        {
            try
            {
                var schedule = Calculate(config, today.PlusDays(offset));
                if (offset == 0) daily = schedule;
                foreach (var (key, time) in schedule.Times)
                    if (key != "sunrise" && time is { } instant)
                        events.Add(new PrayerEvent(key, schedule.Date, instant));
            }
            catch (CalendarCoverageException) { error = "calendarUnavailable"; }
        }
        return new ScheduleSnapshot(today, daily ?? new DailySchedule(today,
            TaskbarConfiguration.PrayerKeys.ToDictionary(key => key, _ => (Instant?)null)),
            events.OrderBy(item => item.Time).ThenBy(item =>
                Array.IndexOf(TaskbarConfiguration.PrayerKeys, item.Key)).ToArray(), error);
    }
}
