package com.aw.huda.widget.lockscreen

import com.aw.huda.widget.prayer.*
import java.time.Instant
import java.util.Date
import org.junit.Assert.*
import org.junit.Test

class SamsungPrayerPolicyTest {
    private val snapshot = lockPrayerSnapshot()
    private fun now(clock: String) = Date.from(Instant.parse("2026-10-13T${clock}Z"))

    @Test fun exactBoundarySelectsFutureSalahWithoutTheHomeGracePhase() {
        val time = now("05:00:00")
        val timeline = PrayerWidgetCalculator.eventTimeline(snapshot, time)
        val next = requireNotNull(SamsungPrayerWidgetUpdater.futurePrayer(timeline, time))
        assertEquals(PrayerKind.DHUHR, next.kind)
        assertEquals(now("12:00:00"), next.time)
        assertEquals(next.time.time, PrayerWidgetScheduler.computeTargetTimeMillis(
            snapshot, time, PrayerWidgetPresence(compact = 1), timeline))
        assertEquals(time.time + PRAYER_GRACE_MILLIS, PrayerWidgetScheduler.computeTargetTimeMillis(
            snapshot, time, PrayerWidgetPresence(home = 1), timeline))
    }

    @Test fun sunriseNeverBecomesTheCountdownTarget() {
        val time = now("05:59:59")
        val timeline = PrayerWidgetCalculator.eventTimeline(snapshot, time)
        assertFalse(timeline.any { it.kind == PrayerKind.SUNRISE })
        assertEquals(PrayerKind.DHUHR, SamsungPrayerWidgetUpdater.futurePrayer(timeline, time)?.kind)
    }

    @Test fun afterIshaUsesTomorrowFajr() {
        val time = now("19:00:00")
        val next = requireNotNull(SamsungPrayerWidgetUpdater.futurePrayer(
            PrayerWidgetCalculator.eventTimeline(snapshot, time), time))
        assertEquals(PrayerKind.FAJR, next.kind)
        assertEquals(Date.from(Instant.parse("2026-10-14T05:00:00Z")), next.time)
    }

    @Test fun mixedSurfacesChooseEarliestRequiredTransition() {
        val time = now("05:00:00")
        val timeline = PrayerWidgetCalculator.eventTimeline(snapshot, time)
        assertEquals(time.time + PRAYER_GRACE_MILLIS, PrayerWidgetScheduler.computeTargetTimeMillis(
            snapshot, time, PrayerWidgetPresence(home = 1, expanded = 2), timeline))
        val close = snapshot.copy(precomputedDays = snapshot.precomputedDays.mapValues { (date, times) ->
            if (date == "2026-10-13") times + ("dhuhr" to now("05:01:00").time) else times
        })
        assertEquals(now("05:01:00").time, PrayerWidgetScheduler.computeTargetTimeMillis(
            close, time, PrayerWidgetPresence(home = 1, compact = 1)))
    }

    @Test fun removingOneProviderKeepsTheOtherProvidersTransitions() {
        val time = now("05:00:00")
        for (presence in listOf(PrayerWidgetPresence(compact = 1), PrayerWidgetPresence(expanded = 1))) {
            assertEquals(now("12:00:00").time, PrayerWidgetScheduler.computeTargetTimeMillis(snapshot, time, presence))
        }
        assertNull(PrayerWidgetScheduler.computeTargetTimeMillis(snapshot, time, PrayerWidgetPresence()))
        assertNull(PrayerWidgetScheduler.computeTargetTimeMillis(
            snapshot.copy(latitude = null, longitude = null), time, PrayerWidgetPresence(compact = 1)))
    }

    @Test fun combinedReportKeepsOtherSuccessesAndSchedulingErrors() {
        val report = PrayerWidgetUpdateResult.fromUpdates(42, listOf(
            SingleWidgetUpdateResult(1, true, "canvas_live"),
            SingleWidgetUpdateResult(2, false, "failed", "compact failed"),
            SingleWidgetUpdateResult(3, true, "samsung_live"),
        ), PrayerAlarmScheduleResult(false, null, PrayerAlarmPrecision.NONE, "alarm failed"))
        assertEquals(3, report.widgetCount)
        assertEquals(2, report.successfulUpdates)
        assertEquals(1, report.failedUpdates)
        assertEquals(listOf("compact failed"), report.errors)
        assertEquals(3, report.rendererPaths.values.sum())
        assertEquals(42L, report.toPlatformMap()["revision"])
        assertEquals("alarm failed", report.toPlatformMap()["alarmError"])
    }

    @Test fun snapshotMinuteFallbackRoundsUpAtMinuteAndHourBoundaries() {
        assertEquals("00:01", PrayerTimeFormatter.formatHHMMRoundedUp(Date(0), Date(1), false))
        assertEquals("00:02", PrayerTimeFormatter.formatHHMMRoundedUp(Date(0), Date(60_001), false))
        assertEquals("01:01", PrayerTimeFormatter.formatHHMMRoundedUp(Date(0), Date(3_600_001), false))
        assertEquals("٠٠:٠١", PrayerTimeFormatter.formatHHMMRoundedUp(Date(0), Date(1), true))
        assertEquals("00:00", PrayerTimeFormatter.formatHHMMRoundedUp(Date(1), Date(0), false))
    }
}
