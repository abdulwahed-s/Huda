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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "com.aw.huda/widget"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
