package com.aw.huda.widget.lockscreen

import android.content.Context
import android.graphics.Typeface
import android.graphics.text.LineBreaker
import android.text.Layout
import android.text.TextPaint
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.TextView

internal object LockWidgetTextMetrics {
    fun px(context: Context, sp: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, context.resources.displayMetrics)

    fun paint(context: Context, sp: Float, font: Typeface): TextPaint =
        TextPaint(textView(context, sp, font).paint)

    fun fitLine(
        context: Context, text: String, widthPx: Float, maxSp: Float, minSp: Float,
        font: Typeface = Typeface.DEFAULT,
    ): Float? {
        var size = maxSp.coerceAtLeast(minSp)
        while (size >= minSp) {
            if (paint(context, size, font).measureText(text) <= widthPx) return size
            if (size == minSp) break
            size = (size - 0.5f).coerceAtLeast(minSp)
        }
        return null
    }

    fun lineHeight(context: Context, sp: Float, font: Typeface): Int =
        paint(context, sp, font).fontMetricsInt.let { it.bottom - it.top }

    // A TextView includes the platform's elegant/fallback font spacing. Bare
    // Paint metrics underestimate some Arabic lines on recent Android versions.
    fun layout(context: Context, content: String, widthPx: Int, sp: Float, font: Typeface): Layout {
        val view = textView(context, sp, font).apply {
            text = content
            includeFontPadding = true
            gravity = Gravity.CENTER
            textDirection = View.TEXT_DIRECTION_FIRST_STRONG_RTL
            breakStrategy = LineBreaker.BREAK_STRATEGY_SIMPLE
            hyphenationFrequency = Layout.HYPHENATION_FREQUENCY_NONE
        }
        view.measure(View.MeasureSpec.makeMeasureSpec(widthPx.coerceAtLeast(1), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
        return requireNotNull(view.layout)
    }

    fun fitBlock(context: Context, text: String, widthPx: Int, heightPx: Int,
        maxSp: Float, minSp: Float, font: Typeface, maxLines: Int = 2): Float? {
        var size = maxSp.coerceAtLeast(minSp)
        while (true) {
            val layout = layout(context, text, widthPx, size, font)
            if (layout.lineCount <= maxLines && layout.height <= heightPx &&
                layout.getLineEnd(layout.lineCount - 1) == text.length &&
                (0 until layout.lineCount).all { layout.getLineWidth(it) <= widthPx }) return size
            if (size == minSp) return null
            size = (size - 0.5f).coerceAtLeast(minSp)
        }
    }

    private fun textView(context: Context, sp: Float, font: Typeface) = TextView(context).apply {
        typeface = font
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
    }
}
