package com.aw.huda

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.glance.appwidget.updateAll
import com.aw.huda.widget.HudaGlanceWidget
import com.aw.huda.widget.WidgetDataRepository
import com.aw.huda.widget.prayer.PrayerWidgetReliabilityManager
import com.aw.huda.widget.prayer.PrayerWidgetScheduler
import com.aw.huda.widget.prayer.PrayerWidgetUpdater
import com.aw.huda.miqaat.MiqaatLockMethodHandler
import com.aw.huda.location.LocationSource
import com.aw.huda.location.LocationSupport
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "com.aw.huda/widget"
    private val LOCATION_CHANNEL = "com.aw.huda/location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val locationSource = LocationSource(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isLocationServiceEnabled" ->
                            result.success(
                                LocationSupport.isLocationServiceEnabled(applicationContext)
                            )
                        "openLocationSettings" ->
                            result.success(LocationSupport.openLocationSettings(this))
                        "getLastKnownPosition" ->
                            locationSource.getLastKnownPosition { map ->
                                runOnUiThread { result.success(map) }
                            }
                        "getCurrentPosition" ->
                            locationSource.getCurrentPosition(
                                { map -> runOnUiThread { result.success(map) } },
                                { code, msg -> runOnUiThread { result.error(code, msg, null) } },
                            )
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    android.util.Log.e("HudaLocation", "location channel error", e)
                    runOnUiThread { result.error("LOCATION_ERROR", e.message, null) }
                }
            }
        
        // Widget channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val appCtx = applicationContext
                            val themeName = WidgetDataRepository.getThemeName(appCtx)
                            val isDark = WidgetDataRepository.isDarkMode(appCtx)
                            println("🔄 Updating widget with theme: $themeName, isDark: $isDark")

                            HudaGlanceWidget().updateAll(appCtx)

                            println("✅ Widget updated via MethodChannel")
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            println("❌ Failed to update widget: ${e.message}")
                            e.printStackTrace()
                            withContext(Dispatchers.Main) { result.error("UPDATE_ERROR", e.message, null) }
                        }
                    }
                }
                "updatePrayerWidget" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val appCtx = applicationContext
                            PrayerWidgetUpdater.updateAll(appCtx)
                            PrayerWidgetScheduler.scheduleNext(appCtx)
                            PrayerWidgetReliabilityManager.start(appCtx)
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            println("❌ Failed to update prayer widget: ${e.message}")
                            e.printStackTrace()
                            withContext(Dispatchers.Main) {
                                result.error("PRAYER_UPDATE_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Miqaat Lock channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MiqaatLockMethodHandler.CHANNEL_NAME
        ).setMethodCallHandler(MiqaatLockMethodHandler(this))
    }
}
