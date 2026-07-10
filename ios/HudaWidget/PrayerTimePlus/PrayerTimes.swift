import Foundation

/// The daily prayer times for a location and date.
///
/// Each time is a true UTC instant (or `nil` when the sun never reaches the
/// required angle). Format them with a `DateFormatter` whose `timeZone` you set —
/// the instants themselves carry no wall-clock zone.
///
/// ```swift
/// var params = CalculationMethod.oman.parameters
/// let times = PrayerTimes(
///     coordinates: Coordinates(latitude: 24.3486, longitude: 56.6953, altitude: 5),
///     date: DateComponents(year: 2026, month: 6, day: 28),
///     calculationParameters: params,
///     utcOffset: 4 * 3600,
///     countryCode: "OM",
///     cityName: "sohar"
/// )
///
/// let formatter = DateFormatter()
/// formatter.dateFormat = "HH:mm"
/// formatter.timeZone = TimeZone(secondsFromGMT: 4 * 3600)
/// times.fajr.map { formatter.string(from: $0) }   // "03:59"
/// ```
public struct PrayerTimes: Sendable {
    /// Dawn.
    public let fajr: Date?
    /// Sunrise, which bounds the end of the Fajr period.
    public let sunrise: Date?
    /// Solar noon prayer.
    public let dhuhr: Date?
    /// Afternoon prayer.
    public let asr: Date?
    /// Sunset, from which Maghrib is derived.
    public let sunset: Date?
    /// Sunset prayer.
    public let maghrib: Date?
    /// Night prayer.
    public let isha: Date?

    /// The location these times were computed for.
    public let coordinates: Coordinates
    /// The parameters as supplied by the caller.
    public let calculationParameters: CalculationParameters
    /// Seconds east of UTC used to place the times (fixed; includes DST).
    public let utcOffset: TimeInterval
    /// The location's country code, if supplied.
    public let countryCode: String
    /// The location's city name, if supplied.
    public let cityName: String

    let year: Int
    let month: Int
    let day: Int

    /// Computes the prayer times for a location and date.
    ///
    /// - Parameters:
    ///   - coordinates: The observer's location.
    ///   - date: The calendar date; only its year, month and day are used.
    ///   - calculationParameters: Angles, offsets, madhab and high-latitude rule.
    ///   - utcOffset: Seconds east of UTC for the location (include DST yourself).
    ///   - countryCode: ISO-3166 alpha-2 code, used for the elevation-dip and
    ///     Ramadan rules. Optional.
    ///   - cityName: The city name, retained for reference. Optional.
    public init(
        coordinates: Coordinates,
        date: DateComponents,
        calculationParameters: CalculationParameters,
        utcOffset: TimeInterval,
        countryCode: String = "",
        cityName: String = "",
    ) {
        let (year, month, day) = Self.gregorianYearMonthDay(date)
        self.init(
            coordinates: coordinates,
            year: year,
            month: month,
            day: day,
            calculationParameters: calculationParameters,
            utcOffset: utcOffset,
            countryCode: countryCode,
            cityName: cityName,
        )
    }

