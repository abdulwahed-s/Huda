/// One of the daily prayer-time boundaries.
///
/// Sunrise is included because it bounds the period after Fajr; it is a time
/// marker rather than a prayer.
public enum Prayer: Sendable, Equatable, CaseIterable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
}
