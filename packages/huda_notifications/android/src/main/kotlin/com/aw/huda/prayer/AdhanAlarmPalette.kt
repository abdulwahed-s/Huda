package com.aw.huda.prayer

import android.content.Context

/**
 * The alarm screen's colors, from the theme chosen in Huda (`AppColors` in
 * Flutter): its dark gradient, a light tone for highlights and the Stop
 * button, and a deep tone for text on that button. The screen is always dark,
 * whatever the app's brightness, so a Fajr alarm never lights up a dark room.
 */
internal data class AdhanAlarmPalette(
    val gradientStart: Int, val gradientMid: Int, val gradientEnd: Int,
    val light: Int, val deep: Int,
) {
    companion object {
        private fun palette(start: Long, mid: Long, end: Long, light: Long, deep: Long) =
            AdhanAlarmPalette(start.toInt(), mid.toInt(), end.toInt(), light.toInt(), deep.toInt())

        private val themes = mapOf(
            "teal" to palette(0xFF0A1A18, 0xFF1B2D2A, 0xFF2C4A46, 0xFF5EEAD4, 0xFF042F2E),
            "purple" to palette(0xFF1A0A1A, 0xFF2D1B2D, 0xFF4A2C4A, 0xFFC4B5FD, 0xFF4C1D95),
            "green" to palette(0xFF0A1A0F, 0xFF1B2D20, 0xFF2C4A35, 0xFF4ADE80, 0xFF14532D),
            "blue" to palette(0xFF0A0F1A, 0xFF1B202D, 0xFF2C354A, 0xFF60A5FA, 0xFF1E1B4B),
            "yellow" to palette(0xFF1A180A, 0xFF2D2A1B, 0xFF4A462C, 0xFFFDE047, 0xFF713F12),
            "red" to palette(0xFF1A0A0A, 0xFF2D1B1B, 0xFF4A2C2C, 0xFFFCA5A5, 0xFF7F1D1D),
            "orange" to palette(0xFF1A0F0A, 0xFF2D201B, 0xFF4A352C, 0xFFFB923C, 0xFF7C2D12),
            "indigo" to palette(0xFF0F0A1A, 0xFF201B2D, 0xFF352C4A, 0xFFA5B4FC, 0xFF1E1B4B),
            "cream" to palette(0xFF1A160D, 0xFF2D271A, 0xFF4A402B, 0xFFE8DDBF, 0xFF5C4827),
            "pink" to palette(0xFF1A0A14, 0xFF2D1B26, 0xFF4A2C3E, 0xFFF9A8D4, 0xFF831843),
            "brown" to palette(0xFF1A100C, 0xFF2D211B, 0xFF4A372C, 0xFFD7CCC8, 0xFF3E2723),
        )

        /** Stored by Flutter as `AppColorTheme.teal` or `teal`; `gray` became cream. */
        fun named(stored: String?): AdhanAlarmPalette {
            val name = stored?.removePrefix("AppColorTheme.")?.let { if (it == "gray") "cream" else it }
            return themes[name] ?: themes.getValue("teal")
        }

        /** Before the first unlock Huda's settings are unreadable; Huda's default theme stands in. */
        fun read(context: Context): AdhanAlarmPalette = named(runCatching {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.color_theme", null)
        }.getOrNull())
    }
}
