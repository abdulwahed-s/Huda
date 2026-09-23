package com.aw.huda.widget.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class PrayerWidgetCalculationResilienceTest {
    @Test
    fun ummAlQuraUsesRamadan120MinutesAndOtherwise90Minutes() {
        val snapshot = snapshot(
            latitude = 21.3891,
            longitude = 39.8579,
            countryCode = "OM",
            timeZoneId = "Asia/Muscat",
            calculationMethod = "ummAlQura",
        )
        val ramadan = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, calendar(snapshot, 2026, 3, 1)),
        )
        val normal = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, calendar(snapshot, 2026, 5, 1)),
        )

        assertEquals(
            120L * 60L * 1_000L,
            requireNotNull(ramadan.isha).time - requireNotNull(ramadan.maghrib).time,
        )
        assertEquals(
            90L * 60L * 1_000L,
            requireNotNull(normal.isha).time - requireNotNull(normal.maghrib).time,
        )
    }

    @Test
    fun highLatitudeUndefinedTwilightRetainsValidDayEvents() {
        val snapshot = snapshot(
            latitude = 69.6492,
            longitude = 18.9553,
            countryCode = "NO",
            timeZoneId = "Europe/Oslo",
            calculationMethod = "muslimWorldLeague",
            highLatitudeRule = "none",
        )
        val day = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, calendar(snapshot, 2026, 6, 21)),
        )

        assertNull(day.fajr)
        assertNull(day.isha)
        assertNotNull(day.dhuhr)
        assertNotNull(day.asr)
        assertTrue(PrayerWidgetCalculator.displayList(day).isNotEmpty())
    }

    @Test
    fun adjustedEventsCrossMidnightWithoutLosingTheirDate() {
        val base = snapshot()
        val sourceCalendar = calendar(base, 2026, 9, 5)
        val raw = requireNotNull(PrayerWidgetCalculator.computeDay(base, sourceCalendar))
        val rawIsha = requireNotNull(raw.isha)
        val rawFajr = requireNotNull(raw.fajr)

        val ishaClock = Calendar.getInstance(base.displayTimeZone).apply { time = rawIsha }
        val ishaTo0005 = 24 * 60 + 5 -
                (ishaClock.get(Calendar.HOUR_OF_DAY) * 60 + ishaClock.get(Calendar.MINUTE))
        val fajrClock = Calendar.getInstance(base.displayTimeZone).apply { time = rawFajr }
        val fajrTo2355Previous = -(
                fajrClock.get(Calendar.HOUR_OF_DAY) * 60 + fajrClock.get(Calendar.MINUTE) + 5
                )
        val adjusted = base.copy(
            offsets = mapOf(
                "isha" to ishaTo0005,
                "fajr" to fajrTo2355Previous,
            )
        )
        val around = sourceCalendar.time
        val events = PrayerWidgetCalculator.eventTimeline(adjusted, around)
        val sourceDate = raw.civilDate
        val isha = requireNotNull(events.firstOrNull {
            it.kind == PrayerKind.ISHA && it.day.civilDate == sourceDate
        })
        val fajr = requireNotNull(events.firstOrNull {
            it.kind == PrayerKind.FAJR && it.day.civilDate == sourceDate
        })

        val ishaAdjusted = Calendar.getInstance(base.displayTimeZone).apply { time = isha.time }
        assertEquals(6, ishaAdjusted.get(Calendar.DAY_OF_MONTH))
        assertEquals(0, ishaAdjusted.get(Calendar.HOUR_OF_DAY))
        assertEquals(5, ishaAdjusted.get(Calendar.MINUTE))
        val fajrAdjusted = Calendar.getInstance(base.displayTimeZone).apply { time = fajr.time }
        assertEquals(4, fajrAdjusted.get(Calendar.DAY_OF_MONTH))
        assertEquals(23, fajrAdjusted.get(Calendar.HOUR_OF_DAY))
        assertEquals(55, fajrAdjusted.get(Calendar.MINUTE))
    }

    @Test
    fun reorderedAdjustedPrayersAreSortedAndNeverYieldPastNextTarget() {
        val base = snapshot()
        val cal = calendar(base, 2026, 9, 5)
        val day = requireNotNull(PrayerWidgetCalculator.computeDay(base, cal))
        val dhuhr = requireNotNull(day.dhuhr)
        val asr = requireNotNull(day.asr)
        val moveDhuhrAfterAsr = ((asr.time - dhuhr.time) / 60_000L).toInt() + 10
        val adjusted = base.copy(offsets = mapOf("dhuhr" to moveDhuhrAfterAsr))
        val events = PrayerWidgetCalculator.eventTimeline(adjusted, cal.time)
        assertEquals(events.sortedBy { it.time.time }, events)

        val now = Date(asr.time + 1_000L)
        val next = requireNotNull(PrayerWidgetCalculator.nextAfter(adjusted, now))
        assertTrue(next.time.after(now))
        assertEquals(PrayerKind.DHUHR, next.kind)
    }

    @Test
    fun scheduledDeadlineMovesFromPrayerInstantToGraceEndThenNextPrayer() {
        val snapshot = snapshot()
        val day = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, calendar(snapshot, 2026, 9, 5)),
        )
        val fajr = requireNotNull(day.fajr)
        val dhuhr = requireNotNull(day.dhuhr)
        assertEquals(
            fajr.time,
            PrayerWidgetScheduler.computeTargetTimeMillis(
                snapshot,
                Date(fajr.time - 1_000L),
            ),
        )
        assertEquals(
            fajr.time + PRAYER_GRACE_MILLIS,
            PrayerWidgetScheduler.computeTargetTimeMillis(snapshot, fajr),
        )
        assertEquals(
            dhuhr.time,
            PrayerWidgetScheduler.computeTargetTimeMillis(
                snapshot,
                Date(fajr.time + PRAYER_GRACE_MILLIS),
            ),
        )
    }

    @Test
    fun savedPrayerZoneWinsWhenDeviceZoneDiffers() {
        val original = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Asia/Muscat"))
            val india = snapshot(
                latitude = 19.0760,
                longitude = 72.8777,
                countryCode = "IN",
                timeZoneId = "Asia/Kolkata",
            )
            assertEquals("Asia/Kolkata", india.displayTimeZone.id)
            val day = PrayerWidgetCalculator.computeDay(
                india,
                calendar(india, 2026, 9, 5),
            )
            assertNotNull(day)
        } finally {
            TimeZone.setDefault(original)
        }
    }

    @Test
    fun dstTransitionCalculationUsesPrayerCivilDateNotRefreshSide() {
        val london = snapshot(
            latitude = 51.5074,
            longitude = -0.1278,
            countryCode = "GB",
            timeZoneId = "Europe/London",
            calculationMethod = "muslimWorldLeague",
        )
        val beforeClockChange = Calendar.getInstance(london.displayTimeZone).apply {
            set(2026, Calendar.MARCH, 29, 0, 30, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val afterClockChange = Calendar.getInstance(london.displayTimeZone).apply {
            set(2026, Calendar.MARCH, 29, 12, 30, 0)
            set(Calendar.MILLISECOND, 0)
        }
        assertEquals(
            PrayerWidgetCalculator.computeDay(london, beforeClockChange),
            PrayerWidgetCalculator.computeDay(london, afterClockChange),
        )
    }

    private fun calendar(
        snapshot: PrayerWidgetSnapshot,
        year: Int,
        month: Int,
        day: Int,
    ) = Calendar.getInstance(snapshot.displayTimeZone).apply {
        set(year, month - 1, day, 12, 0, 0)
        set(Calendar.MILLISECOND, 0)
    }

    private fun snapshot(
        latitude: Double = 23.5880,
        longitude: Double = 58.3829,
        countryCode: String = "OM",
        timeZoneId: String = "Asia/Muscat",
        calculationMethod: String = "auto",
        highLatitudeRule: String = "automatic",
    ) = PrayerWidgetSnapshot(
        latitude = latitude,
        longitude = longitude,
        countryCode = countryCode,
        calculationMethod = calculationMethod,
        madhab = "shafi",
        highLatitudeRule = highLatitudeRule,
        offsets = emptyMap(),
        themeName = "teal",
        themeMode = "dark",
        appLocale = "en",
        design = PrayerWidgetDesign.HERO,
        language = PrayerWidgetLanguage.EN,
        numerals = PrayerWidgetNumerals.LATIN,
        backgroundEnabled = true,
        backgroundColor = null,
        glassify = false,
        rounded = false,
        contentColor = null,
        highlightColor = null,
        contentSize = 100,
        timeZoneId = timeZoneId,
    )
}
