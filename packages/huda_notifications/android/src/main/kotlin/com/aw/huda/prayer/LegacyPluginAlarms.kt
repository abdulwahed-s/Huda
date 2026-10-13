package com.aw.huda.prayer

import android.app.*
import android.content.*
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.UserManager
import org.json.JSONArray
import org.json.JSONObject
import java.time.*

/** When an old plugin alarm repeats. Pure, so it is tested without Android. */
internal object LegacyPluginSchedule {
    /** The instant an entry is due, or null when it has none. */
    fun due(entry: JSONObject): Long? = try {
        if (entry.has("scheduledDateTime")) LocalDateTime.parse(entry.getString("scheduledDateTime"))
            .atZone(ZoneId.of(entry.optString("timeZoneName", "UTC"))).toInstant().toEpochMilli()
        else entry.optLong("millisecondsSinceEpoch", 0).takeIf { it > 0 }
    } catch (_: Exception) { null }

    /**
     * The first wall-clock time after [now] matching the entry's
     * `matchDateTimeComponents`, as the plugin repeated it, or null for a
     * one-time entry.
     */
    fun next(entry: JSONObject, now: Long): LocalDateTime? {
        val scheduled = try { LocalDateTime.parse(entry.getString("scheduledDateTime")) } catch (_: Exception) { return null }
        val zone = try { ZoneId.of(entry.optString("timeZoneName", "UTC")) } catch (_: Exception) { return null }
        val after = Instant.ofEpochMilli(now)
        val today = after.atZone(zone).toLocalDate()
        // Steps count from the scheduled date, so the 31st and 29 February stay put.
        val candidates: Sequence<LocalDateTime> = when (entry.optString("matchDateTimeComponents")) {
            "Time" -> generateSequence(today.minusDays(1).atTime(scheduled.toLocalTime())) { it.plusDays(1) }
            "DayOfWeekAndTime" -> {
                val start = today.minusDays(((today.dayOfWeek.value - scheduled.dayOfWeek.value + 7) % 7).toLong() + 7)
                generateSequence(start.atTime(scheduled.toLocalTime())) { it.plusWeeks(1) }
            }
            "DayOfMonthAndTime" -> generateSequence(0L) { it + 1 }.map { scheduled.plusMonths(it) }
            "DateAndTime" -> generateSequence(0L) { it + 1 }.map { scheduled.plusYears(it) }
            else -> return null
        }
        return candidates.take(2000).firstOrNull { it.atZone(zone).toInstant().isAfter(after) && it.isAfter(scheduled) }
    }

    /** How late a delivery may still be shown, e.g. after the device was off. */
    fun lateWindow(entry: JSONObject): Long =
        if (entry.optString("channelId") == "event_reminder") 12 * 3_600_000L else 3_600_000L
}

internal object LegacyPluginAlarms {
    const val RECEIVER = "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    const val DETAILS_EXTRA = "notificationDetails"
    private const val FILE = "scheduled_notifications"
    private val lock = Any()

    private fun read(context: Context): MutableList<JSONObject> {
        val raw = context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString(FILE, "[]") ?: "[]"
        val rows = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        return (0 until rows.length()).mapNotNull { rows.optJSONObject(it) }.toMutableList()
    }

    private fun write(context: Context, entries: List<JSONObject>) {
        val raw = JSONArray().apply { entries.forEach { put(it) } }.toString()
        check(context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putString(FILE, raw).commit()) { "storageUnavailable" }
    }

    /** Every entry, mapped as [LegacyPrayerDeliveryBridge.inventory] maps prayers. */
    fun list(context: Context): List<EventData> = synchronized(lock) { read(context) }.mapNotNull { row ->
        val id = row.optLong("id", -1).takeIf { it >= 0 } ?: return@mapNotNull null
        val zone = row.optString("timeZoneName", "UTC")
        val utc = LegacyPluginSchedule.due(row) ?: 0L
        val date = try { if (utc > 0) Instant.ofEpochMilli(utc).atZone(ZoneId.of(zone)).toLocalDate().toString() else "" }
            catch (_: Exception) { "" }
        val payload = row.optString("payload").takeIf { it.isNotBlank() }
        EventData(id, if (LegacyPrayerDeliveryBridge.isPrayer(id, payload, row.optString("channelId"))) "" else "standard",
            utc, zone, date, row.optString("title", ""), row.optString("body", ""), payload)
    }

