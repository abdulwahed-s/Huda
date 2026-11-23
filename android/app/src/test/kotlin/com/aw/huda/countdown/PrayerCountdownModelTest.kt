package com.aw.huda.countdown

import com.aw.huda.widget.prayer.PrayerKind
import com.aw.huda.widget.prayer.PrayerWidgetCalculator
import io.github.abdulwaheds.prayertimeplus.DateComponents
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

class PrayerCountdownModelTest {
    private val yesterday = day(1, offsetHours = -24)
    private val today = day(2, offsetHours = 0)
    private val tomorrow = day(3, offsetHours = 24)
    private val timeline = listOf(yesterday, today, tomorrow).flatMap { day ->
        day.ordered.map { (kind, time) -> PrayerWidgetCalculator.PrayerEvent(kind, time, day) }
    }

    @Test
    fun countsDownToTheNextPrayerFromThePreviousOne() {
        val now = at(13, 0)
        val content = build(now)

        assertFalse(content.elapsed)
        assertEquals(PrayerKind.ASR, content.focus.kind)
        assertEquals(PrayerKind.ASR, content.next.kind)
        assertEquals(PrayerKind.DHUHR, content.previous?.kind)
        assertEquals(at(12, 0), content.progressStart)
        assertEquals(at(15, 30), content.progressEnd)
        assertEquals(at(15, 30), content.nextRefresh)
        assertEquals(1_000 * 60 / 210, content.progress(now))
    }

    @Test
    fun countsUpForThePrayersIqamahWindow() {
        val now = at(15, 40)
        val content = build(now)

        assertTrue(content.elapsed)
        assertEquals(PrayerKind.ASR, content.focus.kind)
        assertEquals(PrayerKind.MAGHRIB, content.next.kind)
        assertEquals(at(15, 30), content.progressStart)
        assertEquals(at(15, 50), content.progressEnd)
        assertEquals(at(15, 50), content.nextRefresh)
        assertEquals(500, content.progress(now))

        val after = build(at(15, 50))
        assertFalse(after.elapsed)
        assertEquals(PrayerKind.MAGHRIB, after.focus.kind)
    }

    @Test
    fun highlightsThePrayerTheTimerIsAbout() {
        val content = build(at(7, 0))

        // Sunrise is in the table but never counted down to.
        assertEquals(PrayerKind.DHUHR, content.focus.kind)
        assertEquals(6, content.rows.size)
        assertEquals(listOf(PrayerKind.DHUHR), highlighted(content))

        // During the Iqamah window after the adhan, the prayer that just started.
        assertEquals(listOf(PrayerKind.ASR), highlighted(build(at(15, 40))))
    }

    @Test
    fun beforeFajrAndAfterIshaShowFajrsDay() {
        val beforeFajr = build(at(2, 0))
        assertEquals(PrayerKind.FAJR, beforeFajr.focus.kind)
        assertEquals(today.civilDate, beforeFajr.focus.day.civilDate)
        assertEquals(listOf(PrayerKind.FAJR), highlighted(beforeFajr))

        val afterIsha = build(at(23, 0))
        assertEquals(PrayerKind.FAJR, afterIsha.focus.kind)
        assertEquals(at(29, 0), afterIsha.focus.time)
        // The table moves to tomorrow, the day of the Fajr it counts to.
        assertEquals(at(29, 0), afterIsha.rows.first { it.kind == PrayerKind.FAJR }.time)
        assertEquals(listOf(PrayerKind.FAJR), highlighted(afterIsha))
        assertEquals(at(29, 0), afterIsha.nextRefresh)
    }

    @Test
    fun sunriseCanBeLeftOutOfTheTable() {
        val content = PrayerCountdownModel.build(at(13, 0), timeline, showSunrise = false)!!
        assertEquals(5, content.rows.size)
        assertTrue(content.rows.none { it.kind == PrayerKind.SUNRISE })
    }

    @Test
    fun customMaghribAndOffWindowsControlRefreshWithoutSunriseTransitions() {
        val custom = PrayerCountdownModel.build(at(18, 6), timeline, true, mapOf("maghrib" to 7))!!
        assertTrue(custom.elapsed)
        assertEquals(at(18, 7), custom.nextRefresh)
        val off = PrayerCountdownModel.build(at(18, 0), timeline, true, mapOf("maghrib" to 0))!!
        assertFalse(off.elapsed)
        assertEquals(PrayerKind.ISHA, off.focus.kind)
        assertFalse(build(at(18, 5)).elapsed)
        assertTrue(build(at(5, 24)).elapsed)
    }

    @Test
    fun nothingToShowWithoutPrayerTimes() {
        assertNull(PrayerCountdownModel.build(at(13, 0), emptyList(), true))
    }

    @Test
    fun settingsKeepTheOldSwitchAndDefaultToProgressInTheBody() {
        val defaults = PrayerCountdownSettings.fromPrefs(emptyMap<String, Any>())
        assertTrue(defaults.enabled)
        assertEquals(PrayerCountdownStyle.PROGRESS, defaults.style)
        assertTrue(defaults.lockScreen)
        assertTrue(defaults.showSunrise)
        assertFalse(defaults.liveUpdate)
        assertEquals("en", defaults.language)

        val saved = PrayerCountdownSettings.fromPrefs(
            mapOf(
                "flutter.persistent_prayer_countdown_enabled" to false,
                "flutter.prayer_countdown_style" to "timetable",
                "flutter.prayer_countdown_lock_screen" to false,
                "flutter.locale" to "ar",
            ),
        )
        assertFalse(saved.enabled)
        assertEquals(PrayerCountdownStyle.TIMETABLE, saved.style)
        assertFalse(saved.lockScreen)
        assertEquals("ar", saved.language)
        assertEquals(PrayerCountdownStyle.PROGRESS, PrayerCountdownStyle.fromStorage("unknown"))
    }

    private fun build(now: Date): PrayerCountdownContent =
        requireNotNull(PrayerCountdownModel.build(now, timeline, showSunrise = true))

    private fun highlighted(content: PrayerCountdownContent) =
        content.rows.filter { it.highlighted }.map { it.kind }

    private fun day(dayOfMonth: Int, offsetHours: Int) = PrayerWidgetCalculator.DayTimes(
        civilDate = DateComponents(2026, 10, dayOfMonth),
        fajr = at(5 + offsetHours, 0),
        sunrise = at(6 + offsetHours, 15),
        dhuhr = at(12 + offsetHours, 0),
        asr = at(15 + offsetHours, 30),
        maghrib = at(18 + offsetHours, 0),
        isha = at(19 + offsetHours, 30),
    )

    private fun at(hour: Int, minute: Int): Date = Date((hour * 60L + minute) * 60_000L)
}
