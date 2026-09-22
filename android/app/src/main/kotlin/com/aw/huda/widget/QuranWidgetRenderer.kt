package com.aw.huda.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import com.aw.huda.R
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

object QuranWidgetRenderer {
    private const val ARABIC_AUTO_FLOOR_SP = 14f
    private const val TRANSLATION_AUTO_FLOOR_SP = 9f

    fun render(
        context: Context,
        widthDp: Float,
        heightDp: Float,
        snapshot: WidgetDataRepository.Snapshot,
    ): Bitmap {
        val metrics = context.resources.displayMetrics
        val safeWidthDp = widthDp.coerceAtLeast(36f)
        val safeHeightDp = heightDp.coerceAtLeast(36f)
        val rasterScale = min(
            metrics.density,
            min(
                metrics.widthPixels / safeWidthDp,
                metrics.heightPixels / safeHeightDp,
            ),
        ).coerceAtLeast(0.5f)
        val width = (safeWidthDp * rasterScale).roundToInt().coerceAtLeast(1)
        val height = (safeHeightDp * rasterScale).roundToInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val layout = WidgetLayout(safeWidthDp, safeHeightDp, rasterScale)

        drawAtmosphere(canvas, layout, snapshot.palette)
        if (layout.emergency) {
            drawMedallion(
                context = context,
                canvas = canvas,
                centerX = width / 2f,
                centerY = height / 2f,
                diameter = layout.dp(min(safeWidthDp, safeHeightDp) * 0.58f),
                palette = snapshot.palette,
            )
            return bitmap
        }

        val headerBottom = drawHeader(context, canvas, layout, snapshot)
        drawVerse(context, canvas, layout, snapshot, headerBottom)
        return bitmap
    }

    private fun drawAtmosphere(
        canvas: Canvas,
        layout: WidgetLayout,
        palette: QuranWidgetPalette,
    ) {
        val width = layout.widthPx
        val height = layout.heightPx
        val radius = layout.dp(
            min(26f, min(layout.widthDp, layout.heightDp) * 0.22f),
        )
        val bounds = RectF(0f, 0f, width, height)
        val clip = Path().apply { addRoundRect(bounds, radius, radius, Path.Direction.CW) }
        canvas.save()
        canvas.clipPath(clip)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.shader = LinearGradient(
            0f,
            0f,
            width,
            height,
            intArrayOf(palette.surface, palette.background, palette.background),
            floatArrayOf(0f, 0.58f, 1f),
            Shader.TileMode.CLAMP,
        )
        canvas.drawRect(bounds, paint)

        paint.shader = RadialGradient(
            width * 0.50f,
            height * 0.18f,
            width * 0.62f,
            withAlpha(palette.accent, if (palette.isLight) 0.16f else 0.27f),
            Color.TRANSPARENT,
            Shader.TileMode.CLAMP,
        )
        canvas.drawRect(bounds, paint)

        paint.shader = RadialGradient(
            width * 0.88f,
            -height * 0.02f,
            width * 0.37f,
            withAlpha(palette.ornament, 0.14f),
            Color.TRANSPARENT,
            Shader.TileMode.CLAMP,
        )
        canvas.drawRect(bounds, paint)

        paint.shader = LinearGradient(
            0f,
            height * 0.48f,
            0f,
            height,
            Color.TRANSPARENT,
            withAlpha(Color.BLACK, if (palette.isLight) 0.08f else 0.22f),
            Shader.TileMode.CLAMP,
        )
        canvas.drawRect(bounds, paint)
        paint.shader = null

        drawSacredGeometry(canvas, layout, palette)
        canvas.restore()

        val outerStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = layout.dp(1f)
            shader = LinearGradient(
                0f,
                0f,
                width,
                height,
                intArrayOf(
                    withAlpha(palette.accent, 0.62f),
                    withAlpha(palette.ayah, 0.16f),
                    withAlpha(palette.ornament, 0.34f),
                    withAlpha(palette.accent, 0.18f),
                ),
                floatArrayOf(0f, 0.36f, 0.72f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        val halfOuterStroke = outerStroke.strokeWidth / 2f
        canvas.drawRoundRect(
            RectF(halfOuterStroke, halfOuterStroke, width - halfOuterStroke, height - halfOuterStroke),
            radius,
            radius,
            outerStroke,
        )

        val innerInset = layout.dp(1.5f)
        val innerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = layout.dp(0.75f)
            color = withAlpha(palette.ayah, 0.09f)
        }
        canvas.drawRoundRect(
            RectF(innerInset, innerInset, width - innerInset, height - innerInset),
            (radius - innerInset).coerceAtLeast(0f),
            (radius - innerInset).coerceAtLeast(0f),
            innerPaint,
        )
    }

    private fun drawSacredGeometry(
        canvas: Canvas,
        layout: WidgetLayout,
        palette: QuranWidgetPalette,
    ) {
        val width = layout.widthPx
        val height = layout.heightPx
        val arch = Path().apply {
            moveTo(width * 0.18f, height * 0.92f)
            cubicTo(
                width * 0.18f,
                height * 0.50f,
                width * 0.35f,
                height * 0.22f,
                width * 0.50f,
                height * 0.08f,
            )
            cubicTo(
                width * 0.65f,
                height * 0.22f,
                width * 0.82f,
                height * 0.50f,
                width * 0.82f,
                height * 0.92f,
            )
        }
        val archPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = layout.dp(1f)
            strokeCap = Paint.Cap.ROUND
            color = withAlpha(palette.accent, if (palette.isLight) 0.10f else 0.075f)
        }
        canvas.drawPath(arch, archPaint)

        drawStar(
            canvas,
            width * 0.96f,
            height * 0.06f,
            min(width, height) * 0.34f,
            withAlpha(palette.ornament, if (palette.isLight) 0.12f else 0.075f),
            layout.dp(1f),
        )
        drawStar(
            canvas,
            width * 0.02f,
            height * 0.98f,
            min(width, height) * 0.23f,
            withAlpha(palette.accent, if (palette.isLight) 0.09f else 0.055f),
            layout.dp(1f),
        )
    }

