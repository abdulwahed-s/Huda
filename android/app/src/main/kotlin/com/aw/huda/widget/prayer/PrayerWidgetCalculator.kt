package com.aw.huda.widget.prayer

import io.github.abdulwaheds.prayertimeplus.AutoMethod
import io.github.abdulwaheds.prayertimeplus.CalculationMethod
import io.github.abdulwaheds.prayertimeplus.Coordinates
import io.github.abdulwaheds.prayertimeplus.DateComponents
import io.github.abdulwaheds.prayertimeplus.HighLatitudeRule
import io.github.abdulwaheds.prayertimeplus.Madhab
import io.github.abdulwaheds.prayertimeplus.PrayerTimes
import io.github.abdulwaheds.prayertimeplus.SunnahTimes
import java.time.OffsetDateTime
import java.time.LocalDate
import java.time.LocalTime
import java.time.chrono.HijrahDate
import java.time.temporal.ChronoField
import java.util.Calendar
import java.util.Date
import kotlin.math.ceil

internal object PrayerWidgetCalculator {
    private const val DEFAULT_FUTURE_DAYS = 8
    private const val MAX_OFFSET_MINUTES = 7 * 24 * 60

    data class DayTimes(
        val civilDate: DateComponents,
        val fajr: Date?,
        val sunrise: Date?,
        val dhuhr: Date?,
        val asr: Date?,
        val maghrib: Date?,
        val isha: Date?,
    ) {
        val ordered: List<Pair<PrayerKind, Date>>
            get() = listOfNotNull(
                fajr?.let { PrayerKind.FAJR to it },
                dhuhr?.let { PrayerKind.DHUHR to it },
                asr?.let { PrayerKind.ASR to it },
                maghrib?.let { PrayerKind.MAGHRIB to it },
                isha?.let { PrayerKind.ISHA to it },
            )

        fun timeOf(kind: PrayerKind): Date? = when (kind) {
            PrayerKind.FAJR -> fajr
            PrayerKind.SUNRISE -> sunrise
            PrayerKind.DHUHR -> dhuhr
            PrayerKind.ASR -> asr
            PrayerKind.MAGHRIB -> maghrib
            PrayerKind.ISHA -> isha
        }
    }

    data class PrayerEvent(
        val kind: PrayerKind,
        val time: Date,
        val day: DayTimes,
    )

    fun computeDay(snapshot: PrayerWidgetSnapshot, day: Calendar): DayTimes? {
        val raw = rawTimes(snapshot, day) ?: return null
        val date = DateComponents(
            day.get(Calendar.YEAR),
            day.get(Calendar.MONTH) + 1,
            day.get(Calendar.DAY_OF_MONTH),
        )
        return rawToDay(raw, snapshot, date)
    }

    private fun rawTimes(snapshot: PrayerWidgetSnapshot, day: Calendar): PrayerTimes? {
        val lat = snapshot.latitude ?: return null
        val lon = snapshot.longitude ?: return null
        val countryCode = snapshot.countryCode?.trim().orEmpty()
        val method = methodFrom(snapshot.calculationMethod, countryCode)
        val isRamadan = isRamadan(snapshot, day)
        var params = method.parameters().copy(
            madhab = madhabFrom(snapshot.madhab),
            highLatitudeRule = highLatitudeRuleFrom(snapshot.highLatitudeRule),
            isRamadan = isRamadan,
        )
        if (method == CalculationMethod.UMM_AL_QURA &&
            isRamadan && countryCode.uppercase() != "SA"
        ) {
            params = params.copy(ishaValue = 120.0)
        }
        if (method == CalculationMethod.OTHER) {
            params = params.copy(
                fajrAngle = snapshot.customFajrAngle,
                maghribIsInterval = false,
                maghribValue = snapshot.customMaghribAngle,
                ishaIsInterval = false,
                ishaValue = snapshot.customIshaAngle,
            )
        }

        val date = DateComponents(
            day.get(Calendar.YEAR),
            day.get(Calendar.MONTH) + 1,
            day.get(Calendar.DAY_OF_MONTH),
        )
        val utcOffset = LocalDate.of(date.year, date.month, date.day)
            .atTime(LocalTime.NOON)
            .atZone(snapshot.displayTimeZone.toZoneId())
            .offset
        return PrayerTimes(
            Coordinates(lat, lon),
            date,
            params,
            utcOffset,
            countryCode = countryCode,
        )
    }

    private fun rawToDay(
        raw: PrayerTimes,
        snapshot: PrayerWidgetSnapshot,
        civilDate: DateComponents,
    ): DayTimes? {
        val day = DayTimes(
            civilDate = civilDate,
            fajr = raw.fajr?.toDate()?.applyOffset(offset(snapshot, "fajr")),
            sunrise = raw.sunrise?.toDate()?.applyOffset(offset(snapshot, "sunrise")),
            dhuhr = raw.dhuhr?.toDate()?.applyOffset(offset(snapshot, "dhuhr")),
            asr = raw.asr?.toDate()?.applyOffset(offset(snapshot, "asr")),
            maghrib = raw.maghrib?.toDate()?.applyOffset(offset(snapshot, "maghrib")),
            isha = raw.isha?.toDate()?.applyOffset(offset(snapshot, "isha")),
        )
        return day.takeIf { displayList(it).isNotEmpty() }
    }

