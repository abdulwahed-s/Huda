package com.aw.huda.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class QuranWidgetPaletteResolverTest {
    @Test
    fun `every named Quran palette uses the prayer widget theme colors`() {
        val expectedColors = mapOf(
            "ocean" to Triple(0xFF1A3A5C.toInt(), 0xFFF0F4F8.toInt(), 0xFF4DD0E1.toInt()),
            "sunset" to Triple(0xFF5C2A0E.toInt(), 0xFFFFF5EB.toInt(), 0xFFFFD54F.toInt()),
            "forest" to Triple(0xFF1B3A2A.toInt(), 0xFFE8F5E9.toInt(), 0xFF66BB6A.toInt()),
            "midnight" to Triple(0xFF121218.toInt(), 0xFFE0E0E8.toInt(), 0xFF7986CB.toInt()),
            "sandstone" to Triple(0xFFF5E6D3.toInt(), 0xFF3E2C1A.toInt(), 0xFFD84315.toInt()),
            "rose" to Triple(0xFF3D1A2E.toInt(), 0xFFFCE4EC.toInt(), 0xFFF06292.toInt()),
            "lavender" to Triple(0xFF2E2450.toInt(), 0xFFEDE7F6.toInt(), 0xFFBA68C8.toInt()),
            "charcoal" to Triple(0xFF2C2C2C.toInt(), 0xFFF5F5F5.toInt(), 0xFFFFB74D.toInt()),
            "amber" to Triple(0xFF4A3000.toInt(), 0xFFFFF8E1.toInt(), 0xFFFFD740.toInt()),
            "arctic" to Triple(0xFFE3F2FD.toInt(), 0xFF0D2137.toInt(), 0xFF1976D2.toInt()),
            "burgundy" to Triple(0xFF4A0E1E.toInt(), 0xFFFDE8EF.toInt(), 0xFFEF5350.toInt()),
            "sage" to Triple(0xFF3B4A3A.toInt(), 0xFFF1F5E8.toInt(), 0xFF81C784.toInt()),
        )

        expectedColors.forEach { (theme, expected) ->
            val actual = QuranWidgetPaletteResolver.resolve(theme, "teal", false)
            assertEquals("$theme background", expected.first, actual.background)
            assertEquals("$theme ayah", expected.second, actual.ayah)
            assertEquals("$theme accent", expected.third, actual.accent)
        }
    }
}
