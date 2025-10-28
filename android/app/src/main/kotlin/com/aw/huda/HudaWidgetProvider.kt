package com.aw.huda

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*
import java.io.File

class HudaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.huda_widget).apply {
                try {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    
                    // Try to load the complete widget image first
                    val completeImagePath = widgetData?.getString("flutter.completeWidgetImagePath", "") ?: ""
                    var imageLoaded = false
                    
                    println("🔍 Looking for complete widget image at: $completeImagePath")
                    
                    if (completeImagePath.isNotEmpty()) {
                        try {
                            val imageFile = File(completeImagePath)
                            println("📁 Image file exists: ${imageFile.exists()}")
                            if (imageFile.exists()) {
                                val bitmap = BitmapFactory.decodeFile(completeImagePath)
                                if (bitmap != null) {
                                    // Show the complete widget image
                                    setImageViewBitmap(R.id.widget_complete_image, bitmap)
                                    setViewVisibility(R.id.widget_complete_image, android.view.View.VISIBLE)
                                    setViewVisibility(R.id.widget_fallback_content, android.view.View.GONE)
                                    imageLoaded = true
                                    println("✅ Successfully loaded complete widget image")
                                } else {
                                    println("❌ Failed to decode bitmap from file")
                                }
                            } else {
                                println("❌ Image file does not exist")
                            }
                        } catch (e: Exception) {
                            println("💥 Failed to load complete widget image: ${e.message}")
                        }
                    } else {
                        println("⚠️ No complete widget image path provided")
                    }
                    
                    // If complete image not loaded, show fallback content
                    if (!imageLoaded) {
                        showFallbackContent(widgetData)
                    }
                    
                } catch (e: Exception) {
                    // Any error, show fallback content
                    showFallbackContent(null)
                }
                
                // Add click intent to open the app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                intent?.putExtra("widget_clicked", true)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    private fun RemoteViews.showFallbackContent(widgetData: android.content.SharedPreferences?) {
        // Hide the complete image and show fallback content
        setViewVisibility(R.id.widget_complete_image, android.view.View.GONE)
        setViewVisibility(R.id.widget_fallback_content, android.view.View.VISIBLE)
        
        try {
            val quote = widgetData?.getString("flutter.quote", "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا") ?: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا"
            val lastUpdate = widgetData?.getString("flutter.lastUpdate", "") ?: ""
            val themeColorPrimary = widgetData?.getString("flutter.themeColorPrimary", "#8B5CF6") ?: "#8B5CF6"
            val themeName = widgetData?.getString("flutter.themeName", "purple") ?: "purple"
            val themeMode = widgetData?.getString("flutter.themeMode", "light") ?: "light"
            
            // Set fallback content
            setTextViewText(R.id.widget_quote, quote)
            setTextViewText(R.id.widget_last_update, "آخر تحديث: ${formatTime(lastUpdate)}")
            
            // Apply theme colors
            val primaryColor = Color.parseColor(themeColorPrimary)
            setTextColor(R.id.widget_title, primaryColor)
            
            // Set text colors based on theme mode
            val quoteTextColor = if (themeMode == "dark") Color.WHITE else Color.parseColor("#1A1A1A")
            val footerTextColor = if (themeMode == "dark") Color.parseColor("#CCCCCC") else Color.parseColor("#666666")
            
            setTextColor(R.id.widget_quote, quoteTextColor)
            setTextColor(R.id.widget_last_update, footerTextColor)
            
            // Set themed background
            val backgroundResource = getThemedBackground(themeName, themeMode == "dark")
            setInt(R.id.widget_fallback_content, "setBackgroundResource", backgroundResource)
            
        } catch (e: Exception) {
            // Ultimate fallback
            setTextViewText(R.id.widget_quote, "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا")
            setTextViewText(R.id.widget_last_update, "آخر تحديث: الآن")
            setTextColor(R.id.widget_title, Color.parseColor("#8B5CF6"))
            setTextColor(R.id.widget_quote, Color.parseColor("#1A1A1A"))
            setTextColor(R.id.widget_last_update, Color.parseColor("#666666"))
            setInt(R.id.widget_fallback_content, "setBackgroundResource", R.drawable.widget_background_purple)
        }
    }
    
    private fun getThemedBackground(themeName: String, isDarkMode: Boolean): Int {
        return if (isDarkMode) {
            when (themeName) {
                "green" -> R.drawable.widget_background_green_dark
                "blue" -> R.drawable.widget_background_blue_dark
                "red" -> R.drawable.widget_background_red_dark
                "orange" -> R.drawable.widget_background_orange_dark
                "teal" -> R.drawable.widget_background_teal_dark
                "indigo" -> R.drawable.widget_background_indigo_dark
                "pink" -> R.drawable.widget_background_pink_dark
                "purple" -> R.drawable.widget_background_purple_dark
                else -> R.drawable.widget_background_purple_dark
            }
        } else {
            when (themeName) {
                "green" -> R.drawable.widget_background_green
                "blue" -> R.drawable.widget_background_blue
                "red" -> R.drawable.widget_background_red
                "orange" -> R.drawable.widget_background_orange
                "teal" -> R.drawable.widget_background_teal
                "indigo" -> R.drawable.widget_background_indigo
                "pink" -> R.drawable.widget_background_pink
                "purple" -> R.drawable.widget_background_purple
                else -> R.drawable.widget_background_purple
            }
        }
    }
    
    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
        super.onDisabled(context)
    }
    
    private fun formatTime(isoString: String): String {
        return if (isoString.isNotEmpty()) {
            try {
                val time = isoString.substring(11, 16) // Extract HH:MM from ISO string
                time
            } catch (e: Exception) {
                "الآن"
            }
        } else {
            "الآن"
        }
    }
}
