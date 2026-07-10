package com.aw.huda.widget.prayer

import io.github.abdulwaheds.prayertimeplus.AutoMethod
import io.github.abdulwaheds.prayertimeplus.CalculationMethod
import io.github.abdulwaheds.prayertimeplus.Coordinates
import io.github.abdulwaheds.prayertimeplus.DateComponents
import io.github.abdulwaheds.prayertimeplus.HighLatitudeRule
import io.github.abdulwaheds.prayertimeplus.Madhab
import io.github.abdulwaheds.prayertimeplus.Prayer
import io.github.abdulwaheds.prayertimeplus.PrayerTimes
import io.github.abdulwaheds.prayertimeplus.SunnahTimes
import java.time.OffsetDateTime
import java.util.Calendar
import java.util.Date

internal object PrayerWidgetCalculator {
    data class DayTimes(
        val fajr: Date,
        val sunrise: Date,
        val dhuhr: Date,
        val asr: Date,
        val maghrib: Date,
        val isha: Date,
    ) {
        val ordered: List<Pair<PrayerKind, Date>>
            get() = listOf(
                PrayerKind.FAJR to fajr,
                PrayerKind.DHUHR to dhuhr,
                PrayerKind.ASR to asr,
                PrayerKind.MAGHRIB to maghrib,
                PrayerKind.ISHA to isha,
            )

        fun timeOf(kind: PrayerKind): Date = when (kind) {
            PrayerKind.FAJR -> fajr
            PrayerKind.SUNRISE -> sunrise
            PrayerKind.DHUHR -> dhuhr
            PrayerKind.ASR -> asr
            PrayerKind.MAGHRIB -> maghrib
            PrayerKind.ISHA -> isha
        }
    }

    fun computeDay(snapshot: PrayerWidgetSnapshot, day: Calendar): DayTimes? {
        val raw = rawTimes(snapshot, day) ?: return null
        return rawToDay(raw, snapshot)
    }

    private fun rawTimes(snapshot: PrayerWidgetSnapshot, day: Calendar): PrayerTimes? {
        val lat = snapshot.latitude ?: return null
        val lon = snapshot.longitude ?: return null

        val countryCode = snapshot.countryCode?.trim().orEmpty()
        val method = methodFrom(snapshot.calculationMethod, countryCode)
        val params = method.parameters().copy(
            madhab = madhabFrom(snapshot.madhab),
            highLatitudeRule = highLatitudeRuleFrom(snapshot.highLatitudeRule),
        )

        val date = DateComponents(
            day.get(Calendar.YEAR),
            day.get(Calendar.MONTH) + 1,
            day.get(Calendar.DAY_OF_MONTH),
        )
        val utcOffset = PrayerWidgetTimeZones.zoneOffsetFor(countryCode, day.toInstant())
        return PrayerTimes(
            Coordinates(lat, lon),
            date,
            params,
            utcOffset,
            countryCode = countryCode,
        )
    }

    private fun rawToDay(raw: PrayerTimes, snapshot: PrayerWidgetSnapshot): DayTimes? {
        val fajr = raw.fajr?.toDate() ?: return null
        val sunrise = raw.sunrise?.toDate() ?: return null
        val dhuhr = raw.dhuhr?.toDate() ?: return null
        val asr = raw.asr?.toDate() ?: return null
        val maghrib = raw.maghrib?.toDate() ?: return null
        val isha = raw.isha?.toDate() ?: return null
        return DayTimes(
            fajr = fajr.applyOffset(snapshot.offsets["fajr"] ?: 0),
            sunrise = sunrise.applyOffset(snapshot.offsets["sunrise"] ?: 0),
            dhuhr = dhuhr.applyOffset(snapshot.offsets["dhuhr"] ?: 0),
            asr = asr.applyOffset(snapshot.offsets["asr"] ?: 0),
            maghrib = maghrib.applyOffset(snapshot.offsets["maghrib"] ?: 0),
            isha = isha.applyOffset(snapshot.offsets["isha"] ?: 0),
        )
    }

    fun computeSunnah(snapshot: PrayerWidgetSnapshot, day: Calendar): SunnahTimesResult? {
        val raw = rawTimes(snapshot, day) ?: return null
        return try {
            val sunnah = SunnahTimes(raw)
            val middle = sunnah.middleOfTheNight?.toDate() ?: return null
            val lastThird = sunnah.lastThirdOfTheNight?.toDate() ?: return null
            SunnahTimesResult(
                middleOfNight = middle,
                lastThirdOfNight = lastThird,
            )
        } catch (_: Exception) {
            null
        }
    }

    fun displayList(day: DayTimes): List<Pair<PrayerKind, Date>> = listOf(
        PrayerKind.FAJR to day.fajr,
        PrayerKind.SUNRISE to day.sunrise,
        PrayerKind.DHUHR to day.dhuhr,
        PrayerKind.ASR to day.asr,
        PrayerKind.MAGHRIB to day.maghrib,
        PrayerKind.ISHA to day.isha,
    )

