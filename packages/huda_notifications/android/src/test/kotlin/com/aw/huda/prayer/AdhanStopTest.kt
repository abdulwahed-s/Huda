package com.aw.huda.prayer

import android.content.Context
import android.content.Intent
import android.os.Looper
import android.os.UserManager
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.util.concurrent.*

/** Stop always wins: from the notification, the alarm screen, and before the player exists. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class AdhanStopTest {
    private lateinit var runtime: PrayerNotificationRuntime
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(120, TimeUnit.SECONDS)
    private val gate = CountDownLatch(1)

    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        runtime = PrayerNotificationRuntime.get(context)
        offMain { runtime.initialize() }
        // Busy delivery work: the preview's asset lookup queues behind it.
        runtime.delivery.execute { gate.await(30, TimeUnit.SECONDS) }
    }
    @After fun cleanup() { gate.countDown(); PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }

    private fun drain() {
        gate.countDown()
        runtime.delivery.submit {}.get(30, TimeUnit.SECONDS)
        Shadows.shadowOf(Looper.getMainLooper()).idle()
    }

    @Test fun notificationStopActsAtOnceEvenWhileDeliveryIsBusy() {
        val session = runtime.playback.preview("fajr")
        val stop = Shadows.shadowOf(runtime.notifications.action(session, "STOP")).savedIntent
        PrayerActionReceiver().onReceive(runtime.context, stop)
        assertNull("Stop must not wait for the delivery executor", runtime.liveSession)
        drain()
        // The asset lookup that was queued before Stop never starts a player.
        assertNull(runtime.liveSession)
    }

    @Test fun aStaleStopNeverStopsANewerSession() {
        val old = runtime.playback.preview("fajr")
        val stale = Shadows.shadowOf(runtime.notifications.action(old, "STOP")).savedIntent
        runtime.playback.stop(old.id, "previewStopped")
        val current = runtime.playback.preview("isha")
        PrayerActionReceiver().onReceive(runtime.context, stale)
        assertEquals(current.id, runtime.liveSession?.id)
        runtime.playback.stop(current.id)
        drain()
    }

    @Test fun alarmScreenStopEndsTheSessionAndCloses() {
        val session = runtime.playback.preview("maghrib")
        val activity = Robolectric.buildActivity(AdhanAlarmActivity::class.java,
            Intent(runtime.context, AdhanAlarmActivity::class.java).putExtra("session", session.id)).setup().get()
        val buttons = mutableListOf<Button>()
        fun visit(view: View) {
            if (view is Button) buttons.add(view)
            if (view is ViewGroup) for (index in 0 until view.childCount) visit(view.getChildAt(index))
        }
        visit(activity.findViewById(android.R.id.content))
        assertEquals(NativePrayerStrings.forLocale("en").stop, buttons.first().text.toString())
        buttons.first().performClick()
        assertNull(runtime.liveSession)
        Shadows.shadowOf(Looper.getMainLooper()).idle()
        assertTrue(activity.isFinishing)
        drain()
    }

    @Test fun paletteFollowsHudasStoredTheme() {
        assertEquals(AdhanAlarmPalette.named("indigo"), AdhanAlarmPalette.named("AppColorTheme.indigo"))
        assertNotEquals(AdhanAlarmPalette.named("teal"), AdhanAlarmPalette.named("indigo"))
        assertEquals(AdhanAlarmPalette.named("cream"), AdhanAlarmPalette.named("AppColorTheme.gray"))
        assertEquals(AdhanAlarmPalette.named("teal"), AdhanAlarmPalette.named(null))
        assertEquals(AdhanAlarmPalette.named("teal"), AdhanAlarmPalette.named("unknown"))
        runtime.context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
            .putString("flutter.color_theme", "AppColorTheme.brown").commit()
        assertEquals(AdhanAlarmPalette.named("brown"), AdhanAlarmPalette.read(runtime.context))
    }

    @Test fun prayerNamesAreLocalized() {
        assertEquals("Fajr", NativePrayerStrings.prayerName("en", "fajr"))
        assertEquals("العشاء", NativePrayerStrings.prayerName("ar", "isha"))
        assertEquals("Zohor", NativePrayerStrings.prayerName("ms-MY", "dhuhr"))
    }
}
