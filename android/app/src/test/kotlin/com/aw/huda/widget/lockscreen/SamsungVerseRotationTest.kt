package com.aw.huda.widget.lockscreen

import org.junit.Assert.*
import org.junit.Test

class SamsungVerseRotationTest {
    @Test fun rotationUsesCurrentHourAndManualOffsetWithinFittingSubset() {
        val fitting = listOf("94:8", "89:30", "74:7")
        assertEquals("94:8", SamsungVerseFitter.select(fitting, 0, 0))
        assertEquals("94:8", SamsungVerseFitter.select(fitting, 3_599_999, 0))
        assertEquals("89:30", SamsungVerseFitter.select(fitting, 3_600_000, 0))
        assertEquals("74:7", SamsungVerseFitter.select(fitting, 3_600_000, 1))
        assertEquals("94:8", SamsungVerseFitter.select(fitting, 3_600_000, 2))
    }

    @Test fun noFittingVerseUsesFallbackAndSingleVerseRemainsDeterministic() {
        assertNull(SamsungVerseFitter.select(emptyList<String>(), 0, 0))
        assertEquals("89:30", SamsungVerseFitter.select(listOf("89:30"), 99_000_000, 1000))
    }

    @Test fun negativeHoursAndExtremeOffsetsDoNotOverflow() {
        val fitting = listOf(1, 2, 3)
        assertEquals(3, SamsungVerseFitter.select(fitting, -1, 0))
        assertEquals(3, SamsungVerseFitter.select(fitting, 3_600_000, Long.MAX_VALUE))
    }
}
