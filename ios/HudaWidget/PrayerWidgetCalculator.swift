import Foundation

struct PrayerWidgetCalculator {

    static let dailyPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    static let displayPrayers: [Prayer] = [
        .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha
    ]

    static func computeTimes(
        coordinates: Coordinates,
        date: Date,
        settings: PrayerWidgetSettings
    ) -> PrayerTimes? {
        let countryCode = settings.countryCode.trimmingCharacters(in: .whitespaces)
        var params = method(from: settings.calculationMethod, countryCode: countryCode).parameters
        params.madhab = madhab(from: settings.madhab)
        params.highLatitudeRule = highLatitudeRule(from: settings.highLatitudeRule)

        let offsets = settings.offsets
        params.adjustments.fajr = offsets[.fajr] ?? 0
        params.adjustments.sunrise = offsets[.sunrise] ?? 0
        params.adjustments.dhuhr = offsets[.dhuhr] ?? 0
        params.adjustments.asr = offsets[.asr] ?? 0
        params.adjustments.maghrib = offsets[.maghrib] ?? 0
        params.adjustments.isha = offsets[.isha] ?? 0

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params,
            utcOffset: TimeInterval(settings.displayTimeZone.secondsFromGMT(for: date)),
            countryCode: countryCode
        )
    }

    static func dailyMap(from times: PrayerTimes) -> [(Prayer, Date)] {
        return dailyPrayers.compactMap { prayer in
            times.time(for: prayer).map { (prayer, $0) }
        }
    }

    static func displayMap(from times: PrayerTimes) -> [(Prayer, Date)] {
        return displayPrayers.compactMap { prayer in
            times.time(for: prayer).map { (prayer, $0) }
        }
    }

    static func nextTransition(
        coordinates: Coordinates,
        settings: PrayerWidgetSettings,
        from now: Date
    ) -> (prayer: Prayer, date: Date)? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        for dayOffset in 0..<5 {
            guard
                let target = calendar.date(byAdding: .day, value: dayOffset, to: now),
                let times = computeTimes(coordinates: coordinates, date: target, settings: settings)
            else { continue }
            for (prayer, date) in dailyMap(from: times) where date > now {
                return (prayer, date)
            }
        }
        return nil
    }

    static func transitions(
        coordinates: Coordinates,
        settings: PrayerWidgetSettings,
        startingAt start: Date,
        dayCount: Int
    ) -> [(prayer: Prayer, date: Date)] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        var result: [(Prayer, Date)] = []
        for dayOffset in 0..<dayCount {
            guard
                let target = calendar.date(byAdding: .day, value: dayOffset, to: start),
                let times = computeTimes(coordinates: coordinates, date: target, settings: settings)
            else { continue }
            for entry in dailyMap(from: times) {
                result.append(entry)
            }
        }
        return result.sorted { $0.1 < $1.1 }
    }

    // MARK: Settings mapping

    private static func method(from token: String, countryCode: String) -> CalculationMethod {
        switch token {
        case "", "auto":
            return countryCode.isEmpty ? .ummAlQura : AutoMethod.forCountry(countryCode)
        case "ummAlQura": return .ummAlQura
        case "muslimWorldLeague": return .muslimWorldLeague
        case "egyptian": return .egyptian
        case "karachi": return .karachi
        case "northAmerica": return .northAmerica
        case "dubai": return .dubai
        case "qatar": return .qatar
        case "kuwait": return .kuwait
        case "turkey": return .turkey
        case "indonesia": return .indonesia
        default: return .ummAlQura
        }
    }

    private static func madhab(from token: String) -> Madhab {
        return token == "hanafi" ? .hanafi : .shafi
    }

    private static func highLatitudeRule(from token: String) -> HighLatitudeRule {
        switch token {
        case "automatic": return .automatic
        case "middleOfTheNight": return .middleOfTheNight
        case "seventhOfTheNight": return .seventhOfTheNight
        case "twilightAngle": return .twilightAngle
        case "none": return .unadjusted
        default: return .automatic
        }
    }
}
