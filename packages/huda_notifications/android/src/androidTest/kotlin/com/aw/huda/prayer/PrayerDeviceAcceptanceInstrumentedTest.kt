package com.aw.huda.prayer

import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ActivityInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Bundle
import android.os.SystemClock
import android.widget.TextView
import android.widget.Button
import android.view.View
import android.view.ViewGroup
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runners.MethodSorters
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import com.aw.huda.prayer.core.NativePrayerCalculator
import com.aw.huda.prayer.core.PrayerCalculationInput
import com.aw.huda.prayer.core.PrayerOccurrenceIdentity

/** A native-only foreground for preview/focus tests. No Flutter engine is created. */
class PrayerDeviceTestActivity : Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        if (android.os.Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        setContentView(TextView(this).apply { text = "Huda native Adhan device validation"; textSize = 24f })
    }
}

/** Verifies alarm delivery, playback, notification intents and audio focus on a device. */
@RunWith(AndroidJUnit4::class)
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class PrayerDeviceAcceptanceInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var runtime: PrayerNotificationRuntime
    private var preserveColdProbe = false
    private val manager get() = context.getSystemService(NotificationManager::class.java)
    private val audio get() = context.getSystemService(AudioManager::class.java)
    private val report get() = File(context.filesDir, "adhan-device-results.jsonl")
    private val automation get() = if (InstrumentationRegistry.getArguments().getString("hudaTalkBackProbe") == "true")
        instrumentation.getUiAutomation(android.app.UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        else instrumentation.uiAutomation

    @Before fun prepare() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaDeviceAcceptance") == "true")
        assertEquals("This campaign must not touch the user's Huda database", "com.aw.huda.prayer.test", context.packageName)
        runtime = PrayerNotificationRuntime.get(context)
        runtime.initialize()
        if (InstrumentationRegistry.getArguments().getString("hudaColdProcessProbe") != "verify" &&
            InstrumentationRegistry.getArguments().getString("hudaLifecycleStage") != "verify") {
            runtime.reset(true)
            runtime.updateQuota(QuotaData(100, 30, 8, 4, 1))
        }
        shell("input keyevent KEYCODE_WAKEUP")
        instrumentation.startActivitySync(Intent(context, PrayerDeviceTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        if (InstrumentationRegistry.getArguments().getString("hudaLifecycleStage") != "verify") setPolicy("full")
        val capability = PrayerCapabilities.read(context)
        if (InstrumentationRegistry.getArguments().getString("hudaNotificationsDeniedProbe") == "true") {
            assertFalse("Revoke POST_NOTIFICATIONS before this separate probe", capability.notifications)
        } else assertTrue("Grant notification permission to the isolated test package", capability.notifications)
        assertTrue("Grant exact-alarm access to the isolated test package", capability.exactAlarms)
        assertTrue("Alarm stream must be nonzero for playback checks", capability.alarmVolume > 0)
    }

    @After fun cleanup() {
        if (!::runtime.isInitialized) return
        main { runtime.playback.stopAll("testCleanup", true) }
        if (!preserveColdProbe) runtime.reset(true)
        shell("cmd deviceidle unforce")
        shell("dumpsys battery reset")
        shell("input keyevent KEYCODE_WAKEUP")
    }

    @Test fun a01_deviceCapabilitiesAndPrivateStorage() {
        val capability = PrayerCapabilities.read(context)
        assertEquals(InstrumentationRegistry.getArguments().getString("hudaExpectedTargetSdk", "36").toInt(),
            context.applicationInfo.targetSdkVersion)
        assertTrue(runtime.store.database.openHelper.writableDatabase.path!!.startsWith(context.createDeviceProtectedStorageContext().dataDir.path))
        assertFalse(PrayerPolicy.effective(runtime.policy(), "fajr").screen)
        assertFalse(PrayerPolicy.effective(runtime.policy(), "fajr").flip)
        for (id in listOf(PrayerNotifications.SILENT_CHANNEL, PrayerNotifications.ADHAN_CHANNEL)) {
            assertNull(manager.getNotificationChannel(id).sound)
            assertFalse(manager.getNotificationChannel(id).shouldVibrate())
        }
        record("capabilities", mapOf("targetSdk" to context.applicationInfo.targetSdkVersion, "capability" to JSONObject(runtime.store.gson.toJson(capability))))
    }

    @Test fun a02_exactAlarmInForcedDozeWithoutFlutter() {
        setPolicy("short", mapOf("stopAfterSeconds" to 2L))
        val originalConstants = shell("settings get global device_idle_constants").trim()
        require(originalConstants.matches(Regex("[a-zA-Z0-9_.,=:+-]+"))) { "Unsupported idle constants fixture" }
        val constants = if (originalConstants == "null") emptyList() else originalConstants.split(',')
        val override = (constants.filterNot { it.substringBefore('=') == "min_time_to_alarm" } + "min_time_to_alarm=0").joinToString(",")
        shell("input keyevent KEYCODE_SLEEP")
        try {
            shell("dumpsys battery unplug")
            // Samsung refuses forced idle if another application's wake alarm is
            // within its one-hour entry window. Only the entry threshold changes;
            // alarm delivery quotas/permissions remain at their platform values.
            shell("settings put global device_idle_constants $override")
            await("Temporary idle-entry threshold applied", 3000) { shell("dumpsys deviceidle").contains("min_time_to_alarm=0") }
            record("dozeState", mapOf("force" to shell("cmd deviceidle force-idle deep"), "state" to shell("cmd deviceidle get deep"), "minTimeToAlarmOverrideMillis" to 0))
            assertEquals("IDLE", shell("cmd deviceidle get deep").trim())
            val row = schedule("fajr")
            val session = playing(row)
            assertTrue(session.automatic)
            await("Doze cutoff and cleanup", 7000) { runtime.liveSession == null }
            assertClean()
            deliveryRecord("forcedDoze", row, session)
        } finally {
            shell("cmd deviceidle unforce")
            shell("dumpsys battery reset")
            if (originalConstants == "null") shell("settings delete global device_idle_constants")
            else shell("settings put global device_idle_constants $originalConstants")
        }
    }

    @Test fun a03_tenSilentExactAlarmsWithScreenOff() {
        setPolicy("silent")
        repeat(10) { index ->
            val row = schedule(PrayerRules.prayers[index % 5])
            shell("input keyevent KEYCODE_SLEEP")
            await("Silent callback ${row.id}", 20000) { runtime.store.dao.claim(row.id)?.outcome == "displayed" }
            assertNull(runtime.liveSession)
            await("Silent notification posted", 3000) { manager.activeNotifications.any { it.id == row.id.toInt() && it.tag == PrayerNotifications.TAG } }
            assertClean()
            deliveryRecord("silentScreenOff", row, null)
            runtime.notifications.dismiss(row.id)
        }
    }

    @Test fun a04_tenShortAlarmsStopViaNotificationWithScreenOff() {
        setPolicy("short")
        repeat(10) { index ->
            val row = schedule(PrayerRules.prayers[index % 5])
            shell("input keyevent KEYCODE_SLEEP")
            val session = playing(row)
            assertEquals(30000L, session.limitMillis)
            val notification = foreground()
            assertNull(notification.fullScreenIntent)
            val before = SystemClock.elapsedRealtime()
            notification.actions[0].actionIntent.send()
            await("Native notification Stop", 3000) { runtime.liveSession == null }
            val latency = SystemClock.elapsedRealtime() - before
            assertTrue("Stop exceeded 500 ms: $latency", latency < 500)
            assertClean()
            deliveryRecord("shortScreenOffStop", row, session, mapOf("stopMillis" to latency))
        }
    }

    @Test fun a05_twentyFullAlarmsMixedStopDismissCutoffCleanup() {
        repeat(20) { index ->
            // "dismiss" sends the old DISMISS intent that notifications posted
            // by earlier versions still carry; it now behaves like Stop.
            val terminal = when (index % 3) { 0 -> "stop"; 1 -> "dismiss"; else -> "cutoff" }
            setPolicy("full", if (terminal == "cutoff") mapOf("stopAfterSeconds" to 1L) else emptyMap())
            val row = schedule(PrayerRules.prayers[index % 5])
            val session = playing(row)
            val notification = foreground()
            val before = SystemClock.elapsedRealtime()
            if (terminal == "stop") notification.actions[0].actionIntent.send()
            if (terminal == "dismiss") runtime.notifications.action(session, "DISMISS").send()
            await("Full $terminal", 4000) { runtime.liveSession == null }
            val latency = SystemClock.elapsedRealtime() - before
            if (terminal != "cutoff") assertTrue("$terminal exceeded 500 ms: $latency", latency < 500)
            assertClean()
            await("Terminal outcome", 3000) { runtime.store.dao.claim(row.id)?.outcome in listOf("stopped", "completed") }
            // The prayer's own notification stays, with its original text.
            await("Plain prayer notification", 3000) { manager.activeNotifications.any {
                it.tag == PrayerNotifications.TAG && it.id == row.id.toInt() &&
                    it.notification.extras.getString(android.app.Notification.EXTRA_TEXT) == row.body } }
            deliveryRecord("fullMixedTerminal", row, session, mapOf("terminal" to terminal, "controlMillis" to latency))
        }
    }

    @Test fun a06_allFiveRemoteShortRecordingsCompleteOffline() {
        registerFixtures()
        for (reciter in remoteReciters()) {
            setPolicy("short", mapOf("reciterId" to reciter.getString("id")))
            val before = SystemClock.elapsedRealtime()
            val session = preview()
            val expected = reciter.getJSONObject("notification").getLong("duration_ms")
            assertEquals(reciter.getString("id"), session.reciterId)
            assertTrue(kotlin.math.abs(session.limitMillis!! - expected) <= 1500)
            await("Remote Short completion", expected + 5000) { runtime.liveSession == null }
            val duration = SystemClock.elapsedRealtime() - session.startedElapsedMillis
            assertTrue("Unexpected Short playback duration: $duration", kotlin.math.abs(duration - expected) < 1800)
            assertClean()
            record("remoteShortCompleted", mapOf("reciter" to session.reciterId, "expectedMillis" to expected, "actualMillis" to duration, "prepareMillis" to session.startedElapsedMillis - before))
        }
    }

    @Test fun a07_bundledShortActuallyStopsAtThirtySeconds() {
        setPolicy("short")
        val session = preview()
        assertEquals(30000L, session.limitMillis)
        await("Bundled Short cutoff", 35000) { runtime.liveSession == null }
        val duration = SystemClock.elapsedRealtime() - session.startedElapsedMillis
        assertTrue(duration in 30000..31800)
        assertClean()
        record("bundledShortCutoff", mapOf("actualMillis" to duration))
    }

    @Test fun a08_allRemoteFullAssetsDecodeAndStartOffline() {
        registerFixtures()
        for (reciter in remoteReciters()) {
            setPolicy("full", mapOf("reciterId" to reciter.getString("id"), "stopAfterSeconds" to 2L))
            val session = preview()
            assertEquals(reciter.getString("id"), session.reciterId)
            await("Remote Full cutoff", 5000) { runtime.liveSession == null }
            assertClean()
            record("remoteFullStarted", mapOf("reciter" to session.reciterId, "cutoffMillis" to session.limitMillis))
        }
    }

    @Test fun a09_gainFadeLiveCutoffPreserveSystemAudioSettings() {
        val volume = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        val ringer = audio.ringerMode
        val filter = manager.currentInterruptionFilter
        setPolicy("full", mapOf("volumeGain" to 0.25, "fadeInSeconds" to 1L))
        val session = preview()
        main { runtime.playback.setGain(session.id, 0.6) }
        assertEquals(0.6, runtime.liveSession!!.gain, 0.0001)
        setPolicy("full", mapOf("volumeGain" to 0.35, "stopAfterSeconds" to 1L))
        await("Live shortened cutoff", 4000) { runtime.liveSession == null }
        assertEquals(volume, audio.getStreamVolume(AudioManager.STREAM_ALARM))
        assertEquals(ringer, audio.ringerMode)
        assertEquals(filter, manager.currentInterruptionFilter)
        assertClean()
        record("gainFadeCutoff", mapOf("alarmVolumeBefore" to volume, "alarmVolumeAfter" to audio.getStreamVolume(AudioManager.STREAM_ALARM), "ringerMode" to ringer, "dndFilter" to filter))
    }

    @Test fun a10_staleStopAndDuplicateCallbackCannotAffectNewSession() {
        val first = schedule("fajr")
        val oldSession = playing(first)
        val stale = foreground().actions[0].actionIntent
        stale.send()
        await("First Stop", 3000) { runtime.liveSession == null }
        val second = schedule("dhuhr")
        val current = playing(second)
        stale.send()
        SystemClock.sleep(300)
        assertEquals(current.id, runtime.liveSession?.id)
        context.sendBroadcast(runtime.alarms.intent(first))
        context.sendBroadcast(runtime.alarms.intent(second))
        SystemClock.sleep(300)
        assertEquals(current.id, runtime.liveSession?.id)
        assertEquals(2, runtime.store.dao.history(0, 100).size)
        main { runtime.playback.stop(current.id) }
        await("Current Stop", 3000) { runtime.liveSession == null }
        assertClean()
        record("staleStopDuplicate", mapOf("oldSession" to oldSession.id, "currentSession" to current.id, "claims" to 2))
    }

    @Test fun a11_focusLossEndsPlaybackAndNeverResumes() {
        val session = preview()
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build())
            .setOnAudioFocusChangeListener { }.build()
        try {
            assertEquals(AudioManager.AUDIOFOCUS_REQUEST_GRANTED, audio.requestAudioFocus(request))
            await("Focus loss", 3000) { runtime.liveSession == null }
        } finally { audio.abandonAudioFocusRequest(request) }
        SystemClock.sleep(300)
        assertNull(runtime.liveSession)
        assertClean()
        record("focusInterrupted", mapOf("session" to session.id, "resumed" to false))
    }

    @Test fun a12_tenOffOccurrencesNeverCreatePlayerOrNotification() {
        setPolicy("full", mapOf("enabled" to false))
        repeat(10) { index ->
            val row = schedule(PrayerRules.prayers[index % 5])
            await("Off callback", 20000) { runtime.store.dao.claim(row.id)?.reason == "policyOff" }
            assertNull(runtime.liveSession)
            assertFalse(manager.activeNotifications.any { it.id == row.id.toInt() })
            assertClean()
            deliveryRecord("off", row, null)
        }
    }

    @Test fun a13_zeroGainAndRespectSilentRingerSuppressAutomaticAudio() {
        setPolicy("full", mapOf("volumeGain" to 0.0))
        val muted = schedule("fajr")
        await("Muted gain suppression", 20000) { runtime.store.dao.claim(muted.id)?.reason == "volumeMuted" }
        assertNull(runtime.liveSession)
        deliveryRecord("zeroGain", muted, null)
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) {
            setPolicy("full", mapOf("respectRingerMode" to true))
            val ringer = schedule("dhuhr")
            await("Silent-ringer suppression", 20000) { runtime.store.dao.claim(ringer.id)?.reason == "ringerSuppressed" }
            assertNull(runtime.liveSession)
            deliveryRecord("respectRinger", ringer, null)
        }
        assertClean()
    }

    @Test fun a14_missingSelectedFileUsesBoundedBundledFallback() {
        registerFixtures()
        val id = remoteReciters().first().getString("id")
        setPolicy("short", mapOf("reciterId" to id, "stopAfterSeconds" to 1L))
        val selected = runtime.audio.asset(id, "v1", "short")!!
        val original = File(selected.path)
        val missing = File(original.path + ".test-hidden")
        assertTrue(original.renameTo(missing))
        try {
            val session = preview()
            assertEquals("huda-default", session.reciterId)
            assertTrue(session.limitMillis!! <= 1000)
            await("Fallback cutoff", 4000) { runtime.liveSession == null }
            assertClean()
            record("missingFileFallback", mapOf("selected" to id, "actual" to session.reciterId, "limitMillis" to session.limitMillis))
        } finally { assertTrue(missing.renameTo(original)) }
    }

    @Test fun a15_notificationDenialIsTruthfulAndQuiet() {
        // Permission revocation kills its application; do it from adb before this
        // separately selected method, then grant it again after instrumentation.
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaNotificationsDeniedProbe") == "true")
        assertFalse(PrayerCapabilities.read(context).notifications)
        val row = schedule("fajr")
        await("Notification denial suppression", 20000) { runtime.store.dao.claim(row.id)?.reason == "notificationsBlocked" }
        assertNull(runtime.liveSession)
        assertClean()
        deliveryRecord("notificationDenied", row, null)
    }

    @Test fun a16_dndNoneSuppressesAndRestoresOriginalFilter() {
        val original = manager.currentInterruptionFilter
        Assume.assumeTrue("Run DND mutation only from the ordinary off state", original == NotificationManager.INTERRUPTION_FILTER_ALL)
        try {
            if (android.os.Build.VERSION.SDK_INT <= 28) {
                assertTrue("Grant DND policy access to this isolated probe", manager.isNotificationPolicyAccessGranted)
                manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            } else shell("cmd notification set_dnd none")
            await("DND none", 3000) { PrayerCapabilities.read(context).dndAllowsAlarms == false }
            val row = schedule("fajr")
            await("DND suppression", 20000) { runtime.store.dao.claim(row.id)?.reason == "dndSuppressed" }
            assertNull(runtime.liveSession)
            assertClean()
            deliveryRecord("dndBlocked", row, null)
        } finally {
            if (android.os.Build.VERSION.SDK_INT <= 28) manager.setInterruptionFilter(original)
            else shell("cmd notification set_dnd all")
            await("Original DND restored", 3000) { manager.currentInterruptionFilter == original }
        }
    }

    @Test fun a17_coldProcessAlarmProbe() {
        val stage = InstrumentationRegistry.getArguments().getString("hudaColdProcessProbe")
        Assume.assumeTrue(stage in listOf("prepare", "verify"))
        if (stage == "prepare") {
            setPolicy("short", mapOf("stopAfterSeconds" to 1L))
            val row = schedule("fajr", 30000)
            runtime.store.putText("coldProbeId", row.id.toString())
            preserveColdProbe = true
            record("coldProcessPrepared", mapOf("id" to row.id, "scheduledUtcMillis" to row.utcMillis))
        } else {
            val id = runtime.store.text("coldProbeId").toLong()
            await("Cold-process alarm completed", 20000) { runtime.store.dao.claim(id)?.outcome == "completed" }
            val row = runtime.store.dao.events().first { it.id == id }
            val claim = runtime.store.dao.claim(id)!!
            assertEquals("cutoff", claim.reason)
            assertClean()
            deliveryRecord("coldProcessCompleted", row, null)
        }
    }

    @Test fun a18_nativeOverviewArabicLargeTextAndDeniedFullScreen() {
        Assume.assumeTrue(android.os.Build.VERSION.SDK_INT >= 34) // User-controlled FSI access was added in Android 14.
        val fontScale = shell("settings get system font_scale").trim()
        val fullScreenOp = shell("cmd appops get ${context.packageName} USE_FULL_SCREEN_INTENT")
        try {
            shell("settings put system font_scale 2.0")
            shell("cmd appops set ${context.packageName} USE_FULL_SCREEN_INTENT ignore")
            shell("cmd appops set --uid ${context.packageName} USE_FULL_SCREEN_INTENT ignore")
            await("Full-screen denial capability", 3000) { !PrayerCapabilities.read(context).fullScreen }
            setPolicy("full", mapOf("localeCode" to "ar", "alarmScreenEnabled" to true,
                "flipToStopEnabled" to true, "vibrate" to true))
            assertFalse(PrayerCapabilities.read(context).fullScreen)
            val row = schedule("fajr")
            val session = playing(row)
            val notification = foreground()
            assertNull("Denied full-screen access must retain ordinary playback", notification.fullScreenIntent)
            val activity = instrumentation.startActivitySync(Intent(context, AdhanAlarmActivity::class.java)
                .putExtra("session", session.id).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            instrumentation.waitForIdleSync()
            val buttons = mutableListOf<Button>()
            val texts = mutableListOf<TextView>()
            main {
                fun visit(view: View) {
                    if (view is Button) buttons.add(view)
                    if (view is TextView) texts.add(view)
                    if (view is ViewGroup) for (index in 0 until view.childCount) visit(view.getChildAt(index))
                }
                visit(activity.findViewById(android.R.id.content))
                assertTrue(buttons.size >= 2)
                assertEquals(NativePrayerStrings.forLocale("ar").stop, buttons[0].text.toString())
                assertTrue(buttons.all { it.height >= 48 * activity.resources.displayMetrics.density })
                assertEquals(View.LAYOUT_DIRECTION_RTL, buttons[0].parent.let { it as View }.layoutDirection)
                val location = IntArray(2)
                texts.first().getLocationOnScreen(location)
                val bars = requireNotNull(ViewCompat.getRootWindowInsets(activity.window.decorView))
                    .getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
                assertTrue("Native heading overlaps the status bar", location[1] >= bars.top)
            }
            val bitmap = requireNotNull(automation.takeScreenshot())
            try {
                File(context.filesDir, "adhan-native-arabic-large-text.png").outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
            } finally { bitmap.recycle() }
            val before = SystemClock.elapsedRealtime()
            main { buttons[0].performClick() }
            await("Arabic native Activity Stop", 3000) { runtime.liveSession == null }
            val stopMillis = SystemClock.elapsedRealtime() - before
            assertClean()
            record("nativeArabicLargeText", mapOf("stopMillis" to stopMillis,
                "fontScale" to 2.0, "fullScreenDenied" to true, "buttons" to buttons.map { it.text.toString() },
                "flipEnabled" to true, "vibrationEnabled" to true))
        } finally {
            shell("settings put system font_scale $fontScale")
            val mode = Regex("USE_FULL_SCREEN_INTENT: (allow|ignore|deny|default)").find(fullScreenOp)?.groupValues?.get(1) ?: "default"
            shell("cmd appops set ${context.packageName} USE_FULL_SCREEN_INTENT $mode")
            val uidMode = Regex("Uid mode: USE_FULL_SCREEN_INTENT: (allow|ignore|deny|default)").find(fullScreenOp)?.groupValues?.get(1) ?: "default"
            shell("cmd appops set --uid ${context.packageName} USE_FULL_SCREEN_INTENT $uidMode")
        }
    }

    @Test fun a19_bundledFullCompletesOnceWithoutFlutter() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaFullCompletion") == "true")
        val row = schedule("fajr")
        val session = playing(row)
        assertEquals(204446L, session.limitMillis)
        await("Bundled Full completion", 210000) { runtime.liveSession == null }
        val elapsed = SystemClock.elapsedRealtime() - session.startedElapsedMillis
        assertTrue("Full recording ended outside its bound: $elapsed", elapsed in 203500..205446)
        await("Full completed outcome", 3000) { runtime.store.dao.claim(row.id)?.outcome == "completed" }
        context.sendBroadcast(runtime.alarms.intent(row))
        SystemClock.sleep(300)
        assertNull(runtime.liveSession)
        assertEquals(1, runtime.store.dao.history(0, 100).size)
        assertClean()
        deliveryRecord("bundledFullCompleted", row, session, mapOf("actualMillis" to elapsed, "repeatClaims" to 0))
    }

    @Test fun a20_automaticFullScreenLaunchesOverSecureLockAndDismisses() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaFullScreenLaunch") == "true")
        val originalOp = shell("cmd appops get ${context.packageName} USE_FULL_SCREEN_INTENT")
        val monitor = instrumentation.addMonitor(AdhanAlarmActivity::class.java.name, null, false)
        var activity: Activity? = null
        try {
            shell("cmd appops set ${context.packageName} USE_FULL_SCREEN_INTENT allow")
            shell("cmd appops set --uid ${context.packageName} USE_FULL_SCREEN_INTENT allow")
            setPolicy("full", mapOf("alarmScreenEnabled" to true, "stopAfterSeconds" to 40L))
            assertTrue(PrayerCapabilities.read(context).fullScreen)
            val keyguard = context.getSystemService(KeyguardManager::class.java)
            shell("input keyevent KEYCODE_HOME")
            shell("input keyevent KEYCODE_SLEEP")
            await("Device securely locked before alarm", 12000) { keyguard.isDeviceLocked }
            val row = schedule("fajr")
            // Observe Android's notification delivery. Never explicitly start the
            // overview or send its PendingIntent from the test.
            activity = monitor.waitForActivityWithTimeout(18000)
            assertNotNull("Android did not automatically launch the alarm overview", activity)
            val session = playing(row)
            val notification = foreground()
            assertNotNull(notification.fullScreenIntent)
            assertEquals(android.app.Notification.GROUP_ALERT_ALL, notification.groupAlertBehavior)
            assertTrue("Overview must not unlock the device", keyguard.isDeviceLocked)
            await("Automatic overview owns window focus", 5000) { activity!!.hasWindowFocus() }
            // Samsung's keyguard exit animation can outlive Activity/Looper idle.
            SystemClock.sleep(1000)
            instrumentation.waitForIdleSync()
            val buttons = mutableListOf<Button>()
            main {
                fun visit(view: View) {
                    if (view is Button) buttons.add(view)
                    if (view is ViewGroup) for (index in 0 until view.childCount) visit(view.getChildAt(index))
                }
                visit(activity!!.findViewById(android.R.id.content))
                assertEquals(NativePrayerStrings.forLocale("en").stop, buttons[0].text.toString())
            }
            val bitmap = requireNotNull(automation.takeScreenshot())
            try {
                File(context.filesDir, "adhan-automatic-locked-screen.png").outputStream().use {
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                }
            } finally { bitmap.recycle() }
            val before = SystemClock.elapsedRealtime()
            main { buttons[0].performClick() }
            await("Automatic locked overview Stop", 3000) { runtime.liveSession == null }
            val dismissMillis = SystemClock.elapsedRealtime() - before
            assertClean()
            deliveryRecord("automaticLockedOverview", row, session, mapOf(
                "deviceStayedLocked" to keyguard.isDeviceLocked, "fullScreenGranted" to true,
                "explicitOverviewLaunch" to false, "dismissMillis" to dismissMillis,
                "dismissAndCleanupMillis" to SystemClock.elapsedRealtime() - before))
        } finally {
            activity?.let { main { it.finish() } }
            instrumentation.removeMonitor(monitor)
            val mode = Regex("USE_FULL_SCREEN_INTENT: (allow|ignore|deny|default)").find(originalOp)?.groupValues?.get(1) ?: "default"
            val uidMode = Regex("Uid mode: USE_FULL_SCREEN_INTENT: (allow|ignore|deny|default)").find(originalOp)?.groupValues?.get(1) ?: "default"
            shell("cmd appops set ${context.packageName} USE_FULL_SCREEN_INTENT $mode")
            shell("cmd appops set --uid ${context.packageName} USE_FULL_SCREEN_INTENT $uidMode")
        }
    }

    @Test fun a21_allDownloadedFullRecordingsCompleteOffline() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaExtendedAcceptance") == "true")
        registerFixtures()
        for (reciter in remoteReciters()) {
            setPolicy("full", mapOf("reciterId" to reciter.getString("id")))
            val session = preview()
            val expected = reciter.getJSONObject("full").getLong("duration_ms")
            assertEquals(reciter.getString("id"), session.reciterId)
            record("remoteFullPlaying", mapOf("reciter" to session.reciterId, "expectedMillis" to expected,
                "startedElapsedMillis" to session.startedElapsedMillis))
            await("Complete downloaded Full recording", expected + 6000) { runtime.liveSession == null }
            val actual = SystemClock.elapsedRealtime() - session.startedElapsedMillis
            assertTrue("Full recording ended outside its duration: $actual vs $expected",
                kotlin.math.abs(actual - expected) < 2000)
            assertClean()
            record("remoteFullCompleted", mapOf("reciter" to session.reciterId, "expectedMillis" to expected,
                "actualMillis" to actual, "audibleObservation" to false))
        }
    }

    @Test fun a22_actualSensorFlipProbe() {
        val args = InstrumentationRegistry.getArguments()
        Assume.assumeTrue(args.getString("hudaExtendedAcceptance") == "true")
        val fixture = args.getString("hudaFlipFixture")
        Assume.assumeTrue(fixture != null)
        val sensors = context.getSystemService(SensorManager::class.java)
        val source = sensors.getDefaultSensor(Sensor.TYPE_GRAVITY, true)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER, true)
            ?: sensors.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        assertNotNull("A motion sensor is required", source)
        val samples = java.util.concurrent.CopyOnWriteArrayList<List<Number>>()
        val listener = object : SensorEventListener {
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
            override fun onSensorChanged(event: SensorEvent) {
                if (samples.size < 1500) samples.add(listOf(event.timestamp / 1_000_000,
                    event.values[0].toDouble(), event.values[1].toDouble(), event.values[2].toDouble()))
            }
        }
        assertTrue(sensors.registerListener(listener, source, 66_667))
        try {
            setPolicy("full", mapOf("flipToStopEnabled" to true, "stopAfterSeconds" to 90L))
            val row = schedule("fajr")
            val session = playing(row)
            if (args.getString("hudaFlipScreenOff") == "true") shell("input keyevent KEYCODE_SLEEP")
            record("flipProbeReady", mapOf("fixture" to fixture, "sensorType" to source!!.type,
                "sensorName" to source.name, "wakeUpSensor" to source.isWakeUpSensor,
                "session" to session.id, "screenOff" to (args.getString("hudaFlipScreenOff") == "true")))
            if (fixture in listOf("initialFaceDown", "uprightNoise", "briefFaceDown")) {
                SystemClock.sleep(10000)
                assertEquals("Unintentional motion stopped playback", session.id, runtime.liveSession?.id)
                main { runtime.playback.stop(session.id) }
                await("Negative gesture fixture Stop", 3000) { runtime.liveSession == null }
            } else {
                await("Physical or emulator flip must stop playback", 65000) { runtime.liveSession == null }
                await("Flip terminal outcome", 3000) { runtime.store.dao.claim(row.id)?.reason == "stoppedByFlip" }
            }
            assertClean()
            record("flipProbeResult", mapOf("fixture" to fixture, "reason" to runtime.store.dao.claim(row.id)?.reason,
                "sampleCount" to samples.size,
                "screenOff" to (args.getString("hudaFlipScreenOff") == "true")))
        } finally {
            sensors.unregisterListener(listener)
            record("flipProbeSamples", mapOf("fixture" to fixture,
                "sampleCount" to samples.size, "samples" to samples.toList()))
        }
    }

    @Test fun a23_nativeOverviewRotationAndAccessibilityActions() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaExtendedAcceptance") == "true")
        val row = schedule("fajr")
        val session = playing(row)
        val activity = instrumentation.startActivitySync(Intent(context, AdhanAlarmActivity::class.java)
            .putExtra("session", session.id).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        val monitor = instrumentation.addMonitor(AdhanAlarmActivity::class.java.name, null, false)
        try {
            main { activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE }
            val rotated = monitor.waitForActivityWithTimeout(5000) ?: activity
            await("Landscape configuration", 6000) {
                rotated.resources.configuration.orientation == android.content.res.Configuration.ORIENTATION_LANDSCAPE
            }
            instrumentation.waitForIdleSync()
            await("Rotated overview is the visible focused window", 6000) {
                shell("dumpsys window").lineSequence().any {
                    it.contains("mCurrentFocus") && it.contains("AdhanAlarmActivity")
                }
            }
            val buttons = mutableListOf<Button>()
            main {
                fun visit(view: View) {
                    if (view is Button) buttons.add(view)
                    if (view is ViewGroup) for (index in 0 until view.childCount) visit(view.getChildAt(index))
                }
                visit(rotated.findViewById(android.R.id.content))
                assertTrue(buttons.size >= 2)
                assertTrue(buttons.all { it.isEnabled && it.isClickable && it.text.isNotBlank() })
                assertTrue(buttons.all { it.height >= 48 * rotated.resources.displayMetrics.density })
            }
            var stopNode: android.view.accessibility.AccessibilityNodeInfo? = null
            await("Visible Stop accessibility action", 6000) {
                val tree = automation.rootInActiveWindow
                fun find(node: android.view.accessibility.AccessibilityNodeInfo?): android.view.accessibility.AccessibilityNodeInfo? {
                    if (node == null) return null
                    if (node.isClickable && node.isVisibleToUser && node.text?.toString()?.equals(buttons[0].text.toString(), true) == true) return node
                    for (index in 0 until node.childCount) find(node.getChild(index))?.let { return it }
                    return null
                }
                stopNode = find(tree)
                stopNode != null
            }
            SystemClock.sleep(1500) // Allow rotation and the newly focused surface to finish drawing.
            val bitmap = requireNotNull(automation.takeScreenshot())
            try { File(context.filesDir, "adhan-native-landscape.png").outputStream().use {
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            } } finally { bitmap.recycle() }
            assertTrue(stopNode!!.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK))
            await("Rotated Activity Stop", 3000) { runtime.liveSession == null }
            assertClean()
            record("nativeRotationAccessibility", mapOf("rotation" to "landscape", "buttonLabels" to buttons.map { it.text.toString() },
                "accessibilityTree" to true, "visibleStopAccessibilityClick" to true, "talkBackAudibleReading" to false))
            main { rotated.finish() }
        } finally { instrumentation.removeMonitor(monitor) }
    }

    @Test fun a24_externalAudioInterruptionProbe() {
        val args = InstrumentationRegistry.getArguments()
        Assume.assumeTrue(args.getString("hudaExtendedAcceptance") == "true")
        val kind = args.getString("hudaAudioInterruption")
        Assume.assumeTrue(kind != null)
        setPolicy("full", mapOf("stopOnHeadsetDisconnect" to true, "stopAfterSeconds" to 90L))
        val row = if (args.getString("hudaAudioInterruptionAutomatic") == "true") schedule("fajr") else null
        val session = row?.let { playing(it) } ?: preview()
        record("audioInterruptionReady", mapOf("kind" to kind, "session" to session.id,
            "automatic" to session.automatic,
            "outputTypes" to audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS).map { it.type }))
        await("Actual external audio interruption", 65000) { runtime.liveSession == null }
        if (row != null) {
            await("Headset-disconnect outcome persisted", 3000) {
                runtime.store.dao.claim(row.id)?.reason == "headsetDisconnected"
            }
            deliveryRecord("automaticHeadsetDisconnect", row, session)
        }
        assertClean()
        SystemClock.sleep(500)
        assertNull("Audio must not resume after interruption", runtime.liveSession)
        record("audioInterruptionStopped", mapOf("kind" to kind, "resumed" to false))
    }

    @Test fun a25_durableLifecycleProbe() {
        val args = InstrumentationRegistry.getArguments()
        Assume.assumeTrue(args.getString("hudaExtendedAcceptance") == "true")
        val kind = args.getString("hudaLifecycleKind") ?: return
        val stage = args.getString("hudaLifecycleStage") ?: return
        if (stage == "prepare") {
            val cutoff = args.getString("hudaLifecycleCutoffSeconds", "2").toLong()
            val gain = args.getString("hudaLifecycleGain", "0.12").toDouble()
            setPolicy("full", mapOf("stopAfterSeconds" to cutoff, "volumeGain" to gain))
            val count = args.getString("hudaLifecycleCount", "1").toInt()
            val delay = args.getString("hudaLifecycleDelay", "30000").toLong()
            val spacing = args.getString("hudaLifecycleSpacing", "542000").toLong()
            val rows = (0 until count).map { schedule(PrayerRules.prayers[it % 5], delay + it * spacing) }
            runtime.store.putText("extendedProbeIds", rows.joinToString(",") { it.id.toString() })
            runtime.store.putText("extendedProbeKind", kind)
            preserveColdProbe = true
            record("lifecyclePrepared", mapOf("kind" to kind, "ids" to rows.map { it.id },
                "scheduledUtcMillis" to rows.map { it.utcMillis }, "count" to count, "spacingMillis" to spacing,
                "cutoffSeconds" to cutoff, "volumeGain" to gain))
        } else {
            assertEquals(kind, runtime.store.text("extendedProbeKind"))
            val ids = runtime.store.text("extendedProbeIds").split(',').map { it.toLong() }
            if (kind == "forceStop") {
                // Android 15+ sends BOOT_COMPLETED when explicit launch clears
                // the stopped state. Its repair may already have journaled the
                // missed occurrence before instrumentation reaches this line.
                record("forceStopBeforeExplicitRepair", mapOf("claims" to ids.map { runtime.store.dao.claim(it) }))
                assertTrue("Relaunch must never replay the missed alarm", ids.all { id ->
                    runtime.store.dao.claim(id)?.let { it.outcome == "skippedLate" && it.reason == "recoveryPastDue" } != false
                })
                runtime.plans.repair()
                assertTrue(ids.all { runtime.store.dao.claim(it)?.reason == "recoveryPastDue" })
                assertNull(runtime.liveSession)
                record("forceStopRecovery", mapOf("ids" to ids, "missedNeverReplayed" to true))
                nextId = ids.max() - 326_100_000L + 1
                val next = schedule("isha")
                val session = playing(next)
                await("Delivery restored after explicit relaunch", 6000) { runtime.liveSession == null }
                deliveryRecord("forceStopRelaunchedDelivery", next, session)
            } else {
                for (id in ids) {
                    await("Durable $kind outcome for $id", 20000) { runtime.store.dao.claim(id)?.outcome == "completed" }
                    val row = runtime.store.dao.events().first { it.id == id }
                    assertEquals("cutoff", runtime.store.dao.claim(id)?.reason)
                    deliveryRecord(kind, row, null)
                }
            }
            assertClean()
        }
    }

    @Test fun a26_migrationOwnershipSurvivesProcessInterruption() {
        val args = InstrumentationRegistry.getArguments()
        Assume.assumeTrue(args.getString("hudaExtendedAcceptance") == "true")
        val stage = args.getString("hudaLifecycleStage") ?: return
        if (stage == "prepare") {
            val instant = Instant.now().plusSeconds(10800)
            val date = instant.atZone(ZoneOffset.UTC).toLocalDate()
            val event = EventData(PrayerOccurrenceIdentity.idFor(date, "fajr"), "fajr", instant.toEpochMilli(),
                "UTC", date.toString(), "Fajr", "Migration device fixture", null)
            val request = PlanRequest("device-migration", 0, runtime.livePolicy.revision, 1, 1,
                runtime.digest("device-configuration"), runtime.digest("device-events"),
                PrayerPolicy.eligibility(runtime.livePolicy), 300, listOf(event), emptyList(), listOf(event))
            runtime.reservePluginAlarm(event.id)
            runtime.store.dao.putOwner(OwnerRow(event.id, "legacy", 0))
            val receipt = runtime.plans.prepare(request)
            assertEquals(listOf(event.id), receipt.legacyCleanupIds)
            assertEquals("native", runtime.store.dao.owner(event.id)?.backend)
            runtime.store.write("extendedMigrationRequest", request)
            preserveColdProbe = true
            record("migrationCheckpointPrepared", mapOf("operation" to request.operationId, "legacyCleanupIds" to receipt.legacyCleanupIds,
                "backend" to runtime.backend(), "owner" to runtime.store.dao.owner(event.id)?.backend,
                "processId" to android.os.Process.myPid()))
        } else {
            val request = requireNotNull(runtime.store.read("extendedMigrationRequest", PlanRequest::class.java))
            val event = request.legacyEvents.single()
            val payload = JSONObject().put("type", "prayer_time").put("prayer", event.prayer)
                .put("scheduledUtc", Instant.ofEpochMilli(event.utcMillis).toString()).put("timeZone", "UTC").toString()
            assertFalse(LegacyPrayerDeliveryBridge.allowRestore(context, event.id.toInt(), payload))
            val partial = runtime.plans.prepare(request)
            assertEquals(listOf(event.id), partial.legacyCleanupIds)
            runtime.plans.acknowledgeCleanup(request.operationId, partial.legacyCleanupIds)
            val prepared = runtime.plans.prepare(request)
            assertEquals("prepared", prepared.state)
            val active = runtime.plans.activate(request.operationId, 0)
            assertEquals("native", runtime.backend())
            assertEquals(1, active.registrations.size)
            record("migrationInterruptionRecovered", mapOf("backend" to runtime.backend(), "legacyRestoreAllowed" to false,
                "generation" to active.generation, "registrationCount" to active.registrations.size,
                "flutterEngine" to false, "processId" to android.os.Process.myPid()))
        }
    }

    @Test fun a27_ninetyDayRenewalWithRealDatabaseAndAlarmManager() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaExtendedAcceptance") == "true")
        val base = Instant.now()
        var now = base
        runtime.wallClock = { now.toEpochMilli() }
        try {
            val input = PrayerCalculationInput(23.588, 58.3829, "OM", "Asia/Muscat", "muslimWorldLeague", "shafi", "none",
                offsets = mapOf("fajr" to 2880, "isha" to -1440))
            val events = (-7L..67L).flatMap { day ->
                val date = now.atZone(ZoneId.of(input.timeZoneId)).toLocalDate().plusDays(day)
                NativePrayerCalculator.adjustedTimes(input, date).filter { it.key in PrayerRules.prayers }.mapNotNull { (prayer, instant) ->
                    if (instant == null || instant <= now || instant > now.plusSeconds(60 * 86400)) null
                    else {
                        val local = instant.atZone(ZoneId.of(input.timeZoneId)).toLocalDate()
                        EventData(PrayerOccurrenceIdentity.idFor(local, prayer), prayer, instant.toEpochMilli(), input.timeZoneId,
                            local.toString(), prayer, "Renewal device fixture", null)
                    }
                }
            }.sortedBy { it.utcMillis }.take(300)
            val request = PlanRequest("device-renewal", 0, runtime.livePolicy.revision, 1, 1,
                runtime.digest("lat:23.588|lon:58.3829"), runtime.digest("device-renewal-events"),
                PrayerPolicy.eligibility(runtime.livePolicy), 300, events, emptyList(), emptyList())
            runtime.plans.prepare(request)
            val active = runtime.plans.activate(request.operationId, 0)
            val configuration = JSONObject().put("location", JSONObject().put("revision", 1).put("latitude", input.latitude)
                .put("longitude", input.longitude).put("countryCode", "OM").put("timeZoneId", input.timeZoneId))
                .put("methodToken", input.method).put("madhabToken", input.madhab).put("highLatitudeRuleToken", input.highLatitude)
                .put("customAngles", JSONObject().put("fajr", 18).put("maghrib", 0).put("isha", 17))
                .put("offsets", JSONObject(input.offsets)).put("androidLabels", JSONObject().apply {
                    PrayerRules.prayers.forEach { put(it, JSONObject().put("title", it).put("body", "Prayer time")) }
                })
            runtime.plans.finalize(FinalizeRequest(request.operationId, active.generation, "lat:23.588|lon:58.3829",
                configuration.toString(), request.eventDigest))
            val originalEnd = runtime.ownedFuture().maxOf { it.utcMillis }
            for (day in 1..90) {
                now = base.plusSeconds(day * 86400L)
                runtime.plans.repair()
                if (day == 65) runtime.setPolicy(runtime.policy().copy(values = runtime.policy().values +
                    ("perPrayer" to mapOf("fajr" to mapOf("mode" to "off")))), runtime.policy().revision)
                if (day == 75) runtime.updateQuota(QuotaData(260, 30, 8, 4, 1))
                NativePrayerRenewal(runtime).extend(300)
                val future = runtime.ownedFuture().filter { it.purpose == "prayer" }
                assertTrue("Empty coverage on simulated day $day", future.isNotEmpty())
                assertTrue(future.all { it.utcMillis > now.toEpochMilli() && it.utcMillis <= now.plusSeconds(60 * 86400L).toEpochMilli() })
                assertTrue(future.size <= runtime.quota())
                if (day >= 65) assertTrue(future.none { it.prayer == "fajr" })
                if (day % 15 == 0) record("renewalSimulatedCheckpoint", mapOf("day" to day, "futureCount" to future.size,
                    "quota" to runtime.quota(), "coverageUtcMillis" to future.maxOf { it.utcMillis }))
            }
            assertTrue(runtime.ownedFuture().maxOf { it.utcMillis } > originalEnd + 50 * 86400_000L)
            assertEquals(147L, runtime.plans.active()!!.quota)
            now = base
            runtime.plans.repair()
            assertTrue(runtime.ownedFuture().none { runtime.store.dao.claim(it.id) != null })
            record("renewalNinetySimulatedDays", mapOf("days" to 90, "actualDatabase" to true, "actualAlarmManager" to true,
                "simulatedWallClock" to true, "elapsedOvernightSoak" to false, "flutterEngine" to false,
                "clockReversalReplayedClaims" to false))
        } finally { runtime.wallClock = System::currentTimeMillis }
    }

    @Test fun a28_boundTalkBackReadsAndActivatesNativeControls() {
        val args = InstrumentationRegistry.getArguments()
        Assume.assumeTrue(args.getString("hudaTalkBackProbe") == "true")
        val accessibility = context.getSystemService(android.view.accessibility.AccessibilityManager::class.java)
        await("TalkBack is actually enabled alongside automation", 12000) {
            accessibility.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_SPOKEN)
                .any { it.id.contains("talkback", true) }
        }
        setPolicy("full", mapOf("stopAfterSeconds" to 90L))
        val row = schedule("fajr")
        val session = playing(row)
        val activity = instrumentation.startActivitySync(Intent(context, AdhanAlarmActivity::class.java)
            .putExtra("session", session.id).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        val labels = NativePrayerStrings.forLocale("en").let { listOf(it.stop, it.open) }
        fun node(label: String): android.view.accessibility.AccessibilityNodeInfo? {
            fun find(current: android.view.accessibility.AccessibilityNodeInfo?): android.view.accessibility.AccessibilityNodeInfo? {
                if (current == null) return null
                if (current.isClickable && current.isVisibleToUser && current.text?.toString()?.equals(label, true) == true) return current
                for (index in 0 until current.childCount) find(current.getChild(index))?.let { return it }
                return null
            }
            return find(automation.rootInActiveWindow)
        }
        await("TalkBack overview is visible", 6000) { node(labels.first()) != null }
        record("talkBackProbeReady", mapOf("labels" to labels, "automationSuppressesServices" to false,
            "enabledServiceIds" to accessibility.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_SPOKEN).map { it.id }))
        for (label in labels) {
            assertTrue(requireNotNull(node(label)).performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS))
            SystemClock.sleep(3500)
            assertEquals("Spoken exploration must leave native controls usable", session.id, runtime.liveSession?.id)
        }
        assertTrue(requireNotNull(node(labels.first())).performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK))
        await("Stop activated through accessibility", 3000) { runtime.liveSession == null }
        assertClean()
        record("boundTalkBackNativeControls", mapOf("labels" to labels, "accessibilityFocusActions" to 3,
            "accessibilityStopClick" to true, "audibleObservation" to false))
        main { activity.finish() }
    }

    @Test fun a29_simulatedOvernightRolloverAndSingleFajrDelivery() {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("hudaExtendedAcceptance") == "true")
        val zone = ZoneId.of("Asia/Muscat")
        val evening = Instant.now().atZone(zone).toLocalDate().atTime(23, 55).atZone(zone).toInstant()
        val morningDate = evening.atZone(zone).toLocalDate().plusDays(1)
        val input = PrayerCalculationInput(23.588, 58.3829, "OM", zone.id, "muslimWorldLeague", "shafi", "none")
        val fajr = requireNotNull(NativePrayerCalculator.adjustedTimes(input, morningDate)["fajr"])
        val simulatedNow = java.util.concurrent.atomic.AtomicLong(evening.toEpochMilli())
        runtime.wallClock = { simulatedNow.get() }
        try {
            setPolicy("full", mapOf("stopAfterSeconds" to 2L))
            val id = PrayerOccurrenceIdentity.idFor(morningDate, "fajr")
            val event = EventData(id, "fajr", fajr.toEpochMilli(), zone.id, morningDate.toString(),
                "Fajr", "Simulated overnight device fixture", null)
            val request = PlanRequest("device-overnight", 0, runtime.livePolicy.revision, 1, 1,
                runtime.digest("overnight-Muscat"), runtime.digest("overnight-Fajr"),
                PrayerPolicy.eligibility(runtime.livePolicy), 300, listOf(event), emptyList(), emptyList())
            runtime.plans.prepare(request)
            runtime.plans.activate(request.operationId, 0)
            fun registered(): AlarmRow = runtime.store.dao.events().single { it.id == id && it.purpose == "prayer" }
            fun dispatchAndWait(row: AlarmRow) {
                val finished = java.util.concurrent.CountDownLatch(1)
                context.sendOrderedBroadcast(runtime.alarms.intent(row), null, object : android.content.BroadcastReceiver() {
                    override fun onReceive(context: android.content.Context?, intent: Intent?) { finished.countDown() }
                }, null, Activity.RESULT_OK, null, null)
                assertTrue("Injected receiver callback must finish before advancing the simulated clock",
                    finished.await(5, java.util.concurrent.TimeUnit.SECONDS))
            }
            assertEquals("registered", registered().registration)
            assertEquals("exact", registered().precision)
            simulatedNow.set(morningDate.atTime(0, 5).atZone(zone).toInstant().toEpochMilli())
            runtime.plans.repair()
            assertEquals("registered", registered().registration)
            assertEquals(morningDate.toString(), registered().localDate)
            assertNull(runtime.store.dao.claim(id))
            record("simulatedMidnightRollover", mapOf("id" to id, "localDate" to morningDate.toString(),
                "futureFajrRetained" to true, "simulatedWallClock" to true, "systemClockChanged" to false))

            simulatedNow.set(fajr.minusSeconds(60).toEpochMilli())
            dispatchAndWait(registered())
            assertNull("An early receiver callback must not claim Fajr", runtime.store.dao.claim(id))
            assertEquals("registered", registered().registration)
            simulatedNow.set(fajr.toEpochMilli())
            val row = registered()
            dispatchAndWait(row)
            val session = playing(row)
            await("Simulated morning playback cutoff", 6000) { runtime.liveSession == null }
            await("Simulated morning terminal outcome persisted", 3000) {
                runtime.store.dao.claim(id)?.let { it.outcome == "completed" && it.reason == "cutoff" } == true
            }
            val claim = requireNotNull(runtime.store.dao.claim(id))
            assertEquals("completed", claim.outcome)
            assertEquals("cutoff", claim.reason)
            assertEquals(fajr.toEpochMilli(), claim.receivedMillis)
            assertClean()

            dispatchAndWait(row)
            simulatedNow.set(evening.toEpochMilli())
            runtime.plans.repair()
            dispatchAndWait(row)
            assertNull("Duplicate dispatch and clock reversal must not replay Fajr", runtime.liveSession)
            assertEquals(claim, runtime.store.dao.claim(id))
            assertTrue(runtime.ownedFuture().none { it.id == id })
            record("simulatedOvernightFajr", mapOf("id" to id, "session" to session.id,
                "scheduledUtcMillis" to fajr.toEpochMilli(), "receivedUtcMillis" to claim.receivedMillis,
                "outcome" to claim.outcome, "reason" to claim.reason, "earlyCallbackClaimed" to false,
                "duplicateOrClockReversalReplayed" to false, "simulatedWallClock" to true,
                "injectedReceiverCallback" to true, "actualAlarmManagerRegistration" to true,
                "systemClockChanged" to false, "elapsedOvernightSoak" to false))
        } finally { runtime.wallClock = System::currentTimeMillis }
    }

    private fun setPolicy(mode: String, overrides: Map<String, Any?> = emptyMap()) {
        val current = runtime.policy()
        runtime.setPolicy(PrayerPolicy.initial().copy(values = PrayerPolicy.initial().values + mapOf(
            "defaultMode" to mode, "vibrate" to false, "respectRingerMode" to false, "volumeGain" to 0.12
        ) + overrides), current.revision)
        instrumentation.waitForIdleSync()
    }

    private fun schedule(prayer: String, delayMillis: Long = 6000): AlarmRow {
        val id = 326_100_000L + nextId++
        val row = AlarmRow("device:$id", id, prayer, System.currentTimeMillis() + delayMillis,
            "UTC", "2026-10-09", "Huda validation · $prayer", "Native-only device test", runtime.epoch(),
            1, 1, 1, "redacted-device-fixture", UUID.randomUUID().toString())
        runtime.store.dao.putOwner(OwnerRow(id, "native", 1))
        val registered = runtime.alarms.register(row)
        assertEquals("exact", registered.precision)
        runtime.store.dao.putEvent(registered)
        return registered
    }

    private fun playing(row: AlarmRow): SessionData {
        await("Automatic player started ${row.id}", 20000) { runtime.liveSession?.occurrenceId == row.id && runtime.liveSession?.phase == "playing" }
        foreground()
        return runtime.liveSession!!
    }

    private fun preview(): SessionData {
        main { runtime.playback.preview("fajr") }
        await("Preview player started", 10000) { runtime.liveSession?.phase == "playing" }
        return runtime.liveSession!!
    }

    private fun foreground() = manager.activeNotifications.first { it.id == PrayerNotifications.FOREGROUND_ID }.notification

    private fun assertClean() {
        await("Foreground notification removed", 3000) { manager.activeNotifications.none { it.id == PrayerNotifications.FOREGROUND_ID } }
        assertNull(runtime.liveSession)
        await("Durable session cleared", 3000) { runtime.store.dao.state("session") == null }
        val power = shell("dumpsys power")
        assertFalse("Adhan wake lock leaked", power.substringAfter("Wake Locks:").substringBefore("Suspend Blockers:").contains("Huda:AdhanPlayback"))
        val audioDump = shell("dumpsys audio")
        assertTrue("Audio dump must expose the actual focus stack", audioDump.contains("Audio Focus stack entries"))
        val following = audioDump.substringAfter("Audio Focus stack entries")
        // Older Android uses "Audio event log"; newer Samsung uses "Events
        // log". Historical abandon/request entries are not live focus owners.
        val boundary = Regex("^\\s*(No external focus policy|In external focus policy|Notify on duck:|Audio event log:|Events log:)",
            RegexOption.MULTILINE).find(following)?.range?.first ?: following.length
        val focus = following.substring(0, boundary)
        assertFalse("Adhan audio focus leaked", focus.contains(context.packageName))
        await("Playback service removed", 3000) {
            val activeServices = shell("dumpsys activity -p ${context.packageName} services")
                .substringBefore("Last ANR service:")
            !activeServices.lineSequence().any { it.contains("ServiceRecord{") &&
                it.contains(context.packageName + "/") && it.contains("AdhanPlaybackService") }
        }
    }

    private fun deliveryRecord(case: String, row: AlarmRow, session: SessionData?, extra: Map<String, Any?> = emptyMap()) {
        val claim = runtime.store.dao.claim(row.id)!!
        val receivedElapsed = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - claim.receivedMillis)
        record(case, mapOf("id" to row.id, "prayer" to row.prayer, "scheduledUtcMillis" to row.utcMillis,
            "receivedUtcMillis" to claim.receivedMillis, "receiverLatenessMillis" to claim.receivedMillis - row.utcMillis,
            "playerStartedElapsedMillis" to session?.startedElapsedMillis,
            "receiverToPlayerMillis" to session?.let { it.startedElapsedMillis - receivedElapsed },
            "outcome" to claim.outcome, "reason" to claim.reason, "precision" to row.precision) + extra)
    }

    private fun remoteReciters(): List<JSONObject> {
        val catalog = JSONObject(context.assets.open("athan_catalog.json").bufferedReader().use { it.readText() })
        val rows = catalog.getJSONArray("reciters")
        return (0 until rows.length()).map { rows.getJSONObject(it) }.filter { it.optString("source") != "bundled" }
    }

    private fun registerFixtures() {
        val staging = File(runtime.audio.storage().stagingRoot)
        for (reciter in remoteReciters()) {
            if (runtime.audio.selectionReady(reciter.getString("id"), "v1")) continue
            val pair = listOf("full", "notification").map { variant ->
                val spec = reciter.getJSONObject(variant)
                val suffix = if (variant == "full") "mp3" else "wav"
                val filename = "${reciter.getString("id")}-$variant.$suffix"
                val local = File(staging, filename)
                context.assets.open(filename).use { input -> local.outputStream().use { input.copyTo(it) } }
                AudioAssetData(reciter.getString("id"), "v1", if (variant == "notification") "short" else "full",
                    local.path, spec.getLong("bytes"), spec.getString("sha256"), spec.getLong("duration_ms"))
            }
            runtime.audio.register(pair)
            assertTrue(runtime.audio.selectionReady(reciter.getString("id"), "v1"))
            record("registeredPair", mapOf("reciter" to reciter.getString("id")))
        }
    }

    private fun main(action: () -> Unit) = instrumentation.runOnMainSync(action)
    private fun shell(command: String): String = automation.executeShellCommand(command).use { descriptor ->
        android.os.ParcelFileDescriptor.AutoCloseInputStream(descriptor).bufferedReader().use { it.readText() }
    }
    private fun await(label: String, timeout: Long, predicate: () -> Boolean) {
        val deadline = SystemClock.elapsedRealtime() + timeout
        while (SystemClock.elapsedRealtime() < deadline) { if (predicate()) return; SystemClock.sleep(30) }
        record("failure", mapOf("label" to label, "session" to runtime.liveSession?.phase,
            "latest" to runtime.store.dao.latest(3).map { it.reason }))
        fail("Timed out: $label")
    }
    private fun record(case: String, details: Map<String, Any?>) {
        val line = JSONObject(mapOf("case" to case, "utcMillis" to System.currentTimeMillis()) + details).toString()
        report.appendText(line + "\n")
        android.util.Log.i("HudaDeviceAcceptance", line)
    }
    companion object { private var nextId = 1L }
}
