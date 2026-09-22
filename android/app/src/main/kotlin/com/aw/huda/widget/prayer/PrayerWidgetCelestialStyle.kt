package com.aw.huda.widget.prayer

import android.graphics.Color
import kotlin.math.roundToInt

internal data class PrayerWidgetPalette(
    val gradientStart: Int,
    val gradientEnd: Int,
    val surface: Int,
    val raised: Int,
    val text: Int,
    val secondary: Int,
    val accent: Int,
    val countdownAccent: Int,
    val gold: Int,
    val line: Int,
    val isLight: Boolean,
    val transparent: Boolean,
)

internal object PrayerWidgetPaletteResolver {
    fun resolve(theme: PrayerWidgetTheme): PrayerWidgetPalette {
        val base = theme.customBackground ?: blend(theme.gradientStart, theme.gradientEnd, 0.56f)
        val isLight = luminance(base) >= 0.52f
        val transparent = theme.isTransparent
        val surface = when {
            theme.customBackground != null && isLight -> blend(base, Color.WHITE, 0.18f)
            theme.customBackground != null -> blend(base, Color.WHITE, 0.08f)
            else -> theme.gradientStart
        }
        val raised = if (isLight) {
            blend(surface, Color.BLACK, 0.075f)
        } else {
            blend(surface, Color.WHITE, 0.10f)
        }
        val secondary = withAlpha(
            theme.primaryText,
            if (isLight) 0.70f else 0.76f,
        )
        val gold = if (isLight) 0xFFA9783E.toInt() else 0xFFE4C777.toInt()
        return PrayerWidgetPalette(
            gradientStart = if (transparent) Color.TRANSPARENT else surface,
            gradientEnd = if (transparent) Color.TRANSPARENT else base,
            surface = surface,
            raised = raised,
            text = theme.primaryText,
            secondary = secondary,
            accent = theme.highlight,
            countdownAccent = blend(
                theme.highlight,
                theme.primaryText,
                if (isLight) 0.14f else 0.18f,
            ),
            gold = gold,
            line = blend(theme.highlight, gold, 0.34f),
            isLight = isLight,
            transparent = transparent,
        )
    }

    fun withAlpha(color: Int, alpha: Float): Int {
        val a = (alpha.coerceIn(0f, 1f) * 255f).roundToInt()
        return (color and 0x00FFFFFF) or (a shl 24)
    }

    fun blend(from: Int, to: Int, amount: Float): Int {
        val t = amount.coerceIn(0f, 1f)
        fun channel(a: Int, b: Int): Int = (a + (b - a) * t).roundToInt()
        return Color.argb(
            channel(Color.alpha(from), Color.alpha(to)),
            channel(Color.red(from), Color.red(to)),
            channel(Color.green(from), Color.green(to)),
            channel(Color.blue(from), Color.blue(to)),
        )
    }

    private fun luminance(color: Int): Float {
        fun linear(channel: Int): Float {
            val value = channel / 255f
            return if (value <= 0.04045f) value / 12.92f
            else Math.pow(((value + 0.055f) / 1.055f).toDouble(), 2.4).toFloat()
        }
        return 0.2126f * linear(Color.red(color)) +
            0.7152f * linear(Color.green(color)) +
            0.0722f * linear(Color.blue(color))
    }
}
