package com.aw.huda.widget.prayer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.text.Spannable
import android.text.SpannableString
import android.text.style.TypefaceSpan
import android.util.DisplayMetrics
import android.util.Log
import android.util.SizeF
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import androidx.core.content.res.ResourcesCompat
import com.aw.huda.MainActivity
import com.aw.huda.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.util.Calendar
import java.util.Date
import kotlin.math.roundToInt

internal enum class WidgetFamily {
    CIRCULAR, RECTANGULAR, SMALL, MEDIUM, LARGE
}

internal object PrayerWidgetUpdater {
    private const val TAG = "PrayerWidgetUpdater"
    private const val DEEP_LINK = "huda://prayer_times"

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrayerWidgetReceiver::class.java),
        )
        if (ids.isEmpty()) {
            Log.d(TAG, "No prayer widgets pinned; skipping update.")
        } else {
            ids.forEach { update(context, manager, it) }
            PrayerWidgetScheduler.ensureAlarmsActive(context)
        }
    }

    fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
        try {
            val snapshot = PrayerWidgetRepository.readSnapshot(context)
            val opts = manager.getAppWidgetOptions(widgetId)

            val (rawWDp, rawHDp) = resolveWidgetSizeDp(context, opts)
            val (wDp, hDp) = normalizeForStableDensity(context, rawWDp, rawHDp)
            val family = classifySize(wDp.toFloat(), hDp.toFloat())
            Log.d(TAG, "[$widgetId] size=${wDp}x${hDp}dp(raw ${rawWDp}x${rawHDp}) family=$family " +
                "minW=${opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)} " +
                "maxW=${opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)} " +
                "minH=${opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)} " +
                "maxH=${opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)} " +
                "density=${context.resources.displayMetrics.density}")

            val theme = if (snapshot.hasCoordinates) PrayerWidgetTheme.resolve(context, snapshot) else null
            val views = buildForFamily(context, snapshot, family)

            val finalViews = renderToBitmap(context, views, wDp, hDp, family, theme)

            manager.updateAppWidget(widgetId, finalViews)
        } catch (e: Exception) {
            Log.e(TAG, "Update failed for $widgetId", e)
        }
    }

    private fun resolveWidgetSizeDp(
        context: Context,
        opts: android.os.Bundle,
    ): Pair<Int, Int> {
        val portrait = context.resources.configuration.orientation ==
            android.content.res.Configuration.ORIENTATION_PORTRAIT

        val w = opts.getInt(
            if (portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
            else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,
        )
        val h = opts.getInt(
            if (portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
            else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
        )
        if (w > 0 && h > 0) return Pair(w, h)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            @Suppress("DEPRECATION")
            val sizes = opts.getParcelableArrayList<SizeF>(
                AppWidgetManager.OPTION_APPWIDGET_SIZES,
            )
            if (!sizes.isNullOrEmpty()) {
                val best = if (portrait) {
                    sizes.maxByOrNull { it.height }
                } else {
                    sizes.maxByOrNull { it.width }
                } ?: sizes.first()
                return Pair(best.width.toInt(), best.height.toInt())
            }
        }

        return Pair(
            maxOf(
                opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH),
                opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH),
            ),
            maxOf(
                opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT),
                opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT),
            ),
        )
    }

    private fun normalizeForStableDensity(context: Context, wDp: Int, hDp: Int): Pair<Int, Int> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return Pair(wDp, hDp)
        val current = context.resources.displayMetrics.densityDpi
        val stable = DisplayMetrics.DENSITY_DEVICE_STABLE
        if (stable <= 0 || current <= 0 || current == stable) return Pair(wDp, hDp)
        val factor = current.toFloat() / stable
        return Pair((wDp * factor).roundToInt(), (hDp * factor).roundToInt())
    }

    private fun classifySize(w: Float, h: Float): WidgetFamily {
        return when {
            w <= 0 || h <= 0 -> WidgetFamily.MEDIUM
            w < 120 -> WidgetFamily.CIRCULAR
            h < 150 -> WidgetFamily.RECTANGULAR
            w >= 340 && h >= 340 -> WidgetFamily.LARGE
            w >= 240 -> WidgetFamily.MEDIUM
            else -> WidgetFamily.SMALL
        }
    }

    private fun buildForFamily(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        family: WidgetFamily,
    ): RemoteViews {
        ensureAmiriTypeface(context)
        if (!snapshot.hasCoordinates) {
            return when (family) {
                WidgetFamily.CIRCULAR,
                WidgetFamily.RECTANGULAR -> buildAccessoryEmpty(context, snapshot, family)
                else -> buildEmpty(context, snapshot)
            }
        }
        val now = Date()
        val next = PrayerWidgetCalculator.nextAfter(snapshot, now)
            ?: return when (family) {
                WidgetFamily.CIRCULAR,
                WidgetFamily.RECTANGULAR -> buildAccessoryEmpty(context, snapshot, family)
                else -> buildEmpty(context, snapshot)
            }
        val theme = PrayerWidgetTheme.resolve(context, snapshot)

        return when (family) {
            WidgetFamily.CIRCULAR,
            WidgetFamily.RECTANGULAR -> buildAccessory(context, snapshot, theme, next, now, family)
            else -> buildHome(context, snapshot, theme, next, now, family)
        }
    }

    private fun buildHome(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        family: WidgetFamily,
    ): RemoteViews {
        return when (snapshot.design) {
            PrayerWidgetDesign.HERO -> buildHero(context, snapshot, theme, next, now, family)
            PrayerWidgetDesign.COMPACT -> buildCompact(context, snapshot, theme, next, now, family)
        }
    }

    private fun buildHero(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        family: WidgetFamily,
    ): RemoteViews {
        val isRtl = PrayerWidgetLocalization.isRTL(snapshot.effectiveLocale)
        val layoutRes = when (family) {
            WidgetFamily.SMALL -> R.layout.prayer_widget_hero_small
            WidgetFamily.MEDIUM -> if (isRtl) R.layout.prayer_widget_hero_medium_rtl
                else R.layout.prayer_widget_hero_medium
            WidgetFamily.LARGE -> if (isRtl) R.layout.prayer_widget_hero_large_rtl
                else R.layout.prayer_widget_hero_large
            else -> if (isRtl) R.layout.prayer_widget_hero_medium_rtl
                else R.layout.prayer_widget_hero_medium
        }
        val views = RemoteViews(context.packageName, layoutRes)
        val locale = snapshot.effectiveLocale
        val secondary = theme.secondaryTextHero
        val primary = theme.primaryText

        applyBackground(context, views, theme)

        if (family == WidgetFamily.LARGE) {
            views.setInt(
                R.id.prayer_widget_inner_card,
                "setBackgroundResource",
                R.drawable.prayer_widget_inner_card,
            )
            tintBackground(views, R.id.prayer_widget_inner_card,
                PrayerWidgetTheme.withAlpha(theme.highlight, 0.12f))
        }

        setStyledText(views,
            R.id.prayer_widget_label,
            PrayerWidgetLocalization.string("next_prayer", locale),
        )
        views.setTextColor(R.id.prayer_widget_label, secondary)

        val compact = PrayerTimeFormatter.formatHHMMRoundedUp(
            from = now, to = next.time,
            useArabicNumerals = snapshot.useArabicNumerals(),
        )
        viewIfPresent(views, R.id.prayer_widget_countdown_static) {
            setStyledText(views, R.id.prayer_widget_countdown_static, compact)

            val countdownColor = if (family == WidgetFamily.SMALL) theme.highlight else secondary
            views.setTextColor(R.id.prayer_widget_countdown_static, countdownColor)
        }

        if (family == WidgetFamily.SMALL) {
            viewIfPresent(views, R.id.prayer_widget_divider) {
                views.setInt(R.id.prayer_widget_divider, "setBackgroundColor", primary)
            }
        }

        when (family) {
            WidgetFamily.SMALL -> bindHeroSmall(views, snapshot, theme, next, locale)
            WidgetFamily.LARGE -> bindHeroLarge(context, views, snapshot, theme, next, now, locale)
            else -> bindHeroMedium(views, snapshot, theme, next, locale)
        }

        if (PrayerWidgetLocalization.isRTL(locale) && family != WidgetFamily.SMALL) {
            when (family) {
                WidgetFamily.LARGE -> {
                    setStyledText(views, R.id.prayer_widget_label, compact)
                    setStyledText(views, R.id.prayer_widget_countdown_static,
                        PrayerWidgetLocalization.string("next_prayer", locale))
                }
                else -> {
                    setStyledText(views, R.id.prayer_widget_in_word, compact)
                    setStyledText(views, R.id.prayer_widget_countdown_static,
                        PrayerWidgetLocalization.string("in_word", locale))
                }
            }
        }

        applyContentSize(views, snapshot, heroFontSizes(family))
        applyDeepLink(views, context)
        applyLayoutDirection(views, locale)
        return views
    }

    private fun bindHeroSmall(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        locale: String,
    ) {
        val primary = theme.primaryText
        val secondary = theme.secondaryTextHero

        setStyledText(views,
            R.id.prayer_widget_next_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_next_name, primary)

        setStyledText(views,
            R.id.prayer_widget_next_time,
            PrayerTimeFormatter.format(next.time, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_next_time, primary)

        if (PrayerWidgetLocalization.isRTL(locale)) {
            views.setInt(R.id.prayer_widget_next_time, "setGravity", Gravity.RIGHT)
            views.setInt(R.id.prayer_widget_countdown_static, "setGravity", Gravity.RIGHT)
        }

        val allPrayers = PrayerWidgetCalculator.displayList(next.day)
        val nextIndex = allPrayers.indexOfFirst { it.first == next.kind }
        val upcoming = if (nextIndex >= 0) {
            (1..3).map { offset ->
                allPrayers[(nextIndex + offset) % allPrayers.size]
            }
        } else {
            allPrayers.take(3)
        }

        val upcomingRowIds = listOf(
            R.id.prayer_widget_upcoming_1_name to R.id.prayer_widget_upcoming_1_time,
            R.id.prayer_widget_upcoming_2_name to R.id.prayer_widget_upcoming_2_time,
            R.id.prayer_widget_upcoming_3_name to R.id.prayer_widget_upcoming_3_time,
        )
        val upcomingContainerIds = listOf(
            R.id.prayer_widget_upcoming_1,
            R.id.prayer_widget_upcoming_2,
            R.id.prayer_widget_upcoming_3,
        )

        for (i in upcomingRowIds.indices) {
            if (i < upcoming.size) {
                val (kind, time) = upcoming[i]
                views.setViewVisibility(upcomingContainerIds[i], View.VISIBLE)
                setStyledText(views, upcomingRowIds[i].first,
                    PrayerWidgetLocalization.prayerName(kind, locale))
                views.setTextColor(upcomingRowIds[i].first, secondary)
                setStyledText(views, upcomingRowIds[i].second,
                    PrayerTimeFormatter.format(time, snapshot.useArabicNumerals()))
                views.setTextColor(upcomingRowIds[i].second, secondary)
            } else {
                views.setViewVisibility(upcomingContainerIds[i], View.GONE)
            }
        }
    }

    private fun bindHeroMedium(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        locale: String,
    ) {
        val primary = theme.primaryText
        val secondary = theme.secondaryTextHero

        setStyledText(views,
            R.id.prayer_widget_next_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_next_name, primary)

        setStyledText(views,
            R.id.prayer_widget_next_time,
            PrayerTimeFormatter.format(next.time, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_next_time, primary)

        setStyledText(views,
            R.id.prayer_widget_in_word,
            PrayerWidgetLocalization.string("in_word", locale),
        )
        views.setTextColor(R.id.prayer_widget_in_word, secondary)

        if (PrayerWidgetLocalization.isRTL(locale)) {
            views.setInt(R.id.prayer_widget_next_time, "setGravity", Gravity.END)
            views.setInt(R.id.prayer_widget_countdown_row, "setGravity",
                Gravity.CENTER_VERTICAL or Gravity.END)
        }

        applyHeroList(views, snapshot, theme, next, locale, includeIcons = false)
    }

    private fun bindHeroLarge(
        context: Context,
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText
        val secondary = theme.secondaryTextHero

        setStyledText(views,
            R.id.prayer_widget_next_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_next_name, secondary)
        setStyledText(views,
            R.id.prayer_widget_next_time,
            PrayerTimeFormatter.format(next.time, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_next_time, primary)

        setStyledText(views,
            R.id.prayer_widget_label,
            PrayerWidgetLocalization.string("next_prayer", locale),
        )
        views.setTextColor(R.id.prayer_widget_label, secondary)
        setStyledText(views,
            R.id.prayer_widget_in_word,
            PrayerWidgetLocalization.string("in_word", locale),
        )
        views.setTextColor(R.id.prayer_widget_in_word, secondary)

        views.setImageViewResource(R.id.prayer_widget_hero_icon, prayerIconRes(next.kind))
        views.setInt(R.id.prayer_widget_hero_icon, "setColorFilter", secondary)

        applyHeroList(views, snapshot, theme, next, locale, includeIcons = true)
    }

    private fun applyHeroList(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        locale: String,
        includeIcons: Boolean,
    ) {
        val rows = PrayerWidgetCalculator.displayList(next.day)
        for ((kind, time) in rows) {
            applyHeroRow(views, snapshot, theme, kind, time, locale,
                isHighlighted = kind == next.kind, includeIcons = includeIcons)
        }
    }

    private fun applyHeroRow(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        kind: PrayerKind,
        time: Date,
        locale: String,
        isHighlighted: Boolean,
        includeIcons: Boolean,
    ) {
        val ids = heroRowIds(kind)
        val color = if (isHighlighted) theme.primaryText else theme.secondaryTextHero

        setStyledText(views,
            ids.nameId,
            PrayerWidgetLocalization.prayerName(kind, locale),
        )
        views.setTextColor(ids.nameId, color)
        setStyledText(views,
            ids.timeId,
            PrayerTimeFormatter.format(time, snapshot.useArabicNumerals()),
        )
        views.setTextColor(ids.timeId, color)

        if (isHighlighted) {
            views.setInt(
                ids.rowId,
                "setBackgroundResource",
                R.drawable.prayer_widget_pill_highlight,
            )
            tintBackground(views, ids.rowId,
                PrayerWidgetTheme.withAlpha(theme.highlight, 0.15f))
        } else {
            views.setInt(
                ids.rowId,
                "setBackgroundResource",
                0,
            )
        }

        if (includeIcons && ids.iconId != null) {
            views.setImageViewResource(ids.iconId, prayerIconRes(kind))
            views.setInt(ids.iconId, "setColorFilter", color)
        }
    }

    private data class HeroRowIds(
        val rowId: Int, val nameId: Int, val timeId: Int, val iconId: Int?,
    )

    private fun heroRowIds(kind: PrayerKind): HeroRowIds = when (kind) {
        PrayerKind.FAJR -> HeroRowIds(
            R.id.prayer_widget_row_fajr,
            R.id.prayer_widget_row_fajr_name,
            R.id.prayer_widget_row_fajr_time,
            R.id.prayer_widget_row_fajr_icon,
        )
        PrayerKind.SUNRISE -> HeroRowIds(
            R.id.prayer_widget_row_sunrise,
            R.id.prayer_widget_row_sunrise_name,
            R.id.prayer_widget_row_sunrise_time,
            R.id.prayer_widget_row_sunrise_icon,
        )
        PrayerKind.DHUHR -> HeroRowIds(
            R.id.prayer_widget_row_dhuhr,
            R.id.prayer_widget_row_dhuhr_name,
            R.id.prayer_widget_row_dhuhr_time,
            R.id.prayer_widget_row_dhuhr_icon,
        )
        PrayerKind.ASR -> HeroRowIds(
            R.id.prayer_widget_row_asr,
            R.id.prayer_widget_row_asr_name,
            R.id.prayer_widget_row_asr_time,
            R.id.prayer_widget_row_asr_icon,
        )
        PrayerKind.MAGHRIB -> HeroRowIds(
            R.id.prayer_widget_row_maghrib,
            R.id.prayer_widget_row_maghrib_name,
            R.id.prayer_widget_row_maghrib_time,
            R.id.prayer_widget_row_maghrib_icon,
        )
        PrayerKind.ISHA -> HeroRowIds(
            R.id.prayer_widget_row_isha,
            R.id.prayer_widget_row_isha_name,
            R.id.prayer_widget_row_isha_time,
            R.id.prayer_widget_row_isha_icon,
        )
    }

    private fun prayerIconRes(kind: PrayerKind): Int = when (kind) {
        PrayerKind.FAJR -> R.drawable.ic_prayer_fajr
        PrayerKind.SUNRISE -> R.drawable.ic_prayer_sunrise
        PrayerKind.DHUHR -> R.drawable.ic_prayer_dhuhr
        PrayerKind.ASR -> R.drawable.ic_prayer_asr
        PrayerKind.MAGHRIB -> R.drawable.ic_prayer_maghrib
        PrayerKind.ISHA -> R.drawable.ic_prayer_isha
    }

    private fun heroFontSizes(family: WidgetFamily): List<Pair<Int, Float>> = when (family) {
        WidgetFamily.SMALL -> listOf(
            R.id.prayer_widget_label to 11f,
            R.id.prayer_widget_next_name to 18f,
            R.id.prayer_widget_next_time to 22f,
            R.id.prayer_widget_countdown_static to 16f,

            R.id.prayer_widget_upcoming_1_name to 11f,
            R.id.prayer_widget_upcoming_1_time to 11f,
            R.id.prayer_widget_upcoming_2_name to 11f,
            R.id.prayer_widget_upcoming_2_time to 11f,
            R.id.prayer_widget_upcoming_3_name to 11f,
            R.id.prayer_widget_upcoming_3_time to 11f,
        )
        WidgetFamily.MEDIUM -> listOf(
            R.id.prayer_widget_label to 15f,
            R.id.prayer_widget_next_name to 42f,
            R.id.prayer_widget_next_time to 32f,
            R.id.prayer_widget_in_word to 18f,
            R.id.prayer_widget_countdown_static to 18f,
            R.id.prayer_widget_row_fajr_name to 13f,
            R.id.prayer_widget_row_fajr_time to 13f,
            R.id.prayer_widget_row_sunrise_name to 13f,
            R.id.prayer_widget_row_sunrise_time to 13f,
            R.id.prayer_widget_row_dhuhr_name to 13f,
            R.id.prayer_widget_row_dhuhr_time to 13f,
            R.id.prayer_widget_row_asr_name to 13f,
            R.id.prayer_widget_row_asr_time to 13f,
            R.id.prayer_widget_row_maghrib_name to 13f,
            R.id.prayer_widget_row_maghrib_time to 13f,
            R.id.prayer_widget_row_isha_name to 13f,
            R.id.prayer_widget_row_isha_time to 13f,
        )
        WidgetFamily.LARGE -> listOf(
            R.id.prayer_widget_next_name to 16f,
            R.id.prayer_widget_next_time to 42f,
            R.id.prayer_widget_label to 13f,
            R.id.prayer_widget_in_word to 13f,
            R.id.prayer_widget_countdown_static to 13f,
            R.id.prayer_widget_row_fajr_name to 16f,
            R.id.prayer_widget_row_fajr_time to 16f,
            R.id.prayer_widget_row_sunrise_name to 16f,
            R.id.prayer_widget_row_sunrise_time to 16f,
            R.id.prayer_widget_row_dhuhr_name to 16f,
            R.id.prayer_widget_row_dhuhr_time to 16f,
            R.id.prayer_widget_row_asr_name to 16f,
            R.id.prayer_widget_row_asr_time to 16f,
            R.id.prayer_widget_row_maghrib_name to 16f,
            R.id.prayer_widget_row_maghrib_time to 16f,
            R.id.prayer_widget_row_isha_name to 16f,
            R.id.prayer_widget_row_isha_time to 16f,
        )
        else -> emptyList()
    }

    private fun buildCompact(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        family: WidgetFamily,
    ): RemoteViews {
        val isRtl = PrayerWidgetLocalization.isRTL(snapshot.effectiveLocale)
        val layoutRes = when (family) {
            WidgetFamily.SMALL -> R.layout.prayer_widget_compact_small
            WidgetFamily.MEDIUM -> if (isRtl) R.layout.prayer_widget_compact_medium_rtl
                else R.layout.prayer_widget_compact_medium
            WidgetFamily.LARGE -> R.layout.prayer_widget_compact_large
            else -> if (isRtl) R.layout.prayer_widget_compact_medium_rtl
                else R.layout.prayer_widget_compact_medium
        }
        val views = RemoteViews(context.packageName, layoutRes)
        val locale = snapshot.effectiveLocale

        applyBackground(context, views, theme)

        if (family != WidgetFamily.SMALL) {
            val dividerColor = PrayerWidgetTheme.withAlpha(theme.highlight, 0.20f)
            views.setInt(
                R.id.prayer_widget_divider,
                "setBackgroundColor",
                dividerColor,
            )
        }
        if (family == WidgetFamily.LARGE) {
            views.setInt(
                R.id.prayer_widget_hero_pill,
                "setBackgroundResource",
                R.drawable.prayer_widget_hero_pill,
            )
            tintBackground(views, R.id.prayer_widget_hero_pill,
                PrayerWidgetTheme.withAlpha(theme.highlight, 0.12f))
        }

        when (family) {
            WidgetFamily.SMALL -> bindCompactSmall(views, snapshot, theme, next, now, locale)
            WidgetFamily.LARGE -> bindCompactLarge(views, snapshot, theme, next, now, locale)
            else -> bindCompactMedium(views, snapshot, theme, next, now, locale)
        }

        applyContentSize(views, snapshot, compactFontSizes(family, locale))
        applyDeepLink(views, context)
        applyLayoutDirection(views, locale)
        return views
    }

    private fun bindCompactSmall(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText
        val tatweel = if (PrayerWidgetLocalization.isRTL(locale)) 1 else 0

        setStyledText(views,
            R.id.prayer_widget_iso_date,
            PrayerTimeFormatter.formatISODate(now, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_iso_date, primary)

        val day = ArabicTatweel.elongate(
            PrayerTimeFormatter.formatDayOfWeek(now, locale), tatweel,
        )
        setStyledText(views, R.id.prayer_widget_day_of_week, day)
        views.setTextColor(R.id.prayer_widget_day_of_week, primary)

        setStyledText(views,
            R.id.prayer_widget_next_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_next_name, primary)

        setStyledText(views,
            R.id.prayer_widget_next_time,
            PrayerTimeFormatter.format12WithMeridiem(
                next.time, snapshot.useArabicNumerals(), locale,
            ),
        )
        views.setTextColor(R.id.prayer_widget_next_time, primary)

        setStyledText(views, R.id.prayer_widget_countdown,
            PrayerTimeFormatter.formatHHMMRoundedUp(
                from = now, to = next.time,
                useArabicNumerals = snapshot.useArabicNumerals(),
            ))
        views.setTextColor(R.id.prayer_widget_countdown, primary)
    }

    private fun bindCompactMedium(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText
        val highlight = theme.highlight
        val isRtl = PrayerWidgetLocalization.isRTL(locale)
        val tatweel = if (isRtl) 2 else 0

        setStyledText(views,
            R.id.prayer_widget_iso_date,
            PrayerTimeFormatter.formatISODate(now, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_iso_date, primary)

        val day = ArabicTatweel.elongate(
            PrayerTimeFormatter.formatDayOfWeek(now, locale), tatweel,
        )
        setStyledText(views, R.id.prayer_widget_day_of_week, day)
        views.setTextColor(R.id.prayer_widget_day_of_week, primary)

        val stripSlots = compactStripIds()
        val stripKinds = stripKindsOrdered(isRtl)
        for (i in stripSlots.indices) {
            val ids = stripSlots[i].second
            val kind = stripKinds[i]
            val time = next.day.timeOf(kind)
            val isNext = kind == next.kind
            val color = if (isNext) highlight else primary
            setStyledText(views,
                ids.nameId,
                PrayerWidgetLocalization.prayerName(kind, locale),
            )
            views.setTextColor(ids.nameId, color)
            setStyledText(views,
                ids.timeId,
                PrayerTimeFormatter.format12(time, snapshot.useArabicNumerals()),
            )
            views.setTextColor(ids.timeId, color)
        }

        if (isRtl) {
            val remainLabel = PrayerWidgetLocalization.string("remaining_until", locale)
            val prayerName = PrayerWidgetLocalization.prayerName(next.kind, locale)
            setStyledText(views, R.id.prayer_widget_remaining_label,
                "$remainLabel $prayerName")
            views.setTextColor(R.id.prayer_widget_remaining_label, highlight)
            setStyledText(views, R.id.prayer_widget_remaining_name, "")
            setStyledText(views, R.id.prayer_widget_countdown,
                PrayerTimeFormatter.formatHHMMRoundedUp(
                    from = now, to = next.time,
                    useArabicNumerals = snapshot.useArabicNumerals(),
                ))
            views.setTextColor(R.id.prayer_widget_countdown, highlight)
        } else {
            setStyledText(views,
                R.id.prayer_widget_remaining_label,
                PrayerWidgetLocalization.string("remaining_until", locale),
            )
            views.setTextColor(R.id.prayer_widget_remaining_label, highlight)
            setStyledText(views,
                R.id.prayer_widget_remaining_name,
                PrayerWidgetLocalization.prayerName(next.kind, locale),
            )
            views.setTextColor(R.id.prayer_widget_remaining_name, highlight)
            setStyledText(views, R.id.prayer_widget_countdown,
                PrayerTimeFormatter.formatHHMMRoundedUp(
                    from = now, to = next.time,
                    useArabicNumerals = snapshot.useArabicNumerals(),
                ))
            views.setTextColor(R.id.prayer_widget_countdown, highlight)
        }
    }

    private fun bindCompactLarge(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText
        val highlight = theme.highlight
        val isRTL = PrayerWidgetLocalization.isRTL(locale)
        val tatweel = if (isRTL) 2 else 0

        setStyledText(views,
            R.id.prayer_widget_iso_date,
            PrayerTimeFormatter.formatISODate(now, snapshot.useArabicNumerals()),
        )
        views.setTextColor(R.id.prayer_widget_iso_date, primary)

        val daySize = if (isRTL) 30f else 56f
        val day = ArabicTatweel.elongate(
            PrayerTimeFormatter.formatDayOfWeek(now, locale), tatweel,
        )
        setStyledText(views, R.id.prayer_widget_day_of_week, day)
        views.setTextColor(R.id.prayer_widget_day_of_week, primary)
        views.setTextViewTextSize(
            R.id.prayer_widget_day_of_week,
            TypedValue.COMPLEX_UNIT_SP,
            daySize * (snapshot.contentSize.coerceIn(60, 140) / 100f),
        )

        setStyledText(views, R.id.prayer_widget_countdown,
            PrayerTimeFormatter.formatHHMMRoundedUp(
                from = now, to = next.time,
                useArabicNumerals = snapshot.useArabicNumerals(),
            ))
        views.setTextColor(R.id.prayer_widget_countdown, primary)
        setStyledText(views,
            R.id.prayer_widget_pill_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_pill_name, primary)
        setStyledText(views,
            R.id.prayer_widget_pill_time,
            PrayerTimeFormatter.format12WithMeridiem(
                next.time, snapshot.useArabicNumerals(), locale,
            ),
        )
        views.setTextColor(R.id.prayer_widget_pill_time, primary)

        val gridSlots = compactGridIds()
        val gridKinds = gridKindsOrdered(isRTL)
        for (i in gridSlots.indices) {
            val ids = gridSlots[i].second
            val kind = gridKinds[i]
            val time = next.day.timeOf(kind)
            val isNext = kind == next.kind
            val color = if (isNext) highlight else primary
            setStyledText(views,
                ids.nameId,
                PrayerWidgetLocalization.prayerName(kind, locale),
            )
            views.setTextColor(ids.nameId, color)
            setStyledText(views,
                ids.timeId,
                PrayerTimeFormatter.format12(time, snapshot.useArabicNumerals()),
            )
            views.setTextColor(ids.timeId, color)
        }

        val sunnah = PrayerWidgetCalculator.computeSunnah(
            snapshot,
            Calendar.getInstance().apply { time = now },
        )
        setStyledText(views,
            R.id.prayer_widget_sunnah_last_third_label,
            PrayerWidgetLocalization.string("last_third_night", locale),
        )
        views.setTextColor(R.id.prayer_widget_sunnah_last_third_label, primary)
        setStyledText(views,
            R.id.prayer_widget_sunnah_last_third_value,
            sunnah?.lastThirdOfNight?.let {
                PrayerTimeFormatter.format12(it, snapshot.useArabicNumerals())
            } ?: "—",
        )
        views.setTextColor(R.id.prayer_widget_sunnah_last_third_value, primary)

        setStyledText(views,
            R.id.prayer_widget_sunnah_middle_label,
            PrayerWidgetLocalization.string("middle_of_night", locale),
        )
        views.setTextColor(R.id.prayer_widget_sunnah_middle_label, primary)
        setStyledText(views,
            R.id.prayer_widget_sunnah_middle_value,
            sunnah?.middleOfNight?.let {
                PrayerTimeFormatter.format12(it, snapshot.useArabicNumerals())
            } ?: "—",
        )
        views.setTextColor(R.id.prayer_widget_sunnah_middle_value, primary)
    }

    private data class CompactCellIds(val nameId: Int, val timeId: Int)

    private fun compactStripIds(): List<Pair<PrayerKind, CompactCellIds>> = listOf(
        PrayerKind.FAJR to CompactCellIds(
            R.id.prayer_widget_strip_fajr_name,
            R.id.prayer_widget_strip_fajr_time,
        ),
        PrayerKind.DHUHR to CompactCellIds(
            R.id.prayer_widget_strip_dhuhr_name,
            R.id.prayer_widget_strip_dhuhr_time,
        ),
        PrayerKind.ASR to CompactCellIds(
            R.id.prayer_widget_strip_asr_name,
            R.id.prayer_widget_strip_asr_time,
        ),
        PrayerKind.MAGHRIB to CompactCellIds(
            R.id.prayer_widget_strip_maghrib_name,
            R.id.prayer_widget_strip_maghrib_time,
        ),
        PrayerKind.ISHA to CompactCellIds(
            R.id.prayer_widget_strip_isha_name,
            R.id.prayer_widget_strip_isha_time,
        ),
    )

    private fun compactGridIds(): List<Pair<PrayerKind, CompactCellIds>> = listOf(
        PrayerKind.FAJR to CompactCellIds(
            R.id.prayer_widget_grid_fajr_name, R.id.prayer_widget_grid_fajr_time,
        ),
        PrayerKind.SUNRISE to CompactCellIds(
            R.id.prayer_widget_grid_sunrise_name, R.id.prayer_widget_grid_sunrise_time,
        ),
        PrayerKind.DHUHR to CompactCellIds(
            R.id.prayer_widget_grid_dhuhr_name, R.id.prayer_widget_grid_dhuhr_time,
        ),
        PrayerKind.ASR to CompactCellIds(
            R.id.prayer_widget_grid_asr_name, R.id.prayer_widget_grid_asr_time,
        ),
        PrayerKind.MAGHRIB to CompactCellIds(
            R.id.prayer_widget_grid_maghrib_name, R.id.prayer_widget_grid_maghrib_time,
        ),
        PrayerKind.ISHA to CompactCellIds(
            R.id.prayer_widget_grid_isha_name, R.id.prayer_widget_grid_isha_time,
        ),
    )

    private fun stripKindsOrdered(isRtl: Boolean): List<PrayerKind> {
        val ltr = listOf(
            PrayerKind.FAJR, PrayerKind.DHUHR, PrayerKind.ASR,
            PrayerKind.MAGHRIB, PrayerKind.ISHA,
        )
        return if (isRtl) ltr.reversed() else ltr
    }

    private fun gridKindsOrdered(isRtl: Boolean): List<PrayerKind> = if (isRtl) listOf(
        PrayerKind.DHUHR, PrayerKind.SUNRISE, PrayerKind.FAJR,
        PrayerKind.ISHA,  PrayerKind.MAGHRIB, PrayerKind.ASR,
    ) else listOf(
        PrayerKind.FAJR,  PrayerKind.SUNRISE, PrayerKind.DHUHR,
        PrayerKind.ASR,   PrayerKind.MAGHRIB, PrayerKind.ISHA,
    )

    private fun compactFontSizes(family: WidgetFamily, locale: String): List<Pair<Int, Float>> {
        val isArabicScript = PrayerWidgetLocalization.isRTL(locale)
        val opticalScale: Float = when {
            !isArabicScript -> 1f
            family == WidgetFamily.LARGE -> 1.15f
            family == WidgetFamily.SMALL -> 1.1f
            else -> 1.3f
        }
        fun s(size: Float) = size * opticalScale
        return when (family) {
            WidgetFamily.SMALL -> listOf(
                R.id.prayer_widget_iso_date to s(11f),
                R.id.prayer_widget_day_of_week to s(if (isArabicScript) 26f else 32f),
                R.id.prayer_widget_next_name to s(20f),
                R.id.prayer_widget_next_time to s(26f),
                R.id.prayer_widget_countdown to s(18f),
            )
            WidgetFamily.MEDIUM -> listOf(
                R.id.prayer_widget_iso_date to s(11f),
                R.id.prayer_widget_day_of_week to s(if (isArabicScript) 32f else 42f),
                R.id.prayer_widget_strip_fajr_name to s(16f),
                R.id.prayer_widget_strip_fajr_time to s(16f),
                R.id.prayer_widget_strip_dhuhr_name to s(16f),
                R.id.prayer_widget_strip_dhuhr_time to s(16f),
                R.id.prayer_widget_strip_asr_name to s(16f),
                R.id.prayer_widget_strip_asr_time to s(16f),
                R.id.prayer_widget_strip_maghrib_name to s(16f),
                R.id.prayer_widget_strip_maghrib_time to s(16f),
                R.id.prayer_widget_strip_isha_name to s(16f),
                R.id.prayer_widget_strip_isha_time to s(16f),
                R.id.prayer_widget_remaining_label to s(14f),
                R.id.prayer_widget_remaining_name to s(14f),
                R.id.prayer_widget_countdown to s(14f),
            )
            WidgetFamily.LARGE -> listOf(
                R.id.prayer_widget_iso_date to s(12f),

                R.id.prayer_widget_countdown to s(22f),
                R.id.prayer_widget_pill_name to s(18f),
                R.id.prayer_widget_pill_time to s(18f),
                R.id.prayer_widget_grid_fajr_name to s(20f),
                R.id.prayer_widget_grid_fajr_time to s(20f),
                R.id.prayer_widget_grid_sunrise_name to s(20f),
                R.id.prayer_widget_grid_sunrise_time to s(20f),
                R.id.prayer_widget_grid_dhuhr_name to s(20f),
                R.id.prayer_widget_grid_dhuhr_time to s(20f),
                R.id.prayer_widget_grid_asr_name to s(20f),
                R.id.prayer_widget_grid_asr_time to s(20f),
                R.id.prayer_widget_grid_maghrib_name to s(20f),
                R.id.prayer_widget_grid_maghrib_time to s(20f),
                R.id.prayer_widget_grid_isha_name to s(20f),
                R.id.prayer_widget_grid_isha_time to s(20f),
                R.id.prayer_widget_sunnah_last_third_label to s(16f),
                R.id.prayer_widget_sunnah_last_third_value to s(18f),
                R.id.prayer_widget_sunnah_middle_label to s(16f),
                R.id.prayer_widget_sunnah_middle_value to s(18f),
            )
            else -> emptyList()
        }
    }

    private fun buildAccessory(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        family: WidgetFamily,
    ): RemoteViews {
        val layoutRes = when (family) {
            WidgetFamily.CIRCULAR -> R.layout.prayer_widget_circular
            else -> R.layout.prayer_widget_rectangular
        }
        val views = RemoteViews(context.packageName, layoutRes)
        val locale = snapshot.effectiveLocale

        applyBackground(context, views, theme)

        when (family) {
            WidgetFamily.CIRCULAR -> bindCircular(views, snapshot, theme, next, now, locale)
            else -> bindRectangular(views, snapshot, theme, next, now, locale)
        }

        applyDeepLink(views, context)
        applyLayoutDirection(views, locale)
        return views
    }

    private fun buildAccessoryEmpty(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        family: WidgetFamily,
    ): RemoteViews {
        val layoutRes = when (family) {
            WidgetFamily.CIRCULAR -> R.layout.prayer_widget_circular
            else -> R.layout.prayer_widget_rectangular
        }
        val views = RemoteViews(context.packageName, layoutRes)
        val theme = PrayerWidgetTheme.resolve(context, snapshot)
        applyBackground(context, views, theme)
        val locale = snapshot.effectiveLocale
        val message = PrayerWidgetLocalization.string("empty_message", locale)

        when (family) {
            WidgetFamily.CIRCULAR -> {
                views.setViewVisibility(R.id.prayer_widget_ring, View.GONE)
                setStyledText(views, R.id.prayer_widget_next_name, "--")
                views.setTextColor(R.id.prayer_widget_next_name, theme.primaryText)
                setStyledText(views, R.id.prayer_widget_countdown, "--:--")
                views.setTextColor(R.id.prayer_widget_countdown, theme.primaryText)

                views.setImageViewBitmap(R.id.prayer_widget_ring_progress, null)
            }
            else -> {
                setStyledText(views, R.id.prayer_widget_next_name, message)
                views.setTextColor(R.id.prayer_widget_next_name, theme.primaryText)
                views.setViewVisibility(R.id.prayer_widget_in_word, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_countdown, View.GONE)
            }
        }
        applyDeepLink(views, context)
        applyLayoutDirection(views, locale)
        return views
    }

    private fun bindCircular(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText

        views.setViewVisibility(R.id.prayer_widget_ring, View.GONE)

        val previous = PrayerWidgetCalculator.previousBefore(snapshot, now)
        val start = progressStart(previous, next.time)
        val totalMs = (next.time.time - start.time).coerceAtLeast(1L).toFloat()
        val elapsedMs = (now.time - start.time).coerceAtLeast(0L).toFloat()
        val progress = (elapsedMs / totalMs).coerceIn(0f, 1f)

        val arcBitmap = buildProgressArcBitmap(
            sizePx = CIRCULAR_ARC_SIZE_PX,
            strokePx = CIRCULAR_ARC_STROKE_PX,
            progress = progress,
            foregroundColor = theme.accent,
            trackColor = PrayerWidgetTheme.withAlpha(theme.accent, 0.25f),
        )
        views.setImageViewBitmap(R.id.prayer_widget_ring_progress, arcBitmap)

        setStyledText(views,
            R.id.prayer_widget_next_name,
            PrayerWidgetLocalization.prayerName(next.kind, locale),
        )
        views.setTextColor(R.id.prayer_widget_next_name, primary)

        views.setViewVisibility(R.id.prayer_widget_countdown_static, View.GONE)
        views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)
        setStyledText(views, R.id.prayer_widget_countdown,
            PrayerTimeFormatter.formatHHMMRoundedUp(
                from = now, to = next.time,
                useArabicNumerals = snapshot.useArabicNumerals(),
            ))
        views.setTextColor(R.id.prayer_widget_countdown, primary)
    }

    private const val CIRCULAR_ARC_SIZE_PX = 384

    private const val CIRCULAR_ARC_STROKE_PX = 27f

    private fun buildProgressArcBitmap(
        sizePx: Int,
        strokePx: Float,
        progress: Float,
        foregroundColor: Int,
        trackColor: Int,
    ): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val half = strokePx / 2f
        val rect = RectF(half, half, sizePx - half, sizePx - half)

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            strokeCap = Paint.Cap.ROUND
            color = trackColor
        }
        canvas.drawArc(rect, 0f, 360f, false, trackPaint)

        val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            strokeCap = Paint.Cap.ROUND
            color = foregroundColor
        }

        canvas.drawArc(rect, -90f, progress * 360f, false, progressPaint)
        return bmp
    }

    private fun bindRectangular(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        theme: PrayerWidgetTheme,
        next: NextPrayer,
        now: Date,
        locale: String,
    ) {
        val primary = theme.primaryText
        val accent = theme.accent
        val isRtl = PrayerWidgetLocalization.isRTL(locale)

        val compact = PrayerTimeFormatter.formatHHMMRoundedUp(
            from = now, to = next.time,
            useArabicNumerals = snapshot.useArabicNumerals(),
        )

        if (isRtl) {
            val prayerName = PrayerWidgetLocalization.prayerName(next.kind, locale)
            val inWord = PrayerWidgetLocalization.string("in_word", locale)
            setStyledText(views, R.id.prayer_widget_countdown,
                "$prayerName $inWord $compact")
            views.setTextColor(R.id.prayer_widget_countdown, accent)
            views.setViewVisibility(R.id.prayer_widget_next_name, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_in_word, View.GONE)
        } else {
            setStyledText(views,
                R.id.prayer_widget_next_name,
                PrayerWidgetLocalization.prayerName(next.kind, locale),
            )
            views.setTextColor(R.id.prayer_widget_next_name, accent)
            setStyledText(views,
                R.id.prayer_widget_in_word,
                PrayerWidgetLocalization.string("in_word", locale),
            )
            views.setTextColor(R.id.prayer_widget_in_word, primary)
            setStyledText(views, R.id.prayer_widget_countdown, compact)
            views.setTextColor(R.id.prayer_widget_countdown, accent)
        }

        val stripSlots = compactStripIds()
        val stripKinds = stripKindsOrdered(isRtl)
        for (i in stripSlots.indices) {
            val ids = stripSlots[i].second
            val kind = stripKinds[i]
            val time = next.day.timeOf(kind)
            val isNext = kind == next.kind
            val color = if (isNext) accent else primary
            setStyledText(views,
                ids.nameId,
                PrayerWidgetLocalization.prayerName(kind, locale),
            )
            views.setTextColor(ids.nameId, color)
            setStyledText(views,
                ids.timeId,
                PrayerTimeFormatter.format(time, snapshot.useArabicNumerals()),
            )
            views.setTextColor(ids.timeId, color)
        }
    }

    private fun buildEmpty(context: Context, snapshot: PrayerWidgetSnapshot): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_empty)
        val locale = snapshot.effectiveLocale
        val theme = PrayerWidgetTheme.resolve(context, snapshot)
        applyBackground(context, views, theme)

        setStyledText(views,
            R.id.prayer_widget_empty_title,
            context.getString(R.string.prayer_widget_empty_title),
        )
        views.setTextColor(R.id.prayer_widget_empty_title, theme.primaryText)
        setStyledText(views,
            R.id.prayer_widget_empty_body,
            PrayerWidgetLocalization.string("empty_message", locale),
        )
        views.setTextColor(R.id.prayer_widget_empty_body, theme.primaryText)

        applyDeepLink(views, context)
        applyLayoutDirection(views, locale)
        return views
    }

    private var amiriTypeface: Typeface? = null

    private fun ensureAmiriTypeface(context: Context) {
        if (amiriTypeface == null) {
            amiriTypeface = ResourcesCompat.getFont(context, R.font.amiri_bold)
        }
    }

    private fun styledText(text: CharSequence): CharSequence {
        val tf = amiriTypeface ?: return text
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return text
        val spannable = SpannableString(text)
        spannable.setSpan(
            TypefaceSpan(tf), 0, spannable.length,
            Spannable.SPAN_INCLUSIVE_INCLUSIVE,
        )
        return spannable
    }

    private fun setStyledText(rv: RemoteViews, id: Int, text: CharSequence) {
        rv.setTextViewText(id, styledText(text))
    }

    private fun tintBackground(views: RemoteViews, viewId: Int, color: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val tint = android.content.res.ColorStateList.valueOf(color)
            views.setColorStateList(viewId, "setBackgroundTintList", tint)
        }
    }

    private fun renderContext(context: Context): Context {
        val config = Configuration(context.resources.configuration)
        config.fontScale = 1f
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.densityDpi = DisplayMetrics.DENSITY_DEVICE_STABLE
        }
        return context.createConfigurationContext(config)
    }

    private fun renderToBitmap(
        context: Context,
        remoteViews: RemoteViews,
        widthDp: Int,
        heightDp: Int,
        family: WidgetFamily,
        theme: PrayerWidgetTheme? = null,
    ): RemoteViews {
        val ctx = renderContext(context)
        val density = ctx.resources.displayMetrics.density
        val widthPx = (widthDp * density).toInt()
        val heightPx = (heightDp * density).toInt()

        if (widthPx <= 0 || heightPx <= 0) return remoteViews

        return try {
            val parent = FrameLayout(ctx)
            val view = remoteViews.apply(ctx, parent)
            parent.addView(view)

            if (theme != null) {
                val bgView = view.findViewById<android.widget.ImageView>(R.id.prayer_widget_background)
                if (bgView != null && bgView.visibility == View.VISIBLE) {
                    val correctedBg = PrayerWidgetBackgrounds.render(ctx, theme, widthPx, heightPx)
                    if (correctedBg != null) bgView.setImageBitmap(correctedBg)
                }
            }

            applyFontRecursive(parent, amiriTypeface)

            val wSpec = View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY)

            if (theme != null) {
                repeat(2) {
                    parent.measure(
                        wSpec,
                        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                    )
                    val naturalH = parent.measuredHeight
                    if (naturalH > heightPx) {
                        val scale = (heightPx.toFloat() / naturalH).coerceIn(0.70f, 0.99f)
                        scaleTextRecursive(parent, scale)
                    }
                }
            }

            val bmpH = heightPx

            parent.measure(
                wSpec,
                View.MeasureSpec.makeMeasureSpec(bmpH, View.MeasureSpec.EXACTLY),
            )
            parent.layout(0, 0, widthPx, bmpH)

            val bitmap = Bitmap.createBitmap(widthPx, bmpH, Bitmap.Config.ARGB_8888)
            parent.draw(Canvas(bitmap))

            val bitmapViews = RemoteViews(
                context.packageName, R.layout.prayer_widget_bitmap_container,
            )
            bitmapViews.setImageViewBitmap(R.id.prayer_widget_bitmap, bitmap)
            applyDeepLink(bitmapViews, context)
            bitmapViews
        } catch (e: Exception) {
            Log.e(TAG, "Bitmap render failed, falling back", e)
            remoteViews
        }
    }

    private fun scaleTextRecursive(view: View, scale: Float) {
        if (scale >= 1f) return
        if (view is TextView) {
            view.setTextSize(TypedValue.COMPLEX_UNIT_PX, view.textSize * scale)
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                scaleTextRecursive(view.getChildAt(i), scale)
            }
        }
    }

    private fun applyFontRecursive(view: View, typeface: Typeface?) {
        if (typeface == null) return
        if (view is TextView) view.typeface = typeface
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                applyFontRecursive(view.getChildAt(i), typeface)
            }
        }
    }

    private fun applyBackground(
        context: Context,
        views: RemoteViews,
        theme: PrayerWidgetTheme,
    ) {
        val bitmap = PrayerWidgetBackgrounds.render(context, theme)
        if (bitmap == null) {
            views.setViewVisibility(R.id.prayer_widget_background, View.INVISIBLE)
        } else {
            views.setViewVisibility(R.id.prayer_widget_background, View.VISIBLE)
            views.setImageViewBitmap(R.id.prayer_widget_background, bitmap)
        }
    }

    private fun applyContentSize(
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        targets: List<Pair<Int, Float>>,
    ) {
        val factor = (snapshot.contentSize.coerceIn(60, 140)) / 100f
        for ((id, baseSp) in targets) {
            views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, baseSp * factor)
        }
    }

    private fun applyDeepLink(views: RemoteViews, context: Context) {
        val pi = buildLaunchIntent(context)
        views.setOnClickPendingIntent(R.id.prayer_widget_root, pi)
    }

    private fun buildLaunchIntent(context: Context): PendingIntent {
        return HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(DEEP_LINK),
        )
    }

    private fun applyLayoutDirection(views: RemoteViews, locale: String) {
        val isRtl = PrayerWidgetLocalization.isRTL(locale)
        views.setInt(
            R.id.prayer_widget_root,
            "setLayoutDirection",
            if (isRtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )
    }

    private inline fun viewIfPresent(views: RemoteViews, id: Int, block: () -> Unit) {
        @Suppress("UNUSED_PARAMETER")
        if (id != 0) block()
    }
}

private fun PrayerWidgetSnapshot.useArabicNumerals(): Boolean {
    return when (numerals) {
        PrayerWidgetNumerals.ARABIC -> true
        PrayerWidgetNumerals.LATIN -> false
        PrayerWidgetNumerals.AUTO -> effectiveLocale.startsWith("ar")
    }
}
