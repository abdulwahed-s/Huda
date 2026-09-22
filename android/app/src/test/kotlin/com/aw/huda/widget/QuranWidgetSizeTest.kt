package com.aw.huda.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class QuranWidgetSizeTest {
    @Test
    fun dimensionsMapToContentSafeCatalogSizes() {
        assertEquals(QuranWidgetSize.SMALL, QuranWidgetSize.fromDimensions(180f, 140f))
        assertEquals(QuranWidgetSize.SMALL, QuranWidgetSize.fromDimensions(279f, 310f))
        assertEquals(QuranWidgetSize.MEDIUM, QuranWidgetSize.fromDimensions(280f, 140f))
        assertEquals(QuranWidgetSize.MEDIUM, QuranWidgetSize.fromDimensions(400f, 310f))
        assertEquals(QuranWidgetSize.LARGE, QuranWidgetSize.fromDimensions(280f, 311f))
    }
}
