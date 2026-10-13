package com.aw.huda.prayer

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.os.UserManager
import com.aw.huda.prayer.core.PrayerOccurrenceIdentity
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.time.*
import java.util.concurrent.*

/** Reminders before a prayer: derived natively from the owned prayer rows. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class PrayerAdvanceReminderTest {
    private lateinit var runtime: PrayerNotificationRuntime
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(120, TimeUnit.SECONDS)
    private val manager get() = runtime.context.getSystemService(NotificationManager::class.java)
    private val alarmManager get() = Shadows.shadowOf(runtime.context.getSystemService(AlarmManager::class.java))

    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        runtime = PrayerNotificationRuntime.get(context)
        offMain { runtime.initialize() }
    }
    @After fun cleanup() { PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }

    // AlarmManager registration rejects deadlines before the real clock, so
    // every fixture starts tomorrow (UTC) at fixed hours.
    private val base = Instant.now().atZone(ZoneOffset.UTC).toLocalDate().plusDays(1)
    private val hours = mapOf("fajr" to 5L, "dhuhr" to 12L, "asr" to 15L, "maghrib" to 18L, "isha" to 20L)
    private fun events(days: Int, prayers: List<String> = PrayerRules.prayers) = (0 until days).flatMap { day ->
        val date = base.plusDays(day.toLong())
        prayers.map { prayer ->
            EventData(PrayerOccurrenceIdentity.idFor(date, prayer), prayer,
                date.atStartOfDay(ZoneOffset.UTC).plusHours(hours.getValue(prayer)).toInstant().toEpochMilli(),
                "UTC", date.toString(), "Time for $prayer", "Prayer time", null)
        }
    }
    private fun plan(events: List<EventData>, id: String = "first", generation: Long = 0): PlanReceipt {
        val policy = runtime.policy()
        val prepared = runtime.plans.prepare(PlanRequest(id, generation, policy.revision, 1, generation + 1,
            runtime.digest("lat:23.588|lon:58.3829"), runtime.digest(id), PrayerPolicy.eligibility(policy),
            runtime.quota(), events, emptyList(), emptyList()))
        assertEquals(prepared.error, "prepared", prepared.state)
        return runtime.plans.activate(id, generation)
    }
    /** Saves the policy, then waits for the reminder sync it queues. */
    private fun policy(vararg values: Pair<String, Any?>) {
        runtime.setPolicy(runtime.policy().copy(values = runtime.policy().values + values), runtime.policy().revision)
        runtime.maintenance.submit {}.get(30, TimeUnit.SECONDS)
    }
    private fun reminders() = runtime.store.dao.events().filter { it.purpose == "advance" && it.registration == "registered" }
    private fun prayers() = runtime.ownedFuture().filter { it.purpose == "prayer" }
    private fun parentOf(reminder: AlarmRow) = prayers().single { PrayerRules.advanceId(it.id) == reminder.id }
    private fun minutesBefore(reminder: AlarmRow) = (parentOf(reminder).utcMillis - reminder.utcMillis) / 60_000
    private fun advanceAlarms() = alarmManager.scheduledAlarms.filter {
        Shadows.shadowOf(it.operation).savedIntent.getStringExtra("purpose") == "advance"
    }
    private fun posted() = manager.activeNotifications.filter { it.tag == PrayerNotifications.TAG }

    @Test fun eachEligiblePrayerGetsOneReminderWithItsOwnIdTokenAndText() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(2))
        val reminders = reminders()
        assertEquals(10, reminders.size)
        for (reminder in reminders) {
            val parent = parentOf(reminder)
            assertEquals(parent.id + 140_000_000L, reminder.id)
            assertTrue(PrayerRules.isAdvanceId(reminder.id) && !PrayerRules.prayerId(reminder.id))
            assertEquals(parent.utcMillis - 600_000, reminder.utcMillis)
            assertEquals("advance:${reminder.id}", reminder.key)
            assertNotEquals(parent.token, reminder.token)
            assertEquals(parent.generation, reminder.generation)
            assertEquals("Prayer reminder", reminder.title)
        }
        val fajr = reminders.first { it.prayer == "fajr" }
        assertEquals("Fajr in 10 minutes", fajr.body)
        assertEquals(reminders.map { it.utcMillis }.sorted(), advanceAlarms().map { it.triggerAtTime }.sorted())
        // Dart's plan, coverage and digests only ever see prayers.
        assertTrue(runtime.snapshot().plan!!.registrations.all { PrayerRules.prayerId(it.event.id) })
    }

    @Test fun perPrayerOverridesZeroAndOffDecideWhichPrayersGetOne() = offMain {
        policy("advanceMinutes" to 10L, "perPrayer" to mapOf("fajr" to mapOf("advanceMinutes" to 5L),
            "dhuhr" to mapOf("advanceMinutes" to 0L), "asr" to mapOf("mode" to "off")))
        plan(events(1))
        assertEquals(mapOf("fajr" to 5L, "maghrib" to 10L, "isha" to 10L),
            reminders().associate { it.prayer to minutesBefore(it) })
        policy("advanceMinutes" to 0L, "perPrayer" to mapOf("isha" to mapOf("advanceMinutes" to 15L)))
        assertEquals(mapOf("isha" to 15L), reminders().associate { it.prayer to minutesBefore(it) })
    }

    @Test fun changingMinutesOrTurningPrayersOffCancelsPendingReminders() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(1))
        val old = reminders()
        val oldFajr = old.single { it.prayer == "fajr" }
        policy("advanceMinutes" to 15L)
        assertTrue(old.none { runtime.store.dao.eventByToken(it.token) != null })
        assertTrue(reminders().all { minutesBefore(it) == 15L })
        assertEquals(5, advanceAlarms().size)
        // An alarm Android already queued for the old reminder finds nothing to show.
        runtime.wallClock = { oldFajr.utcMillis + 1000 }
        PrayerAlarmReceiver.deliver(runtime.context, runtime.alarms.intent(oldFajr))
        assertTrue(posted().isEmpty())
        runtime.wallClock = System::currentTimeMillis

        policy("perPrayer" to mapOf("fajr" to mapOf("mode" to "off")))
        assertEquals(setOf("dhuhr", "asr", "maghrib", "isha"), reminders().map { it.prayer }.toSet())
        policy("enabled" to false)
        assertTrue(reminders().isEmpty())
        assertTrue(advanceAlarms().isEmpty())
    }

    @Test fun aReplacedPlanMovesOrDropsRemindersAndAnAbortedOneKeepsThem() = offMain {
        policy("advanceMinutes" to 10L)
        val first = events(1)
        plan(first)
        val fajrToken = reminders().single { it.prayer == "fajr" }.token
        val moved = first.filter { it.prayer != "isha" }.map {
            if (it.prayer == "maghrib") it.copy(utcMillis = it.utcMillis + 3600_000) else it
        }
        plan(moved, "second", 1)
        assertEquals(setOf("fajr", "dhuhr", "asr", "maghrib"), reminders().map { it.prayer }.toSet())
        assertEquals(moved.single { it.prayer == "maghrib" }.utcMillis - 600_000,
            reminders().single { it.prayer == "maghrib" }.utcMillis)
        assertEquals(fajrToken, reminders().single { it.prayer == "fajr" }.token)

        val prepared = runtime.plans.prepare(PlanRequest("third", 2, runtime.policy().revision, 1, 3,
            runtime.digest("lat:23.588|lon:58.3829"), runtime.digest("third"), PrayerPolicy.eligibility(runtime.policy()),
            runtime.quota(), moved.filter { it.prayer != "fajr" }, emptyList(), emptyList()))
        assertEquals("prepared", prepared.state)
        assertEquals("aborted", runtime.plans.abort("third").state)
        assertEquals(fajrToken, reminders().single { it.prayer == "fajr" }.token)
        assertEquals(4, advanceAlarms().size)
    }

    @Test fun theReservationShrinksThePrayerQuotaAndRemindersOnlyUseFreeRoom() = offMain {
        runtime.updateQuota(QuotaData(150, 30, 8, 4, 1))
        assertEquals(257, runtime.quota())
        val all = events(52)
        plan(all.take(257))
        policy("advanceMinutes" to 10L)
        assertEquals(187, runtime.quota())
        // Prayers already fill the budget: no reminder pushes one out.
        assertTrue(reminders().isEmpty())
        assertEquals(257, prayers().size)

        // Dart then plans within the smaller quota; the farthest prayers make room.
        plan(all.take(187), "second", 1)
        val now = runtime.nowMillis()
        val inWindow = prayers().count { it.utcMillis - 600_000 <= now + PrayerRules.ADVANCE_WINDOW_MS }
        assertEquals(minOf(70, inWindow), reminders().size)
        assertTrue(reminders().all { it.utcMillis <= now + PrayerRules.ADVANCE_WINDOW_MS })
        assertTrue(prayers().size + reminders().size + 193 <= PrayerRules.TOTAL_QUOTA)
        assertTrue(all.filter { it.utcMillis <= now + 3 * 86400_000L }.all { event -> prayers().any { it.id == event.id } })

        policy("advanceMinutes" to 0L)
        assertEquals(257, runtime.quota())
        assertTrue(reminders().isEmpty())
    }

    @Test fun theWindowRollsForwardAndRepairNeverShowsPastReminders() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(20))
        val start = runtime.nowMillis()
        val before = reminders()
        assertTrue(before.isNotEmpty() && before.all { it.utcMillis <= start + PrayerRules.ADVANCE_WINDOW_MS })
        val later = start + 3 * 86400_000L
        runtime.wallClock = { later }
        runtime.plans.repair()
        val after = reminders()
        assertTrue(after.maxOf { it.utcMillis } > before.maxOf { it.utcMillis })
        assertTrue(after.all { it.utcMillis > later && it.utcMillis <= later + PrayerRules.ADVANCE_WINDOW_MS })
        assertTrue(posted().isEmpty())
        assertTrue(runtime.store.dao.states("auxclaim:advance:%").isEmpty())
    }

    @Test fun rebootRepairReArmsFutureRemindersAndConsumesADueOneWithoutPosting() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(2))
        val fajr = reminders().minBy { it.utcMillis }
        // A reboot loses every alarm.
        alarmManager.scheduledAlarms.toList().forEach {
            runtime.context.getSystemService(AlarmManager::class.java).cancel(it.operation!!)
        }
        runtime.wallClock = { fajr.utcMillis + 5 * 60_000 }
        runtime.plans.repair()
        assertTrue(posted().isEmpty())
        assertTrue(reminders().none { it.id == fajr.id })
        assertEquals(9, reminders().size)
        assertEquals(reminders().map { it.utcMillis }.sorted(), advanceAlarms().map { it.triggerAtTime }.sorted())
        // Its prayer is still ahead and still armed.
        assertTrue(prayers().any { PrayerRules.advanceId(it.id) == fajr.id })
    }

    @Test fun aReminderIsShownOnceOnItsOwnChannelAndNeverPlaysTheAdhan() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(1))
        val reminder = reminders().single { it.prayer == "fajr" }
        runtime.wallClock = { reminder.utcMillis + 1000 }
        PrayerAlarmReceiver.deliver(runtime.context, runtime.alarms.intent(reminder))
        val shown = posted().single()
        assertEquals(reminder.id.toInt(), shown.id)
        assertEquals(PrayerNotifications.BEFORE_CHANNEL, shown.notification.channelId)
        assertEquals("Fajr in 10 minutes", shown.notification.extras.getString(android.app.Notification.EXTRA_TEXT))
        assertNull(runtime.liveSession)
        assertNull(runtime.store.dao.claim(reminder.id - PrayerRules.ADVANCE_OFFSET))
        val channel = manager.getNotificationChannel(PrayerNotifications.BEFORE_CHANNEL)
        assertEquals(NotificationManager.IMPORTANCE_DEFAULT, channel.importance)
        assertNotNull("The channel keeps Android's default sound", channel.sound)

        manager.cancelAll()
        PrayerAlarmReceiver.deliver(runtime.context, runtime.alarms.intent(reminder))
        // A re-created row (new token) for the same occurrence is never shown again either.
        runtime.syncAdvance()
        assertTrue(reminders().none { it.id == reminder.id })
        runtime.store.dao.putEvent(reminder.copy(key = "advance:again", token = "again"))
        PrayerAlarmReceiver.deliver(runtime.context, runtime.alarms.intent(reminder.copy(token = "again")))
        assertTrue(posted().isEmpty())
    }

    @Test fun aLateReminderIsSkippedSilentlyAndConsumed() = offMain {
        policy("advanceMinutes" to 10L)
        plan(events(1))
        val reminder = reminders().single { it.prayer == "dhuhr" }
        runtime.wallClock = { reminder.utcMillis + PrayerRules.LATE_WINDOW_MS + 1 }
        PrayerAlarmReceiver.deliver(runtime.context, runtime.alarms.intent(reminder))
        assertTrue(posted().isEmpty())
        assertEquals("consumed", runtime.store.dao.eventByToken(reminder.token)!!.registration)
        assertNotNull(runtime.store.dao.state("auxclaim:advance:${reminder.id}"))
    }

    @Test fun policyValidationAcceptsOnlyTheOfferedMinutes() {
        val initial = PrayerPolicy.initial()
        assertEquals(0, PrayerPolicy.effective(PrayerPolicy.validate(initial), "fajr").advanceMinutes)
        // Policies saved before this key existed still load.
        val legacy = initial.copy(values = initial.values - "advanceMinutes")
        assertFalse(PrayerPolicy.advanceActive(PrayerPolicy.validate(legacy)))
        for (bad in listOf(7L, -5L, 60L, 10.5, "10")) {
            try { PrayerPolicy.validate(initial.copy(values = initial.values + ("advanceMinutes" to bad))); fail("$bad accepted") }
            catch (_: Exception) { }
            try {
                PrayerPolicy.validate(initial.copy(values = initial.values +
                    ("perPrayer" to mapOf("asr" to mapOf("advanceMinutes" to bad)))))
                fail("$bad override accepted")
            } catch (_: Exception) { }
        }
        // Gson reads stored numbers back as doubles.
        val stored = PrayerPolicy.validate(initial.copy(values = initial.values + ("advanceMinutes" to 15.0)))
        assertEquals(15, PrayerPolicy.effective(stored, "asr").advanceMinutes)
        assertTrue(PrayerPolicy.advanceActive(stored))
        assertFalse(PrayerPolicy.advanceActive(PrayerPolicy.validate(stored.copy(values = stored.values + ("enabled" to false)))))
    }

    @Test fun nativeTextUsesTheLocaleAndItsDigits() {
        assertEquals("تذكير بالصلاة" to "الفجر بعد ١٠ دقائق", NativePrayerStrings.advance("ar", "fajr", 10))
        assertEquals("العصر بعد ١٥ دقيقة", NativePrayerStrings.advance("ar-SA", "asr", 15).second)
        assertEquals("عشاء میں ۵ منٹ باقی ہیں", NativePrayerStrings.advance("ur", "isha", 5).second)
        assertEquals("মাগরিব ৩০ মিনিট পরে", NativePrayerStrings.advance("bn", "maghrib", 30).second)
        assertEquals("Öğle namazına 10 dakika kaldı", NativePrayerStrings.advance("tr", "dhuhr", 10).second)
        assertEquals("Isha in 30 minutes", NativePrayerStrings.advance("xx", "isha", 30).second)
    }
}
