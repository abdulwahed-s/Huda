import Foundation

/// Optional times derived from the night between Maghrib and the following Fajr.
///
/// The night runs from this day's Maghrib to the next day's Fajr. Both values are
/// `nil` when either endpoint is undefined (for example at high latitudes).
///
/// ```swift
/// let sunnah = SunnahTimes(from: times)
/// sunnah.lastThirdOfTheNight   // start of the last third of the night
/// ```
public struct SunnahTimes: Sendable {
    /// The midpoint between Maghrib and the next day's Fajr.
    public let middleOfTheNight: Date?

    /// The start of the last third of the night before the next day's Fajr.
    public let lastThirdOfTheNight: Date?

    /// Derives the Sunnah times from a day's prayer times.
    public init(from prayerTimes: PrayerTimes) {
        guard let maghrib = prayerTimes.maghrib,
              let nextFajr = prayerTimes.dayAfter().fajr
        else {
            middleOfTheNight = nil
            lastThirdOfTheNight = nil
            return
        }
        let night = nextFajr.timeIntervalSince(maghrib)
        middleOfTheNight = Self.roundedToMinute(maghrib.addingTimeInterval(night / 2.0))
        lastThirdOfTheNight = Self.roundedToMinute(maghrib.addingTimeInterval(night * 2.0 / 3.0))
    }

    private static func roundedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60.0).rounded() * 60.0)
    }
}
