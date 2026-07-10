import Foundation

/// The seven rounded prayer times for a day, each as a minute-of-day in local
/// wall-clock time, or `nil` when the sun never reaches the required angle.
struct DayTimes {
    let fajr: Int?
    let sunrise: Int?
    let dhuhr: Int?
    let asr: Int?
    let sunset: Int?
    let maghrib: Int?
    let isha: Int?

    /// Whether Fajr or Isha came out degenerate (`00:00`, hour 0, or hour 12),
    /// which is the signal to retry with a high-latitude fallback.
    var isBroken: Bool {
        let fajrBroken = fajr == nil || fajr == 0
        let ishaBroken: Bool
        if let isha {
            let hour = isha / 60
            ishaBroken = hour == 0 || hour == 12
        } else {
            ishaBroken = true
        }
        return fajrBroken || ishaBroken
    }
}

/// Computes one day's prayer times for a location and parameter set.
///
/// This is the single-pass numerical core: it evaluates each prayer once at its
/// fixed time-of-day seed, applies the localisation, per-prayer offsets,
/// sunset-relative Maghrib, interval/angle Isha, the Umm al-Qura Ramadan bump and
/// the high-latitude fallback, then rounds to the minute — in exactly that order.
struct PrayerTimeEngine {
    let coordinates: Coordinates
    let year: Int
    let month: Int
    let day: Int
    let parameters: CalculationParameters
    /// UTC offset in hours (standard plus any DST the caller has folded in).
    let utcOffsetHours: Double
    let countryCode: String

    /// Methods whose Sunrise/Sunset depression includes the geometric horizon dip.
    private static let elevationMethods: Set<String> = [
        "iraq", "morocco", "tunisia", "jordan", "orleans", "sudan", "belgium", "kazakhstan",
    ]

    /// Countries whose Sunrise/Sunset depression includes the geometric horizon dip.
    private static let elevationCountries: Set<String> = ["PS", "IL", "CZ", "CH"]

    func compute() -> DayTimes {
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        let base = SolarTime.julianDay(year: year, month: month, day: day) - longitude / 360.0
        let solar = SolarTime(baseJulianDay: base, latitude: latitude)

        let methodKey = parameters.method ?? ""
        let usesElevation = Self.elevationMethods.contains(methodKey)
            || Self.elevationCountries.contains(countryCode.uppercased())
        var dip = 0.833
        if usesElevation {
            // Geometric horizon dip in degrees for an observer above sea level.
            dip += 0.0347 * coordinates.altitude.squareRoot()
        }

        // Raw times in the longitude-shifted frame, each at its own seed hour.
        var fajr = solar.sunAngleTime(angle: 180.0 - parameters.fajrAngle, t: 5.0 / 24.0)
        var sunrise = solar.sunAngleTime(angle: 180.0 - dip, t: 6.0 / 24.0)
        var dhuhr = solar.midDay(12.0 / 24.0)
        var asr = solar.asrTime(factor: Double(parameters.madhab.shadowFactor), t: 13.0 / 24.0)
        var sunset = solar.sunAngleTime(angle: dip, t: 18.0 / 24.0)
        var isha = solar.sunAngleTime(angle: parameters.ishaValue, t: 18.0 / 24.0)

        // Convert the longitude-shifted frame to the local wall clock.
        let localShift = utcOffsetHours - longitude / 15.0
        fajr += localShift
        sunrise += localShift
        dhuhr += localShift
        asr += localShift
        sunset += localShift
        isha += localShift

        // Fold the method's built-in offsets with the caller's tuning (minutes).
        let method = parameters.methodAdjustments
        let manual = parameters.adjustments
        let fajrOffset = method.fajr + manual.fajr
        let sunriseOffset = method.sunrise + manual.sunrise
        let dhuhrOffset = method.dhuhr + manual.dhuhr
        let asrOffset = method.asr + manual.asr
        let maghribOffset = method.maghrib + manual.maghrib
        let ishaOffset = method.isha + manual.isha

        fajr += Double(fajrOffset) / 60.0
        sunrise += Double(sunriseOffset) / 60.0
        dhuhr += Double(dhuhrOffset) / 60.0
        asr += Double(asrOffset) / 60.0

        // Maghrib is always Sunset plus its offset, plus the interval when set.
        var maghrib = sunset + Double(maghribOffset) / 60.0
        if parameters.maghribIsInterval {
            maghrib += parameters.maghribValue / 60.0
        }

        // Isha: an interval overrides the angle-based value; then apply the offset.
        if parameters.ishaIsInterval {
            isha = maghrib + parameters.ishaValue / 60.0
        }
        isha += Double(ishaOffset) / 60.0

        // Umm al-Qura adds 30 minutes to Isha during Ramadan in Saudi Arabia.
        if methodKey == "makkah", countryCode.uppercased() == "SA", parameters.isRamadan {
            isha += 0.5
        }

        // High-latitude night-fraction fallback for Fajr and Isha.
        if let rule = activeHighLatitudeRule {
            let night = fixHour(sunrise - sunset)
            let fajrPortion = Self.nightPortion(angle: parameters.fajrAngle, rule: rule) * night
            if fajr.isNaN || fixHour(sunrise - fajr) > fajrPortion {
                fajr = sunrise - fajrPortion + Double(fajrOffset) / 60.0
            }
            let ishaAngle = parameters.ishaIsInterval ? 18.0 : parameters.ishaValue
            let ishaPortion = Self.nightPortion(angle: ishaAngle, rule: rule) * night
            if isha.isNaN || fixHour(isha - maghrib) > ishaPortion {
                isha = maghrib + ishaPortion + Double(ishaOffset) / 60.0
            }
        }

        return DayTimes(
            fajr: Self.roundedMinute(fajr),
            sunrise: Self.roundedMinute(sunrise),
            dhuhr: Self.roundedMinute(dhuhr),
            asr: Self.roundedMinute(asr),
            sunset: Self.roundedMinute(sunset),
            maghrib: Self.roundedMinute(maghrib),
            isha: Self.roundedMinute(isha),
        )
    }

    /// The rule to apply now, or `nil` when no night-fraction adjustment runs.
    private var activeHighLatitudeRule: HighLatitudeRule? {
        switch parameters.highLatitudeRule {
        case .middleOfTheNight, .seventhOfTheNight, .twilightAngle:
            parameters.highLatitudeRule
        case .automatic, .unadjusted:
            nil
        }
    }

    /// The fraction of the night used to pin a prayer at `angle` under `rule`.
    private static func nightPortion(angle: Double, rule: HighLatitudeRule) -> Double {
        switch rule {
        case .twilightAngle:
            angle / 60.0
        case .middleOfTheNight:
            0.5
        case .seventhOfTheNight:
            // Literal, not 1.0 / 7.0, for numeric parity with the reference.
            0.14286
        case .automatic, .unadjusted:
            0.0
        }
    }

    /// Rounds a fractional-hour time to the nearest minute of the day.
    ///
    /// Adds 30 seconds then truncates — so `12:59:31` rolls to `13:00` — and maps
    /// `NaN` (an undefined time) to `nil`.
    private static func roundedMinute(_ hours: Double) -> Int? {
        guard !hours.isNaN else { return nil }
        let bumped = fixHour(hours + 0.0083333333)
        let hour = floor(bumped)
        let minute = floor((bumped - hour) * 60.0)
        return Int(hour) * 60 + Int(minute)
    }
}