    init(
        coordinates: Coordinates,
        year: Int,
        month: Int,
        day: Int,
        calculationParameters: CalculationParameters,
        utcOffset: TimeInterval,
        countryCode: String,
        cityName: String,
    ) {
        self.coordinates = coordinates
        self.year = year
        self.month = month
        self.day = day
        self.calculationParameters = calculationParameters
        self.utcOffset = utcOffset
        self.countryCode = countryCode
        self.cityName = cityName

        var parameters = calculationParameters
        func compute() -> DayTimes {
            PrayerTimeEngine(
                coordinates: coordinates,
                year: year,
                month: month,
                day: day,
                parameters: parameters,
                utcOffsetHours: utcOffset / 3600.0,
                countryCode: countryCode,
            ).compute()
        }

        var times = compute()
        // Automatic mode retries once with a one-seventh fallback if the first
        // pass leaves Fajr or Isha degenerate.
        if calculationParameters.highLatitudeRule == .automatic, times.isBroken {
            parameters.highLatitudeRule = .seventhOfTheNight
            times = compute()
        }

        let midnightUTC = (SolarTime.julianDay(year: year, month: month, day: day) - 2440587.5) *
            86400.0
        func instant(_ minuteOfDay: Int?) -> Date? {
            guard let minuteOfDay else { return nil }
            return Date(timeIntervalSince1970: midnightUTC + Double(minuteOfDay) * 60.0 - utcOffset)
        }

        fajr = instant(times.fajr)
        sunrise = instant(times.sunrise)
        dhuhr = instant(times.dhuhr)
        asr = instant(times.asr)
        sunset = instant(times.sunset)
        maghrib = instant(times.maghrib)
        isha = instant(times.isha)
    }

    /// The prayer times for the current calendar day at the given UTC offset.
    public static func today(
        coordinates: Coordinates,
        calculationParameters: CalculationParameters,
        utcOffset: TimeInterval,
        countryCode: String = "",
        cityName: String = "",
    ) -> PrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        if let zone = TimeZone(secondsFromGMT: Int(utcOffset)) {
            calendar.timeZone = zone
        }
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: calculationParameters,
            utcOffset: utcOffset,
            countryCode: countryCode,
            cityName: cityName,
        )
    }

    /// The time for a specific prayer.
    public func time(for prayer: Prayer) -> Date? {
        switch prayer {
        case .fajr: fajr
        case .sunrise: sunrise
        case .dhuhr: dhuhr
        case .asr: asr
        case .maghrib: maghrib
        case .isha: isha
        }
    }

    /// The prayer currently in effect at `time`, or `nil` before Fajr.
    public func currentPrayer(at time: Date = Date()) -> Prayer? {
        if let isha, time >= isha { return .isha }
        if let maghrib, time >= maghrib { return .maghrib }
        if let asr, time >= asr { return .asr }
        if let dhuhr, time >= dhuhr { return .dhuhr }
        if let sunrise, time >= sunrise { return .sunrise }
        if let fajr, time >= fajr { return .fajr }
        return nil
    }

    /// The next upcoming prayer at `time`, or `nil` after Isha.
    public func nextPrayer(at time: Date = Date()) -> Prayer? {
        if let fajr, time < fajr { return .fajr }
        if let sunrise, time < sunrise { return .sunrise }
        if let dhuhr, time < dhuhr { return .dhuhr }
        if let asr, time < asr { return .asr }
        if let maghrib, time < maghrib { return .maghrib }
        if let isha, time < isha { return .isha }
        return nil
    }

    /// The prayer times for the day after this one, using the same inputs.
    func dayAfter() -> PrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let midnightUTC = (SolarTime.julianDay(year: year, month: month, day: day) - 2440587.5) *
            86400.0
        let nextMidnight = Date(timeIntervalSince1970: midnightUTC + 86400.0)
        let components = calendar.dateComponents([.year, .month, .day], from: nextMidnight)
        return PrayerTimes(
            coordinates: coordinates,
            year: components.year ?? year,
            month: components.month ?? month,
            day: components.day ?? day,
            calculationParameters: calculationParameters,
            utcOffset: utcOffset,
            countryCode: countryCode,
            cityName: cityName,
        )
    }

    /// Extracts year/month/day, resolving through a Gregorian calendar if the
    /// components are incomplete.
    private static func gregorianYearMonthDay(
        _ components: DateComponents,
    ) -> (year: Int, month: Int, day: Int) {
        if let year = components.year, let month = components.month, let day = components.day {
            return (year, month, day)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let date = calendar.date(from: components) else { return (1970, 1, 1) }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        return (resolved.year ?? 1970, resolved.month ?? 1, resolved.day ?? 1)
    }
}
