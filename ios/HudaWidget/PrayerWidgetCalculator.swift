import Foundation

struct PrayerWidgetDayTimes {
    let base: PrayerTimes
    let offsets: [Prayer: Int]
    let timeZone: TimeZone

    func time(for prayer: Prayer) -> Date? {
        guard let date = base.time(for: prayer) else { return nil }
        var fixedCalendar = Calendar(identifier: .gregorian)
        fixedCalendar.timeZone = TimeZone(
            secondsFromGMT: Int(base.utcOffset)
        ) ?? timeZone
        let components = fixedCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        var locationCalendar = Calendar(identifier: .gregorian)
        locationCalendar.timeZone = timeZone
        guard let locationDate = locationCalendar.date(from: components) else {
            return nil
        }
        return PrayerWidgetCalculator.applyingManualOffset(
            to: locationDate,
            minutes: offsets[prayer] ?? 0
        )
    }

    var fajr: Date? {
        time(for: .fajr)
    }

    var maghrib: Date? {
        time(for: .maghrib)
    }
}

enum PrayerWidgetCalculator {
    static let dailyPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    static let displayPrayers: [Prayer] = [
        .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha,
    ]

    static func applyingManualOffset(to date: Date, minutes: Int) -> Date {
        date.addingTimeInterval(TimeInterval(minutes * 60))
    }

    static func computeTimes(
        coordinates: Coordinates,
        date: Date,
        settings: PrayerWidgetSettings
    ) -> PrayerWidgetDayTimes? {
        let countryCode = settings.countryCode.trimmingCharacters(in: .whitespaces)
        let calculationMethod = method(
            from: settings.calculationMethod,
            countryCode: countryCode
        )
        var params = calculationMethod.parameters
        params.madhab = madhab(from: settings.madhab)
        params.highLatitudeRule = highLatitudeRule(from: settings.highLatitudeRule)
        var islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        islamicCalendar.timeZone = settings.displayTimeZone
        let isRamadan = islamicCalendar.component(.month, from: date) == 9
        params.isRamadan = isRamadan
        if calculationMethod == .ummAlQura,
           isRamadan,
           countryCode.uppercased() != "SA"
        {
            params.ishaValue = 120
        }
        if calculationMethod == .other {
            params.fajrAngle = settings.customFajrAngle
            params.maghribIsInterval = false
            params.maghribValue = settings.customMaghribAngle
            params.ishaIsInterval = false
            params.ishaValue = settings.customIshaAngle
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var noonComponents = components
        noonComponents.hour = 12
        let offsetReference = calendar.date(from: noonComponents) ?? date
        let base = PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params,
            utcOffset: TimeInterval(
                settings.displayTimeZone.secondsFromGMT(for: offsetReference)
            ),
            countryCode: countryCode
        )
        return PrayerWidgetDayTimes(
            base: base,
            offsets: settings.offsets,
            timeZone: settings.displayTimeZone
        )
    }

    static func dailyMap(from times: PrayerWidgetDayTimes) -> [(Prayer, Date)] {
        dailyPrayers.compactMap { prayer in
            times.time(for: prayer).map { (prayer, $0) }
        }
    }

    static func displayMap(from times: PrayerWidgetDayTimes) -> [(Prayer, Date)] {
        displayPrayers.compactMap { prayer in
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
        for dayOffset in 0 ..< 5 {
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
        for dayOffset in 0 ..< dayCount {
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

    static func sunnahTimes(
        coordinates: Coordinates,
        settings: PrayerWidgetSettings,
        date: Date
    ) -> (middle: Date?, lastThird: Date?) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        guard
            let today = computeTimes(
                coordinates: coordinates,
                date: date,
                settings: settings
            ),
            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date),
            let tomorrow = computeTimes(
                coordinates: coordinates,
                date: tomorrowDate,
                settings: settings
            ),
            let maghrib = today.maghrib,
            let nextFajr = tomorrow.fajr,
            nextFajr > maghrib
        else { return (nil, nil) }
        let night = nextFajr.timeIntervalSince(maghrib)
        func rounded(_ value: Date) -> Date {
            Date(timeIntervalSince1970: (value.timeIntervalSince1970 / 60).rounded() * 60)
        }
        return (
            rounded(maghrib.addingTimeInterval(night / 2)),
            rounded(maghrib.addingTimeInterval(night * 2 / 3))
        )
    }

    // MARK: Settings mapping

    static func method(from token: String, countryCode: String) -> CalculationMethod {
        if token.isEmpty || token == "auto" {
            return countryCode.isEmpty ? .ummAlQura : AutoMethod.forCountry(countryCode)
        }

        let methodKey: String
        switch token {
        case "muslimWorldLeague": methodKey = "mwl"
        case "egyptian": methodKey = "egypt"
        case "ummAlQura": methodKey = "makkah"
        case "northAmerica": methodKey = "isna"
        case "southKorea": methodKey = "southkorea"
        case "other": return .other
        default: methodKey = token
        }
        return CalculationMethod.from(key: methodKey) ?? .ummAlQura
    }

    private static func madhab(from token: String) -> Madhab {
        token == "hanafi" ? .hanafi : .shafi
    }

    private static func highLatitudeRule(from token: String) -> HighLatitudeRule {
        switch token {
        case "automatic": .automatic
        case "middleOfTheNight": .middleOfTheNight
        case "seventhOfTheNight": .seventhOfTheNight
        case "twilightAngle": .twilightAngle
        case "none": .unadjusted
        default: .automatic
        }
    }
}
