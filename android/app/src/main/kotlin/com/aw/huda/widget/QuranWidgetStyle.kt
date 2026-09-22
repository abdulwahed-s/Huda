package com.aw.huda.widget

data class QuranWidgetPalette(
    val background: Int,
    val surface: Int,
    val ayah: Int,
    val translation: Int,
    val accent: Int,
    val ornament: Int = 0xFFD9BE72.toInt(),
    val isLight: Boolean = false,
)

object QuranWidgetPaletteResolver {
    fun resolve(
        visualTheme: String?,
        appThemeName: String,
        isDarkMode: Boolean,
    ): QuranWidgetPalette = when (visualTheme) {
        "forest" -> palette(0x1B3A2A, 0x244D38, 0xE8F5E9, 0xC9DDCB, 0x81C784)
        "ocean" -> palette(0x1A3A5C, 0x244B73, 0xF0F4F8, 0xD2DEE8, 0x4DD0E1)
        "sandstone" -> palette(
            0xF5E6D3,
            0xFFF8EF,
            0x3E2C1A,
            0x5E4932,
            0xA83D15,
            ornament = 0xC18445,
            isLight = true,
        )
        "midnight" -> palette(0x121218, 0x20202A, 0xF3F0FA, 0xC9C6D5, 0x9FA8DA)
        "burgundy" -> palette(0x4A0E1E, 0x62152A, 0xFDE8EF, 0xE6BEC9, 0xFF8A80)
        "lavender" -> palette(0x2E2450, 0x3D3168, 0xEDE7F6, 0xCBC2DE, 0xD59BE6)
        else -> autoPalette(appThemeName, isDarkMode)
    }

    private fun autoPalette(themeName: String, isDarkMode: Boolean): QuranWidgetPalette {
        if (themeName == "teal" && isDarkMode) {
            return palette(0x061821, 0x0A3339, 0xF6F5EA, 0xD7E7E5, 0x62E6D2)
        }

        val app = WidgetThemeColors.getThemeColors(themeName, isDarkMode)
        return QuranWidgetPalette(
            background = app.gradientStart,
            surface = app.gradientEnd,
            ayah = app.quoteTextColor,
            translation = app.secondaryTextColor,
            accent = app.accent,
            ornament = if (isDarkMode) 0xFFD9BE72.toInt() else 0xFFC18445.toInt(),
            isLight = !isDarkMode,
        )
    }

    private fun palette(
        background: Long,
        surface: Long,
        ayah: Long,
        translation: Long,
        accent: Long,
        ornament: Long = 0xD9BE72,
        isLight: Boolean = false,
    ) = QuranWidgetPalette(
        background = (0xFF000000L or background).toInt(),
        surface = (0xFF000000L or surface).toInt(),
        ayah = (0xFF000000L or ayah).toInt(),
        translation = (0xFF000000L or translation).toInt(),
        accent = (0xFF000000L or accent).toInt(),
        ornament = (0xFF000000L or ornament).toInt(),
        isLight = isLight,
    )
}