    private fun drawStar(
        canvas: Canvas,
        centerX: Float,
        centerY: Float,
        outerRadius: Float,
        color: Int,
        strokeWidth: Float,
    ) {
        val star = Path()
        val innerRadius = outerRadius * 0.46f
        repeat(16) { index ->
            val angle = -PI / 2 + index * PI / 8
            val radius = if (index % 2 == 0) outerRadius else innerRadius
            val x = centerX + cos(angle).toFloat() * radius
            val y = centerY + sin(angle).toFloat() * radius
            if (index == 0) star.moveTo(x, y) else star.lineTo(x, y)
        }
        star.close()
        canvas.drawPath(
            star,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                this.color = color
            },
        )
    }

    private fun drawHeader(
        context: Context,
        canvas: Canvas,
        layout: WidgetLayout,
        snapshot: WidgetDataRepository.Snapshot,
    ): Float {
        val palette = snapshot.palette
        val diameterDp = if (layout.expanded) 34f else if (layout.compact) 25f else 29f
        val diameter = layout.dp(diameterDp)
        val top = layout.dp(layout.verticalPadding + if (layout.compact) -2f else -4f)
        val centerY = top + diameter / 2f
        val medallionCenterY = centerY + layout.dp(2f)
        drawMedallion(
            context,
            canvas,
            layout.dp(layout.horizontalPadding) + diameter / 2f,
            medallionCenterY,
            diameter,
            palette,
        )

        val textSize = layout.dp(
            if (layout.compact) 8f else if (layout.expanded) 10f else 8.8f,
        )
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            color = withAlpha(palette.ayah, 0.92f)
            this.textSize = textSize
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }
        val capsuleHeight = layout.dp(if (layout.compact) 20f else 23f)
        val horizontalInset = layout.dp(if (layout.compact) 8f else 10f)
        val dotSize = layout.dp(3.5f)
        val dotGap = layout.dp(5f)
        val maxCapsuleWidth = layout.widthPx * 0.57f
        val maxTextWidth = (
            maxCapsuleWidth - horizontalInset * 2f - dotSize - dotGap
            ).coerceAtLeast(layout.dp(28f))
        val reference = TextUtils.ellipsize(
            snapshot.displayReference,
            textPaint,
            maxTextWidth,
            TextUtils.TruncateAt.END,
        ).toString()
        val textWidth = textPaint.measureText(reference)
        val capsuleWidth = (
            horizontalInset * 2f + dotSize + dotGap + textWidth
            ).coerceAtMost(maxCapsuleWidth)
        val right = layout.widthPx - layout.dp(layout.horizontalPadding)
        val capsule = RectF(
            right - capsuleWidth,
            centerY - capsuleHeight / 2f,
            right,
            centerY + capsuleHeight / 2f,
        )
        val capsuleRadius = capsuleHeight / 2f
        canvas.drawRoundRect(
            capsule,
            capsuleRadius,
            capsuleRadius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = withAlpha(palette.ayah, if (palette.isLight) 0.055f else 0.075f)
            },
        )
        canvas.drawRoundRect(
            capsule,
            capsuleRadius,
            capsuleRadius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = layout.dp(0.75f)
                color = withAlpha(palette.ayah, 0.14f)
            },
        )
        val contentLeft = capsule.left + horizontalInset
        canvas.drawCircle(
            contentLeft + dotSize / 2f,
            centerY,
            dotSize / 2f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = palette.ornament },
        )
        val referenceLayout = createLayout(
            reference,
            textPaint,
            (textWidth + 1f).roundToInt().coerceAtLeast(1),
            maxLines = 1,
            rtl = snapshot.appLanguage == "ar" || snapshot.appLanguage == "ur",
            lineSpacingExtraPx = 0f,
        )
        drawLayout(
            canvas,
            referenceLayout,
            contentLeft + dotSize + dotGap,
            centerY - referenceLayout.height / 2f,
        )
        return top + diameter
    }

    private fun drawMedallion(
        context: Context,
        canvas: Canvas,
        centerX: Float,
        centerY: Float,
        diameter: Float,
        palette: QuranWidgetPalette,
    ) {
        val radius = diameter / 2f
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                centerX,
                centerY,
                radius,
                withAlpha(palette.accent, 0.22f),
                withAlpha(palette.ayah, 0.06f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawCircle(centerX, centerY, radius, fill)
        canvas.drawCircle(
            centerX,
            centerY,
            radius - 0.5f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = (diameter * 0.026f).coerceAtLeast(1f)
                color = withAlpha(palette.accent, 0.38f)
            },
        )

        val iconInset = diameter * 0.15f
        ContextCompat.getDrawable(context, R.drawable.huda_icon)?.mutate()?.let { logo ->
            logo.setTint(withAlpha(palette.ayah, 0.96f))
            logo.bounds = android.graphics.Rect(
                (centerX - radius + iconInset).roundToInt(),
                (centerY - radius + iconInset).roundToInt(),
                (centerX + radius - iconInset).roundToInt(),
                (centerY + radius - iconInset).roundToInt(),
            )
            logo.draw(canvas)
        }
    }

    private fun drawVerse(
        context: Context,
        canvas: Canvas,
        widget: WidgetLayout,
        snapshot: WidgetDataRepository.Snapshot,
        headerBottom: Float,
    ) {
        val contentLeft = widget.dp(widget.horizontalPadding)
        val contentWidth = (widget.widthPx - contentLeft * 2f).roundToInt().coerceAtLeast(1)
        val contentTop = headerBottom + widget.dp(widget.headerGap)
        val contentBottom = widget.heightPx - widget.dp(widget.verticalPadding)
        val availableHeight = (contentBottom - contentTop).roundToInt().coerceAtLeast(1)
        val arabicTypeface = ResourcesCompat.getFont(
            context,
            if (snapshot.ayahBold) R.font.amiri_bold else R.font.amiri,
        ) ?: Typeface.SERIF
        val translationTypeface = Typeface.create(
            "sans-serif",
            if (snapshot.translationBold) Typeface.BOLD else Typeface.NORMAL,
        )
        val arabicBase = when {
            widget.expanded -> 27f
            widget.compact -> 17f
            else -> 20f
        }
        val translationBase = when {
            widget.expanded -> 13f
            widget.compact -> 9f
            else -> 10.5f
        }
        var arabicSp = arabicBase * if (snapshot.ayahAutoFit) 1f else snapshot.ayahTextSize / 100f
        var translationSp = translationBase *
            if (snapshot.translationAutoFit) 1f else snapshot.translationTextSize / 100f
        val arabicMaxLines = when {
            widget.expanded -> 4
            widget.micro -> 2
            else -> 3
        }
        val translationMaxLines = when {
            widget.expanded -> 5
            widget.micro -> 1
            else -> if (widget.compact) 2 else 3
        }
        var arabicLines = arabicMaxLines
        var translationLines = translationMaxLines
        var translation = snapshot.translation?.takeIf { it.isNotBlank() }
        val dividerHeight = widget.dp(widget.dividerHeight).roundToInt()

        fun arabicPaint() = textPaint(
            color = snapshot.palette.ayah,
            sizePx = widget.dp(arabicSp),
            typeface = arabicTypeface,
        )
        fun translationPaint() = textPaint(
            color = withAlpha(snapshot.palette.translation, 0.90f),
            sizePx = widget.dp(translationSp),
            typeface = translationTypeface,
        )
        fun arabicLayout() = createLayout(
            snapshot.verse.arabic,
            arabicPaint(),
            contentWidth,
            arabicLines,
            rtl = true,
            lineSpacingExtraPx = widget.dp(widget.arabicLineSpacing),
        )
        fun translationLayout() = translation?.let {
            createLayout(
                it,
                translationPaint(),
                contentWidth,
                translationLines,
                rtl = snapshot.translationLanguage == "ur",
                lineSpacingExtraPx = widget.dp(widget.translationLineSpacing),
            )
        }
        fun totalHeight(): Int = arabicLayout().height +
            (translationLayout()?.let { dividerHeight + it.height } ?: 0)

        for (attempt in 0 until 120) {
            if (totalHeight() <= availableHeight) break
            when {
                snapshot.translationAutoFit && translation != null &&
                    translationSp > TRANSLATION_AUTO_FLOOR_SP -> translationSp -= 0.5f
                snapshot.ayahAutoFit && arabicSp > ARABIC_AUTO_FLOOR_SP -> arabicSp -= 0.5f
                else -> break
            }
        }

        while (translation != null && totalHeight() > availableHeight && translationLines > 1) {
            translationLines -= 1
        }
        while (totalHeight() > availableHeight && arabicLines > 1) {
            arabicLines -= 1
        }

        val arabicWouldTruncate = createLayout(
            snapshot.verse.arabic,
            arabicPaint(),
            contentWidth,
            Int.MAX_VALUE,
            rtl = true,
            lineSpacingExtraPx = widget.dp(widget.arabicLineSpacing),
        ).lineCount > arabicLines
        val translationWouldTruncate = translation?.let {
            createLayout(
                it,
                translationPaint(),
                contentWidth,
                Int.MAX_VALUE,
                rtl = snapshot.translationLanguage == "ur",
                lineSpacingExtraPx = widget.dp(widget.translationLineSpacing),
            ).lineCount > translationLines
        } ?: false
        if (
            translation != null &&
            widget.compact &&
            (totalHeight() > availableHeight || arabicWouldTruncate || translationWouldTruncate)
        ) {
            translation = null
            arabicLines = arabicMaxLines
            if (snapshot.ayahAutoFit) arabicSp = arabicBase
            while (totalHeight() > availableHeight && arabicSp > ARABIC_AUTO_FLOOR_SP) {
                arabicSp = (arabicSp - 0.5f).coerceAtLeast(ARABIC_AUTO_FLOOR_SP)
            }
            while (totalHeight() > availableHeight && arabicLines > 1) {
                arabicLines -= 1
            }
        }

        val finalArabic = arabicLayout()
        val finalTranslation = translationLayout()
        val finalHeight = finalArabic.height +
            (finalTranslation?.let { dividerHeight + it.height } ?: 0)
        var y = contentTop + ((availableHeight - finalHeight) / 2f).coerceAtLeast(0f)
        drawLayout(canvas, finalArabic, contentLeft, y)
        y += finalArabic.height
        if (finalTranslation != null) {
            drawDivider(canvas, widget, snapshot.palette, y + dividerHeight / 2f)
            y += dividerHeight
            drawLayout(canvas, finalTranslation, contentLeft, y)
        }
    }

    private fun textPaint(color: Int, sizePx: Float, typeface: Typeface) =
        TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            this.color = color
            textSize = sizePx
            this.typeface = typeface
        }

    private fun createLayout(
        text: String,
        paint: TextPaint,
        width: Int,
        maxLines: Int,
        rtl: Boolean,
        lineSpacingExtraPx: Float,
    ): StaticLayout = StaticLayout.Builder
        .obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_CENTER)
        .setIncludePad(false)
        .setLineSpacing(lineSpacingExtraPx, 1f)
        .setTextDirection(if (rtl) TextDirectionHeuristics.RTL else TextDirectionHeuristics.LTR)
        .setMaxLines(maxLines.coerceAtLeast(1))
        .setEllipsize(TextUtils.TruncateAt.END)
        .build()

    private fun drawLayout(canvas: Canvas, layout: StaticLayout, x: Float, y: Float) {
        canvas.save()
        canvas.translate(x, y)
        layout.draw(canvas)
        canvas.restore()
    }

    private fun drawDivider(
        canvas: Canvas,
        widget: WidgetLayout,
        palette: QuranWidgetPalette,
        centerY: Float,
    ) {
        val lineWidth = widget.dp(if (widget.compact) 26f else 34f)
        val gap = widget.dp(5f)
        val dotRadius = widget.dp(1.5f)
        val centerX = widget.widthPx / 2f
        val stroke = widget.dp(0.75f).coerceAtLeast(1f)
        val leftStart = centerX - dotRadius - gap - lineWidth
        val leftEnd = centerX - dotRadius - gap
        val rightStart = centerX + dotRadius + gap
        val rightEnd = rightStart + lineWidth
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { strokeWidth = stroke }
        paint.shader = LinearGradient(
            leftStart,
            centerY,
            leftEnd,
            centerY,
            Color.TRANSPARENT,
            withAlpha(palette.accent, 0.58f),
            Shader.TileMode.CLAMP,
        )
        canvas.drawLine(leftStart, centerY, leftEnd, centerY, paint)
        paint.shader = LinearGradient(
            rightStart,
            centerY,
            rightEnd,
            centerY,
            withAlpha(palette.accent, 0.58f),
            Color.TRANSPARENT,
            Shader.TileMode.CLAMP,
        )
        canvas.drawLine(rightStart, centerY, rightEnd, centerY, paint)
        paint.shader = null
        paint.color = withAlpha(palette.ornament, 0.92f)
        canvas.drawCircle(centerX, centerY, dotRadius, paint)
    }

    private fun withAlpha(color: Int, alpha: Float): Int {
        val channel = (alpha.coerceIn(0f, 1f) * 255).roundToInt()
        return (color and 0x00FFFFFF) or (channel shl 24)
    }

    private class WidgetLayout(
        val widthDp: Float,
        val heightDp: Float,
        private val scale: Float,
    ) {
        val widthPx = widthDp * scale
        val heightPx = heightDp * scale
        val emergency = widthDp < 120f || heightDp < 64f
        val micro = widthDp < 220f || heightDp < 112f
        val compact = widthDp < 330f || heightDp < 172f
        val expanded = widthDp >= 280f && heightDp >= 235f
        val horizontalPadding = when {
            expanded -> 24f
            micro -> 10f
            compact -> 14f
            else -> 18f
        }
        val verticalPadding = when {
            expanded -> 20f
            micro -> 6f
            compact -> 7f
            else -> 10f
        }
        val headerGap = when {
            expanded -> 13f
            micro -> 1f
            compact -> 2f
            else -> 4f
        }
        val arabicLineSpacing = when {
            expanded -> 7f
            micro -> 2f
            compact -> 2.5f
            else -> 4f
        }
        val translationLineSpacing = when {
            expanded -> 2f
            micro -> 1f
            compact -> 1f
            else -> 1.5f
        }
        val dividerHeight = when {
            expanded -> 11f
            micro -> 6f
            compact -> 7f
            else -> 9f
        }

        fun dp(value: Float): Float = value * scale
    }
}
