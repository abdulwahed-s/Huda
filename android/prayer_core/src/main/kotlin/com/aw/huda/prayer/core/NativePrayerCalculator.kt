package com.aw.huda.prayer.core

import io.github.abdulwaheds.prayertimeplus.*
import java.time.*
import java.time.chrono.HijrahDate
import java.time.temporal.ChronoField

/** Explicit accepted input, independent of widgets, Flutter and location discovery. */
data class PrayerCalculationInput(
    val latitude: Double, val longitude: Double, val countryCode: String,
    val timeZoneId: String, val method: String, val madhab: String,
    val highLatitude: String, val fajrAngle: Double = 18.0,
    val maghribAngle: Double = 0.0, val ishaAngle: Double = 17.0,
    val offsets: Map<String, Int> = emptyMap(),
)

object PrayerOccurrenceIdentity {
    val prayers = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
    fun idFor(date: LocalDate, prayer: String): Long {
        val index = prayers.indexOf(prayer)
        require(index >= 0)
        val datePart = date.year * 10000L + date.monthValue * 100 + date.dayOfMonth
        return 300_000_000L + (datePart - 20_000_000L) * 10 + index + 1
    }
}

object NativePrayerCalculator {
    private fun key(token: String) = when (token) {
        "muslimWorldLeague" -> "mwl"
        "egyptian" -> "egypt"
        "ummAlQura" -> "makkah"
        "northAmerica" -> "isna"
        "southKorea" -> "southkorea"
        "other" -> "custom"
        else -> token
    }
    fun isKnownMethod(token: String) = CalculationMethod.fromKey(key(token)) != null
    fun methodFrom(token: String?, countryCode: String): CalculationMethod {
        if (token.isNullOrBlank() || token == "auto") {
            return if (countryCode.isBlank()) CalculationMethod.UMM_AL_QURA else AutoMethod.forCountry(countryCode)
        }
        return CalculationMethod.fromKey(key(token)) ?: CalculationMethod.UMM_AL_QURA
    }
    fun isRamadan(date: LocalDate) = HijrahDate.from(date).get(ChronoField.MONTH_OF_YEAR) == 9

    fun rawTimes(input: PrayerCalculationInput, date: LocalDate): PrayerTimes {
        require(input.latitude.isFinite() && input.latitude in -90.0..90.0)
        require(input.longitude.isFinite() && input.longitude in -180.0..180.0)
        val zone = ZoneId.of(input.timeZoneId)
        val method = methodFrom(input.method, input.countryCode)
        val ramadan = isRamadan(date)
        var parameters = method.parameters().copy(
            madhab = if (input.madhab == "hanafi") Madhab.HANAFI else Madhab.SHAFI,
            highLatitudeRule = when (input.highLatitude) {
                "middleOfTheNight" -> HighLatitudeRule.MIDDLE_OF_THE_NIGHT
                "seventhOfTheNight" -> HighLatitudeRule.SEVENTH_OF_THE_NIGHT
                "twilightAngle" -> HighLatitudeRule.TWILIGHT_ANGLE
                "none" -> HighLatitudeRule.NONE
                else -> HighLatitudeRule.AUTOMATIC
            }, isRamadan = ramadan,
        )
        if (method == CalculationMethod.UMM_AL_QURA && ramadan && input.countryCode.uppercase() != "SA") {
            parameters = parameters.copy(ishaValue = 120.0)
        }
        if (method == CalculationMethod.OTHER) {
            parameters = parameters.copy(fajrAngle = input.fajrAngle,
                maghribIsInterval = false, maghribValue = input.maghribAngle,
                ishaIsInterval = false, ishaValue = input.ishaAngle)
        }
        return PrayerTimes(Coordinates(input.latitude, input.longitude),
            DateComponents(date.year, date.monthValue, date.dayOfMonth), parameters,
            date.atTime(LocalTime.NOON).atZone(zone).offset, countryCode = input.countryCode)
    }

    /** Reinterpret library wall time in the accepted zone, as Dart does, then apply offsets. */
    fun adjustedTimes(input: PrayerCalculationInput, date: LocalDate): Map<String, Instant?> {
        val raw = rawTimes(input, date)
        val zone = ZoneId.of(input.timeZoneId)
        return linkedMapOf("fajr" to raw.fajr, "sunrise" to raw.sunrise, "dhuhr" to raw.dhuhr,
            "asr" to raw.asr, "maghrib" to raw.maghrib, "isha" to raw.isha).mapValues { (prayer, time) ->
            time?.toLocalDateTime()?.atZone(zone)?.toInstant()
                ?.plusSeconds((input.offsets[prayer] ?: 0).coerceIn(-10080, 10080) * 60L)
        }
    }
}
