package com.aw.huda

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.aw.huda.widget.HudaGlanceWidget
import com.aw.huda.widget.WidgetDataRepository
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.aw.huda/widget"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            delay(100)

                            val themeName = WidgetDataRepository.getThemeName(this@MainActivity)
                            val isDark = WidgetDataRepository.isDarkMode(this@MainActivity)
                            println("🔄 Updating widget with theme: $themeName, isDark: $isDark")

                            val manager = GlanceAppWidgetManager(this@MainActivity)
                            val glanceIds = manager.getGlanceIds(HudaGlanceWidget::class.java)
                            
                            println("📱 Found ${glanceIds.size} widget instance(s) to update")

                            val widget = HudaGlanceWidget()
                            for (glanceId in glanceIds) {
                                widget.update(this@MainActivity, glanceId)
                                println("✓ Updated widget: $glanceId")
                            }
                            
                            CoroutineScope(Dispatchers.Main).launch {
                                println("✅ Widget updated via MethodChannel")
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            println("❌ Failed to update widget: ${e.message}")
                            e.printStackTrace()
                            CoroutineScope(Dispatchers.Main).launch {
                                result.error("UPDATE_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
