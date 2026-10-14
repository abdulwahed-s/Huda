package com.aw.huda.countdown

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.text.format.DateFormat
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import com.aw.huda.R
import com.aw.huda.widget.WidgetThemeColors
import com.aw.huda.widget.prayer.PrayerTimeFormatter
import com.aw.huda.widget.prayer.PrayerWidgetCalculator.PrayerEvent
import com.aw.huda.widget.prayer.PrayerWidgetLocalization
import com.aw.huda.widget.prayer.PrayerWidgetSnapshot
import java.util.Date

/** Builds the countdown in the user's style. Nothing here schedules or posts. */
internal object PrayerCountdownNotification {
    const val CHANNEL_ID = "huda_prayer_countdown_v1"

    // flutter_foreground_task's channel from releases before the native countdown.
    private const val LEGACY_CHANNEL_ID = "prayer_countdown_visible"
    const val NOTIFICATION_ID = 410_000_010

    // Routed by NotificationTaps.routeForPayload, like a prayer notification.
    private const val TAP_EXTRA = "hudaReminderPayload"
    private const val TAP_PAYLOAD = """{"type":"prayer_time"}"""

    private val cellIds = listOf(
        Triple(R.id.countdown_cell_0, R.id.countdown_cell_0_name, R.id.countdown_cell_0_time) to R.id.countdown_cell_0_bg,
        Triple(R.id.countdown_cell_1, R.id.countdown_cell_1_name, R.id.countdown_cell_1_time) to R.id.countdown_cell_1_bg,
        Triple(R.id.countdown_cell_2, R.id.countdown_cell_2_name, R.id.countdown_cell_2_time) to R.id.countdown_cell_2_bg,
        Triple(R.id.countdown_cell_3, R.id.countdown_cell_3_name, R.id.countdown_cell_3_time) to R.id.countdown_cell_3_bg,
        Triple(R.id.countdown_cell_4, R.id.countdown_cell_4_name, R.id.countdown_cell_4_time) to R.id.countdown_cell_4_bg,
        Triple(R.id.countdown_cell_5, R.id.countdown_cell_5_name, R.id.countdown_cell_5_time) to R.id.countdown_cell_5_bg,
    )

