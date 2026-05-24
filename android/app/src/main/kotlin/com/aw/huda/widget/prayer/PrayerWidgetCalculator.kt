package com.aw.huda.widget.prayer

import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.Prayer
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.SunnahTimes
import com.batoulapps.adhan.data.DateComponents
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

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
        return rawTimes(snapshot, day)?.let { rawToDay(it, snapshot) }
    }

    private fun rawTimes(snapshot: PrayerWidgetSnapshot, day: Calendar): PrayerTimes? {
        val lat = snapshot.latitude ?: return null
        val lon = snapshot.longitude ?: return null

        val params = CalculationMethod.UMM_AL_QURA.parameters
        params.madhab = Madhab.SHAFI

        val date = DateComponents.from(day.time)
        return PrayerTimes(Coordinates(lat, lon), date, params)
    }

    private fun rawToDay(raw: PrayerTimes, snapshot: PrayerWidgetSnapshot): DayTimes {
        return DayTimes(
            fajr = raw.fajr.applyOffset(snapshot.offsets["fajr"] ?: 0),
            sunrise = raw.sunrise.applyOffset(snapshot.offsets["sunrise"] ?: 0),
            dhuhr = raw.dhuhr.applyOffset(snapshot.offsets["dhuhr"] ?: 0),
            asr = raw.asr.applyOffset(snapshot.offsets["asr"] ?: 0),
            maghrib = raw.maghrib.applyOffset(snapshot.offsets["maghrib"] ?: 0),
            isha = raw.isha.applyOffset(snapshot.offsets["isha"] ?: 0),
        )
    }

    fun computeSunnah(snapshot: PrayerWidgetSnapshot, day: Calendar): SunnahTimesResult? {
        val raw = rawTimes(snapshot, day) ?: return null
        return try {
            val sunnah = SunnahTimes(raw)
            SunnahTimesResult(
                middleOfNight = sunnah.middleOfTheNight,
                lastThirdOfNight = sunnah.lastThirdOfTheNight,
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
        val today = computeDay(snapshot, calendarFor(now)) ?: return null
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

        val tomorrowCal = calendarFor(now).apply { add(Calendar.DATE, 1) }
        val tomorrow = computeDay(snapshot, tomorrowCal) ?: return null
        return NextPrayer(PrayerKind.FAJR, tomorrow.fajr, tomorrow)
    }

    fun previousBefore(snapshot: PrayerWidgetSnapshot, now: Date): PreviousPrayer? {
        val today = computeDay(snapshot, calendarFor(now)) ?: return null
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

    private fun Date.applyOffset(minutes: Int): Date {
        if (minutes == 0) return this
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.time = this
        cal.add(Calendar.MINUTE, minutes)
        return cal.time
    }

    private fun calendarFor(now: Date): Calendar {
        val cal = Calendar.getInstance(TimeZone.getDefault())
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
