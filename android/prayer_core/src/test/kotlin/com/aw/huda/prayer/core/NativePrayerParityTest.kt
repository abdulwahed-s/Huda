package com.aw.huda.prayer.core

import com.google.gson.Gson
import com.google.gson.JsonObject
import org.junit.Assert.*
import org.junit.Test
import java.time.*

class NativePrayerParityTest {
    @Test fun acceptedDartInstantsAndIdentitiesMatch() {
        val fixtures = javaClass.getResourceAsStream("/dart_prayer_fixtures_v1.json")!!
            .bufferedReader().use { Gson().fromJson(it, JsonObject::class.java) }
        var checked = 0
        var maxDeviation = 0L
        for (fixture in fixtures.getAsJsonArray("cases")) {
            val row = fixture.asJsonObject
            val input = Gson().fromJson(row.getAsJsonObject("input"), PrayerCalculationInput::class.java)
            val calculated = NativePrayerCalculator.adjustedTimes(input, LocalDate.parse(row["date"].asString))
            for (prayer in PrayerOccurrenceIdentity.prayers) {
                val expected = row.getAsJsonObject("expected")[prayer]
                val actual = calculated[prayer]
                val label = "${row["date"]} ${input.countryCode}/${input.timeZoneId} ${input.method} ${input.madhab} ${input.highLatitude} $prayer"
                if (expected.isJsonNull) assertNull(label, actual)
                else {
                    assertNotNull(label, actual)
                    maxDeviation = maxOf(maxDeviation, kotlin.math.abs(actual!!.toEpochMilli() - expected.asJsonObject["utcMillis"].asLong))
                    assertTrue("$label expected=${expected.asJsonObject["utcMillis"]} actual=${actual!!.toEpochMilli()}",
                        kotlin.math.abs(actual.toEpochMilli() - expected.asJsonObject["utcMillis"].asLong) <= 1000)
                    assertEquals(label, expected.asJsonObject["id"].asLong,
                        PrayerOccurrenceIdentity.idFor(actual.atZone(ZoneId.of(input.timeZoneId)).toLocalDate(), prayer))
                }
                checked++
            }
        }
        assertTrue(checked > 3000)
        println("Verified $checked Dart/native prayer instants and IDs; maximum UTC difference: ${maxDeviation}ms")
    }
}
