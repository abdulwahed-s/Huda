package com.aw.huda.widget.prayer

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.ZoneId

class PrayerLocationTimeZoneResolverTest {
    @Test
    fun resolvesRepresentativeTravelAndDateLineLocations() {
        val cases = listOf(
            Triple(23.5880, 58.4059, "Asia/Muscat"),
            Triple(25.2048, 55.2708, "Asia/Dubai"),
            Triple(51.5074, -0.1278, "Europe/London"),
            Triple(35.6762, 139.6503, "Asia/Tokyo"),
            Triple(21.3069, -157.8583, "Pacific/Honolulu"),
            Triple(1.8721, -157.4278, "Pacific/Kiritimati"),
        )

        for ((latitude, longitude, expected) in cases) {
            assertEquals(
                "$latitude,$longitude",
                expected,
                PrayerLocationTimeZoneResolver.resolveWithZoneIds(
                    latitude,
                    longitude,
                    candidateZoneIds = setOf(ZoneId.of(expected)),
                ),
            )
        }
    }
}
