package com.aw.huda.prayer

import org.junit.Assert.*
import org.junit.Test

class PrayerPolicyAndFlipTest {
    @Test fun sparseOverridesInheritAndOnlyEligibilityChangesItsSignature() {
        val initial = PrayerPolicy.initial()
        val quieter = PrayerPolicy.validate(initial.copy(values = initial.values + mapOf("volumeGain" to 0.2,
            "fadeInSeconds" to 10L, "alarmScreenEnabled" to true)))
        assertEquals(PrayerPolicy.eligibility(initial), PrayerPolicy.eligibility(quieter))
        val custom = PrayerPolicy.validate(quieter.copy(values = quieter.values + mapOf("perPrayer" to mapOf("fajr" to mapOf("mode" to "off")))))
        assertEquals("off", PrayerPolicy.effective(custom, "fajr").mode)
        assertEquals(0.2, PrayerPolicy.effective(custom, "isha").gain, 0.0)
        assertNotEquals(PrayerPolicy.eligibility(quieter), PrayerPolicy.eligibility(custom))
    }
    @Test fun invalidPolicyCannotPartiallyApply() {
        for (values in listOf(mapOf("volumeGain" to Double.NaN), mapOf("fadeInSeconds" to 1.5),
            mapOf("stopAfterSeconds" to 0L), mapOf("respectDoNotDisturb" to false),
            mapOf("perPrayer" to mapOf("sunrise" to mapOf("mode" to "full"))),
            mapOf("perPrayer" to mapOf("fajr" to mapOf("reciterId" to "../../outside"))))) {
            try { PrayerPolicy.validate(PrayerPolicy.initial().copy(values = values)); fail(values.toString()) }
            catch (_: IllegalArgumentException) { }
        }
    }
    /** Feeds [poses] (x, y, z) every 100 ms from [from]; true if it fired. */
    private fun FlipGestureRecognizer.feed(from: Long, until: Long, x: Double, y: Double, z: Double): Boolean {
        var fired = false
        for (time in from..until step 100) if (sample(x, y, z, time)) fired = true
        return fired
    }
    private val g = 9.81
    private val tilt = 6.94 // 45 degrees

    @Test fun alreadyFaceDownNeverStopsEvenAfterABogusStartupReading() {
        val gesture = FlipGestureRecognizer()
        // Some phones report face up for the first readings, then the truth.
        assertFalse(gesture.feed(0, 900, 0.0, 0.0, g))
        assertFalse(gesture.feed(1000, 6000, 0.0, 0.0, -g))
        assertFalse(gesture.sample(0.0, 0.0, 30.0, 6100))
        assertEquals(FlipGestureRecognizer.State.WAITING, gesture.state)
    }
    @Test fun flippingFromStandingUprightStops() {
        val gesture = FlipGestureRecognizer()
        assertFalse(gesture.feed(0, 2000, 0.0, g, 0.0)) // on a stand
        assertEquals(FlipGestureRecognizer.State.ARMED, gesture.state)
        assertFalse(gesture.feed(2100, 2400, 0.0, 0.0, -g))
        assertTrue(gesture.sample(0.0, 0.0, -g, 2500))
        assertFalse(gesture.sample(0.0, 0.0, -g, 3000))
        assertEquals(FlipGestureRecognizer.State.DETECTED, gesture.state)
    }
    @Test fun flippingFromFlatOrTiltedInTheHandStops() {
        for ((y, z) in listOf(0.0 to g, tilt to tilt)) {
            val gesture = FlipGestureRecognizer()
            assertFalse(gesture.feed(0, 2000, 0.0, y, z))
            assertTrue(gesture.feed(2100, 2600, 0.0, y, -z))
        }
    }
    @Test fun aBriefFaceDownOrShakingDoesNotStop() {
        val gesture = FlipGestureRecognizer()
        assertFalse(gesture.feed(0, 2000, 0.0, 0.0, g))
        assertFalse(gesture.feed(2100, 2300, 0.0, 0.0, -g)) // 300 ms only
        assertFalse(gesture.feed(2400, 2600, 0.0, 0.0, g))
        assertFalse(gesture.feed(2700, 2900, 0.0, 0.0, -g))
        assertFalse(gesture.sample(0.0, 0.0, -30.0, 3000)) // shake resets the dwell
        assertFalse(gesture.feed(3100, 3400, 0.0, 0.0, -g))
        assertTrue(gesture.sample(0.0, 0.0, -g, 3500))
    }
    @Test fun aSlowSlideFaceDownIsNotAFlip() {
        val gesture = FlipGestureRecognizer()
        assertFalse(gesture.feed(0, 2000, 0.0, g, 0.0))
        // Lying on its side between poses for three seconds, then face down.
        assertFalse(gesture.feed(2100, 5100, 0.0, 7.4, -6.4))
        assertFalse(gesture.feed(5200, 8000, 0.0, 0.0, -g))
        assertEquals(FlipGestureRecognizer.State.WAITING, gesture.state)
    }
    @Test fun walkingWithThePhoneUprightNeverStops() {
        val gesture = FlipGestureRecognizer()
        for (time in 0L..10_000L step 100) {
            val bob = if (time % 400 == 0L) 2.0 else 0.0
            assertFalse(gesture.sample(0.0, g + bob, 0.5, time))
        }
    }
}
