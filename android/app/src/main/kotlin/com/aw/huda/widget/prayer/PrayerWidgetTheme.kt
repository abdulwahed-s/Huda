package com.aw.huda.widget.prayer

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import com.aw.huda.widget.WidgetThemeColors

internal data class PrayerWidgetTheme(
    val gradientStart: Int,
    val gradientEnd: Int,
    val customBackground: Int?,
    val backgroundEnabled: Boolean,
    val glassify: Boolean,
    val rounded: Boolean,
    val primaryText: Int,
    val secondaryTextHero: Int,
    val secondaryTextCompact: Int,
    val accent: Int,
    val highlight: Int,
    val isDark: Boolean,
) {
    val isTransparent: Boolean
        get() = customBackground == null && !backgroundEnabled

    companion object {
        const val COMPACT_HIGHLIGHT_FALLBACK: Int = 0xFFD04034.toInt()

        fun resolve(
            context: Context,
            snapshot: PrayerWidgetSnapshot,
        ): PrayerWidgetTheme {
            val isDark = isDark(context, snapshot)
            val colors = WidgetThemeColors.getThemeColors(snapshot.themeName, isDark)
            val custom = parseHex(snapshot.backgroundColor)
            val contentOverride = parseHex(snapshot.contentColor)

            val primaryText = contentOverride ?: colors.textColor
            val secondaryHero = contentOverride?.let { withAlpha(it, 0.70f) }
                ?: colors.secondaryTextColor
            val secondaryCompact = contentOverride?.let { withAlpha(it, 0.60f) }
                ?: colors.secondaryTextColor
            val highlight = parseHex(snapshot.highlightColor)
                ?: colors.accent
            val accent = highlight

            return PrayerWidgetTheme(
                gradientStart = colors.gradientStart,
                gradientEnd = colors.gradientEnd,
                customBackground = custom,
                backgroundEnabled = snapshot.backgroundEnabled,
                glassify = snapshot.glassify,
                rounded = snapshot.rounded,
                primaryText = primaryText,
                secondaryTextHero = secondaryHero,
                secondaryTextCompact = secondaryCompact,
                accent = accent,
                highlight = highlight,
                isDark = isDark,
            )
        }

        private fun isDark(
            context: Context,
            snapshot: PrayerWidgetSnapshot,
        ): Boolean = when (snapshot.themeMode) {
            "dark" -> true
            "light" -> false
            else -> {
                val mask = context.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK
                mask == Configuration.UI_MODE_NIGHT_YES
            }
        }

        private fun parseHex(hex: String?): Int? {
            if (hex.isNullOrBlank()) return null
            val sanitized = hex.removePrefix("#").uppercase()
            val padded = if (sanitized.length == 6) "FF$sanitized" else sanitized
            if (padded.length != 8) return null
            return try {
                padded.toLong(16).toInt()
            } catch (_: NumberFormatException) {
                null
            }
        }

        fun withAlpha(color: Int, alpha: Float): Int {
            val a = (alpha.coerceIn(0f, 1f) * 255).toInt()
            return Color.argb(a, Color.red(color), Color.green(color), Color.blue(color))
        }
    }
}
