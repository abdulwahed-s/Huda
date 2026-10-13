package com.aw.huda.prayer

import android.app.*
import android.content.*
import android.graphics.Color
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import java.time.*
import kotlin.random.Random

/** When reminders fire. Pure, so it is tested without Android. */
internal object ReminderRules {
    /** The first delivery strictly after [after], or null when a one-time reminder has passed. */
    fun next(rule: ReminderData, after: Long, zone: ZoneId): Long? = when (rule.kind) {
        "once" -> rule.utcMillis.takeIf { it > after }
        "daily", "weekly" -> {
            val hour = requireNotNull(rule.hour).toInt()
            val minute = requireNotNull(rule.minute).toInt()
            val start = Instant.ofEpochMilli(after).atZone(zone).toLocalDate()
            // Eight days covers every weekday; DST gaps resolve forward.
            (0L..8L).asSequence()
                .map { start.plusDays(it) }
                .filter { rule.kind == "daily" || it.dayOfWeek.value.toLong() == rule.weekday }
                .map { it.atTime(hour, minute).atZone(zone).toInstant().toEpochMilli() }
                .first { it > after }
        }
        "interval" -> {
            val step = requireNotNull(rule.intervalMinutes) * 60_000L
            require(step > 0) { "invalidReminder" }
            if (rule.utcMillis > after) rule.utcMillis
            else rule.utcMillis + ((after - rule.utcMillis) / step + 1) * step
        }
        else -> throw IllegalArgumentException("invalidReminder")
    }

    /** How late a delivery may still be shown, e.g. after the device was off. */
    fun lateWindow(rule: ReminderData): Long = when (rule.kind) {
        "once" -> 12 * 3_600_000L
        "interval" -> requireNotNull(rule.intervalMinutes) * 60_000L
        else -> 3_600_000L
    }

    fun validate(rule: ReminderData) {
        require(rule.kind in setOf("once", "daily", "weekly", "interval")) { "invalidReminder" }
        require(rule.style in setOf("dailyReminder", "weeklyReminder", "athkar", "calendar")) { "invalidReminder" }
        if (rule.kind == "daily" || rule.kind == "weekly") {
            require(rule.hour in 0L..23L && rule.minute in 0L..59L) { "invalidReminder" }
        }
        if (rule.kind == "weekly") require(rule.weekday in 1L..7L) { "invalidReminder" }
        if (rule.kind == "interval") {
            require((rule.intervalMinutes ?: 0L) in 1L..1440L && rule.texts.isNotEmpty()) { "invalidReminder" }
        }
    }
}

/**
 * Reminders, random Athkar and calendar events, owned by the app instead of
 * the notification plugin. Each reminder is one alarm: repeats re-arm after
 * every delivery, and random Athkar pick their text when they fire. Rules
 * live in the state table under `reminder:<id>`, so a reboot, time change or
 * update re-arms them without Flutter.
 */
internal class ReminderScheduler(private val runtime: PrayerNotificationRuntime) {
    private val context = runtime.context
    private val alarms = context.getSystemService(AlarmManager::class.java)
    private val manager = context.getSystemService(NotificationManager::class.java)
    internal var zone: () -> ZoneId = ZoneId::systemDefault
    internal var random: Random = Random.Default

    fun list(): List<ReminderData> = runtime.store.dao.states("$KEY%")
        .mapNotNull { runtime.store.gson.fromJson(it.value, ReminderData::class.java) }
        .sortedBy { it.id }

    /** Cancels first, then schedules; returns the IDs that were not accepted. */
    fun apply(batch: ReminderBatch): List<Long> {
        batch.cancel.forEach(::remove)
        val failed = mutableListOf<Long>()
        for (rule in batch.schedule) {
            try {
                ReminderRules.validate(rule)
                val next = ReminderRules.next(rule, runtime.nowMillis(), zone()) ?: error("deadlineProtected")
                arm(rule.copy(utcMillis = next))
            } catch (_: Exception) {
                remove(rule.id)
                failed += rule.id
            }
        }
        return failed
    }

    /** Cancels every reminder, for an app-wide reset. */
    fun clear() = list().forEach { remove(it.id) }

    /**
     * Re-arms every stored reminder after a reboot, time change or update.
     * A delivery missed while the device was off is still shown within its
     * late window; one already delivered is never repeated, even when the
     * clock moves back.
     */
    fun repair() {
        for (rule in list()) {
            val after = maxOf(runtime.nowMillis() - ReminderRules.lateWindow(rule), lastDelivered(rule.id))
            val next = ReminderRules.next(rule, after, zone())
            if (next == null) remove(rule.id) else try { arm(rule.copy(utcMillis = next)) } catch (_: Exception) { }
        }
    }

