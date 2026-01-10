package com.aw.huda.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class HudaGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    
    override val glanceAppWidget: GlanceAppWidget = HudaGlanceWidget()
    
    companion object {
        const val WORK_NAME = "huda_widget_update_work"
        const val UPDATE_INTERVAL_MINUTES = 15L
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        schedulePeriodicUpdate(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelPeriodicUpdate(context)
    }
    
    private fun schedulePeriodicUpdate(context: Context) {
        val workRequest = PeriodicWorkRequestBuilder<HudaWidgetWorker>(
            UPDATE_INTERVAL_MINUTES, TimeUnit.MINUTES
        ).build()
        
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
        
        println("📅 Scheduled widget updates every $UPDATE_INTERVAL_MINUTES minutes")
    }
    
    private fun cancelPeriodicUpdate(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        println("🛑 Cancelled widget periodic updates")
    }
}