    fun ensureChannel(context: Context, language: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        // Creating it again only renames it after a language change.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                PrayerCountdownStrings.string("channel", language),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = PrayerCountdownStrings.string("channel_description", language)
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            },
        )
        manager.deleteNotificationChannel(LEGACY_CHANNEL_ID)
    }

    fun supportsLiveUpdate(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA &&
                Build.VERSION.SDK_INT_FULL >= Build.VERSION_CODES_FULL.BAKLAVA_1

    /**
     * Android's own template ticks the timer only in the header (and the
     * Android 16 status-bar chip). Unless the user asked for that, Huda draws
     * one worded timer in the body instead.
     */
    fun usesSystemTemplate(settings: PrayerCountdownSettings): Boolean =
        settings.liveUpdate && settings.style != PrayerCountdownStyle.TIMETABLE &&
                supportsLiveUpdate()

    // setRequestPromotedOngoing (36.1) only runs when supportsLiveUpdate() is true.
    @SuppressLint("NewApi")
    fun build(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        settings: PrayerCountdownSettings,
        content: PrayerCountdownContent,
        now: Date,
    ): Notification {
        val language = settings.language
        val accent = accentColor(context, snapshot)
        val prayer = name(content.focus, language)
        val time = clock(context, snapshot, content.focus.time, language)
        val tap = tapIntent(context)

        @Suppress("DEPRECATION")
        val builder = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        })
            .setSmallIcon(R.drawable.ic_stat_name)
            .setColor(accent)
            // Says whether the timer counts down or up, wherever it is drawn.
            .setContentTitle(
                PrayerCountdownStrings.phrase(
                    if (content.elapsed) "started_at_format" else "at_format",
                    language, prayer, time,
                ),
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(
                if (settings.lockScreen) Notification.VISIBILITY_PUBLIC
                else Notification.VISIBILITY_SECRET,
            )
            .setContentIntent(tap)
            .setDeleteIntent(PrayerCountdownReceiver.dismissedIntent(context))

        if (usesSystemTemplate(settings)) {
            builder.setShowWhen(true)
                .setWhen(content.focus.time.time)
                .setUsesChronometer(true)
                .setChronometerCountDown(!content.elapsed)
                .setRequestPromotedOngoing(true)
            if (settings.style == PrayerCountdownStyle.PROGRESS) {
                applyProgressStyle(builder, content, now, accent)
            }
            return builder.build()
        }

        builder.setShowWhen(false)
            .setStyle(Notification.DecoratedCustomViewStyle())
        when (settings.style) {
            PrayerCountdownStyle.MINIMAL -> builder.setCustomContentView(
                line(context, R.layout.prayer_countdown_line, content, now, language, prayer, time),
            )

            PrayerCountdownStyle.PROGRESS -> builder.setCustomContentView(
                line(context, R.layout.prayer_countdown_progress, content, now, language, prayer, time)
                    .also { bindProgress(it, content, now, accent) },
            )

            PrayerCountdownStyle.TIMETABLE -> builder
                .setCustomContentView(
                    line(context, R.layout.prayer_countdown_line, content, now, language, prayer, time),
                )
                .setCustomBigContentView(
                    line(context, R.layout.prayer_countdown_timetable, content, now, language, prayer, time)
                        .also { bindTable(context, it, snapshot, content, language, accent) },
                )
                .addAction(
                    Notification.Action.Builder(
                        null as Icon?,
                        PrayerCountdownStrings.string("prayer_times", language),
                        tap,
                    ).build(),
                )
        }
        return builder.build()
    }

    private fun applyProgressStyle(
        builder: Notification.Builder,
        content: PrayerCountdownContent,
        now: Date,
        accent: Int,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA) return
        builder.setStyle(
            Notification.ProgressStyle()
                .setStyledByProgress(true)
                .setProgressSegments(
                    listOf(
                        Notification.ProgressStyle.Segment(PrayerCountdownContent.PROGRESS_MAX)
                            .setColor(accent),
                    ),
                )
                .setProgress(content.progress(now)),
        )
    }

    /** One ticking timer in words: "Asr in 1:23:45" or "Asr started 9:24 ago". */
    private fun line(
        context: Context,
        layout: Int,
        content: PrayerCountdownContent,
        now: Date,
        language: String,
        prayer: String,
        time: String,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layout)
        val format = PrayerCountdownStrings.phrase(
            if (content.elapsed) "started_ago_format" else "in_format",
            language, prayer,
        )
        // Chronometer bases are on the elapsed-realtime clock.
        val base = SystemClock.elapsedRealtime() + (content.focus.time.time - now.time)
        views.setChronometer(R.id.countdown_timer, base, format, true)
        views.setChronometerCountDown(R.id.countdown_timer, !content.elapsed)
        if (PrayerWidgetLocalization.isRTL(language)) {
            views.setInt(R.id.countdown_timer, "setGravity", Gravity.RIGHT or Gravity.CENTER_VERTICAL)
            views.setTextViewText(R.id.countdown_time_left, time)
            views.setViewVisibility(R.id.countdown_time_left, View.VISIBLE)
            views.setViewVisibility(R.id.countdown_time_right, View.GONE)
        } else {
            views.setTextViewText(R.id.countdown_time_right, time)
        }
        return views
    }

    private fun bindProgress(
        views: RemoteViews,
        content: PrayerCountdownContent,
        now: Date,
        accent: Int,
    ) {
        views.setProgressBar(
            R.id.countdown_progress, PrayerCountdownContent.PROGRESS_MAX, content.progress(now), false,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorStateList(
                R.id.countdown_progress, "setProgressTintList", ColorStateList.valueOf(accent),
            )
        }
    }

    private fun bindTable(
        context: Context,
        views: RemoteViews,
        snapshot: PrayerWidgetSnapshot,
        content: PrayerCountdownContent,
        language: String,
        accent: Int,
    ) {
        views.setInt(R.id.countdown_divider, "setColorFilter", withAlpha(accent, 0x55))
        val is24Hour = DateFormat.is24HourFormat(context)
        val rows = if (PrayerWidgetLocalization.isRTL(language)) content.rows.reversed() else content.rows
        cellIds.forEachIndexed { index, (ids, background) ->
            val (cell, nameId, timeId) = ids
            val row = rows.getOrNull(index)
            if (row == null) {
                views.setViewVisibility(cell, View.GONE)
                return@forEachIndexed
            }
            views.setTextViewText(nameId, PrayerWidgetLocalization.prayerName(row.kind, language))
            views.setTextViewText(
                timeId,
                if (is24Hour) PrayerTimeFormatter.format(row.time, false, snapshot.displayTimeZone)
                else PrayerTimeFormatter.format12(row.time, false, snapshot.displayTimeZone),
            )
            if (row.highlighted) {
                views.setViewVisibility(background, View.VISIBLE)
                views.setInt(background, "setColorFilter", accent)
                views.setTextColor(nameId, Color.WHITE)
                views.setTextColor(timeId, Color.WHITE)
            }
        }
    }

    private fun clock(context: Context, snapshot: PrayerWidgetSnapshot, at: Date, language: String) =
        PrayerTimeFormatter.formatForDevice(
            context, at, useArabicNumerals = false, languageCode = language,
            timeZone = snapshot.displayTimeZone,
        )

    private fun name(event: PrayerEvent, language: String): String =
        PrayerWidgetLocalization.prayerName(event.kind, language)

    private fun accentColor(context: Context, snapshot: PrayerWidgetSnapshot): Int {
        val night = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        return WidgetThemeColors.getThemeColors(snapshot.themeName, night).accent
    }

    private fun withAlpha(color: Int, alpha: Int): Int = (color and 0x00FFFFFF) or (alpha shl 24)

    private fun tapIntent(context: Context): PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        intent.action = "com.aw.huda.countdown.OPEN"
        intent.data = Uri.parse("huda-countdown://open")
        intent.putExtra(TAP_EXTRA, TAP_PAYLOAD)
        return PendingIntent.getActivity(
            context, NOTIFICATION_ID, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    internal fun receiverIntent(context: Context, action: String): Intent =
        Intent(action).setComponent(ComponentName(context, PrayerCountdownReceiver::class.java))
}
