package com.aw.huda.widget.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PrayerWidgetTravelManagerTest {
    @Test
    fun manualModeNeverAcceptsTravel() {
        val decision = PrayerWidgetTravelManager.decide(
            locationMode = PrayerLocationMode.MANUAL,
            previousLatitude = 23.588,
            previousLongitude = 58.3829,
            candidateLatitude = 51.5074,
            candidateLongitude = -0.1278,
            previousTimeZoneId = "Asia/Muscat",
            candidateTimeZoneId = "Europe/London",
        )

        assertFalse(decision.shouldUpdate)
        assertFalse(decision.timeZoneChanged)
    }

    @Test
    fun nearbyNoiseDoesNotActivate() {
        val decision = PrayerWidgetTravelManager.decide(
            locationMode = PrayerLocationMode.AUTOMATIC,
            previousLatitude = 23.5880,
            previousLongitude = 58.3829,
            candidateLatitude = 23.5900,
            candidateLongitude = 58.3840,
            previousTimeZoneId = "Asia/Muscat",
            candidateTimeZoneId = "Asia/Muscat",
        )

        assertFalse(decision.shouldUpdate)
        assertTrue(decision.distanceMeters < 10_000)
    }

    @Test
    fun timezoneBoundaryActivatesBelowDistanceThreshold() {
        val decision = PrayerWidgetTravelManager.decide(
            locationMode = PrayerLocationMode.AUTOMATIC,
            previousLatitude = 41.0000,
            previousLongitude = -87.5000,
            candidateLatitude = 41.0100,
            candidateLongitude = -87.5000,
            previousTimeZoneId = "America/Chicago",
            candidateTimeZoneId = "America/Indiana/Indianapolis",
        )

        assertTrue(decision.distanceMeters < 10_000)
        assertTrue(decision.timeZoneChanged)
        assertTrue(decision.shouldUpdate)
    }

    @Test
    fun permissionPlanNeverStartsActiveLookupWithoutBackgroundAccess() {
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
    fun staleFutureAndLowAccuracyFixesAreRejected() {
        val now = 1_800_000_000_000L

        assertFalse(
            PrayerWidgetTravelManager.acceptableFix(
                now,
                now - 30L * 60L * 1_000L - 1L,
                20f,
            ),
        )
        assertFalse(
            PrayerWidgetTravelManager.acceptableFix(
                now,
                now + 120_001L,
                20f,
            ),
        )
        assertFalse(PrayerWidgetTravelManager.acceptableFix(now, now, 5_001f))
        assertTrue(
            PrayerWidgetTravelManager.acceptableFix(now, now - 60_000L, 5_000f),
        )
    }

    @Test
    fun clockRollbackDoesNotThrottleTravelValidation() {
        val now = 1_800_000_000_000L

        assertTrue(PrayerWidgetTravelManager.shouldThrottle(now, now - 60_000L))
        assertFalse(PrayerWidgetTravelManager.shouldThrottle(now, now + 1L))
        assertFalse(PrayerWidgetTravelManager.shouldThrottle(now, 0L))
    }

    @Test
    fun travelLocationProjectionIsValidatedIndependentlyOfWidgetPayload() {
        val valid = """
            {
              "schemaVersion": 1,
              "revision": 42,
              "mode": "automatic",
              "latitude": 23.588,
              "longitude": 58.3829,
              "timeZoneId": "Asia/Muscat",
              "timeZoneProvenance": "coordinateResolved",
              "countryCode": "OM",
              "capturedAtUtc": "2026-09-09T08:00:00Z",
              "committedAtUtc": "2026-09-09T08:01:00Z",
              "accuracyMeters": 25,
              "source": "foreground"
            }
        """.trimIndent()

        val decoded = PrayerWidgetRepository.decodeActiveLocationProjection(valid)
        assertEquals(42L, decoded?.revision)
        assertEquals(PrayerLocationMode.AUTOMATIC, decoded?.locationMode)
        assertEquals("Asia/Muscat", decoded?.timeZoneId)

        assertNull(
            PrayerWidgetRepository.decodeActiveLocationProjection(
                valid.replace("Asia/Muscat", "Invalid/Zone"),
            ),
        )
        assertNull(
            PrayerWidgetRepository.decodeActiveLocationProjection(
                valid.replace("\"automatic\"", "\"unknown\""),
            ),
        )
    }
}
