package com.aw.huda.widget.prayer

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.util.TypedValue
import kotlin.math.max

internal object PrayerWidgetBackgrounds {
    private const val BITMAP_W = 600
    private const val BITMAP_H = 600

    fun render(context: Context, theme: PrayerWidgetTheme): Bitmap? {
        if (theme.isTransparent) return null

        val w = BITMAP_W
        val h = BITMAP_H
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val cornerPx = if (theme.rounded) dp(context, 22f) else 0f
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())

        val basePaint = Paint(Paint.ANTI_ALIAS_FLAG)
        if (theme.customBackground != null) {
            basePaint.color = theme.customBackground
            canvas.drawRoundRect(rect, cornerPx, cornerPx, basePaint)
            if (theme.glassify) {
                basePaint.color = Color.argb((0.08f * 255).toInt(), 255, 255, 255)
                canvas.drawRoundRect(rect, cornerPx, cornerPx, basePaint)
            }
        } else if (theme.backgroundEnabled) {
            basePaint.shader = LinearGradient(
                0f, 0f, w.toFloat(), h.toFloat(),
                theme.gradientStart, theme.gradientEnd,
                Shader.TileMode.CLAMP,
            )
            canvas.drawRoundRect(rect, cornerPx, cornerPx, basePaint)
        }

        val sheen = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f, 0f, 0f, h.toFloat(),
                intArrayOf(
                    Color.argb((0.10f * 255).toInt(), 255, 255, 255),
                    Color.TRANSPARENT,
                    Color.argb((0.04f * 255).toInt(), 0, 0, 0),
                ),
                floatArrayOf(0f, 0.5f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRoundRect(rect, cornerPx, cornerPx, sheen)

        return bitmap
    }

    private fun dp(context: Context, value: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            context.resources.displayMetrics,
        )
    }

    @Suppress("unused")
    fun renderPill(
        context: Context,
        argb: Int,
        cornerDp: Float,
    ): Bitmap {
        val w = max(60, dp(context, cornerDp * 2 + 32f).toInt())
        val h = max(40, dp(context, cornerDp * 2 + 16f).toInt())
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = argb }
        val cornerPx = dp(context, cornerDp)
        canvas.drawRoundRect(
            RectF(0f, 0f, w.toFloat(), h.toFloat()),
            cornerPx, cornerPx, paint,
        )
        return bitmap
    }
}
