package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.aw.huda.R
import com.aw.huda.widget.prayer.NextPrayer
import com.aw.huda.widget.prayer.PrayerTimeFormatter
import com.aw.huda.widget.prayer.PrayerWidgetCalculator
import com.aw.huda.widget.prayer.PrayerWidgetLocalization
import com.aw.huda.widget.prayer.PrayerWidgetSnapshot
import com.aw.huda.widget.prayer.SingleWidgetUpdateResult
import com.aw.huda.widget.prayer.useArabicNumeralsForWidget
import java.util.Date

internal object SamsungPrayerWidgetUpdater {
    private val counterFont by lazy { Typeface.create("sans-serif-condensed", Typeface.BOLD) }
    private val titleFont by lazy { Typeface.create("sans-serif-medium", Typeface.NORMAL) }
    private val clockFont by lazy { Typeface.create("sans-serif-condensed", Typeface.NORMAL) }

    fun futurePrayer(events: List<PrayerWidgetCalculator.PrayerEvent>, now: Date): NextPrayer? =
        events.firstOrNull { it.time.after(now) }?.let { NextPrayer(it.kind, it.time, it.day) }

    fun update(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        expanded: Boolean,
        snapshot: PrayerWidgetSnapshot,
        target: NextPrayer?,
        now: Date,
    ): SingleWidgetUpdateResult = try {
        val options = manager.getAppWidgetOptions(id)
        val viewport = SamsungLockWidgetLayouts.viewport(options, expanded)
        val (views, live) = buildViews(context, expanded, viewport, snapshot, target, now)
        manager.updateAppWidget(id, views)
        Log.i("SamsungPrayerWidget", "id=$id expanded=$expanded viewport=$viewport revision=${snapshot.revision} target=${target?.time?.time} live=$live options=$options")
        SingleWidgetUpdateResult(id, true, if (live) "samsung_live" else "samsung_static")
    } catch (error: Exception) {
        Log.e("SamsungPrayerWidget", "id=$id failed", error)
        SingleWidgetUpdateResult(id, false, "failed", "Samsung prayer widget $id: ${error.message}")
    }