    /** Cancels each alarm and forgets its entry. */
    fun cancel(context: Context, ids: Collection<Long>): Unit = synchronized(lock) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        ids.forEach { id -> pending(context, id.toInt(), null, PendingIntent.FLAG_NO_CREATE)?.let { alarms.cancel(it); it.cancel() } }
        val entries = read(context)
        if (entries.removeAll { it.optLong("id", -1) in ids }) write(context, entries)
        ids.forEach { LegacyPrayerDeliveryBridge.releaseAlarm(context, it.toInt()) }
    }

    /**
     * Re-arms every entry after a reboot, as FLN's boot receiver did. A time
     * that passed while the device was off fires at once, and [deliver] judges
     * whether it is still worth showing.
     */
    fun repair(context: Context) {
        if (!context.getSystemService(UserManager::class.java).isUserUnlocked) return
        synchronized(lock) { repairLocked(context) }
    }

    private fun repairLocked(context: Context) {
        val entries = read(context)
        val kept = entries.filter { entry ->
            val id = entry.optInt("id")
            val restore = LegacyPrayerDeliveryBridge.allowRestore(context, id, entry.optString("payload").ifBlank { null },
                entry.optString("channelId").ifBlank { null })
            val due = LegacyPluginSchedule.due(entry)
            if (restore && due != null) arm(context, entry, due)
            else LegacyPrayerDeliveryBridge.releaseAlarm(context, id)
            restore && due != null
        }
        if (kept.size != entries.size) write(context, kept)
    }

    fun deliver(context: Context, intent: Intent) {
        synchronized(lock) { deliverLocked(context, intent) }
    }

    private fun deliverLocked(context: Context, intent: Intent) {
        val fired = try { JSONObject(intent.getStringExtra(DETAILS_EXTRA) ?: return) } catch (_: Exception) { return }
        val entries = read(context)
        // A cancelled entry is never shown, even if its alarm survived.
        val entry = entries.firstOrNull { it.optInt("id") == fired.optInt("id", -1) } ?: return
        val id = entry.optInt("id")
        val payload = entry.optString("payload").ifBlank { null }
        val channel = entry.optString("channelId").ifBlank { null }
        val due = LegacyPluginSchedule.due(entry)
        if (!LegacyPrayerDeliveryBridge.allowDelivery(context, id, payload, channel)) {
            // An early prayer callback keeps its entry and fires again on time.
            if (LegacyPrayerDeliveryBridge.shouldDeferDelivery(context, id, payload, channel) && due != null) {
                arm(context, entry, due)
            } else {
                entries.remove(entry); write(context, entries)
                LegacyPrayerDeliveryBridge.releaseAlarm(context, id)
            }
            return
        }
        val now = PrayerNotificationRuntime.get(context).nowMillis()
        // Prayers were judged by the claim ledger; other reminders by their late window.
        if (LegacyPrayerDeliveryBridge.isPrayer(id.toLong(), payload, channel) ||
            due == null || now - due <= LegacyPluginSchedule.lateWindow(entry)) post(context, entry)
        val next = LegacyPluginSchedule.next(entry, now)
        if (next == null) {
            entries.remove(entry); write(context, entries)
            LegacyPrayerDeliveryBridge.releaseAlarm(context, id)
        } else {
            entry.put("scheduledDateTime", next.toString())
            write(context, entries)
            LegacyPluginSchedule.due(entry)?.let { arm(context, entry, it) }
        }
    }

    /** Equal to the plugin's own: same receiver class, request code (the ID) and flags. */
    private fun pending(context: Context, id: Int, details: String?, flags: Int): PendingIntent? =
        PendingIntent.getBroadcast(context, id, Intent().setClassName(context, RECEIVER).apply {
            details?.let { putExtra(DETAILS_EXTRA, it) }
        }, flags or PendingIntent.FLAG_IMMUTABLE)

    private fun arm(context: Context, entry: JSONObject, at: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val intent = pending(context, entry.optInt("id"), entry.toString(), PendingIntent.FLAG_UPDATE_CURRENT)!!
        val mode = entry.optString("scheduleMode", "exact")
        val exactAllowed = Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()
        try {
            when {
                mode == "alarmClock" && exactAllowed -> alarms.setAlarmClock(AlarmManager.AlarmClockInfo(at, intent), intent)
                mode in setOf("exact", "exactAllowWhileIdle") && exactAllowed ->
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
                else -> alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            }
        } catch (_: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    /** Shown as the plugin showed it, untagged under its ID; a tap opens its page. */
    private fun post(context: Context, entry: JSONObject) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val id = entry.optInt("id")
        val channel = entry.optString("channelId").ifBlank { "islamic_reminders" }
        ensureChannel(context, manager, channel, entry)
        val title = entry.optString("title")
        val body = entry.optString("body")
        val builder = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel)
            else @Suppress("DEPRECATION") Notification.Builder(context).setPriority(entry.optInt("priority", 1)))
            .setSmallIcon(icon(context, entry.optString("icon")))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(entry.optBoolean("autoCancel", true))
            .setShowWhen(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
        if (entry.has("color")) builder.setColor(entry.optInt("color"))
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            launch.action = "com.aw.huda.reminder.OPEN"
            launch.data = Uri.parse("huda-legacy://open/$id")
            entry.optString("payload").takeIf { it.isNotBlank() }?.let { launch.putExtra(ReminderScheduler.TAP_EXTRA, it) }
            builder.setContentIntent(PendingIntent.getActivity(context, id, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        }
        manager.notify(id, builder.build())
    }

    private fun icon(context: Context, name: String): Int =
        listOf(name to "drawable", name to "mipmap", "ic_launcher" to "mipmap")
            .filter { it.first.isNotBlank() }
            .map { (resource, type) -> context.resources.getIdentifier(resource, type, context.packageName) }
            .firstOrNull { it != 0 } ?: android.R.drawable.ic_popup_reminder

    /** The plugin created a channel when it first showed on it; do the same from the saved details. */
    private fun ensureChannel(context: Context, manager: NotificationManager, id: String, entry: JSONObject) {
        if (Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(id) != null) return
        val importance = entry.optInt("importance", NotificationManager.IMPORTANCE_HIGH)
            .coerceIn(NotificationManager.IMPORTANCE_MIN, NotificationManager.IMPORTANCE_MAX)
        manager.createNotificationChannel(NotificationChannel(id, entry.optString("channelName").ifBlank { id }, importance).apply {
            entry.optString("channelDescription").takeIf { it.isNotBlank() }?.let { description = it }
            enableVibration(entry.optBoolean("enableVibration", true))
            setShowBadge(entry.optBoolean("channelShowBadge", true))
            val sound = entry.optString("sound").takeIf { it.isNotBlank() }
                ?.let { context.resources.getIdentifier(it, "raw", context.packageName) }?.takeIf { it != 0 }
            when {
                !entry.optBoolean("playSound", true) -> setSound(null, null)
                sound != null -> setSound(Uri.parse("android.resource://${context.packageName}/$sound"),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            }
        })
    }
}
