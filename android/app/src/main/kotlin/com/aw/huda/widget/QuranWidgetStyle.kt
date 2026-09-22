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
        "ocean" -> palette(0x1A3A5C, 0x244B73, 0xF0F4F8, 0xD2DEE8, 0x4DD0E1)
        "sunset" -> palette(0x5C2A0E, 0x743816, 0xFFF5EB, 0xE6D6C7, 0xFFD54F)
        "forest" -> palette(0x1B3A2A, 0x244D38, 0xE8F5E9, 0xC9DDCB, 0x66BB6A)
        "midnight" -> palette(0x121218, 0x20202A, 0xE0E0E8, 0xC9C6D5, 0x7986CB)
        "sandstone" -> palette(
            0xF5E6D3,
            0xFFF8EF,
            0x3E2C1A,
            0x5E4932,
            0xD84315,
            ornament = 0xC18445,
            isLight = true,
        )

        "rose" -> palette(0x3D1A2E, 0x532740, 0xFCE4EC, 0xDFC5CF, 0xF06292)
        "lavender" -> palette(0x2E2450, 0x3D3168, 0xEDE7F6, 0xCBC2DE, 0xBA68C8)
        "charcoal" -> palette(0x2C2C2C, 0x3D3D3D, 0xF5F5F5, 0xD6D6D6, 0xFFB74D)
        "amber" -> palette(0x4A3000, 0x63430A, 0xFFF8E1, 0xE6D8AD, 0xFFD740)
        "arctic" -> palette(
            0xE3F2FD,
            0xF6FAFE,
            0x0D2137,
            0x40566D,
            0x1976D2,
            ornament = 0xC18445,
            isLight = true,
        )

        "burgundy" -> palette(0x4A0E1E, 0x62152A, 0xFDE8EF, 0xE6BEC9, 0xEF5350)
        "sage" -> palette(0x3B4A3A, 0x4D5F4C, 0xF1F5E8, 0xD0DACA, 0x81C784)
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
