using NodaTime;

namespace Huda.PrayerTaskbar.Core;

public static class LocationClock
{
    public static string DatabaseVersion => DateTimeZoneProviders.Tzdb.VersionId;

    // Deliberately reproduce timezone 0.11.1's wall-time adapter, including its
    // offset estimate during overlaps. NodaTime.AtLeniently uses a different overlap policy.
    public static Instant Resolve(LocalDateTime wall, DateTimeZone zone)
    {
        var localAsUtc = wall.InUtc().ToInstant();
        var firstOffset = zone.GetUtcOffset(localAsUtc);
        var adjusted = localAsUtc - Duration.FromSeconds(firstOffset.Seconds);
        var secondOffset = zone.GetUtcOffset(adjusted);
        var result = localAsUtc - Duration.FromSeconds(secondOffset.Seconds);
        if (firstOffset != secondOffset && firstOffset.Seconds < secondOffset.Seconds &&
            secondOffset != zone.GetUtcOffset(result))
            result = adjusted;
        return result;
    }
}
