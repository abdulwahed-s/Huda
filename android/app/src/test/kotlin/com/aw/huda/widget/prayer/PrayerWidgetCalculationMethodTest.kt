package com.aw.huda.widget.prayer

import io.github.abdulwaheds.prayertimeplus.CalculationMethod
import org.junit.Assert.assertEquals
import org.junit.Test

class PrayerWidgetCalculationMethodTest {
    @Test
    fun everyFlutterCalculationMethodTokenResolvesToItsNativeMethod() {
        val flutterTokens = listOf(
            "muslimWorldLeague", "egyptian", "karachi", "ummAlQura", "northAmerica",
            "emirates", "dubai", "qatar", "kuwait", "oman", "omanMuscat", "jordan",
            "palestine", "syria", "iraq", "morocco", "azrou", "algeria", "tunisia",
            "libya", "sudan", "turkey", "malaysia", "malaysia2", "indonesia",
            "kazakhstan", "tajikistan", "maldives", "southKorea", "uoif", "paris",
            "toulouse", "lyon", "orleans", "moscow", "czech", "switzerland",
            "fribourg", "belgium", "luxembourg", "austria", "london", "birmingham",
            "blackburn", "aachen", "munchen", "potsdam", "nurnberg", "rotterdam",
            "dordrecht", "eindhoven", "montreal", "windsor", "calgary", "mississauga",
            "other",
        )

        for (token in flutterTokens) {
            val expectedKey = when (token) {
                "muslimWorldLeague" -> "mwl"
                "egyptian" -> "egypt"
                "ummAlQura" -> "makkah"
                "northAmerica" -> "isna"
                "southKorea" -> "southkorea"
                "other" -> "custom"
                else -> token
            }
            assertEquals(
                "Unexpected native calculation method for $token",
                expectedKey,
                PrayerWidgetCalculator.methodFrom(token, "OM").key,
            )
        }
    }

    @Test
    fun automaticMethodStillUsesTheSavedCountry() {
        assertEquals(
            CalculationMethod.OMAN,
            PrayerWidgetCalculator.methodFrom("auto", "OM"),
        )
    }
}
