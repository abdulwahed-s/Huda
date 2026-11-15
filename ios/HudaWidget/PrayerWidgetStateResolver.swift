import Foundation
import CoreFoundation

struct PrayerIqamahWindows {
    static let defaults = ["fajr": 25, "dhuhr": 20, "asr": 20, "maghrib": 5, "isha": 20]
    let minutes: [String: Int]

    init(_ raw: Any? = nil) {
        let values = raw as? [String: Any] ?? [:]
        minutes = Self.defaults.merging(values.compactMapValues { value -> Int? in
            guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
                number.doubleValue.isFinite else { return nil }
            return Int(min(60, max(0, number.doubleValue)))
        }.filter { Self.defaults[$0.key] != nil }) { _, value in value }
    }

    func window(for prayer: Prayer) -> TimeInterval {
        TimeInterval(minutes[String(describing: prayer)] ?? 0) * 60
    }
}

enum PrayerWidgetCountdownMode {
    case countdown
    case elapsed
}

struct PrayerWidgetTransition {
    let prayer: Prayer
    let date: Date
}

struct PrayerWidgetResolvedMoment {
    let mode: PrayerWidgetCountdownMode
    let prayer: Prayer
    let prayerDate: Date
    let stateEnd: Date
    let latestStartedIndex: Int?
    let nextIndex: Int?
}

enum PrayerWidgetStateResolver {
    static let compactCountdownThreshold: TimeInterval = 60 * 60

    static func resolve(
        now: Date,
        transitions: [PrayerWidgetTransition],
        iqamah: PrayerIqamahWindows = PrayerIqamahWindows()
    ) -> PrayerWidgetResolvedMoment? {
        let ordered = transitions.filter { $0.prayer != .sunrise }.sorted { $0.date < $1.date }
        let latestIndex = ordered.lastIndex { $0.date <= now }
        let futureIndex = ordered.firstIndex { $0.date > now }

        if let latestIndex {
            let latest = ordered[latestIndex]
            let windowEnd = latest.date.addingTimeInterval(iqamah.window(for: latest.prayer))
            if now < windowEnd {
                return PrayerWidgetResolvedMoment(
                    mode: .elapsed,
                    prayer: latest.prayer,
                    prayerDate: latest.date,
                    stateEnd: windowEnd,
                    latestStartedIndex: latestIndex,
                    nextIndex: futureIndex
                )
            }
        }
        guard let futureIndex else { return nil }
        let future = ordered[futureIndex]
        return PrayerWidgetResolvedMoment(
            mode: .countdown,
            prayer: future.prayer,
            prayerDate: future.date,
            stateEnd: future.date,
            latestStartedIndex: latestIndex,
            nextIndex: futureIndex
        )
    }

    static func activationPoints(
        now: Date,
        through horizon: Date,
        transitions: [PrayerWidgetTransition],
        iqamah: PrayerIqamahWindows = PrayerIqamahWindows()
    ) -> [Date] {
        var points = [now]
        for transition in transitions where transition.prayer != .sunrise {
            if transition.date > now, transition.date <= horizon {
                points.append(transition.date)
            }

            let compactCountdownStart = transition.date.addingTimeInterval(
                -compactCountdownThreshold + 1
            )
            if compactCountdownStart > now, compactCountdownStart <= horizon {
                points.append(compactCountdownStart)
            }

            let window = iqamah.window(for: transition.prayer)
            let windowEnd = transition.date.addingTimeInterval(window)
            if window > 0, windowEnd > now, windowEnd <= horizon { points.append(windowEnd) }
        }
        return Array(Set(points)).sorted()
    }
}