    fun deliver(id: Long, dueMillis: Long) {
        val rule = runtime.store.read("$KEY$id", ReminderData::class.java) ?: return
        // A stale alarm from an earlier schedule of this ID.
        if (rule.utcMillis != dueMillis) return
        val now = runtime.nowMillis()
        if (now < rule.utcMillis) { arm(rule); return }
        // Recorded before posting: a crash never shows the same delivery twice.
        if (rule.utcMillis > lastDelivered(id)) {
            runtime.store.putText("$DELIVERED$id", rule.utcMillis.toString())
            if (now - rule.utcMillis <= ReminderRules.lateWindow(rule)) post(rule)
        }
        val next = ReminderRules.next(rule, now, zone())
        if (next == null) remove(id) else arm(rule.copy(utcMillis = next))
    }

    private fun lastDelivered(id: Long) = runtime.store.text("$DELIVERED$id").toLongOrNull() ?: Long.MIN_VALUE

    private fun arm(rule: ReminderData) {
        runtime.store.write("$KEY${rule.id}", rule)
        val intent = pending(rule.id, rule.utcMillis, PendingIntent.FLAG_UPDATE_CURRENT)!!
        // Athkar are not time-critical; inexact alarms let Android batch them.
        val exact = rule.style != "athkar" && (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms())
        try {
            if (exact) alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, rule.utcMillis, intent)
            else alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, rule.utcMillis, intent)
        } catch (_: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, rule.utcMillis, intent)
        }
    }

    private fun remove(id: Long) {
        pending(id, 0, PendingIntent.FLAG_NO_CREATE)?.let { alarms.cancel(it); it.cancel() }
        runtime.store.dao.deleteState("$KEY$id")
        runtime.store.dao.deleteState("$DELIVERED$id")
    }

    private fun pending(id: Long, due: Long, flags: Int): PendingIntent? = PendingIntent.getBroadcast(context,
        id.toInt(), Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = ACTION
            data = Uri.parse("huda-reminder://alarm/$id")
            putExtra("id", id)
            putExtra("due", due)
        }, flags or PendingIntent.FLAG_IMMUTABLE)

    private fun post(rule: ReminderData) {
        val channel = when (rule.style) {
            "weeklyReminder" -> "kahf_friday"
            "calendar" -> "event_reminder"
            else -> "islamic_reminders"
        }
        ensureChannel(channel)
        val body = if (rule.kind == "interval") rule.texts[random.nextInt(rule.texts.size)] else rule.body
        val builder = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel)
            else @Suppress("DEPRECATION") Notification.Builder(context))
            .setSmallIcon(icon(rule.style))
            .setContentTitle(rule.title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setShowWhen(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setColor(rule.color?.toInt() ?: GREEN)
        tap(rule)?.let(builder::setContentIntent)
        manager.notify(TAG, rule.id.toInt(), builder.build())
    }

    private fun tap(rule: ReminderData): PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        intent.action = "com.aw.huda.reminder.OPEN"
        intent.data = Uri.parse("huda-reminder://open/${rule.id}")
        intent.putExtra(TAP_EXTRA, rule.payload)
        return PendingIntent.getActivity(context, rule.id.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun icon(style: String): Int {
        val name = when (style) {
            "weeklyReminder" -> "ic_notification_jummah"
            "athkar" -> "ic_notification_random"
            "calendar" -> "ic_calendar_notification"
            else -> "ic_notification_islam"
        }
        return listOf(name to "drawable", name to "mipmap", "ic_launcher" to "mipmap")
            .map { (resource, type) -> context.resources.getIdentifier(resource, type, context.packageName) }
            .firstOrNull { it != 0 } ?: android.R.drawable.ic_popup_reminder
    }

    /** Reuses existing channel IDs and sound settings. */
    private fun ensureChannel(id: String) {
        if (Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(id) != null) return
        val name = when (id) {
            "kahf_friday" -> "Al-Kahf Friday"
            "event_reminder" -> "Event Reminder"
            else -> "Islamic Reminders"
        }
        manager.createNotificationChannel(NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH).apply {
            val sound = context.resources.getIdentifier("notification", "raw", context.packageName)
            if (id != "event_reminder" && sound != 0) {
                setSound(Uri.parse("android.resource://${context.packageName}/$sound"),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            }
        })
    }

    companion object {
        const val KEY = "reminder:"
        const val DELIVERED = "reminderDelivered:"
        const val ACTION = "com.aw.huda.reminder.DELIVER"
        const val TAG = "huda.reminder"
        const val TAP_EXTRA = "hudaReminderPayload"
        private val GREEN = Color.rgb(76, 175, 80)
    }
}

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderScheduler.ACTION) return
        val pending = goAsync()
        val runtime = PrayerNotificationRuntime.get(context)
        runtime.delivery.execute {
            try {
                runtime.initialize()
                runtime.reminders.deliver(intent.getLongExtra("id", -1), intent.getLongExtra("due", -1))
            } catch (_: Exception) {
                // Storage before the first unlock or a removed rule; repair re-arms later.
            } finally { pending.finish() }
        }
    }
}
