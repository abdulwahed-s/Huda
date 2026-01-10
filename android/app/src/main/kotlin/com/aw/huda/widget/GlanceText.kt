package com.aw.huda.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import androidx.core.content.res.ResourcesCompat
import com.aw.huda.R

object GlanceText {
    
    fun createTextBitmap(
        context: Context,
        text: String,
        textColor: Int,
        maxFontSize: Float = 15f,
        minFontSize: Float = 8f,
        maxWidth: Int = 800,
        fontResId: Int = R.font.amiri
    ): Bitmap {
        val density = context.resources.displayMetrics.density

        val typeface = try {
            ResourcesCompat.getFont(context, fontResId) ?: Typeface.SERIF
        } catch (e: Exception) {
            Typeface.SERIF
        }

        var fontSize = maxFontSize
        var textPaint: TextPaint
        var textWidth: Float
        
        do {
            textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = textColor
                textSize = fontSize * density
                this.typeface = typeface
            }
            textWidth = textPaint.measureText(text)
            
            if (textWidth <= maxWidth) {
                break
            }
            
            fontSize -= 0.5f
        } while (fontSize >= minFontSize)

        val finalPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = textColor
            textSize = fontSize * density
            this.typeface = typeface
        }

        val displayText = if (finalPaint.measureText(text) > maxWidth) {
            TextUtils.ellipsize(
                text,
                finalPaint,
                maxWidth.toFloat(),
                TextUtils.TruncateAt.END
            ).toString()
        } else {
            text
        }

        val staticLayout = StaticLayout.Builder
            .obtain(displayText, 0, displayText.length, finalPaint, maxWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setLineSpacing(0f, 1.0f)
            .setMaxLines(1)
            .setIncludePad(true)
            .setEllipsize(TextUtils.TruncateAt.END)
            .build()

        val horizontalPadding = (16 * density).toInt()
        val verticalPadding = (12 * density).toInt()
        val width = maxWidth + (horizontalPadding * 2)
        val height = staticLayout.height + (verticalPadding * 2)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        canvas.save()
        val xOffset = horizontalPadding.toFloat()
        val yOffset = verticalPadding.toFloat()
        canvas.translate(xOffset, yOffset)
        staticLayout.draw(canvas)
        canvas.restore()
        
        return bitmap
    }
}