    fun computeSunnah(snapshot: PrayerWidgetSnapshot, day: Calendar): SunnahTimesResult? {
        val raw = rawTimes(snapshot, day) ?: return null
        return try {
            val sunnah = SunnahTimes(raw)
            val middle = sunnah.middleOfTheNight?.toDate() ?: return null
            val lastThird = sunnah.lastThirdOfTheNight?.toDate() ?: return null
            SunnahTimesResult(middleOfNight = middle, lastThirdOfNight = lastThird)
        } catch (_: Exception) {
            null
        }
    }

    fun displayList(day: DayTimes): List<Pair<PrayerKind, Date>> = listOfNotNull(
        day.fajr?.let { PrayerKind.FAJR to it },
        day.sunrise?.let { PrayerKind.SUNRISE to it },
        day.dhuhr?.let { PrayerKind.DHUHR to it },
        day.asr?.let { PrayerKind.ASR to it },
        day.maghrib?.let { PrayerKind.MAGHRIB to it },
        day.isha?.let { PrayerKind.ISHA to it },
    )

    fun eventTimeline(
        snapshot: PrayerWidgetSnapshot,
        around: Date,
        futureDays: Int = DEFAULT_FUTURE_DAYS,
    ): List<PrayerEvent> {
        if (!snapshot.hasCoordinates) return emptyList()
        val offsetDays = ceil(
            snapshot.offsets.keys.maxOfOrNull { kotlin.math.abs(offset(snapshot, it)) }
                .orZero() / (24.0 * 60.0),
        ).toInt()
        val anchor = calendarFor(snapshot, around)
        val events = ArrayList<PrayerEvent>()
        for (dayOffset in -(offsetDays + 2)..(futureDays + offsetDays)) {
            val dayCalendar = (anchor.clone() as Calendar).apply {
                add(Calendar.DATE, dayOffset)
            }
            val day = computeDay(snapshot, dayCalendar) ?: continue
            for ((kind, time) in day.ordered) {
                events += PrayerEvent(kind, time, day)
            }
        }
        return events.sortedWith(compareBy<PrayerEvent> { it.time.time }.thenBy { it.kind.ordinal })
    }

    fun nextAfter(snapshot: PrayerWidgetSnapshot, now: Date): NextPrayer? =
        eventTimeline(snapshot, now).firstOrNull { it.time.after(now) }
            ?.let { NextPrayer(it.kind, it.time, it.day) }

    fun previousBefore(snapshot: PrayerWidgetSnapshot, now: Date): PreviousPrayer? =
        eventTimeline(snapshot, now).lastOrNull { !it.time.after(now) }
            ?.let { PreviousPrayer(it.kind, it.time) }

    @Suppress("UNUSED_PARAMETER")
    private fun isRamadan(snapshot: PrayerWidgetSnapshot, day: Calendar): Boolean = try {
        val civilDate = LocalDate.of(
            day.get(Calendar.YEAR),
            day.get(Calendar.MONTH) + 1,
            day.get(Calendar.DAY_OF_MONTH),
        )
        HijrahDate.from(civilDate).get(ChronoField.MONTH_OF_YEAR) == 9
    } catch (_: Exception) {
        false
    }

    private fun OffsetDateTime.toDate(): Date = Date.from(toInstant())
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

    internal fun methodFrom(token: String?, countryCode: String): CalculationMethod {
        if (token.isNullOrBlank() || token == "auto") {
            return if (countryCode.isBlank()) CalculationMethod.UMM_AL_QURA
            else AutoMethod.forCountry(countryCode)
        }
        val methodKey = when (token) {
            "muslimWorldLeague" -> "mwl"
            "egyptian" -> "egypt"
            "ummAlQura" -> "makkah"
            "northAmerica" -> "isna"
            "southKorea" -> "southkorea"
            "other" -> "custom"
            else -> token
        }
        return CalculationMethod.fromKey(methodKey) ?: CalculationMethod.UMM_AL_QURA
    }

    private fun offset(snapshot: PrayerWidgetSnapshot, key: String): Int =
        (snapshot.offsets[key] ?: 0).coerceIn(-MAX_OFFSET_MINUTES, MAX_OFFSET_MINUTES)

    private fun Date.applyOffset(minutes: Int): Date =
        if (minutes == 0) this else Date(time + minutes * 60L * 1_000L)

    private fun calendarFor(snapshot: PrayerWidgetSnapshot, now: Date): Calendar =
        Calendar.getInstance(snapshot.displayTimeZone).apply { time = now }

    private fun Int?.orZero(): Int = this ?: 0
}

internal enum class PrayerKind { FAJR, SUNRISE, DHUHR, ASR, MAGHRIB, ISHA }

internal data class NextPrayer(
    val kind: PrayerKind,
    val time: Date,
    val day: PrayerWidgetCalculator.DayTimes,
)

internal data class PreviousPrayer(val kind: PrayerKind, val time: Date)
internal data class SunnahTimesResult(val middleOfNight: Date, val lastThirdOfNight: Date)

internal fun progressStart(previous: PreviousPrayer?, target: Date): Date {
    if (previous != null && previous.time.before(target)) return previous.time
    return Date(target.time - 6L * 60L * 60L * 1_000L)
}