    internal fun buildViews(
        context: Context,
        expanded: Boolean,
        viewport: LockWidgetViewport,
        snapshot: PrayerWidgetSnapshot,
        target: NextPrayer?,
        now: Date,
    ): Pair<RemoteViews, Boolean> {
        val views = RemoteViews(context.packageName,
            if (expanded) R.layout.samsung_prayer_expanded else R.layout.samsung_prayer_compact)
        val language = snapshot.effectiveLocale
        val rtl = PrayerWidgetLocalization.isRTL(language)
        SamsungLockWidgetLayouts.bindDirection(views, rtl)
        SamsungLockWidgetLayouts.bindTap(context, views, "huda://prayer_times")
        val remaining = target?.time?.time?.minus(maxOf(now.time, System.currentTimeMillis())) ?: 0L
        if (!snapshot.hasCoordinates || target == null || remaining <= 0L) {
            val message = SamsungLockWidgetLayouts.text(context,
                if (!snapshot.hasCoordinates) R.string.samsung_lock_setup else R.string.samsung_lock_open_prayer,
                language)
            return staticState(context, views, expanded, viewport, message, message)
        }
        val name = PrayerWidgetLocalization.prayerName(target.kind, language)
        views.setContentDescription(R.id.samsung_lock_root, null)
        val clock = PrayerTimeFormatter.formatForWidget(context, target.time, snapshot.timeFormat,
            snapshot.useArabicNumeralsForWidget(), language, snapshot.displayTimeZone)
        val density = context.resources.displayMetrics.density
        val width = (viewport.widthDp - if (expanded) 12f else 8f).coerceAtLeast(1f) * density
        val height = (viewport.heightDp - 8f).coerceAtLeast(1f) * density
        val scale = snapshot.contentSize.coerceIn(60, 140) / 100f
        val rounded = PrayerTimeFormatter.formatHHMMRoundedUp(now, target.time, snapshot.useArabicNumeralsForWidget())
        fun fallback() = staticState(context, views, expanded, viewport, "$name\n$rounded",
            "${PrayerWidgetLocalization.string("next_prayer", language)}: $name • $clock • $rounded", name)
        val clockSize = if (expanded) LockWidgetTextMetrics.fitLine(context, clock,
            width * 0.55f, 10f * scale, 8.5f, clockFont) ?: return fallback() else 0f
        val clockWidth = if (expanded) LockWidgetTextMetrics.paint(context, clockSize, clockFont)
            .measureText(clock) + 4 * density else 0f
        val nameSize = LockWidgetTextMetrics.fitLine(context, name, width - clockWidth,
            (if (expanded) 11f else 10f) * scale, 9f, titleFont) ?: return fallback()
        views.setTextViewText(R.id.samsung_prayer_name, name)
        views.setViewVisibility(R.id.samsung_prayer_name, View.VISIBLE)
        views.setTextViewTextSize(R.id.samsung_prayer_name, TypedValue.COMPLEX_UNIT_SP, nameSize)
        if (!expanded) views.setViewVisibility(R.id.samsung_prayer_rule, View.VISIBLE)
        if (expanded) {
            views.setTextViewText(R.id.samsung_prayer_time, clock)
            views.setViewVisibility(R.id.samsung_prayer_time, View.VISIBLE)
            views.setTextViewTextSize(R.id.samsung_prayer_time, TypedValue.COMPLEX_UNIT_SP, clockSize)
        }
        val hours = (remaining + 999L) / 3_600_000L
        val sample = if (hours > 0) "${"8".repeat(hours.toString().length)}:88:88" else "88:88"
        val arabicSample = sample.map { if (it in '0'..'9') ('٠'.code + it.digitToInt()).toChar() else it }.joinToString("")
        val latinSize = LockWidgetTextMetrics.fitLine(context, sample, width,
            (if (expanded) 21f else 17f) * scale, 11f, counterFont)
        val arabicSize = LockWidgetTextMetrics.fitLine(context, arabicSample, width,
            (if (expanded) 21f else 17f) * scale, 11f, counterFont)
        var counterSize = if (latinSize != null && arabicSize != null) minOf(latinSize, arabicSize) else null
        val headerHeight = maxOf(LockWidgetTextMetrics.layout(context, name,
            (width - clockWidth).toInt(), nameSize, titleFont).height,
            if (expanded) LockWidgetTextMetrics.layout(context, clock, clockWidth.toInt(), clockSize, clockFont).height else 0)
        fun counterHeight(size: Float) = maxOf(
            LockWidgetTextMetrics.layout(context, sample, width.toInt(), size, counterFont).height,
            LockWidgetTextMetrics.layout(context, arabicSample, width.toInt(), size, counterFont).height)
        while (counterSize != null && counterSize > 11f && headerHeight +
            counterHeight(counterSize) + (if (expanded) 1 else 5) * density > height) {
            counterSize = (counterSize - 0.5f).coerceAtLeast(11f)
        }
        val live = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && counterSize != null &&
            headerHeight + counterHeight(counterSize) +
            (if (expanded) 1 else 5) * density <= height
        if (live) {
            views.setTextViewTextSize(R.id.samsung_prayer_countdown, TypedValue.COMPLEX_UNIT_SP, counterSize!!)
            views.setChronometerCountDown(R.id.samsung_prayer_countdown, true)
            // The duration is mapped on each update; this base is never persisted.
            views.setChronometer(R.id.samsung_prayer_countdown,
                SystemClock.elapsedRealtime() + (target.time.time - System.currentTimeMillis()), "%s", true)
            views.setViewVisibility(R.id.samsung_prayer_countdown, View.VISIBLE)
            views.setViewVisibility(R.id.samsung_prayer_static_counter, View.GONE)
        } else {
            return fallback()
        }
        views.setContentDescription(R.id.samsung_prayer_name,
            "${PrayerWidgetLocalization.string("next_prayer", language)}: $name")
        return views to live
    }

    private fun staticState(context: Context, views: RemoteViews, expanded: Boolean,
        viewport: LockWidgetViewport, message: String, description: String, shorter: String? = null): Pair<RemoteViews, Boolean> {
        val density = context.resources.displayMetrics.density
        val width = ((viewport.widthDp - if (expanded) 12f else 8f) * density).toInt().coerceAtLeast(1)
        val height = ((viewport.heightDp - 8f) * density).toInt().coerceAtLeast(1)
        fun fit(text: String) = LockWidgetTextMetrics.fitBlock(context, text, width, height,
            if (expanded) 13f else 11f, 9f, clockFont)
        var text = message
        var size = fit(text)
        if (size == null && shorter != null) { text = shorter; size = fit(text) }
        if (size == null) { text = "↗"; size = fit(text) ?: 9f }
        views.setChronometer(R.id.samsung_prayer_countdown, 0L, null, false)
        views.setViewVisibility(R.id.samsung_prayer_countdown, View.GONE)
        views.setViewVisibility(R.id.samsung_prayer_name, View.GONE)
        views.setViewVisibility(R.id.samsung_prayer_time, View.GONE)
        if (!expanded) views.setViewVisibility(R.id.samsung_prayer_rule, View.GONE)
        views.setTextViewText(R.id.samsung_prayer_static_counter, text)
        views.setTextViewTextSize(R.id.samsung_prayer_static_counter, TypedValue.COMPLEX_UNIT_SP, size)
        views.setViewVisibility(R.id.samsung_prayer_static_counter, View.VISIBLE)
        views.setContentDescription(R.id.samsung_lock_root, description)
        return views to false
    }
}
