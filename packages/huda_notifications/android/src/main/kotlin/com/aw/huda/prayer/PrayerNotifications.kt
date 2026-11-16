package com.aw.huda.prayer

import android.app.*
import android.content.*
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

internal class PrayerNotifications(private val runtime: PrayerNotificationRuntime) {
    private val context get() = runtime.context
    private val manager get() = context.getSystemService(NotificationManager::class.java)
    fun createChannels() {
        if (Build.VERSION.SDK_INT < 26) return
        val labels = NativePrayerStrings.labels(runtime.livePolicy.values["localeCode"] as? String ?: "en")
        listOf(Triple(SILENT_CHANNEL, labels.prayers, NotificationManager.IMPORTANCE_DEFAULT),
            Triple(ADHAN_CHANNEL, labels.adhan, NotificationManager.IMPORTANCE_HIGH),
            Triple(STATUS_CHANNEL, labels.status, NotificationManager.IMPORTANCE_LOW)).forEach { (id, name, importance) ->
            manager.createNotificationChannel(NotificationChannel(id, name, importance).apply {
                setSound(null, null); enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            })
        }
        // Reminders before a prayer keep the channel's default sound, so the
        // user chooses it (or silences it) in Android's settings.
        manager.createNotificationChannel(NotificationChannel(BEFORE_CHANNEL, labels.before,
            NotificationManager.IMPORTANCE_DEFAULT).apply { lockscreenVisibility = Notification.VISIBILITY_PUBLIC })
        manager.deleteNotificationChannel(FOLLOWUP_CHANNEL)
    }
    private fun icon(): Int = context.resources.getIdentifier("ic_pray_notification", "drawable", context.packageName)
        .takeIf { it != 0 } ?: android.R.drawable.ic_lock_idle_alarm
    fun launch(occurrenceId: Long, token: String): PendingIntent? {
        // Android excludes the ordinary launcher before the first credential
        // unlock. Optional navigation must not prevent a Direct Boot alarm from
        // promoting its service or posting its terminal/silent notification.
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        intent.putExtra("hudaPrayerNavigation", token).putExtra("occurrenceId", occurrenceId)
        intent.action = "com.aw.huda.prayer.OPEN"
        intent.data = Uri.parse("huda-prayer://open/$token")
        return PendingIntent.getActivity(context, occurrenceId.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun overview(session: SessionData): PendingIntent = PendingIntent.getActivity(context, session.occurrenceId.toInt(),
        Intent(context, AdhanAlarmActivity::class.java).apply {
            action = "com.aw.huda.prayer.OVERVIEW"
            data = Uri.parse("huda-prayer://overview/${session.id}")
            putExtra("session", session.id)
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun action(session: SessionData, action: String): PendingIntent = PendingIntent.getBroadcast(context,
        session.occurrenceId.toInt(), Intent(context, PrayerActionReceiver::class.java).apply {
            this.action = "com.aw.huda.prayer.$action"
            data = Uri.parse("huda-prayer://action/${runtime.epoch()}/${session.id}/$action")
            putExtra("session", session.id); putExtra("epoch", runtime.epoch()); putExtra("id", session.occurrenceId)
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun foreground(session: SessionData, title: String, body: String): Notification {
        val strings = NativePrayerStrings.forLocale(runtime.livePolicy.values["localeCode"] as? String ?: "en")
        val builder = NotificationCompat.Builder(context, ADHAN_CHANNEL).setSmallIcon(icon())
            .setContentTitle(title).setContentText(body).setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX).setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSilent(true).setOnlyAlertOnce(true).setOngoing(true).setContentIntent(overview(session))
            .addAction(0, if (session.prayer == "sahur") runtime.sahur.settings.stop else strings.stop, action(session, "STOP"))
        val policy = runtime.effective(session.prayer)
        if (session.automatic && policy.screen && PrayerCapabilities.read(context).fullScreen) {
            // setSilent also suppresses visual interruptions and can block the
            // full-screen intent. The adhan channel already has no sound
            // or vibration; let Android present this explicitly enabled alarm UI.
            builder.setSilent(false).setFullScreenIntent(overview(session), true)
        }
        return builder.build()
    }
    /**
     * The prayer's own notification, left in the shade once its sound ends or
     * was never played. Its text never changes with the delivery outcome:
     * the reason is kept in the ledger ([PrayerNotificationRuntime.outcome])
     * and shown in Huda, not here.
     */
    @Suppress("UNUSED_PARAMETER")
    fun summary(row: AlarmRow, reason: String? = null) {
        val capability = PrayerCapabilities.read(context)
        val advance = row.purpose == "advance"
        if (!capability.notifications || !(if (advance) channelEnabled(BEFORE_CHANNEL) else capability.silentChannel)) return
        val builder = NotificationCompat.Builder(context, if (advance) BEFORE_CHANNEL else SILENT_CHANNEL).setSmallIcon(icon()).setContentTitle(row.title).setContentText(row.body)
            .setWhen(row.utcMillis).setShowWhen(true)
            // A reminder before a prayer alerts with its channel's sound; it is never an alarm.
            .setCategory(if (advance) NotificationCompat.CATEGORY_REMINDER else NotificationCompat.CATEGORY_ALARM)
            .setSilent(!advance).setOnlyAlertOnce(true)
            .setAutoCancel(true).setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(launch(row.id, row.token))
        // Android 7 has no channels; ask for the default sound directly.
        if (advance) builder.setDefaults(NotificationCompat.DEFAULT_SOUND)
        NotificationManagerCompat.from(context).notify(TAG, row.id.toInt(), builder.build())
    }
    private fun channelEnabled(id: String) = Build.VERSION.SDK_INT < 26 ||
        manager.getNotificationChannel(id)?.importance != NotificationManager.IMPORTANCE_NONE
    fun dismiss(id: Long) { manager.cancel(TAG, id.toInt()) }
    fun vibrate() {
        @Suppress("DEPRECATION") val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
        if (Build.VERSION.SDK_INT >= 26) vibrator.vibrate(android.os.VibrationEffect.createOneShot(500, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
        else @Suppress("DEPRECATION") vibrator.vibrate(500)
    }
    /// A short buzz confirming a flip was recognized.
    fun tick() {
        @Suppress("DEPRECATION") val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
        if (Build.VERSION.SDK_INT >= 26) vibrator.vibrate(android.os.VibrationEffect.createOneShot(120, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
        else @Suppress("DEPRECATION") vibrator.vibrate(120)
    }
    fun clearPrayerSummaries() {
        manager.activeNotifications.filter { it.tag == TAG }.forEach { manager.cancel(it.tag, it.id) }
    }
    companion object {
        const val SILENT_CHANNEL = "huda_prayer_silent_v1"
        const val ADHAN_CHANNEL = "huda_prayer_adhan_v1"
        const val FOLLOWUP_CHANNEL = "huda_prayer_followup_v1"
        const val STATUS_CHANNEL = "huda_prayer_status_v1"
        const val BEFORE_CHANNEL = "huda_prayer_before_v1"
        const val TAG = "huda.native.prayer"
        const val FOREGROUND_ID = 410_000_001
    }
}
