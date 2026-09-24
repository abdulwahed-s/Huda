package com.aw.huda.widget.prayer

import io.github.abdulwaheds.prayertimeplus.DateComponents
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import android.os.Build
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class PrayerWidgetMomentResolverTest {
    private val day = PrayerWidgetCalculator.DayTimes(
        civilDate = DateComponents(2026, 9, 5),
        fajr = null,
        sunrise = null,
        dhuhr = null,
        asr = null,
        maghrib = null,
        isha = null,
    )

    @Test
    fun everyPrayerUsesExactTwentyFiveMinuteGraceBoundary() {
        val prayers = listOf(
            PrayerKind.FAJR to at(5, 0),
            PrayerKind.DHUHR to at(12, 10),
            PrayerKind.ASR to at(15, 30),
            PrayerKind.MAGHRIB to at(18, 20),
            PrayerKind.ISHA to at(20, 0),
            PrayerKind.FAJR to at(29, 0),
        ).map { PrayerWidgetCalculator.PrayerEvent(it.first, it.second, day) }

        for (event in prayers.dropLast(1)) {
            val before = requireNotNull(
                PrayerWidgetMomentResolver.resolve(Date(event.time.time - 1_000), prayers),
            )
            assertTrue(before is PrayerWidgetMoment.Countdown)
            assertEquals(event.time, before.event.time)

            for (delta in listOf(0L, 1_000L, PRAYER_GRACE_MILLIS - 1_000L)) {
                val elapsed = requireNotNull(
                    PrayerWidgetMomentResolver.resolve(Date(event.time.time + delta), prayers),
                )
                assertTrue(elapsed is PrayerWidgetMoment.Elapsed)
                assertEquals(event.kind, elapsed.event.kind)
            }

            val switched = requireNotNull(
                PrayerWidgetMomentResolver.resolve(
                    Date(event.time.time + PRAYER_GRACE_MILLIS),
                    prayers,
                ),
            )
            assertTrue(switched is PrayerWidgetMoment.Countdown)
            assertTrue(switched.event.time.after(Date(event.time.time)))
        }
    }

    @Test
    fun latestStartedPrayerWinsOverlappingGraceWindows() {
        val a = PrayerWidgetCalculator.PrayerEvent(PrayerKind.DHUHR, at(10, 0), day)
        val b = PrayerWidgetCalculator.PrayerEvent(PrayerKind.ASR, at(10, 10), day)
        val next = PrayerWidgetCalculator.PrayerEvent(PrayerKind.MAGHRIB, at(18, 0), day)

        val moment = requireNotNull(
            PrayerWidgetMomentResolver.resolve(at(10, 11), listOf(next, a, b)),
        )
        assertTrue(moment is PrayerWidgetMoment.Elapsed)
        assertEquals(PrayerKind.ASR, moment.event.kind)
        assertEquals(60_000L, at(10, 11).time - moment.event.time.time)
    }

    @Test
    fun ishaGraceTransitionsToSameAbsoluteNextDayFajrAcrossMidnight() {
        val isha = PrayerWidgetCalculator.PrayerEvent(PrayerKind.ISHA, at(20, 0), day)
        val fajr = PrayerWidgetCalculator.PrayerEvent(PrayerKind.FAJR, at(29, 0), day)
        val events = listOf(isha, fajr)

        assertTrue(
            PrayerWidgetMomentResolver.resolve(at(20, 24, 59), events) is
                    PrayerWidgetMoment.Elapsed
        )
        val afterGrace = requireNotNull(
            PrayerWidgetMomentResolver.resolve(at(20, 25), events),
        )
        assertTrue(afterGrace is PrayerWidgetMoment.Countdown)
        assertEquals(fajr.time, afterGrace.event.time)
        assertEquals(fajr.time, PrayerWidgetMomentResolver.resolve(at(23, 59), events)?.event?.time)
        assertEquals(fajr.time, PrayerWidgetMomentResolver.resolve(at(24, 0), events)?.event?.time)
    }

    @Test
    fun noPastCountdownTargetIsReturned() {
        val old = PrayerWidgetCalculator.PrayerEvent(PrayerKind.ISHA, at(1, 0), day)
        assertNull(PrayerWidgetMomentResolver.resolve(at(2, 0), listOf(old)))
    }

    @Test
    fun travelDecisionCoversMuscatDubaiLondonIndiaAndManualMode() {
        val cases = listOf(
            Triple(25.2048, 55.2708, "Asia/Dubai"),
            Triple(51.5074, -0.1278, "Europe/London"),
            Triple(19.0760, 72.8777, "Asia/Kolkata"),
        )
        for ((lat, lon, zone) in cases) {
            val decision = PrayerWidgetTravelManager.decide(
                PrayerLocationMode.AUTOMATIC,
                23.5880,
                58.3829,
                lat,
                lon,
                "Asia/Muscat",
                zone,
            )
            assertTrue(decision.shouldUpdate)
            assertTrue(decision.distanceMeters >= 10_000.0 || decision.timeZoneChanged)
        }

        val manual = PrayerWidgetTravelManager.decide(
            PrayerLocationMode.MANUAL,
            23.5880,
            58.3829,
            51.5074,
            -0.1278,
            "Asia/Muscat",
            "Europe/London",
        )
        assertFalse(manual.shouldUpdate)
    }

    @Test
    fun coordinateResolverReturnsExactIanaZones() {
        assertEquals("Asia/Muscat", PrayerLocationTimeZoneResolver.resolve(23.5880, 58.3829))
        assertEquals("Asia/Dubai", PrayerLocationTimeZoneResolver.resolve(25.2048, 55.2708))
        assertEquals("Europe/London", PrayerLocationTimeZoneResolver.resolve(51.5074, -0.1278))
        assertEquals("Asia/Kolkata", PrayerLocationTimeZoneResolver.resolve(19.0760, 72.8777))
    }

    @Test
    fun exactAlarmAccessSelectsBestAvailablePrecision() {
        assertEquals(
            PrayerAlarmPrecision.EXACT_IDLE,
            PrayerWidgetScheduler.desiredPrecision(Build.VERSION_CODES.R, false),
        )
        assertEquals(
            PrayerAlarmPrecision.EXACT_IDLE,
            PrayerWidgetScheduler.desiredPrecision(Build.VERSION_CODES.S, true),
        )
        assertEquals(
            PrayerAlarmPrecision.INEXACT_IDLE,
            PrayerWidgetScheduler.desiredPrecision(Build.VERSION_CODES.S, false),
        )
    }

    @Test
    fun backgroundLocationAccessDegradesToCachedFixWithoutBackgroundPermission() {
        assertEquals(
            PrayerLocationAccessPlan.NO_PERMISSION,
            PrayerWidgetTravelManager.accessPlan(false, false),
        )
        assertEquals(
            PrayerLocationAccessPlan.CACHED_ONLY,
            PrayerWidgetTravelManager.accessPlan(true, false),
        )
        assertEquals(
            PrayerLocationAccessPlan.CACHED_OR_ACTIVE,
            PrayerWidgetTravelManager.accessPlan(true, true),
        )
    }

    @Test
    fun committedPayloadDecodesAsOneGeneration() {
        val json = """
            {
              "version":2,"revision":42,"committedAt":"2026-09-05T00:00:00Z",
              "coordinates":{"latitude":"19.0760","longitude":"72.8777"},
              "locationMode":"automatic","timeZoneId":"Asia/Kolkata","countryCode":"IN",
              "calculationMethod":"auto","madhab":"hanafi","highLatitudeRule":"automatic",
              "customAngles":{"custom_fajr_angle":"18","custom_maghrib_angle":"0","custom_isha_angle":"17"},
              "offsets":{"fajr":-10,"sunrise":0,"dhuhr":0,"asr":0,"maghrib":0,"isha":10},
              "timeFormat":"12h",
              "appearance":{"themeName":"teal","themeMode":"dark","locale":"en",
                "design":"hero","language":"auto","numerals":"latin","backgroundEnabled":true,
                "glassify":false,"rounded":false,"contentSize":100}
            }
        """.trimIndent()

        val payload = PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(json)
        assertNotNull(payload)
        val snapshot = requireNotNull(payload).toSnapshot()
        assertEquals(42L, snapshot.revision)
        assertEquals(19.0760, snapshot.latitude!!, 0.0)
        assertEquals("Asia/Kolkata", snapshot.displayTimeZone.id)
        assertEquals(PrayerWidgetTimeFormat.TWELVE_HOUR, snapshot.timeFormat)
        assertEquals(-10, snapshot.offsets["fajr"])
        assertEquals(PrayerWidgetSettingsSource.COMMITTED_PAYLOAD, snapshot.source)
    }

    @Test
    fun versionThreeRequiresOneCompleteBoundedRevisionTuple() {
        val common = """
            "committedAt":"2026-09-05T00:00:00.123456Z",
            "coordinates":{"latitude":23.588,"longitude":58.3829},
            "locationMode":"automatic","timeZoneId":"Asia/Muscat","countryCode":"OM",
            "calculationMethod":"auto","madhab":"shafi","highLatitudeRule":"automatic",
            "customAngles":{"custom_fajr_angle":18,"custom_maghrib_angle":0,"custom_isha_angle":17},
            "offsets":{"fajr":0,"sunrise":0,"dhuhr":0,"asr":0,"maghrib":0,"isha":0},
            "timeFormat":"system",
            "appearance":{"themeName":"teal","themeMode":"light","locale":"en",
              "design":"hero","language":"auto","numerals":"latin","backgroundEnabled":true,
              "glassify":false,"rounded":false,"contentSize":100}
        """.trimIndent()
        val valid = """
            {"version":3,"revision":13,"publicationRevision":13,
             "locationRevision":7,"scheduleRevision":11,
             "configurationSignature":"configuration",$common}
        """.trimIndent()
        val decoded = PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(valid)
        assertNotNull(decoded)
        assertEquals(7L, decoded?.locationRevision)
        assertEquals(11L, decoded?.scheduleRevision)
        assertEquals(13L, decoded?.publicationRevision)

        val missingSchedule = valid.replace("\"scheduleRevision\":11,", "")
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(missingSchedule),
        )
        val mixedPublication =
            valid.replace("\"publicationRevision\":13", "\"publicationRevision\":12")
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(mixedPublication),
        )
        val unsafeRevision = valid.replace(
            "\"locationRevision\":7",
            "\"locationRevision\":9007199254740992",
        )
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(unsafeRevision),
        )
        val invalidTimestamp = valid.replace(
            "2026-09-05T00:00:00.123456Z",
            "not-an-instant",
        )
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(invalidTimestamp),
        )
        val missingCoordinates = valid.replace(
            "\"coordinates\":{\"latitude\":23.588,\"longitude\":58.3829},",
            "",
        )
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(missingCoordinates),
        )
        val invalidZone = valid.replace("Asia/Muscat", "Unknown/Nowhere")
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(invalidZone),
        )
        val unknownMode = valid.replace("\"automatic\"", "\"unexpected\"")
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(unknownMode),
        )
        val fractionalRevision = valid.replace("\"locationRevision\":7", "\"locationRevision\":7.5")
        assertNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(fractionalRevision),
        )
    }

    @Test
    fun committedPayloadSanitizesUnboundedManualOffsets() {
        val offsets = """{"fajr":-999999,"sunrise":0,"dhuhr":0,"asr":0,"maghrib":0,"isha":999999}"""
        val json = """
            {"version":2,"revision":1,"committedAt":"2026-09-05T00:00:00Z",
             "coordinates":null,"locationMode":"manual","timeZoneId":"Europe/London",
             "calculationMethod":"auto","madhab":"shafi","highLatitudeRule":"automatic",
             "customAngles":{"custom_fajr_angle":18,"custom_maghrib_angle":0,"custom_isha_angle":17},
             "offsets":$offsets,"timeFormat":"system",
             "appearance":{"themeName":"teal","themeMode":"light","locale":"en",
              "design":"hero","language":"auto","numerals":"latin","backgroundEnabled":true,
              "glassify":false,"rounded":false,"contentSize":100}}
        """.trimIndent()
        val snapshot = requireNotNull(
            PrayerWidgetRepository.PrayerWidgetSettingsPayload.decode(json),
        ).toSnapshot()
        assertEquals(-7 * 24 * 60, snapshot.offsets["fajr"])
        assertEquals(7 * 24 * 60, snapshot.offsets["isha"])
    }

    private fun at(hour: Int, minute: Int, second: Int = 0): Date =
        Date(((hour * 60L + minute) * 60L + second) * 1_000L)
}

private fun <T> requireNotNull(value: T?): T = kotlin.requireNotNull(value)
