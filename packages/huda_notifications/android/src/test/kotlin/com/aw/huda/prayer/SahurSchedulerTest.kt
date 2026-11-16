package com.aw.huda.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.UserManager
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
class SahurSchedulerTest {
    private lateinit var runtime: PrayerNotificationRuntime
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(60, TimeUnit.SECONDS)
    private val tomorrow get() = Instant.now().atZone(ZoneId.systemDefault()).toLocalDate().plusDays(1)
    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit().clear().commit()
        runtime = PrayerNotificationRuntime.get(context)
        offMain { runtime.initialize() }
    }
    @After fun cleanup() { PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }
    private fun parent(date: LocalDate, hour: Int = 5): AlarmRow {
        val row = AlarmRow("parent:$date", 300_000_000 + date.toEpochDay(), "fajr",
            date.atTime(hour, 0).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli(),
            ZoneId.systemDefault().id, date.toString(), "Fajr", "Time for Fajr", runtime.epoch(), 1, 1, 1, "", "parent-$date",
            precision = "exact", registration = "registered")
        runtime.store.dao.putEvent(row); runtime.store.dao.putOwner(OwnerRow(row.id, "native", 1))
        return row
    }
    @Test fun exactTimeOwnsThirtyStableIdsAndRenewsWithoutFlutter() = offMain {
        assertTrue(runtime.sahur.apply(SahurSettings(enabled = true)))
        val before = runtime.sahur.rows()
        assertEquals(30, before.size)
        assertEquals((114L..143L).toSet(), before.map { it.id }.toSet())
        assertTrue(before.all { Instant.ofEpochMilli(it.utcMillis).atZone(ZoneId.systemDefault()).toLocalTime() == LocalTime.of(4, 0) })
        runtime.sahur.sync()
        assertEquals(before.map { it.token }, runtime.sahur.rows().map { it.token })
        runtime.wallClock = { before.first().utcMillis + 3 * 86400_000L }
        runtime.plans.repair()
        assertEquals(30, runtime.sahur.rows().size)
        assertTrue(runtime.sahur.rows().all { it.utcMillis > runtime.nowMillis() })
        assertTrue(runtime.sahur.rows().last().utcMillis > before.last().utcMillis)
    }
    @Test fun beforeFajrUsesOwnedInstantsAndKeepsThePreviousCivilDayWhenNeeded() = offMain {
        val fajr = parent(tomorrow, 1)
        runtime.sahur.apply(SahurSettings(enabled = true, type = 1, minutesBeforeFajr = 150))
        val row = runtime.sahur.rows().single()
        assertEquals(fajr.utcMillis - 150 * 60_000L, row.utcMillis)
        assertEquals(fajr.localDate, row.localDate)
        assertEquals(tomorrow.minusDays(1), Instant.ofEpochMilli(row.utcMillis).atZone(ZoneId.systemDefault()).toLocalDate())
        val next = parent(tomorrow.plusDays(1))
        runtime.plans.repair()
        assertTrue(runtime.sahur.rows().any { it.utcMillis == next.utcMillis - 150 * 60_000L })
    }
    @Test fun disableRemovesOnlySahurAndClaimSurvivesNewTokens() = offMain {
        val fajr = parent(tomorrow)
        runtime.sahur.apply(SahurSettings(enabled = true, type = 1))
        val row = runtime.sahur.rows().single()
        assertTrue(runtime.claim(row, "native", "attempted", "received", "one"))
        assertFalse(runtime.claim(row.copy(token = "different"), "native", "attempted", "received", "two"))
        runtime.sahur.apply(SahurSettings(enabled = false))
        assertTrue(runtime.sahur.rows().isEmpty())
        assertNotNull(runtime.store.dao.event(fajr.key))
    }
    @Test fun beforeFajrNeverKeepsExactTimeRowsWhenItsSourceIsMissing() = offMain {
        runtime.sahur.apply(SahurSettings(enabled = true))
        assertEquals(30, runtime.sahur.rows().size)
        assertFalse(runtime.sahur.apply(SahurSettings(enabled = true, type = 1)))
        assertTrue(runtime.sahur.rows().isEmpty())
    }
    @Test fun aLegacyCrossMidnightAlarmUsesTheSameClaimAsTheNativeFajr() = offMain {
        val fajr = parent(tomorrow.plusDays(1), 1)
        runtime.sahur.apply(SahurSettings(enabled = true, type = 1, minutesBeforeFajr = 150))
        val native = runtime.sahur.rows().single()
        val old = Intent().putExtra("id", 114).putExtra("alarmSettings", JSONObject()
            .put("id", 114).put("dateTime", native.utcMillis).toString())
        val due = runtime.sahur.migrate(old)!!
        assertEquals(fajr.localDate, due.localDate)
        assertEquals(native.id, due.id)
        assertTrue(runtime.claim(native, "native", "attempted", "received", null))
        assertFalse(runtime.claim(due, "native", "attempted", "received", null))
    }
    @Test fun upgradeImportsIsoDatesAndCancelsTheOldReceiverIdentities() = offMain {
        val at = tomorrow.atTime(3, 30).atZone(ZoneId.systemDefault())
        val prefs = runtime.context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.sahurAlarmEnabled", true).putLong("flutter.sahurAlarmType", 1)
            .putString("flutter.__alarm_id__114", JSONObject().put("id", 114)
                .put("dateTime", at.toLocalDateTime().toString()).put("notificationSettings",
                    JSONObject().put("title", "Saved Sahur").put("body", "Saved body")).toString()).commit()
        val oldIntent = Intent().setClassName(runtime.context, "com.gdelataillade.alarm.alarm.AlarmReceiver")
        val old = PendingIntent.getBroadcast(runtime.context, 114, oldIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val manager = runtime.context.getSystemService(AlarmManager::class.java)
        manager.setExact(AlarmManager.RTC_WAKEUP, at.toInstant().toEpochMilli(), old)
        runtime.sahur.migrate()
        val imported = runtime.sahur.rows().single()
        assertEquals(at.toInstant().toEpochMilli(), imported.utcMillis)
        assertEquals("Saved Sahur", imported.title)
        assertNull(prefs.getString("flutter.__alarm_id__114", null))
        assertFalse(Shadows.shadowOf(manager).scheduledAlarms.any { it.operation == old })
        assertEquals("registered", imported.registration)
    }
    @Test fun oldCallbackHandsOffToNativeDeliveryAndCannotDeliverTwice() {
        val at = tomorrow.atTime(4, 0).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        runtime.wallClock = { at + 1000 }
        val intent = Intent().putExtra("id", 114).putExtra("alarmSettings",
            JSONObject().put("id", 114).put("dateTime", at).toString())
        val done = CountDownLatch(1)
        LegacySahurReceiver.deliver(runtime.context, intent) { done.countDown() }
        assertTrue(done.await(30, TimeUnit.SECONDS))
        offMain {
            val row = runtime.sahur.rows().single { it.utcMillis == at }
            assertEquals("consumed", row.registration)
            assertNotNull(runtime.store.dao.state("auxclaim:sahur:${row.localDate}"))
            assertFalse(runtime.claim(row.copy(token = "duplicate"), "native", "attempted", "received", null))
        }
    }
}
