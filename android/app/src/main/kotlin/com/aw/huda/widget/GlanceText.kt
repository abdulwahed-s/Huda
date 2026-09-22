package com.aw.huda.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
import androidx.core.content.res.ResourcesCompat

object GlanceText {
    class TextMetrics internal constructor(private val lineBottoms: List<Int>) {
        val lineCount: Int get() = lineBottoms.size.coerceAtLeast(1)

        fun heightForLines(lines: Int): Int =
            lineBottoms.getOrElse(lines.coerceIn(1, lineCount) - 1) { 1 }.coerceAtLeast(1)
    }

    fun measureText(
        context: Context,
        text: String,
        fontSize: Float,
        maxWidth: Int,
        rtl: Boolean,
        fontResId: Int? = null,
        bold: Boolean = false,
    ): TextMetrics {
        val density = context.resources.displayMetrics.density
        val typeface = resolveTypeface(context, fontResId, rtl, bold)
        val layout = buildFullLayout(
            text = text,
            paint = textPaint(fontSize, density, typeface),
            width = maxWidth.coerceAtLeast(1),
            rtl = rtl,
        )
        return TextMetrics(
            List(layout.lineCount.coerceAtLeast(1)) { index ->
                if (layout.lineCount == 0) 1 else layout.getLineBottom(index)
            },
        )
    }

    fun createTextBitmap(
        context: Context,
        text: String,
        textColor: Int,
        fontSize: Float,
        maxWidth: Int,
        maxHeight: Int,
        maxLines: Int,
        rtl: Boolean,
        fontResId: Int? = null,
        bold: Boolean = false,
        ellipsizeOverflow: Boolean = true,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = maxWidth.coerceAtLeast(1)
        val height = maxHeight.coerceAtLeast(1)
        val typeface = resolveTypeface(context, fontResId, rtl, bold)
        val paint = textPaint(fontSize, density, typeface, textColor)
        val fullLayout = buildFullLayout(text, paint, width, rtl)
        val firstLineHeight = if (fullLayout.lineCount > 0) {
            (fullLayout.getLineBottom(0) - fullLayout.getLineTop(0)).coerceAtLeast(1)
        } else {
            height
        }
        val visibleLines = minOf(
            maxLines,
            (height / firstLineHeight).coerceAtLeast(1),
        )
        val layout = if (!ellipsizeOverflow) {
            fullLayout
        } else if (fullLayout.height <= height && fullLayout.lineCount <= visibleLines) {
            fullLayout
        } else {
            var clippedLines = visibleLines
            var clippedLayout = buildClippedLayout(text, paint, width, clippedLines, rtl)
            while (clippedLayout.height > height && clippedLines > 1) {
                clippedLines -= 1
                clippedLayout = buildClippedLayout(text, paint, width, clippedLines, rtl)
            }
            clippedLayout
        }

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.translate(0f, ((height - layout.height) / 2f).coerceAtLeast(0f))
        layout.draw(canvas)
        return bitmap
    }

    private fun resolveTypeface(
        context: Context,
        fontResId: Int?,
        rtl: Boolean,
        bold: Boolean,
    ): Typeface {
        val baseTypeface = if (fontResId == null) {
            if (rtl) Typeface.SERIF else Typeface.DEFAULT
        } else {
            runCatching { ResourcesCompat.getFont(context, fontResId) }.getOrNull() ?: Typeface.SERIF
        }
        return if (bold) Typeface.create(baseTypeface, Typeface.BOLD) else baseTypeface
    }

    private fun textPaint(
        fontSize: Float,
        density: Float,
        typeface: Typeface,
        textColor: Int = 0,
    ): TextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
        color = textColor
        textSize = fontSize * density
        this.typeface = typeface
    }

    private fun buildFullLayout(
        text: String,
        paint: TextPaint,
        width: Int,
        rtl: Boolean,
    ): StaticLayout = StaticLayout.Builder
        .obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_CENTER)
        .setIncludePad(false)
        .setLineSpacing(0f, 1.08f)
        .setTextDirection(if (rtl) TextDirectionHeuristics.RTL else TextDirectionHeuristics.LTR)
        .build()

    private fun buildClippedLayout(
        text: String,
        paint: TextPaint,
        width: Int,
        maxLines: Int,
        rtl: Boolean,
    ): StaticLayout = StaticLayout.Builder
        .obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_CENTER)
        .setIncludePad(false)
        .setLineSpacing(0f, 1.08f)
        .setMaxLines(maxLines)
        .setEllipsize(TextUtils.TruncateAt.END)
        .setTextDirection(if (rtl) TextDirectionHeuristics.RTL else TextDirectionHeuristics.LTR)
        .build()
}
