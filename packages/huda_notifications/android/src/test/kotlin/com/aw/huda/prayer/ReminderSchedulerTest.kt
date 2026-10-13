package com.aw.huda.prayer

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import android.os.UserManager
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.time.*
import java.util.concurrent.*
import kotlin.random.Random

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class ReminderSchedulerTest {
    private val zone = ZoneId.of("Asia/Muscat")
    private fun at(text: String) = LocalDateTime.parse(text).atZone(zone).toInstant().toEpochMilli()
    private var now = at("2026-10-13T20:00")
    private lateinit var runtime: PrayerNotificationRuntime
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(120, TimeUnit.SECONDS)

    private fun rule(id: Long, kind: String, utcMillis: Long = now + 60_000, hour: Long? = null,
        minute: Long? = null, weekday: Long? = null, interval: Long? = null,
        texts: List<String> = emptyList(), style: String = "dailyReminder") =
        ReminderData(id, kind, style, "Title $id", "Body $id", "payload-$id", utcMillis, hour, minute,
            weekday, interval, texts, null)

    private val alarms get() = Shadows.shadowOf(runtime.context.getSystemService(AlarmManager::class.java))
    private val posted: List<Notification> get() = Shadows.shadowOf(
        runtime.context.getSystemService(NotificationManager::class.java)).allNotifications

    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        runtime = PrayerNotificationRuntime.get(context)
        runtime.wallClock = { now }
        runtime.reminders.zone = { zone }
        runtime.reminders.random = Random(7)
        offMain { runtime.initialize() }
    }
    @After fun cleanup() { PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }

    @Test fun nextDeliveryFollowsLocalTime() {
        assertEquals(at("2026-10-14T07:00"),
            ReminderRules.next(rule(1, "daily", hour = 7, minute = 0), now, zone))
        assertEquals(at("2026-10-13T20:30"),
            ReminderRules.next(rule(1, "daily", hour = 20, minute = 30), now, zone))
        // 2026-10-13 is a Tuesday; Friday is ISO 5.
        assertEquals(at("2026-10-16T09:00"),
            ReminderRules.next(rule(1, "weekly", hour = 9, minute = 0, weekday = 5), now, zone))
        val anchor = now - 150 * 60_000L
        assertEquals(anchor + 180 * 60_000L,
            ReminderRules.next(rule(1, "interval", utcMillis = anchor, interval = 60, texts = listOf("a")), now, zone))
        assertNull(ReminderRules.next(rule(1, "once", utcMillis = now - 1), now, zone))
    }

    @Test fun appliedRemindersAreStoredArmedAndCounted() {
        // Below the 300-prayer cap, so the reminders' share is visible.
        val before = offMain { runtime.updateQuota(QuotaData(150, 30, 8, 4, 1)) }
        assertEquals(257, before)
        val failed = offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(
            rule(1002, "daily", hour = 7, minute = 0),
            rule(1101, "interval", interval = 60, texts = listOf("a", "b"), style = "athkar")))) }

        assertTrue(failed.isEmpty())
        val stored = offMain { runtime.reminders.list() }
        assertEquals(listOf(1002L, 1101L), stored.map { it.id })
        assertEquals(at("2026-10-14T07:00"), stored.first().utcMillis)
        assertEquals(2, alarms.scheduledAlarms.size)
        assertEquals(before - 2, offMain { runtime.quota() })

        offMain { runtime.reminders.apply(ReminderBatch(listOf(1002L), emptyList())) }
        assertEquals(listOf(1101L), offMain { runtime.reminders.list() }.map { it.id })
        assertEquals(1, alarms.scheduledAlarms.size)
    }

    @Test fun invalidRulesAreRejectedWithoutState() {
        val failed = offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(
            rule(1, "daily", hour = 25, minute = 0),
            rule(2, "once", utcMillis = now - 1),
            rule(3, "interval", interval = 60)))) }

        assertEquals(listOf(1L, 2L, 3L), failed)
        assertTrue(offMain { runtime.reminders.list() }.isEmpty())
        assertTrue(alarms.scheduledAlarms.isEmpty())
    }

    @Test fun deliveryPostsOnceAndRearmsTheNextDay() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(rule(1004, "daily", hour = 7, minute = 0)))) }
        val due = at("2026-10-14T07:00")
        now = due + 5_000

        offMain { runtime.reminders.deliver(1004, due) }
        offMain { runtime.reminders.deliver(1004, due) }

        assertEquals(1, posted.size)
        assertEquals("Title 1004", posted.single().extras.getString(Notification.EXTRA_TITLE))
        assertEquals(at("2026-10-15T07:00"), offMain { runtime.reminders.list() }.single().utcMillis)
    }

    @Test fun athkarPickTheirTextAtDelivery() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(
            rule(1101, "interval", utcMillis = now + 60_000, interval = 30,
                texts = listOf("first", "second"), style = "athkar")))) }
        now += 60_000

        offMain { runtime.reminders.deliver(1101, now) }

        val text = posted.single().extras.getString(Notification.EXTRA_TEXT)
        assertTrue(text in setOf("first", "second"))
        assertEquals(now + 30 * 60_000L, offMain { runtime.reminders.list() }.single().utcMillis)
    }

    @Test fun repairNeverRepeatsADeliveryWhenTheClockMovesBack() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(rule(1004, "daily", hour = 7, minute = 0)))) }
        val due = at("2026-10-14T07:00")
        now = due + 1_000
        offMain { runtime.reminders.deliver(1004, due) }

        now = at("2026-10-14T06:30")
        offMain { runtime.reminders.repair() }

        assertEquals(at("2026-10-15T07:00"), offMain { runtime.reminders.list() }.single().utcMillis)
    }

    @Test fun repairShowsADeliveryMissedWhileTheDeviceWasOff() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(rule(1004, "daily", hour = 7, minute = 0)))) }
        val due = at("2026-10-14T07:00")
        now = at("2026-10-14T07:20")

        offMain { runtime.reminders.repair() }
        assertEquals(due, offMain { runtime.reminders.list() }.single().utcMillis)
        offMain { runtime.reminders.deliver(1004, due) }

        assertEquals(1, posted.size)
        assertEquals(at("2026-10-15T07:00"), offMain { runtime.reminders.list() }.single().utcMillis)
    }

    @Test fun anAppWideResetCancelsReminders() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(rule(1004, "daily", hour = 7, minute = 0)))) }

        // Reset stops playback on the main thread, which Robolectric runs here.
        val reset = io.submit { runtime.reset(false) }
        while (!reset.isDone) Shadows.shadowOf(Looper.getMainLooper()).idle()
        reset.get()

        assertTrue(offMain { runtime.reminders.list() }.isEmpty())
        assertTrue(alarms.scheduledAlarms.isEmpty())
    }

    @Test fun aLongMissedOneTimeReminderIsDropped() {
        offMain { runtime.reminders.apply(ReminderBatch(emptyList(), listOf(
            rule(420000001, "once", utcMillis = at("2026-10-14T09:00"), style = "calendar")))) }
        now = at("2026-10-15T09:00")

        offMain { runtime.reminders.repair() }

        assertTrue(offMain { runtime.reminders.list() }.isEmpty())
    }
}