    fun nextAfter(snapshot: PrayerWidgetSnapshot, now: Date): NextPrayer? {
        val today = computeDay(snapshot, calendarFor(snapshot, now)) ?: return null
        val candidates = listOf(
            PrayerKind.FAJR to today.fajr,
            PrayerKind.DHUHR to today.dhuhr,
            PrayerKind.ASR to today.asr,
            PrayerKind.MAGHRIB to today.maghrib,
            PrayerKind.ISHA to today.isha,
        )

        val upcomingToday = candidates.firstOrNull { it.second.after(now) }
        if (upcomingToday != null) {
            return NextPrayer(upcomingToday.first, upcomingToday.second, today)
        }

        val tomorrowCal = calendarFor(snapshot, now).apply { add(Calendar.DATE, 1) }
        val tomorrow = computeDay(snapshot, tomorrowCal) ?: return null
        return NextPrayer(PrayerKind.FAJR, tomorrow.fajr, tomorrow)
    }

    fun previousBefore(snapshot: PrayerWidgetSnapshot, now: Date): PreviousPrayer? {
        val today = computeDay(snapshot, calendarFor(snapshot, now)) ?: return null
        val candidates = listOf(
            PrayerKind.FAJR to today.fajr,
            PrayerKind.DHUHR to today.dhuhr,
            PrayerKind.ASR to today.asr,
            PrayerKind.MAGHRIB to today.maghrib,
            PrayerKind.ISHA to today.isha,
        )
        val passed = candidates.lastOrNull { !it.second.after(now) }
            ?: return null
        return PreviousPrayer(passed.first, passed.second)
    }

    private fun OffsetDateTime.toDate(): Date = Date.from(this.toInstant())

    private fun madhabFrom(token: String?): Madhab =
        if (token == "hanafi") Madhab.HANAFI else Madhab.SHAFI

    private fun highLatitudeRuleFrom(token: String?): HighLatitudeRule = when (token) {
        "automatic" -> HighLatitudeRule.AUTOMATIC
        "middleOfTheNight" -> HighLatitudeRule.MIDDLE_OF_THE_NIGHT
        "seventhOfTheNight" -> HighLatitudeRule.SEVENTH_OF_THE_NIGHT
        "twilightAngle" -> HighLatitudeRule.TWILIGHT_ANGLE
        "none" -> HighLatitudeRule.NONE
        else -> HighLatitudeRule.AUTOMATIC
    }

    private fun methodFrom(token: String?, countryCode: String): CalculationMethod = when (token) {
        null, "", "auto" ->
            if (countryCode.isBlank()) CalculationMethod.UMM_AL_QURA
            else AutoMethod.forCountry(countryCode)
        "ummAlQura" -> CalculationMethod.UMM_AL_QURA
        "muslimWorldLeague" -> CalculationMethod.MUSLIM_WORLD_LEAGUE
        "egyptian" -> CalculationMethod.EGYPTIAN
        "karachi" -> CalculationMethod.KARACHI
        "northAmerica" -> CalculationMethod.NORTH_AMERICA
        "dubai" -> CalculationMethod.DUBAI
        "qatar" -> CalculationMethod.QATAR
        "kuwait" -> CalculationMethod.KUWAIT
        "turkey" -> CalculationMethod.TURKEY
        "indonesia" -> CalculationMethod.INDONESIA
        else -> CalculationMethod.UMM_AL_QURA
    }

    private fun Date.applyOffset(minutes: Int): Date {
        if (minutes == 0) return this
        return Date(time + minutes * 60L * 1000L)
    }

    private fun calendarFor(snapshot: PrayerWidgetSnapshot, now: Date): Calendar {
        val cal = Calendar.getInstance(snapshot.displayTimeZone)
        cal.time = now
        return cal
    }

    @Suppress("UNUSED_PARAMETER")
    private fun Prayer.toKind(): PrayerKind = when (this) {
        Prayer.FAJR -> PrayerKind.FAJR
        Prayer.SUNRISE -> PrayerKind.SUNRISE
        Prayer.DHUHR -> PrayerKind.DHUHR
        Prayer.ASR -> PrayerKind.ASR
        Prayer.MAGHRIB -> PrayerKind.MAGHRIB
        Prayer.ISHA -> PrayerKind.ISHA
        else -> PrayerKind.FAJR
    }
}

internal enum class PrayerKind { FAJR, SUNRISE, DHUHR, ASR, MAGHRIB, ISHA }

internal data class NextPrayer(
    val kind: PrayerKind,
    val time: Date,
    val day: PrayerWidgetCalculator.DayTimes,
)

internal data class PreviousPrayer(
    val kind: PrayerKind,
    val time: Date,
)

internal data class SunnahTimesResult(
    val middleOfNight: Date,
    val lastThirdOfNight: Date,
)

internal fun progressStart(previous: PreviousPrayer?, target: Date): Date {
    if (previous != null && previous.time.before(target)) return previous.time
    return Date(target.time - 6L * 60L * 60L * 1000L)
}
