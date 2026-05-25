import Foundation

struct PrayerWidgetCalculator {

    static let dailyPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    static let displayPrayers: [Prayer] = [
        .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha
    ]

    static func computeTimes(
        coordinates: Coordinates,
        date: Date,
        offsets: [Prayer: Int]
    ) -> PrayerTimes? {
        var params = CalculationMethod.ummAlQura.params
        params.madhab = .shafi
        params.adjustments.fajr = offsets[.fajr] ?? 0
        params.adjustments.sunrise = offsets[.sunrise] ?? 0
        params.adjustments.dhuhr = offsets[.dhuhr] ?? 0
        params.adjustments.asr = offsets[.asr] ?? 0
        params.adjustments.maghrib = offsets[.maghrib] ?? 0
        params.adjustments.isha = offsets[.isha] ?? 0

        let components = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day], from: date)
        return PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params
        )
    }

    static func dailyMap(from times: PrayerTimes) -> [(Prayer, Date)] {
        return dailyPrayers.map { ($0, times.time(for: $0)) }
    }

    static func displayMap(from times: PrayerTimes) -> [(Prayer, Date)] {
        return displayPrayers.map { ($0, times.time(for: $0)) }
    }

    static func nextTransition(
        coordinates: Coordinates,
        offsets: [Prayer: Int],
        from now: Date
    ) -> (prayer: Prayer, date: Date)? {
        let calendar = Calendar(identifier: .gregorian)
        for dayOffset in 0..<5 {
            guard
                let target = calendar.date(byAdding: .day, value: dayOffset, to: now),
                let times = computeTimes(coordinates: coordinates, date: target, offsets: offsets)
            else { continue }
            for (prayer, date) in dailyMap(from: times) where date > now {
                return (prayer, date)
            }
        }
        return nil
    }

    static func transitions(
        coordinates: Coordinates,
        offsets: [Prayer: Int],
        startingAt start: Date,
        dayCount: Int
    ) -> [(prayer: Prayer, date: Date)] {
        let calendar = Calendar(identifier: .gregorian)
        var result: [(Prayer, Date)] = []
        for dayOffset in 0..<dayCount {
            guard
                let target = calendar.date(byAdding: .day, value: dayOffset, to: start),
                let times = computeTimes(coordinates: coordinates, date: target, offsets: offsets)
            else { continue }
            for entry in dailyMap(from: times) {
                result.append(entry)
            }
        }
        return result.sorted { $0.1 < $1.1 }
    }
}
