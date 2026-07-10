import Foundation

/// The longitude-shifted solar calculator for a single observer and day.
///
/// It bundles the two values every per-prayer evaluation needs — the
/// longitude-shifted Julian day (`baseJulianDay`) and the observer `latitude` —
/// and exposes the "sun reaches a given depression" primitives used to build the
/// raw prayer times. All angles are in degrees; all returned times are fractional
/// hours in the longitude-shifted frame (the timezone/longitude clock conversion
/// happens later, during adjustment).
///
/// There is intentionally **no iteration**: each prayer is evaluated once at its
/// own fixed time-of-day seed, which is what fixes the day the sun position is
/// sampled on.
struct SolarTime {
    /// Julian day of local midnight, shifted west by the longitude fraction
    /// (`julianDay − longitude / 360`).
    let baseJulianDay: Double

    /// Observer latitude in degrees, north positive.
    let latitude: Double

    /// The Julian day for a calendar date at 00:00 UT.
    ///
    /// Time-of-day is deliberately excluded here; it is folded in later as a
    /// day-fraction seed. `month` is 1...12 and `day` is the day of the month.
    static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = floor(Double(y) / 100.0)
        return floor((Double(y) + 4716.0) * 365.25)
            + floor((Double(m) + 1.0) * 30.6001)
            + Double(day)
            + (2.0 - a + floor(a / 4.0))
            - 1524.5
    }

    /// The sun's declination (degrees) and the equation of time (hours) at `julianDay`.
    ///
    /// Uses the USNO low-precision coefficients. The argument already includes the
    /// day-fraction time-of-day (`baseJulianDay + seed`).
    static func sunPosition(_ julianDay: Double) -> (declination: Double, equationOfTime: Double) {
        let daysSinceEpoch = julianDay - 2451545.0 // D since J2000.0
        let meanAnomaly = fixAngle(0.98560028 * daysSinceEpoch + 357.529) // g
        let meanLongitude = fixAngle(0.98564736 * daysSinceEpoch + 280.459) // q
        let eclipticLongitude = fixAngle( // L
            meanLongitude + 1.915 * sinDeg(meanAnomaly) + 0.020 * sinDeg(2.0 * meanAnomaly),
        )
        let obliquity = 23.439 - 3.6e-7 * daysSinceEpoch // ε

        let declination = arcsinDeg(sinDeg(obliquity) * sinDeg(eclipticLongitude))
        let rightAscension = arctan2Deg(
            cosDeg(obliquity) * sinDeg(eclipticLongitude),
            cosDeg(eclipticLongitude),
        ) / 15.0
        let equationOfTime = meanLongitude / 15.0 - fixHour(rightAscension)
        return (declination, equationOfTime)
    }

    /// Solar transit (Dhuhr), in longitude-shifted hours, evaluated at seed `dayFraction`.
    ///
    /// Solar noon is `12 − equationOfTime`; no fixed Dhuhr offset is applied here.
    func midDay(_ dayFraction: Double) -> Double {
        let equationOfTime = Self.sunPosition(baseJulianDay + dayFraction).equationOfTime
        return fixHour(12.0 - equationOfTime)
    }

    /// The time (longitude-shifted hours) at which the sun sits `angle` degrees below
    /// the horizon, evaluated at seed `dayFraction`.
    ///
    /// Callers request morning prayers with `angle = 180 − depression` (which is
    /// `> 90`), flipping the result to before noon; evening prayers pass the
    /// depression directly. Returns `NaN` when the sun never reaches `angle`.
    func sunAngleTime(angle: Double, t dayFraction: Double) -> Double {
        let declination = Self.sunPosition(baseJulianDay + dayFraction).declination
        let noon = midDay(dayFraction)
        let numerator = -sinDeg(angle) - sinDeg(declination) * sinDeg(latitude)
        let denominator = cosDeg(declination) * cosDeg(latitude)
        var hourAngle = arccosDeg(numerator / denominator) / 15.0
        if angle > 90.0 {
            hourAngle = -hourAngle
        }
        return noon + hourAngle
    }

    /// The Asr time (longitude-shifted hours) for a shadow `factor`, evaluated at seed
    /// `dayFraction`.
    ///
    /// `factor` is 1 for the standard schools and 2 for Ḥanafī. The sun altitude is
    /// `arccot(factor + tan(|latitude − declination|))`; its negation is fed back
    /// through ``sunAngleTime(angle:t:)`` to land in the afternoon.
    func asrTime(factor: Double, t dayFraction: Double) -> Double {
        let declination = Self.sunPosition(baseJulianDay + dayFraction).declination
        let altitude = arccotDeg(factor + tanDeg(abs(latitude - declination)))
        return sunAngleTime(angle: -altitude, t: dayFraction)
    }
}
