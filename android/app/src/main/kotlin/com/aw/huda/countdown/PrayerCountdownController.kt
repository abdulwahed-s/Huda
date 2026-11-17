package com.aw.huda.countdown

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.aw.huda.widget.prayer.PrayerWidgetRepository
import com.aw.huda.widget.prayer.PrayerWidgetScheduler
import java.util.Date

/**
 * Keeps the ongoing countdown in step with the user's settings without a
 * running service: Android's Chronometer ticks it, and an exact alarm reposts
 * it only when its state changes (a prayer starts, the Iqamah window after the
 * adhan end, or the day changes).
 */
internal object PrayerCountdownController {
    private const val TAG = "PrayerCountdown"
    private const val TRANSITION_REQUEST = 0xC01
    private const val TICK_REQUEST = 0xC02
    private const val TICK_MILLIS = 5L * 60L * 1_000L
    private const val RETRY_MILLIS = 15L * 60L * 1_000L
    private val lock = Any()

    /** Posts, updates or removes the countdown. Returns whether it is showing. */
    fun refresh(context: Context, now: Date = Date()): Boolean = synchronized(lock) {
        val settings = PrayerCountdownSettings.read(context)
        if (!settings.enabled) {
            stop(context)
            return false
        }
        val snapshot = PrayerWidgetRepository.readSnapshot(context)
        val content = PrayerCountdownModel.build(snapshot, settings, now)
        if (content == null) {
            Log.i(TAG, "No location or prayer times yet; countdown hidden")
            stop(context)
            return false
        }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val transition = pending(context, PrayerCountdownReceiver.ACTION_TRANSITION, TRANSITION_REQUEST)
        alarms.cancel(transition)
        PrayerWidgetScheduler.scheduleAt(alarms, content.nextRefresh.time, transition)

        // The Progress bar moves only when reposted. A non-wakeup alarm moves it
        // while the phone is in use and never wakes it from sleep.
        val tick = pending(context, PrayerCountdownReceiver.ACTION_TICK, TICK_REQUEST)
        alarms.cancel(tick)
        val tickAt = now.time + TICK_MILLIS
        if (settings.style == PrayerCountdownStyle.PROGRESS && tickAt < content.nextRefresh.time) {
            alarms.set(AlarmManager.RTC, tickAt, tick)
        }

        PrayerCountdownNotification.ensureChannel(context, settings.language)
        context.getSystemService(NotificationManager::class.java).notify(
            PrayerCountdownNotification.NOTIFICATION_ID,
            PrayerCountdownNotification.build(context, snapshot, settings, content, now),
        )
        Log.i(TAG, "Posted style=${settings.style.storage} next=${content.nextRefresh.time}")
        true
    }

    fun stop(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(pending(context, PrayerCountdownReceiver.ACTION_TRANSITION, TRANSITION_REQUEST))
        alarms.cancel(pending(context, PrayerCountdownReceiver.ACTION_TICK, TICK_REQUEST))
        context.getSystemService(NotificationManager::class.java)
            .cancel(PrayerCountdownNotification.NOTIFICATION_ID)
    }

    /** A refresh that failed tries again later instead of leaving a stale countdown. */
    fun scheduleRetry(context: Context) {
        runCatching {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + RETRY_MILLIS,
                pending(context, PrayerCountdownReceiver.ACTION_TRANSITION, TRANSITION_REQUEST),
            )
        }.onFailure { Log.w(TAG, "Retry alarm failed", it) }
    }

    fun status(context: Context): Map<String, Any> {
        val manager = context.getSystemService(NotificationManager::class.java)
        val channelBlocked = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                manager.getNotificationChannel(PrayerCountdownNotification.CHANNEL_ID)
                    ?.importance == NotificationManager.IMPORTANCE_NONE
        val posted = manager.activeNotifications.any {
            it.id == PrayerCountdownNotification.NOTIFICATION_ID
        }
        val liveUpdateSupported = PrayerCountdownNotification.supportsLiveUpdate()
        return mapOf(
            "enabled" to PrayerCountdownSettings.read(context).enabled,
            "posted" to posted,
            "notificationsAllowed" to manager.areNotificationsEnabled(),
            "channelBlocked" to channelBlocked,
            "hasLocation" to PrayerWidgetRepository.readSnapshot(context).hasCoordinates,
            "liveUpdateSupported" to liveUpdateSupported,
            "liveUpdateAllowed" to (liveUpdateSupported && manager.canPostPromotedNotifications()),
        )
    }

    private fun pending(context: Context, action: String, request: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            request,
            PrayerCountdownNotification.receiverIntent(context, action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/** The system pages that only the user can change for the countdown. */
internal object PrayerCountdownSettingsIntents {
    fun forTarget(context: Context, target: String?): Intent {
        val intent = when {
            target == "liveUpdate" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA ->
                Intent(Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS)
            target == "channel" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_CHANNEL_ID, PrayerCountdownNotification.CHANNEL_ID)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:${context.packageName}"))
        }
        return intent
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
}
