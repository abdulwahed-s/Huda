package com.aw.huda.widget.prayer

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.SpannableString
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
import android.text.style.MetricAffectingSpan
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import com.aw.huda.R
import java.util.Date
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

internal object PrayerWidgetCanvasRenderer {
    enum class CountdownAlignment { CENTER, END }

    data class CountdownOverlay(
        val leftDp: Float,
        val topDp: Float,
        val widthDp: Float,
        val heightDp: Float,
        val canvasWidthDp: Float,
        val canvasHeightDp: Float,
        val textSizeDp: Float,
        val color: Int,
        val alignment: CountdownAlignment,
        val rtl: Boolean,
        val counterMode: PrayerWidgetCounterMode,
        val anchorEpochMillis: Long,
    )

    data class Rendered(
        val bitmap: Bitmap,
        val accessibilityLabel: String,
        val countdownOverlay: CountdownOverlay?,
    )

    fun render(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        family: WidgetFamily,
        widthDp: Float,
        heightDp: Float,
        now: Date = Date(),
        includeStaticCountdown: Boolean = true,
    ): Rendered {
        val safeWidth = widthDp.coerceAtLeast(36f)
        val safeHeight = heightDp.coerceAtLeast(36f)
        val metrics = context.resources.displayMetrics
        val rasterScale = min(
            metrics.density,
            min(metrics.widthPixels / safeWidth, metrics.heightPixels / safeHeight),
        ).coerceIn(0.5f, 3f)
        val bitmap = Bitmap.createBitmap(
            (safeWidth * rasterScale).roundToInt().coerceAtLeast(1),
            (safeHeight * rasterScale).roundToInt().coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        val state = PrayerWidgetRenderState.build(context, snapshot, now)
        val theme = PrayerWidgetTheme.resolve(context, snapshot)
        val palette = PrayerWidgetPaletteResolver.resolve(theme)
        val drawing = Drawing(
            context = context,
            canvas = Canvas(bitmap),
            widthDp = safeWidth,
            heightDp = safeHeight,
            scale = rasterScale,
            family = family,
            state = state,
            palette = palette,
            glassify = theme.glassify,
            includeStaticCountdown = includeStaticCountdown,
        )
        drawing.draw()
        return Rendered(bitmap, state.accessibilityLabel, drawing.countdownOverlay)
    }

    private class Drawing(
        private val context: Context,
        private val canvas: Canvas,
        private val widthDp: Float,
        private val heightDp: Float,
        private val scale: Float,
        private val family: WidgetFamily,
        private val state: PrayerWidgetRenderState,
        private val palette: PrayerWidgetPalette,
        private val glassify: Boolean,
        private val includeStaticCountdown: Boolean,
    ) {
        private val width = dp(widthDp)
        private val height = dp(heightDp)
        private val sans = Typeface.create("sans-serif", Typeface.NORMAL)
        private val medium = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        private val bold = Typeface.create("sans-serif", Typeface.BOLD)
        private val mono = Typeface.create("monospace", Typeface.BOLD)
        private val numericTypeface = runCatching {
            ResourcesCompat.getFont(context, R.font.amiri_bold)
        }.getOrNull() ?: mono
        private val amiri = ResourcesCompat.getFont(context, R.font.amiri) ?: Typeface.SERIF
        private val amiriBold = ResourcesCompat.getFont(context, R.font.amiri_bold)
            ?: Typeface.create(Typeface.SERIF, Typeface.BOLD)
        private val contentScale = state.contentScale
        private val outerCornerRadiusDp = (
                context.resources.getDimension(R.dimen.prayer_widget_outer_corner_radius) /
                        context.resources.displayMetrics.density.coerceAtLeast(0.1f)
                )
        var countdownOverlay: CountdownOverlay? = null
            private set

        fun draw() {
            drawAtmosphere()
            if (widthDp < 56f || heightDp < 48f) {
                drawEmergency()
                return
            }
            if (state.empty) {
                drawEmpty()
                return
            }
            when (state.design) {
                PrayerWidgetDesign.HERO -> drawSpotlight()
                PrayerWidgetDesign.COMPACT -> drawAlmanac()
            }
        }

        private fun drawAtmosphere() {
            val radius = dp(min(outerCornerRadiusDp, min(widthDp, heightDp) / 2f))
            val bounds = RectF(0f, 0f, width, height)
            val clip = Path().apply { addRoundRect(bounds, radius, radius, Path.Direction.CW) }
            canvas.save()
            canvas.clipPath(clip)

            if (!palette.transparent) {
                val base = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        0f,
                        0f,
                        width,
                        height,
                        if (state.design == PrayerWidgetDesign.HERO) {
                            intArrayOf(palette.surface, palette.gradientEnd, palette.gradientEnd)
                        } else {
                            intArrayOf(palette.raised, palette.surface, palette.gradientEnd)
                        },
                        floatArrayOf(0f, 0.55f, 1f),
                        Shader.TileMode.CLAMP,
                    )
                }
                canvas.drawRect(bounds, base)
            }

            val accentCenterX =
                if (state.design == PrayerWidgetDesign.HERO) width * 0.78f else width * 0.12f
            val accentCenterY =
                if (state.design == PrayerWidgetDesign.HERO) height * 0.30f else height * 0.04f
            val atmosphereAlpha =
                if (palette.transparent) 0.08f else if (palette.isLight) 0.16f else 0.24f
            canvas.drawRect(bounds, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    accentCenterX,
                    accentCenterY,
                    maxOf(width, height) * 0.72f,
                    PrayerWidgetPaletteResolver.withAlpha(palette.accent, atmosphereAlpha),
                    Color.TRANSPARENT,
                    Shader.TileMode.CLAMP,
                )
            })
            canvas.drawRect(bounds, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    width * 0.92f,
                    0f,
                    maxOf(width, height) * 0.42f,
                    PrayerWidgetPaletteResolver.withAlpha(
                        palette.gold,
                        if (palette.transparent) 0.05f else 0.15f
                    ),
                    Color.TRANSPARENT,
                    Shader.TileMode.CLAMP,
                )
            })

            if (glassify && !palette.transparent) {
                canvas.drawRect(bounds, Paint().apply {
                    shader = LinearGradient(
                        0f,
                        0f,
                        0f,
                        height,
                        PrayerWidgetPaletteResolver.withAlpha(Color.WHITE, 0.09f),
                        Color.TRANSPARENT,
                        Shader.TileMode.CLAMP,
                    )
                })
            }
            drawGeometry()
            canvas.restore()

            val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(1f)
                shader = LinearGradient(
                    0f,
                    0f,
                    width,
                    height,
                    intArrayOf(
                        PrayerWidgetPaletteResolver.withAlpha(palette.accent, 0.58f),
                        PrayerWidgetPaletteResolver.withAlpha(palette.text, 0.10f),
                        PrayerWidgetPaletteResolver.withAlpha(palette.gold, 0.34f),
                    ),
                    null,
                    Shader.TileMode.CLAMP,
                )
            }
            val borderInset = dp(1f)
            canvas.drawRoundRect(
                RectF(borderInset, borderInset, width - borderInset, height - borderInset),
                (radius - borderInset).coerceAtLeast(0f),
                (radius - borderInset).coerceAtLeast(0f),
                stroke,
            )
            val inner = dp(2f)
            canvas.drawRoundRect(
                RectF(inner, inner, width - inner, height - inner),
                (radius - inner).coerceAtLeast(0f),
                (radius - inner).coerceAtLeast(0f),
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = dp(0.7f)
                    color = PrayerWidgetPaletteResolver.withAlpha(
                        palette.text,
                        if (palette.isLight) 0.12f else 0.075f,
                    )
                },
            )
        }

        private fun drawGeometry() {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(0.8f)
                strokeCap = Paint.Cap.ROUND
            }
            if (state.design == PrayerWidgetDesign.HERO) {
                paint.color = PrayerWidgetPaletteResolver.withAlpha(
                    palette.accent,
                    if (palette.isLight) 0.16f else 0.12f,
                )
                val horizon = Path().apply {
                    moveTo(-width * 0.08f, height * 0.73f)
                    cubicTo(
                        width * 0.24f,
                        height * 0.54f,
                        width * 0.67f,
                        height * 0.56f,
                        width * 1.08f,
                        height * 0.78f
                    )
                }
                canvas.drawPath(horizon, paint)
                if (family != WidgetFamily.CIRCULAR && family != WidgetFamily.SMALL) {
                    paint.color = PrayerWidgetPaletteResolver.withAlpha(palette.gold, 0.075f)
                    canvas.drawOval(
                        RectF(width * 0.47f, -height * 0.38f, width * 1.21f, height * 0.72f),
                        paint,
                    )
                }
            } else {
                paint.color = PrayerWidgetPaletteResolver.withAlpha(
                    palette.gold,
                    if (palette.isLight) 0.13f else 0.075f,
                )
                canvas.drawLine(width * 0.18f, 0f, width * 0.18f, height, paint)
                if (family != WidgetFamily.CIRCULAR && family != WidgetFamily.SMALL) {
                    repeat(4) { index ->
                        val y = height * (0.20f + index * 0.19f)
                        canvas.drawLine(0f, y, width, y, paint)
                    }
                    drawStar(width * 0.96f, height * 0.03f, min(width, height) * 0.20f, paint)
                }
            }
        }

        private fun drawStar(cx: Float, cy: Float, radius: Float, paint: Paint) {
            val path = Path()
            repeat(16) { index ->
                val angle = -PI / 2 + index * PI / 8
                val r = if (index % 2 == 0) radius else radius * 0.46f
                val x = cx + cos(angle).toFloat() * r
                val y = cy + sin(angle).toFloat() * r
                if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }
            path.close()
            canvas.drawPath(path, paint)
        }

        private fun verticalFrame(
            referenceHeight: Float,
            minScale: Float = 0.50f,
            maxScale: Float = 1.16f,
        ): VerticalFrame {
            val scale = (heightDp / referenceHeight).coerceIn(minScale, maxScale)
            return VerticalFrame(
                top = (heightDp - referenceHeight * scale) / 2f,
                scale = scale,
            )
        }

        private data class VerticalFrame(
            val top: Float,
            val scale: Float,
        ) {
            fun y(value: Float): Float = top + value * scale
            fun h(value: Float): Float = value * scale
        }

        private fun drawSpotlight() = when (family) {
            WidgetFamily.CIRCULAR -> drawSpotlightOneByOne()
            WidgetFamily.RECTANGULAR -> drawSpotlightWidth()
            WidgetFamily.SMALL -> drawSpotlightSmall()
            WidgetFamily.MEDIUM -> drawSpotlightMedium()
            WidgetFamily.LARGE -> drawSpotlightLarge()
        }

        private fun drawAlmanac() = when (family) {
            WidgetFamily.CIRCULAR -> drawAlmanacOneByOne()
            WidgetFamily.RECTANGULAR -> drawAlmanacWidth()
            WidgetFamily.SMALL -> drawAlmanacSmall()
            WidgetFamily.MEDIUM -> drawAlmanacMedium()
            WidgetFamily.LARGE -> drawAlmanacLarge()
        }

        private fun drawSpotlightOneByOne() {
            val next = state.next ?: return
            val frame = verticalFrame(
                referenceHeight = 96f,
                maxScale = (widthDp / 96f).coerceIn(0.55f, 1.12f),
            )
            drawCelestial(next.kind, widthDp / 2f - 8.5f, frame.y(9f), 17f)
            text(
                next.name.uppercase(locale()),
                8f,
                frame.y(31f),
                widthDp - 16f,
                frame.h(12f),
                9.5f,
                palette.text,
                medium,
                Align.CENTER
            )
            formattedNumericText(
                next.formattedTime,
                7f,
                frame.y(46f),
                widthDp - 14f,
                frame.h(22f),
                20f,
                palette.text,
                Align.CENTER
            )
            pill(17f, frame.y(75f), widthDp - 34f, frame.h(16f), palette.accent, 0.10f, 8f)
            countdownText(
                state.compactCountdown,
                18f,
                frame.y(76f),
                widthDp - 36f,
                frame.h(14f),
                9f,
                Align.CENTER,
            )
        }

        private fun drawSpotlightWidth() {
            val next = state.next ?: return
            val frame = verticalFrame(96f, minScale = 0.50f, maxScale = 1.16f)
            if (widthDp < 320f) {
                drawSpotlightNarrowWidth(next, frame)
                return
            }
            val padding = 12f
            val contentStart = padding + 60f
            val countdownWidth = (widthDp * 0.30f).coerceIn(96f, 112f)
            val countdownX = widthDp - padding - countdownWidth
            val prayerWidth = (countdownX - contentStart - 10f).coerceAtLeast(42f)
            drawCelestial(next.kind, padding, frame.y(28f), 40f)
            line(padding + 48f, frame.y(18f), padding + 48f, frame.y(78f), palette.text, 0.12f)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                contentStart,
                frame.y(20f),
                prayerWidth,
                frame.h(10f),
                7f
            )
            text(
                next.name,
                contentStart,
                frame.y(33f),
                prayerWidth,
                frame.h(18f),
                15f,
                palette.text,
                bold,
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                contentStart,
                frame.y(53f),
                prayerWidth,
                frame.h(23f),
                17f,
                palette.text,
                Align.START
            )
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                countdownX,
                frame.y(25f),
                countdownWidth,
                frame.h(10f),
                6.5f,
                Align.END
            )
            countdownText(
                state.countdown,
                countdownX,
                frame.y(39f),
                countdownWidth,
                frame.h(29f),
                18f,
                Align.END,
            )
        }

        private fun drawSpotlightNarrowWidth(
            next: PrayerWidgetRenderItem,
            frame: VerticalFrame,
        ) {
            val padding = 9f
            val showMark = widthDp >= 200f
            val contentX = if (showMark) 54f else padding
            if (showMark) {
                drawCelestial(next.kind, padding, frame.y(32f), 32f)
                line(47f, frame.y(24f), 47f, frame.y(72f), palette.text, 0.12f)
            }

            val countdownWidth = if (showMark) {
                (widthDp * 0.34f).coerceIn(76f, 96f)
            } else {
                (widthDp * 0.45f).coerceIn(60f, 76f)
            }
            val countdownX = widthDp - padding - countdownWidth
            val primaryWidth = (countdownX - contentX - 5f).coerceAtLeast(24f)

            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                contentX,
                frame.y(23f),
                primaryWidth,
                frame.h(10f),
                6.3f,
            )
            text(
                next.name,
                contentX,
                frame.y(35f),
                primaryWidth,
                frame.h(18f),
                13f,
                palette.text,
                bold,
                Align.START,
            )
            formattedNumericText(
                next.formattedTime,
                contentX,
                frame.y(54f),
                primaryWidth,
                frame.h(21f),
                14f,
                palette.text,
                Align.START,
            )
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                countdownX,
                frame.y(27f),
                countdownWidth,
                frame.h(10f),
                5.7f,
                Align.END,
            )
            countdownText(
                state.countdown,
                countdownX,
                frame.y(39f),
                countdownWidth,
                frame.h(27f),
                if (showMark) 13.5f else 12.5f,
                Align.END,
            )
        }

        private fun drawSpotlightSmall() {
            val next = state.next ?: return
            val frame = verticalFrame(170f, minScale = 0.82f, maxScale = 1.16f)
            drawSpotlightHeader(12f, frame.y(10f), compact = true)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                12f,
                frame.y(39f),
                widthDp - 24f,
                frame.h(13f),
                8f
            )
            text(
                next.name,
                12f,
                frame.y(51f),
                widthDp - 24f,
                frame.h(28f),
                22f,
                palette.text,
                headlineTypeface(),
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                12f,
                frame.y(78f),
                widthDp - 24f,
                frame.h(32f),
                27f,
                palette.text,
                Align.START
            )
            drawCountdownBand(12f, frame.y(115f), widthDp - 24f, frame.h(29f), compact = true)
            state.afterNext?.let { after ->
                drawPhaseDot(after.kind, 13f, frame.y(150f), 11f, false)
                text(
                    after.name,
                    29f,
                    frame.y(148f),
                    widthDp * 0.44f,
                    frame.h(16f),
                    9f,
                    palette.secondary,
                    medium,
                    Align.START
                )
                formattedNumericText(
                    after.formattedTime,
                    widthDp * 0.61f,
                    frame.y(148f),
                    widthDp * 0.31f,
                    frame.h(16f),
                    9f,
                    palette.secondary,
                    Align.END
                )
            }
        }

        private fun drawSpotlightMedium() {
            val next = state.next ?: return
            val frame = verticalFrame(170f, minScale = 0.82f, maxScale = 1.16f)
            val dividerX = widthDp * if (widthDp < 320f) 0.50f else 0.55f
            drawSpotlightHeader(14f, frame.y(11f), compact = true, maxWidth = dividerX - 28f)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                14f,
                frame.y(43f),
                dividerX - 28f,
                frame.h(13f),
                8f
            )
            text(
                next.name,
                14f,
                frame.y(55f),
                dividerX - 28f,
                frame.h(31f),
                25f,
                palette.text,
                headlineTypeface(),
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                14f,
                frame.y(84f),
                dividerX - 28f,
                frame.h(37f),
                29f,
                palette.text,
                Align.START
            )
            drawCountdownBand(14f, frame.y(131f), dividerX - 28f, frame.h(28f), compact = true)
            line(dividerX, frame.y(12f), dividerX, frame.y(158f), palette.text, 0.11f)
            val rows = listOfNotNull(state.current, state.next, state.afterNext)
            val rowHeight = 38f
            val startY = (170f - rows.size * rowHeight) / 2f
            rows.forEachIndexed { index, item ->
                drawTimelineRow(
                    item,
                    dividerX + 11f,
                    frame.y(startY + index * rowHeight),
                    widthDp - dividerX - 23f,
                    frame.h(31f),
                    item.kind == state.next.kind,
                    when (item.kind) {
                        state.current?.kind -> PrayerWidgetLocalization.string(
                            "current",
                            state.locale
                        )

                        state.next.kind -> PrayerWidgetLocalization.string(
                            state.primaryLabelKey,
                            state.locale
                        )

                        else -> null
                    },
                )
                if (index < rows.lastIndex) {
                    line(
                        dividerX + 18f,
                        frame.y(startY + index * rowHeight + 32f),
                        dividerX + 18f,
                        frame.y(startY + index * rowHeight + 38f),
                        palette.line,
                        0.28f,
                    )
                }
            }
        }

        private fun drawSpotlightLarge() {
            val next = state.next ?: return
            val frame = verticalFrame(360f, minScale = 0.90f, maxScale = 1.16f)
            drawSpotlightHeader(16f, frame.y(14f), compact = false)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                16f,
                frame.y(59f),
                widthDp * 0.55f,
                frame.h(15f),
                9f
            )
            text(
                next.name,
                16f,
                frame.y(73f),
                widthDp * 0.60f,
                frame.h(45f),
                36f,
                palette.text,
                headlineTypeface(),
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                16f,
                frame.y(115f),
                widthDp * 0.62f,
                frame.h(46f),
                35f,
                palette.text,
                Align.START
            )
            drawCelestial(next.kind, widthDp - 100f, frame.y(78f), 72f)
            drawCountdownBand(16f, frame.y(166f), widthDp - 32f, frame.h(44f), compact = false)
            label(
                PrayerWidgetLocalization.string("schedule", state.locale),
                16f,
                frame.y(214f),
                widthDp - 32f,
                frame.h(11f),
                8f
            )
            val gap = 8f
            val cellW = (widthDp - 32f - gap) / 2f
            val gridY = 228f
            val rowGap = 4f
            val cellH = (360f - gridY - 14f - rowGap * 2f) / 3f
            state.schedule.forEachIndexed { index, item ->
                val col = index % 2
                val row = index / 2
                drawScheduleCell(
                    item,
                    16f + col * (cellW + gap),
                    frame.y(gridY + row * (cellH + rowGap)),
                    cellW,
                    frame.h(cellH),
                    item.kind == next.kind,
                    compact = true,
                    prominent = true,
                )
            }
        }

        private fun drawAlmanacOneByOne() {
            val next = state.next ?: return
            val frame = verticalFrame(
                referenceHeight = 96f,
                maxScale = (widthDp / 96f).coerceIn(0.55f, 1.12f),
            )
            label(
                state.weekday,
                9f,
                frame.y(13f),
                widthDp * 0.45f,
                frame.h(13f),
                7f,
                Align.START,
                palette.gold
            )
            text(
                state.dateBadge,
                widthDp - 35f,
                frame.y(10f),
                27f,
                frame.h(18f),
                16f,
                palette.text,
                amiriBold,
                Align.END
            )
            line(9f, frame.y(31f), widthDp - 9f, frame.y(31f), palette.gold, 0.34f)
            drawPhaseDot(next.kind, 9f, frame.y(39f), 9f, true)
            text(
                next.name,
                22f,
                frame.y(36f),
                widthDp - 30f,
                frame.h(23f),
                12f,
                palette.text,
                amiriBold,
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                8f,
                frame.y(60f),
                widthDp - 16f,
                frame.h(27f),
                18f,
                palette.text,
                Align.START
            )
        }

        private fun drawAlmanacWidth() {
            val next = state.next ?: return
            val frame = verticalFrame(96f, minScale = 0.50f, maxScale = 1.16f)
            if (widthDp < 320f) {
                drawAlmanacNarrowWidth(next, frame)
                return
            }
            val countdownWidth = (widthDp * 0.30f).coerceIn(98f, 112f)
            val countdownX = widthDp - 12f - countdownWidth
            val contentX = 76f
            val prayerWidth = (countdownX - contentX - 8f).coerceAtLeast(42f)
            label(
                state.weekday,
                13f,
                frame.y(22f),
                42f,
                frame.h(11f),
                7f,
                Align.CENTER,
                palette.gold
            )
            text(
                state.dateBadge,
                13f,
                frame.y(34f),
                42f,
                frame.h(34f),
                27f,
                palette.text,
                amiriBold,
                Align.CENTER
            )
            line(64f, frame.y(18f), 64f, frame.y(78f), palette.gold, 0.34f)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                contentX,
                frame.y(20f),
                prayerWidth,
                frame.h(10f),
                7f
            )
            text(
                next.name,
                contentX,
                frame.y(33f),
                prayerWidth,
                frame.h(18f),
                14.5f,
                palette.text,
                amiriBold,
                Align.START
            )
            formattedNumericText(
                next.formattedTime,
                contentX,
                frame.y(53f),
                prayerWidth,
                frame.h(23f),
                15.5f,
                palette.text,
                Align.START
            )
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                countdownX,
                frame.y(25f),
                countdownWidth,
                frame.h(10f),
                6.5f,
                Align.END
            )
            countdownText(
                state.countdown,
                countdownX,
                frame.y(39f),
                countdownWidth,
                frame.h(29f),
                18f,
                Align.END,
            )
        }

        private fun drawAlmanacNarrowWidth(
            next: PrayerWidgetRenderItem,
            frame: VerticalFrame,
        ) {
            val padding = 9f
            val showDate = widthDp >= 200f
            val contentX = if (showDate) 57f else padding
            if (showDate) {
                label(
                    state.weekday,
                    padding,
                    frame.y(23f),
                    36f,
                    frame.h(10f),
                    6.2f,
                    Align.CENTER,
                    palette.gold,
                )
                text(
                    state.dateBadge,
                    padding,
                    frame.y(35f),
                    36f,
                    frame.h(30f),
                    23f,
                    palette.text,
                    amiriBold,
                    Align.CENTER,
                )
                line(49f, frame.y(22f), 49f, frame.y(74f), palette.gold, 0.34f)
            }

            val countdownWidth = if (showDate) {
                (widthDp * 0.34f).coerceIn(76f, 96f)
            } else {
                (widthDp * 0.45f).coerceIn(60f, 76f)
            }
            val countdownX = widthDp - padding - countdownWidth
            val primaryWidth = (countdownX - contentX - 5f).coerceAtLeast(24f)
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                contentX,
                frame.y(25f),
                primaryWidth,
                frame.h(10f),
                6.2f,
            )
            text(
                next.name,
                contentX,
                frame.y(37f),
                primaryWidth,
                frame.h(18f),
                13f,
                palette.text,
                amiriBold,
                Align.START,
            )
            formattedNumericText(
                next.formattedTime,
                contentX,
                frame.y(56f),
                primaryWidth,
                frame.h(19f),
                13f,
                palette.text,
                Align.START,
            )
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                countdownX,
                frame.y(27f),
                countdownWidth,
                frame.h(10f),
                5.7f,
                Align.END,
            )
            countdownText(
                state.countdown,
                countdownX,
                frame.y(39f),
                countdownWidth,
                frame.h(27f),
                12.5f,
                Align.END,
            )
        }

        private fun drawAlmanacSmall() {
            val frame = verticalFrame(170f, minScale = 0.82f, maxScale = 1.16f)
            drawDateHeader(11f, frame.y(10f), compact = true)
            drawNextBand(11f, frame.y(62f), widthDp - 22f, frame.h(39f), compact = true)
            val contextRows = listOfNotNull(state.current, state.next, state.afterNext)
            contextRows.forEachIndexed { index, item ->
                drawRuleRow(
                    item,
                    12f,
                    frame.y(108f + index * 18f),
                    widthDp - 24f,
                    frame.h(17f),
                    item.kind == state.next?.kind,
                )
            }
        }

        private fun drawAlmanacMedium() {
            val frame = verticalFrame(170f, minScale = 0.82f, maxScale = 1.16f)
            drawDateHeader(12f, frame.y(8f), compact = true)
            val gap = 4f
            val cellW = (widthDp - 24f - gap * 2f) / 3f
            val cellH = 34f
            state.schedule.forEachIndexed { index, item ->
                val col = index % 3
                val row = index / 3
                drawScheduleCell(
                    item,
                    12f + col * (cellW + gap),
                    frame.y(55f + row * (cellH + gap)),
                    cellW,
                    frame.h(cellH),
                    item.kind == state.next?.kind,
                    compact = true,
                    inline = widthDp >= 320f,
                )
            }
            drawNextBand(12f, frame.y(131f), widthDp - 24f, frame.h(31f), compact = true)
        }

        private fun drawAlmanacLarge() {
            val frame = verticalFrame(360f, minScale = 0.90f, maxScale = 1.16f)
            drawDateHeader(16f, frame.y(16f), compact = false)
            drawNextBand(16f, frame.y(91f), widthDp - 32f, frame.h(59f), compact = false)
            label(
                PrayerWidgetLocalization.string("prayer_table", state.locale),
                16f,
                frame.y(166f),
                widthDp - 32f,
                frame.h(12f),
                8f
            )
            val gap = 7f
            val cellW = (widthDp - 32f - gap * 2f) / 3f
            val gridY = 182f
            val rowGap = 7f
            val nightY = 307f
            val cellH = (nightY - 16f - gridY - rowGap) / 2f
            state.schedule.forEachIndexed { index, item ->
                val col = index % 3
                val row = index / 3
                drawScheduleCell(
                    item,
                    16f + col * (cellW + gap),
                    frame.y(gridY + row * (cellH + rowGap)),
                    cellW,
                    frame.h(cellH),
                    item.kind == state.next?.kind,
                    compact = frame.h(cellH) < 47f,
                )
            }
            line(
                16f,
                frame.y(nightY - 11f),
                widthDp - 16f,
                frame.y(nightY - 11f),
                palette.gold,
                0.24f
            )
            val nightGap = 10f
            val nightW = (widthDp - 32f - nightGap) / 2f
            drawNightCell(
                PrayerWidgetLocalization.string("middle_of_night", state.locale),
                state.middleOfNight ?: "--:--",
                PrayerKind.ISHA,
                16f,
                frame.y(nightY),
                nightW,
                frame.h(45f),
            )
            drawNightCell(
                PrayerWidgetLocalization.string("last_third_night", state.locale),
                state.lastThirdOfNight ?: "--:--",
                PrayerKind.FAJR,
                16f + nightW + nightGap,
                frame.y(nightY),
                nightW,
                frame.h(45f),
            )
        }

        private fun drawSpotlightHeader(
            x: Float,
            y: Float,
            compact: Boolean,
            maxWidth: Float = widthDp - x * 2f
        ) {
            val mark = if (compact) 17f else 20f
            drawHudaMark(x, y, mark)
            if (compact) {
                text(
                    PrayerWidgetLocalization.string("huda", state.locale).uppercase(locale()),
                    x + mark + 6f,
                    y,
                    maxWidth * 0.58f,
                    mark,
                    8f,
                    palette.secondary,
                    medium,
                    Align.START,
                )
            } else {
                mixedNumericText(
                    state.dateLong,
                    x + mark + 6f,
                    y,
                    maxWidth * 0.58f,
                    mark,
                    9f,
                    palette.secondary,
                    medium,
                    Align.START,
                )
            }
            state.current?.let { current ->
                val pillWidth = (maxWidth * 0.36f).coerceAtLeast(62f)
                val px = x + maxWidth - pillWidth
                pill(px, y + 1f, pillWidth, mark - 2f, palette.text, 0.065f, mark / 2f)
                text(
                    "${current.name.uppercase(locale())} · ${
                        PrayerWidgetLocalization.string(
                            "current",
                            state.locale
                        ).uppercase(locale())
                    }",
                    px + 5f,
                    y + 1f,
                    pillWidth - 10f,
                    mark - 2f,
                    if (compact) 6.6f else 7.5f,
                    palette.gold,
                    bold,
                    Align.CENTER,
                )
            }
        }

        private fun drawDateHeader(x: Float, y: Float, compact: Boolean) {
            val headerH = if (compact) 42f else 60f
            val dateW = if (compact) 46f else 58f
            label(
                state.weekday,
                x,
                y,
                dateW,
                if (compact) 11f else 13f,
                if (compact) 7f else 9f,
                Align.CENTER,
                palette.gold
            )
            text(
                state.dateBadge,
                x,
                y + if (compact) 10f else 13f,
                dateW,
                if (compact) 29f else 42f,
                if (compact) 21f else 34f,
                palette.text,
                amiriBold,
                Align.CENTER
            )
            line(x + dateW + 5f, y + 3f, x + dateW + 5f, y + headerH - 4f, palette.gold, 0.34f)
            val infoX = x + dateW + 16f
            mixedNumericText(
                state.monthYear,
                infoX,
                y + 5f,
                widthDp - infoX - 42f,
                if (compact) 16f else 20f,
                if (compact) 9f else 11f,
                palette.text,
                bold,
                Align.START,
            )
            val current = state.current
            if (current != null) {
                text(
                    "${current.name} · ${
                        PrayerWidgetLocalization.string("current", state.locale).uppercase(locale())
                    }",
                    infoX,
                    y + if (compact) 21f else 28f,
                    widthDp - infoX - 42f,
                    if (compact) 15f else 19f,
                    if (compact) 8f else 10f,
                    palette.secondary,
                    medium,
                    Align.START,
                )
            }
            drawHudaMark(
                widthDp - x - if (compact) 18f else 22f,
                y + if (compact) 7f else 13f,
                if (compact) 18f else 22f
            )
        }

        private fun drawCountdownBand(x: Float, y: Float, w: Float, h: Float, compact: Boolean) {
            pill(
                x,
                y,
                w,
                h,
                palette.accent,
                if (palette.isLight) 0.12f else 0.11f,
                if (compact) 12f else 16f,
                strokeAlpha = 0.25f
            )
            if (compact && w < 132f) {
                circle(x + 12f, y + h / 2f, 2.4f, palette.gold)
                countdownText(
                    state.countdown,
                    x + 21f,
                    y,
                    w - 30f,
                    h,
                    13f,
                    Align.END,
                )
                return
            }
            circle(x + 13f, y + h / 2f, if (compact) 2.4f else 3f, palette.gold)
            val rightInset = if (compact) 8f else 12f
            val countdownWidth = if (compact) {
                (w * 0.48f).coerceIn(68f, 92f)
            } else {
                (w * 0.42f).coerceIn(120f, 170f)
            }
            val countdownX = x + w - rightInset - countdownWidth
            val labelX = x + 21f
            val labelWidth = (countdownX - labelX - 7f).coerceAtLeast(24f)
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                labelX,
                y,
                labelWidth,
                h,
                if (compact) 6.5f else 9f,
            )
            countdownText(
                state.countdown,
                countdownX,
                y,
                countdownWidth,
                h,
                if (compact) 14f else 21f,
                Align.END,
            )
        }

        private fun drawNextBand(x: Float, y: Float, w: Float, h: Float, compact: Boolean) {
            val next = state.next ?: return
            pill(
                x,
                y,
                w,
                h,
                palette.accent,
                if (palette.isLight) 0.11f else 0.10f,
                if (compact) 10f else 14f,
                strokeAlpha = 0.22f
            )
            val dot = if (compact) 13f else 18f
            drawPhaseDot(next.kind, x + if (compact) 8f else 11f, y + (h - dot) / 2f, dot, true)
            val infoX = x + if (compact) 27f else 39f
            val rightInset = if (compact) 8f else 12f
            val countdownWidth = when {
                compact && w < 190f -> (w * 0.42f).coerceIn(56f, 68f)
                compact -> (w * 0.29f).coerceIn(76f, 94f)
                else -> (w * 0.30f).coerceIn(96f, 116f)
            }
            val countdownX = x + w - rightInset - countdownWidth
            val infoWidth = (countdownX - infoX - if (compact) 5f else 8f).coerceAtLeast(28f)
            val nextValue =
                if (compact && w < 190f) next.name else "${next.name}  ${next.formattedTime}"
            label(
                PrayerWidgetLocalization.string(state.primaryLabelKey, state.locale),
                infoX,
                y + if (compact) 4f else 7f,
                w * 0.42f,
                if (compact) 11f else 13f,
                if (compact) 6.4f else 8f
            )
            text(
                nextValue,
                infoX,
                y + if (compact) 15f else 21f,
                infoWidth,
                h - if (compact) 17f else 24f,
                if (compact) 11f else 17f,
                palette.text,
                amiriBold,
                Align.START
            )
            val labelHeight = if (compact) 10f else 12f
            val valueHeight = if (compact) 17f else 26f
            val blockGap = if (compact) 1f else 2f
            val blockTop = y + (h - labelHeight - blockGap - valueHeight) / 2f
            label(
                PrayerWidgetLocalization.string(state.counterLabelKey, state.locale),
                countdownX,
                blockTop,
                countdownWidth,
                labelHeight,
                if (compact) 5.7f else 7f,
                Align.END
            )
            countdownText(
                state.countdown,
                countdownX,
                blockTop + labelHeight + blockGap,
                countdownWidth,
                valueHeight,
                if (compact) 11.5f else 18f,
                Align.END,
            )
        }

        private fun drawTimelineRow(
            item: PrayerWidgetRenderItem,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            highlighted: Boolean,
            stateLabel: String?
        ) {
            if (highlighted) pill(x, y, w, h, palette.accent, 0.12f, 10f)
            val narrow = w < 118f
            val dot = if (narrow) 11f else 13f
            val dotX = x + if (narrow) 4f else 6f
            val contentX = x + if (narrow) 20f else 25f
            val timeWidth = (w * if (narrow) 0.40f else 0.34f).coerceIn(36f, 52f)
            val timeX = x + w - timeWidth - 4f
            val nameWidth = (timeX - contentX - 4f).coerceAtLeast(18f)
            drawPhaseDot(item.kind, dotX, y + (h - dot) / 2f, dot, highlighted)
            text(
                item.name,
                contentX,
                y + 4f,
                nameWidth,
                if (stateLabel == null) h - 8f else 14f,
                if (narrow) 9.5f else 10f,
                if (highlighted) palette.text else palette.secondary,
                if (highlighted) bold else medium,
                Align.START
            )
            if (stateLabel != null) label(
                stateLabel,
                contentX,
                y + 17f,
                nameWidth,
                9f,
                5.8f,
                Align.START,
                if (highlighted) palette.accent else palette.secondary
            )
            formattedNumericText(
                item.formattedTime,
                timeX,
                y + 5f,
                timeWidth,
                h - 10f,
                9f,
                if (highlighted) palette.accent else palette.secondary,
                Align.END
            )
        }

        private fun drawScheduleCell(
            item: PrayerWidgetRenderItem,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            highlighted: Boolean,
            compact: Boolean,
            inline: Boolean = false,
            prominent: Boolean = false,
        ) {
            val background = if (highlighted) palette.accent else palette.text
            pill(
                x,
                y,
                w,
                h,
                background,
                if (highlighted) 0.11f else if (palette.isLight) 0.04f else 0.05f,
                if (compact) 8f else 11f
            )
            if (inline) {
                val dot = 10f
                val nameX = x + 20f
                val timeWidth = (w * 0.42f).coerceIn(42f, 52f)
                val timeX = x + w - timeWidth - 6f
                val nameWidth = (timeX - nameX - 4f).coerceAtLeast(18f)
                drawPhaseDot(item.kind, x + 6f, y + (h - dot) / 2f, dot, highlighted)
                text(
                    item.name,
                    nameX,
                    y + 4f,
                    nameWidth,
                    h - 8f,
                    10f,
                    if (highlighted) palette.text else if (item.kind == PrayerKind.SUNRISE) palette.gold else palette.secondary,
                    if (highlighted) bold else medium,
                    Align.START,
                )
                formattedNumericText(
                    item.formattedTime,
                    timeX,
                    y + 4f,
                    timeWidth,
                    h - 8f,
                    10f,
                    if (highlighted) palette.accent else palette.text,
                    Align.END,
                )
                return
            }
            val dot = when {
                prominent -> 12f
                compact -> 9f
                else -> 11f
            }
            val dotX = x + when {
                prominent -> 7f
                compact -> 6f
                else -> 8f
            }
            val dotY = y + when {
                prominent -> (h - dot) / 2f
                compact -> 5f
                else -> 8f
            }
            drawPhaseDot(item.kind, dotX, dotY, dot, highlighted)
            if (prominent) {
                val nameX = x + 21f
                val timeWidth = (w * 0.38f).coerceIn(48f, 62f)
                val timeX = x + w - 8f - timeWidth
                val nameWidth = (timeX - nameX - 3f).coerceAtLeast(18f)
                text(
                    item.name,
                    nameX,
                    y,
                    nameWidth,
                    h,
                    11f,
                    if (highlighted) palette.text else palette.secondary,
                    if (highlighted) bold else medium,
                    Align.START
                )
                formattedNumericText(
                    item.formattedTime,
                    timeX,
                    y,
                    timeWidth,
                    h,
                    11.5f,
                    if (highlighted) palette.accent else palette.text,
                    Align.END
                )
                return
            }
            text(
                item.name,
                x + if (compact) 19f else 24f,
                y + if (compact) 3f else 6f,
                w - if (compact) 24f else 30f,
                if (compact) 14f else 19f,
                if (compact) 7.5f else 10.5f,
                if (highlighted) palette.text else if (item.kind == PrayerKind.SUNRISE) palette.gold else palette.secondary,
                if (highlighted) bold else medium,
                Align.START
            )
            formattedNumericText(
                item.formattedTime,
                x + if (compact) 7f else 9f,
                y + if (compact) 16f else 27f,
                w - if (compact) 14f else 18f,
                if (compact) 14f else 20f,
                if (compact) 8.5f else 12.5f,
                if (highlighted) palette.accent else palette.text,
                Align.START
            )
        }

        private fun drawRuleRow(
            item: PrayerWidgetRenderItem,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            highlighted: Boolean
        ) {
            drawPhaseDot(item.kind, x, y + 4f, 9f, highlighted)
            text(
                item.name,
                x + 14f,
                y,
                w * 0.56f,
                h,
                8.5f,
                if (highlighted) palette.accent else palette.secondary,
                if (highlighted) bold else medium,
                Align.START
            )
            formattedNumericText(
                item.formattedTime,
                x + w * 0.66f,
                y,
                w * 0.34f,
                h,
                8.5f,
                if (highlighted) palette.accent else palette.text,
                Align.END
            )
        }

        private fun drawNightCell(
            label: String,
            time: String,
            iconKind: PrayerKind,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
        ) {
            pill(x, y, w, h, palette.text, if (palette.isLight) 0.04f else 0.05f, 11f)
            drawLegacyPrayerIcon(iconKind, x + 8f, y + 11f, 22f, palette.gold)
            text(label, x + 38f, y + 7f, w - 44f, 14f, 7.5f, palette.secondary, medium, Align.START)
            formattedNumericText(
                time,
                x + 38f,
                y + 20f,
                w - 44f,
                20f,
                12f,
                palette.text,
                Align.START
            )
        }

        private fun drawEmpty() {
            val tiny = family == WidgetFamily.CIRCULAR || widthDp < 120f || heightDp < 72f
            if (tiny) {
                drawHudaMark(widthDp / 2f - 12f, heightDp * 0.20f, 24f)
                numericText(
                    "--:--",
                    8f,
                    heightDp * 0.48f,
                    widthDp - 16f,
                    24f,
                    17f,
                    palette.text,
                    Align.CENTER
                )
                return
            }
            drawHudaMark(widthDp / 2f - 17f, heightDp * 0.18f, 34f)
            val message = PrayerWidgetLocalization.string("empty_message", state.locale)
            multiline(
                message,
                18f,
                heightDp * 0.45f,
                widthDp - 36f,
                heightDp * 0.38f,
                if (family == WidgetFamily.LARGE) 15f else 12f,
                palette.text,
                medium,
                3
            )
        }

        private fun drawEmergency() {
            drawHudaMark(
                widthDp / 2f - min(widthDp, heightDp) * 0.18f,
                heightDp / 2f - min(widthDp, heightDp) * 0.18f,
                min(widthDp, heightDp) * 0.36f
            )
        }

        private fun drawHudaMark(x: Float, y: Float, diameter: Float) {
            val rect = logicalRect(x, y, diameter, diameter)
            val radius = rect.width() / 2f
            circlePx(
                rect.centerX(),
                rect.centerY(),
                radius,
                PrayerWidgetPaletteResolver.withAlpha(palette.accent, 0.12f)
            )
            canvas.drawCircle(
                rect.centerX(),
                rect.centerY(),
                radius - dp(0.4f),
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = dp(0.65f)
                    color = PrayerWidgetPaletteResolver.withAlpha(palette.accent, 0.30f)
                })
            ContextCompat.getDrawable(context, R.drawable.huda_icon)?.mutate()?.let { logo ->
                logo.setTint(PrayerWidgetPaletteResolver.withAlpha(palette.text, 0.95f))
                val inset = rect.width() * 0.17f
                logo.bounds = Rect(
                    (rect.left + inset).roundToInt(),
                    (rect.top + inset).roundToInt(),
                    (rect.right - inset).roundToInt(),
                    (rect.bottom - inset).roundToInt(),
                )
                logo.draw(canvas)
            }
        }

        private fun drawPhaseDot(
            kind: PrayerKind,
            x: Float,
            y: Float,
            diameter: Float,
            highlighted: Boolean,
            physical: Boolean = false
        ) {
            val color =
                if (highlighted) palette.accent else if (kind == PrayerKind.SUNRISE) palette.gold else palette.secondary
            drawLegacyPrayerIcon(kind, x, y, diameter, color, physical)
        }

        private fun drawCelestial(
            kind: PrayerKind,
            x: Float,
            y: Float,
            diameter: Float,
            physical: Boolean = false
        ) {
            drawLegacyPrayerIcon(
                kind,
                x,
                y,
                diameter,
                palette.gold,
                physical,
                insetFraction = 0.08f
            )
        }

        private fun drawLegacyPrayerIcon(
            kind: PrayerKind,
            x: Float,
            y: Float,
            diameter: Float,
            color: Int,
            physical: Boolean = false,
            insetFraction: Float = 0f,
        ) {
            val rect = if (physical) RectF(
                dp(x),
                dp(y),
                dp(x + diameter),
                dp(y + diameter)
            ) else logicalRect(x, y, diameter, diameter)
            val inset = rect.width() * insetFraction
            ContextCompat.getDrawable(context, prayerIconRes(kind))?.mutate()?.let { icon ->
                icon.setTint(color)
                icon.bounds = Rect(
                    (rect.left + inset).roundToInt(),
                    (rect.top + inset).roundToInt(),
                    (rect.right - inset).roundToInt(),
                    (rect.bottom - inset).roundToInt(),
                )
                icon.draw(canvas)
            }
        }

        private fun prayerIconRes(kind: PrayerKind): Int = when (kind) {
            PrayerKind.FAJR -> R.drawable.ic_prayer_fajr
            PrayerKind.SUNRISE -> R.drawable.ic_prayer_sunrise
            PrayerKind.DHUHR -> R.drawable.ic_prayer_dhuhr
            PrayerKind.ASR -> R.drawable.ic_prayer_asr
            PrayerKind.MAGHRIB -> R.drawable.ic_prayer_maghrib
            PrayerKind.ISHA -> R.drawable.ic_prayer_isha
        }

        private fun numericText(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            color: Int,
            align: Align,
            fakeBold: Boolean = false,
            drawText: Boolean = true,
        ): Float = text(
            value = value,
            x = x,
            y = y,
            w = w,
            h = h,
            baseSize = baseSize,
            color = color,
            typeface = numericTypeface,
            align = align,
            fakeBold = fakeBold,
            fitUsingGlyphBounds = true,
            drawText = drawText,
        )

        private fun formattedNumericText(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            color: Int,
            align: Align,
        ): Float = mixedNumericText(
            value = value,
            x = x,
            y = y,
            w = w,
            h = h,
            baseSize = baseSize,
            color = color,
            baseTypeface = mono,
            align = align,
            includeTimeSeparators = true,
        )

        private fun mixedNumericText(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            color: Int,
            baseTypeface: Typeface,
            align: Align,
            includeTimeSeparators: Boolean = false,
        ): Float {
            val numericRanges = mutableListOf<IntRange>()
            var rangeStart = -1
            value.forEachIndexed { index, char ->
                val isTimeSeparator = includeTimeSeparators &&
                        char in charArrayOf(':', '∶', '﹕', '：') &&
                        index > 0 &&
                        index < value.lastIndex &&
                        Character.isDigit(value[index - 1]) &&
                        Character.isDigit(value[index + 1])
                if (Character.isDigit(char) || isTimeSeparator) {
                    if (rangeStart < 0) rangeStart = index
                } else if (rangeStart >= 0) {
                    numericRanges += rangeStart until index
                    rangeStart = -1
                }
            }
            if (rangeStart >= 0) numericRanges += rangeStart until value.length
            if (numericRanges.isEmpty()) {
                return text(value, x, y, w, h, baseSize, color, baseTypeface, align)
            }

            val rect = logicalRect(x, y, w, h)
            if (rect.width() <= 0f || rect.height() <= 0f) return 0f
            val preferred = baseSize * contentScale
            val floor = min(baseSize * 0.50f, preferred)
            var size = preferred
            val styled = SpannableString(value).apply {
                numericRanges.forEach { range ->
                    setSpan(
                        WidgetTypefaceSpan(numericTypeface),
                        range.first,
                        range.last + 1,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
                    )
                }
            }
            val paint = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                this.color = color
                typeface = baseTypeface
            }
            val numericPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                typeface = numericTypeface
            }

            fun fits(): Boolean {
                paint.textSize = dp(size)
                numericPaint.textSize = paint.textSize
                if (Layout.getDesiredWidth(styled, paint) > rect.width()) return false
                val fm = paint.fontMetrics
                if (fm.descent - fm.ascent > rect.height()) return false
                val baseline = rect.centerY() - (fm.ascent + fm.descent) / 2f
                val safety = dp(0.5f)
                return numericRanges.all { range ->
                    val bounds = Rect()
                    numericPaint.getTextBounds(value, range.first, range.last + 1, bounds)
                    baseline + bounds.top >= rect.top + safety &&
                            baseline + bounds.bottom <= rect.bottom - safety
                }
            }
            while (!fits() && size > floor) size = (size - 0.4f).coerceAtLeast(floor)

            paint.textSize = dp(size)
            val rendered = TextUtils.ellipsize(
                styled,
                paint,
                rect.width(),
                TextUtils.TruncateAt.END,
            )
            val layoutWidth = rect.width().roundToInt().coerceAtLeast(1)
            val layout = StaticLayout.Builder.obtain(
                rendered,
                0,
                rendered.length,
                paint,
                layoutWidth,
            )
                .setAlignment(
                    when (align) {
                        Align.CENTER -> Layout.Alignment.ALIGN_CENTER
                        Align.START -> Layout.Alignment.ALIGN_NORMAL
                        Align.END -> Layout.Alignment.ALIGN_OPPOSITE
                    },
                )
                .setIncludePad(false)
                .setTextDirection(if (state.rtl) TextDirectionHeuristics.RTL else TextDirectionHeuristics.LTR)
                .setEllipsize(TextUtils.TruncateAt.END)
                .setEllipsizedWidth(layoutWidth)
                .setMaxLines(1)
                .build()
            val fm = paint.fontMetrics
            val baseline = rect.centerY() - (fm.ascent + fm.descent) / 2f
            canvas.save()
            canvas.clipRect(rect)
            canvas.translate(rect.left, baseline - layout.getLineBaseline(0))
            layout.draw(canvas)
            canvas.restore()
            return size
        }

        private class WidgetTypefaceSpan(
            private val typeface: Typeface,
        ) : MetricAffectingSpan() {
            override fun updateDrawState(paint: TextPaint) {
                paint.typeface = typeface
            }

            override fun updateMeasureState(paint: TextPaint) {
                paint.typeface = typeface
            }
        }

        private fun countdownText(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            align: Align,
        ) {
            val resolvedSize = numericText(
                value = value,
                x = x,
                y = y,
                w = w,
                h = h,
                baseSize = baseSize,
                color = palette.countdownAccent,
                align = align,
                fakeBold = true,
                drawText = includeStaticCountdown,
            )
            val counter = state.counter ?: return
            if (countdownOverlay == null && resolvedSize > 0f) {
                val physicalLeft = if (state.rtl) widthDp - x - w else x
                countdownOverlay = CountdownOverlay(
                    leftDp = physicalLeft,
                    topDp = y,
                    widthDp = w,
                    heightDp = h,
                    canvasWidthDp = widthDp,
                    canvasHeightDp = heightDp,
                    textSizeDp = resolvedSize,
                    color = palette.countdownAccent,
                    alignment = if (align == Align.CENTER) CountdownAlignment.CENTER else CountdownAlignment.END,
                    rtl = state.rtl,
                    counterMode = counter.mode,
                    anchorEpochMillis = counter.anchorEpochMillis,
                )
            }
        }

        private fun label(
            text: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            size: Float,
            align: Align = Align.START,
            color: Int = palette.secondary
        ) {
            this.text(
                text.uppercase(locale()),
                x,
                y,
                w,
                h,
                size,
                color,
                medium,
                align,
                letterSpacing = 0.09f
            )
        }

        private fun text(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            color: Int,
            typeface: Typeface,
            align: Align,
            letterSpacing: Float = 0f,
            fakeBold: Boolean = false,
            fitUsingGlyphBounds: Boolean = false,
            drawText: Boolean = true,
        ): Float {
            if (w <= 0f || h <= 0f || value.isEmpty()) return 0f
            val rect = logicalRect(x, y, w, h)
            val preferred = baseSize * contentScale
            val floor = min(baseSize * 0.50f, preferred)
            var size = preferred
            val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                this.color = color
                this.typeface = typeface
                this.letterSpacing = letterSpacing
                isFakeBoldText = fakeBold
            }

            fun fits(): Boolean {
                paint.textSize = dp(size)
                val fm = paint.fontMetrics
                if (paint.measureText(value) > rect.width()) return false
                if (!fitUsingGlyphBounds) {
                    return fm.descent - fm.ascent <= rect.height()
                }

                val bounds = Rect()
                paint.getTextBounds(value, 0, value.length, bounds)
                val baseline = rect.centerY() - (fm.ascent + fm.descent) / 2f
                val safety = dp(0.5f)
                return baseline + bounds.top >= rect.top + safety &&
                        baseline + bounds.bottom <= rect.bottom - safety
            }
            while (!fits() && size > floor) size = (size - 0.4f).coerceAtLeast(floor)
            paint.textSize = dp(size)
            val rendered = TextUtils.ellipsize(
                value,
                android.text.TextPaint(paint),
                rect.width(),
                TextUtils.TruncateAt.END
            ).toString()
            val physicalAlign = when (align) {
                Align.CENTER -> Paint.Align.CENTER
                Align.START -> if (state.rtl) Paint.Align.RIGHT else Paint.Align.LEFT
                Align.END -> if (state.rtl) Paint.Align.LEFT else Paint.Align.RIGHT
            }
            paint.textAlign = physicalAlign
            val drawX = when (physicalAlign) {
                Paint.Align.CENTER -> rect.centerX()
                Paint.Align.RIGHT -> rect.right
                else -> rect.left
            }
            val fm = paint.fontMetrics
            val baseline = rect.centerY() - (fm.ascent + fm.descent) / 2f
            if (drawText) {
                canvas.save()
                canvas.clipRect(rect)
                canvas.drawText(rendered, drawX, baseline, paint)
                canvas.restore()
            }
            return size
        }

        private fun multiline(
            value: String,
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            baseSize: Float,
            color: Int,
            typeface: Typeface,
            maxLines: Int
        ) {
            val rect = logicalRect(x, y, w, h)
            var size = baseSize * contentScale
            var layout: StaticLayout
            do {
                val paint = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                    this.color = color
                    textSize = dp(size)
                    this.typeface = typeface
                }
                layout = StaticLayout.Builder.obtain(
                    value,
                    0,
                    value.length,
                    paint,
                    rect.width().roundToInt().coerceAtLeast(1)
                )
                    .setAlignment(Layout.Alignment.ALIGN_CENTER)
                    .setIncludePad(false)
                    .setTextDirection(if (state.rtl) TextDirectionHeuristics.RTL else TextDirectionHeuristics.LTR)
                    .setEllipsize(TextUtils.TruncateAt.END)
                    .setMaxLines(maxLines)
                    .build()
                if (layout.height <= rect.height() || size <= baseSize * 0.60f) break
                size -= 0.5f
            } while (true)
            canvas.save()
            canvas.translate(
                rect.left,
                rect.top + ((rect.height() - layout.height) / 2f).coerceAtLeast(0f)
            )
            layout.draw(canvas)
            canvas.restore()
        }

        private fun pill(
            x: Float,
            y: Float,
            w: Float,
            h: Float,
            color: Int,
            alpha: Float,
            radius: Float,
            strokeAlpha: Float = 0f
        ) {
            val rect = logicalRect(x, y, w, h)
            canvas.drawRoundRect(rect, dp(radius), dp(radius), Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = PrayerWidgetPaletteResolver.withAlpha(color, alpha)
            })
            if (strokeAlpha > 0f) {
                canvas.drawRoundRect(
                    rect,
                    dp(radius),
                    dp(radius),
                    Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        style = Paint.Style.STROKE
                        strokeWidth = dp(0.7f)
                        this.color = PrayerWidgetPaletteResolver.withAlpha(color, strokeAlpha)
                    })
            }
        }

        private fun line(x1: Float, y1: Float, x2: Float, y2: Float, color: Int, alpha: Float) {
            val start = logicalPoint(x1, y1)
            val end = logicalPoint(x2, y2)
            canvas.drawLine(
                start.first,
                start.second,
                end.first,
                end.second,
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    strokeWidth = dp(0.8f)
                    this.color = PrayerWidgetPaletteResolver.withAlpha(color, alpha)
                })
        }

        private fun circle(x: Float, y: Float, radius: Float, color: Int) {
            val point = logicalPoint(x, y)
            circlePx(point.first, point.second, dp(radius), color)
        }

        private fun circlePx(x: Float, y: Float, radius: Float, color: Int) {
            canvas.drawCircle(
                x,
                y,
                radius,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color })
        }

        private fun logicalRect(x: Float, y: Float, w: Float, h: Float): RectF {
            val left = if (state.rtl) width - dp(x + w) else dp(x)
            return RectF(left, dp(y), left + dp(w), dp(y + h))
        }

        private fun logicalPoint(x: Float, y: Float): Pair<Float, Float> = Pair(
            if (state.rtl) width - dp(x) else dp(x),
            dp(y),
        )

        private fun headlineTypeface(): Typeface = if (state.rtl) amiriBold else bold
        private fun locale() = java.util.Locale.forLanguageTag(state.locale)
        private fun dp(value: Float): Float = value * scale
    }

    private enum class Align { START, CENTER, END }
}
