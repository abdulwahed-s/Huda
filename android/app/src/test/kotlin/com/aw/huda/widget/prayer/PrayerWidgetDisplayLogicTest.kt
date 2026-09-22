package com.aw.huda.widget.prayer

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class PrayerWidgetDisplayLogicTest {
    @Test
    fun sizeClassifierCoversEveryProductionFamily() {
        assertEquals(WidgetFamily.CIRCULAR, PrayerWidgetUpdater.classifySize(96f, 96f))
        assertEquals(WidgetFamily.RECTANGULAR, PrayerWidgetUpdater.classifySize(364f, 96f))
        assertEquals(WidgetFamily.SMALL, PrayerWidgetUpdater.classifySize(170f, 170f))
        assertEquals(WidgetFamily.MEDIUM, PrayerWidgetUpdater.classifySize(364f, 170f))
        assertEquals(WidgetFamily.LARGE, PrayerWidgetUpdater.classifySize(364f, 360f))
    }

    @Test
    fun deviceClockFormatterSupportsBothHourCycles() {
        val utc = TimeZone.getTimeZone("UTC")
        val date = Calendar.getInstance(utc).apply {
            set(2026, Calendar.AUGUST, 28, 18, 24, 0)
            set(Calendar.MILLISECOND, 0)
        }.time

        assertEquals(
            "18:24",
            PrayerTimeFormatter.formatClock(date, true, false, "en", utc),
        )
        assertEquals(
            "6:24 PM",
            PrayerTimeFormatter.formatClock(date, false, false, "en", utc),
        )
        assertEquals(
            "١٨:٢٤",
            PrayerTimeFormatter.formatClock(date, true, true, "ar", utc),
        )
    }

    @Test
    fun countdownRoundsUpToAvoidDisplayingZeroEarly() {
        val start = Date(0)
        assertEquals(
            "00:02",
            PrayerTimeFormatter.formatHHMMRoundedUp(start, Date(60_001), false),
        )
        assertEquals(
            "٠١:٠١",
            PrayerTimeFormatter.formatHHMMRoundedUp(start, Date(3_600_001), true),
        )
    }

    @Test
    fun countdownUsesStableHoursMinutesSecondsColumns() {
        val start = Date(0)
        assertEquals(
            "00:01:01",
            PrayerTimeFormatter.formatHHMMSS(start, Date(60_001), false),
        )
        assertEquals(
            "٠١:٠١:٠١",
            PrayerTimeFormatter.formatHHMMSS(start, Date(3_660_001), true),
        )
    }

    @Test
    fun afterIshaRollsNextPrayerAndScheduleToTomorrow() {
        val snapshot = muscatSnapshot()
        val calendar = Calendar.getInstance(snapshot.displayTimeZone).apply {
            set(2026, Calendar.AUGUST, 28, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val today = requireNotNull(PrayerWidgetCalculator.computeDay(snapshot, calendar))
        val next = requireNotNull(
            PrayerWidgetCalculator.nextAfter(snapshot, Date(today.isha.time + 1_000)),
        )

        assertEquals(PrayerKind.FAJR, next.kind)
        assertEquals(next.time, next.day.fajr)
        assertEquals(
            29,
            Calendar.getInstance(snapshot.displayTimeZone).apply { time = next.time }
                .get(Calendar.DAY_OF_MONTH),
        )
    }

    @Test
    fun beforeFajrKeepsYesterdayIshaAsCurrentPrayer() {
        val snapshot = muscatSnapshot()
        val todayCalendar = Calendar.getInstance(snapshot.displayTimeZone).apply {
            set(2026, Calendar.AUGUST, 28, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val today = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, todayCalendar),
        )
        val yesterdayCalendar = (todayCalendar.clone() as Calendar).apply {
            add(Calendar.DATE, -1)
        }
        val yesterday = requireNotNull(
            PrayerWidgetCalculator.computeDay(snapshot, yesterdayCalendar),
        )

        val previous = requireNotNull(
            PrayerWidgetCalculator.previousBefore(snapshot, Date(today.fajr.time - 60_000)),
        )

        assertEquals(PrayerKind.ISHA, previous.kind)
        assertEquals(yesterday.isha, previous.time)
    }

    private fun muscatSnapshot() = PrayerWidgetSnapshot(
        latitude = 23.5880,
        longitude = 58.3829,
        countryCode = "OM",
        calculationMethod = "auto",
        madhab = "shafi",
        highLatitudeRule = "automatic",
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
    )
}
