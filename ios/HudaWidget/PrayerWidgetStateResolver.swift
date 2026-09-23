import Foundation

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
    static let gracePeriod: TimeInterval = 25 * 60
    static let compactCountdownThreshold: TimeInterval = 60 * 60

    static func resolve(
        now: Date,
        transitions: [PrayerWidgetTransition],
        gracePeriod: TimeInterval = gracePeriod
    ) -> PrayerWidgetResolvedMoment? {
        let ordered = transitions.sorted { $0.date < $1.date }
        let latestIndex = ordered.lastIndex { $0.date <= now }
        let futureIndex = ordered.firstIndex { $0.date > now }

        if let latestIndex {
            let latest = ordered[latestIndex]
            let graceEnd = latest.date.addingTimeInterval(gracePeriod)
            if now < graceEnd {
                return PrayerWidgetResolvedMoment(
                    mode: .elapsed,
                    prayer: latest.prayer,
                    prayerDate: latest.date,
                    stateEnd: graceEnd,
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
        transitions: [PrayerWidgetTransition]
    ) -> [Date] {
        var points = [now]
        for transition in transitions {
            if transition.date > now, transition.date <= horizon {
                points.append(transition.date)
            }

            let compactCountdownStart = transition.date.addingTimeInterval(
                -compactCountdownThreshold + 1
            )
            if compactCountdownStart > now, compactCountdownStart <= horizon {
                points.append(compactCountdownStart)
            }

            let graceEnd = transition.date.addingTimeInterval(gracePeriod)
            if graceEnd > now, graceEnd <= horizon { points.append(graceEnd) }
        }
        return Array(Set(points)).sorted()
    }
}
