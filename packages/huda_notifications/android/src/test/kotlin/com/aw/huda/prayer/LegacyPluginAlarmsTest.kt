package com.aw.huda.prayer

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.ResolveInfo
import android.os.UserManager
import com.aw.huda.prayer.core.PrayerOccurrenceIdentity
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import org.json.JSONArray
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.time.*
import java.util.concurrent.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LegacyPluginAlarmsTest {
    private val zone = ZoneId.of("Asia/Muscat")
    private fun at(text: String) = LocalDateTime.parse(text).atZone(zone).toInstant().toEpochMilli()
    private var now = at("2026-10-13T20:00")
    private lateinit var runtime: PrayerNotificationRuntime
    private val context: Context get() = runtime.context
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(120, TimeUnit.SECONDS)

    private val alarms get() = Shadows.shadowOf(context.getSystemService(AlarmManager::class.java))
    private val posted: List<Notification> get() = Shadows.shadowOf(
        context.getSystemService(NotificationManager::class.java)).allNotifications

    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit().clear().commit()
        runtime = PrayerNotificationRuntime.get(context)
        runtime.wallClock = { now }
        offMain { runtime.initialize() }
    }
    @After fun cleanup() { PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }

    /** An entry as FLN 22 saved it for `zonedSchedule`. */
    private fun entry(id: Int, local: String, components: String? = null, payload: String? = null,
        channel: String = "islamic_reminders") = JSONObject().put("id", id).put("title", "Title $id").put("body", "Body $id")
        .put("channelId", channel).put("channelName", "Islamic Reminders").put("importance", 4).put("priority", 1)
        .put("icon", "ic_notification_islam").put("scheduledDateTime", local).put("timeZoneName", zone.id)
        .put("scheduleMode", "exactAllowWhileIdle").apply {
            components?.let { put("matchDateTimeComponents", it) }
            payload?.let { put("payload", it) }
        }

    /** What FLN left behind: its cache entry and an alarm targeting its receiver. */
    private fun scheduleLikeFln(vararg entries: JSONObject) {
        val saved = JSONArray().apply { entries.forEach { put(it) } }
        assertTrue(context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit()
            .putString("scheduled_notifications", saved.toString()).commit())
        entries.forEach { entry ->
            val intent = Intent(context, ScheduledNotificationReceiver::class.java)
                .putExtra("notificationDetails", entry.toString())
            val pending = PendingIntent.getBroadcast(context, entry.getInt("id"), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            context.getSystemService(AlarmManager::class.java)
                .setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, LegacyPluginSchedule.due(entry)!!, pending)
        }
    }

    private fun cached(): List<JSONObject> {
        val raw = context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
            .getString("scheduled_notifications", "[]")!!
        return JSONArray(raw).let { rows -> (0 until rows.length()).map { rows.getJSONObject(it) } }
    }

    /** Fires the alarm FLN registered, the way AlarmManager would. */
    private fun fire(id: Int) {
        val alarm = alarms.scheduledAlarms.single { Shadows.shadowOf(it.operation).requestCode == id }
        val intent = Shadows.shadowOf(alarm.operation).savedIntent
        assertEquals(LegacyPluginAlarms.RECEIVER, intent.component!!.className)
        context.getSystemService(AlarmManager::class.java).cancel(alarm.operation!!)
        offMain { LegacyPluginAlarms.deliver(context, intent) }
    }

    @Test fun repeatsFollowThePluginsDateComponents() {
        val daily = entry(1002, "2026-10-13T07:00", "Time")
        assertEquals(LocalDateTime.parse("2026-10-14T07:00"), LegacyPluginSchedule.next(daily, now))
        // 2026-10-16 is a Friday.
        val weekly = entry(1001, "2026-10-09T09:00", "DayOfWeekAndTime")
        assertEquals(LocalDateTime.parse("2026-10-16T09:00"), LegacyPluginSchedule.next(weekly, now))
        val yearly = entry(4200, "2024-02-29T08:00", "DateAndTime")
        assertEquals(LocalDateTime.parse("2027-02-28T08:00"), LegacyPluginSchedule.next(yearly, now))
        assertNull(LegacyPluginSchedule.next(entry(1101, "2026-10-13T19:00"), now))
    }

    @Test fun aDailyReminderIsShownThroughHudaAndRearmedInThePluginsFormat() {
        // Huda's launcher activity, which the tap opens.
        Shadows.shadowOf(context.packageManager).addResolveInfoForIntent(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER).setPackage(context.packageName),
            ResolveInfo().apply { activityInfo = ActivityInfo().apply { packageName = context.packageName; name = "MainActivity" } })
        scheduleLikeFln(entry(1002, "2026-10-14T07:00", "Time", payload = """["huda-reminder-v1",1002]"""))
        now = at("2026-10-14T07:00") + 3_000

        fire(1002)

        val shown = posted.single()
        assertEquals("Title 1002", shown.extras.getString(Notification.EXTRA_TITLE))
        assertEquals("islamic_reminders", shown.channelId)
        val tap = Shadows.shadowOf(shown.contentIntent).savedIntent
        assertEquals("""["huda-reminder-v1",1002]""", tap.getStringExtra(ReminderScheduler.TAP_EXTRA))
        assertEquals("2026-10-15T07:00", cached().single().getString("scheduledDateTime"))
        val next = alarms.scheduledAlarms.single()
        assertEquals(at("2026-10-15T07:00"), next.triggerAtTime)
        assertEquals(LegacyPluginAlarms.RECEIVER, Shadows.shadowOf(next.operation).savedIntent.component!!.className)
    }

    @Test fun aOneTimeReminderIsShownOnceAndForgotten() {
        scheduleLikeFln(entry(1101, "2026-10-13T20:30", payload = """["huda-athkar-v1",1101]"""))
        now = at("2026-10-13T20:30")

        fire(1101)

        assertEquals(1, posted.size)
        assertTrue(cached().isEmpty())
        assertTrue(alarms.scheduledAlarms.isEmpty())
    }

    @Test fun aLateReminderIsSkippedButStillRepeats() {
        scheduleLikeFln(entry(1003, "2026-10-14T07:00", "Time"))
        now = at("2026-10-14T09:00")

        fire(1003)

        assertTrue(posted.isEmpty())
        assertEquals(at("2026-10-15T07:00"), alarms.scheduledAlarms.single().triggerAtTime)
    }

    @Test fun anAlarmWhoseEntryWasCancelledShowsNothing() {
        scheduleLikeFln(entry(1004, "2026-10-13T20:30"))
        val intent = Shadows.shadowOf(alarms.scheduledAlarms.single().operation).savedIntent
        context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit().clear().commit()
        now = at("2026-10-13T20:30")

        offMain { LegacyPluginAlarms.deliver(context, intent) }

        assertTrue(posted.isEmpty())
    }

    @Test fun anOldPrayerIsClaimedOnceThroughTheLedger() {
        val utc = at("2026-10-14T05:00")
        val date = Instant.ofEpochMilli(utc).atZone(zone).toLocalDate()
        val id = PrayerOccurrenceIdentity.idFor(date, "fajr").toInt()
        val payload = JSONObject().put("type", "prayer_time").put("prayer", "fajr")
            .put("scheduledUtc", Instant.ofEpochMilli(utc).toString()).put("timeZone", zone.id).toString()
        val prayer = entry(id, "2026-10-14T05:00", payload = payload, channel = "prayer_times_channel")
        scheduleLikeFln(prayer)

        // An early callback keeps the entry and fires again on time.
        now = utc - 60_000
        fire(id)
        assertTrue(posted.isEmpty())
        assertEquals(1, cached().size)
        assertEquals(utc, alarms.scheduledAlarms.single().triggerAtTime)

        now = utc + 1_000
        fire(id)
        assertEquals("prayer_times_channel", posted.single().channelId)
        assertTrue(cached().isEmpty())
        assertNotNull(offMain { runtime.store.dao.claim(id.toLong()) })

        // A duplicate of the same alarm is never shown twice.
        scheduleLikeFln(prayer)
        fire(id)
        assertEquals(1, posted.size)
    }

    @Test fun cancelRemovesTheAlarmAndTheEntry() {
        scheduleLikeFln(entry(1002, "2026-10-14T07:00", "Time"), entry(1005, "2026-10-14T08:00", "Time"))
        offMain { LegacyPrayerDeliveryBridge.reserveAlarm(context, 1002) }

        offMain { LegacyPluginAlarms.cancel(context, listOf(1002L)) }

        assertEquals(listOf(1005), cached().map { it.getInt("id") })
        assertEquals(listOf(1005), alarms.scheduledAlarms.map { Shadows.shadowOf(it.operation).requestCode })
        assertNull(offMain { runtime.store.dao.state("standard:1002") })
    }

    @Test fun listMarksPrayersAndEverythingElse() {
        val utc = at("2026-10-14T05:00")
        val id = PrayerOccurrenceIdentity.idFor(Instant.ofEpochMilli(utc).atZone(zone).toLocalDate(), "fajr").toInt()
        scheduleLikeFln(
            entry(id, "2026-10-14T05:00", payload = """{"type":"prayer_time","prayer":"fajr"}""", channel = "prayer_times_channel"),
            // A calendar event without a payload can have a hashed ID in the prayer range.
            entry(2100, "2026-11-01T07:00", "DateAndTime", channel = "event_reminder"),
            entry(1002, "2026-10-14T07:00", "Time"))

        val listed = offMain { LegacyPluginAlarms.list(context) }.associateBy { it.id }

        assertEquals("", listed.getValue(id.toLong()).prayer)
        assertEquals(utc, listed.getValue(id.toLong()).utcMillis)
        assertEquals("standard", listed.getValue(2100).prayer)
        assertEquals("standard", listed.getValue(1002).prayer)
    }

    @Test fun aRebootRearmsEntriesAndDropsPastPrayers() {
        val utc = at("2026-10-13T19:00")
        val id = PrayerOccurrenceIdentity.idFor(Instant.ofEpochMilli(utc).atZone(zone).toLocalDate(), "isha").toInt()
        val payload = JSONObject().put("type", "prayer_time").put("prayer", "isha")
            .put("scheduledUtc", Instant.ofEpochMilli(utc).toString()).put("timeZone", zone.id).toString()
        scheduleLikeFln(entry(1002, "2026-10-14T07:00", "Time"),
            entry(id, "2026-10-13T19:00", payload = payload, channel = "prayer_times_channel"))
        // A reboot clears every alarm.
        alarms.scheduledAlarms.forEach { context.getSystemService(AlarmManager::class.java).cancel(it.operation!!) }

        offMain { LegacyPluginAlarms.repair(context) }

        assertEquals(listOf(1002), cached().map { it.getInt("id") })
        assertEquals(at("2026-10-14T07:00"), alarms.scheduledAlarms.single().triggerAtTime)
    }
}
