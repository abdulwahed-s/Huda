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
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        ensureHourlyUpdates(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelPeriodicUpdate(context)
    }
    
    private fun cancelPeriodicUpdate(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }

    companion object {
        const val WORK_NAME = "huda_widget_update_work"
        const val UPDATE_INTERVAL_HOURS = 1L

        fun ensureHourlyUpdates(context: Context) {
            val request = PeriodicWorkRequestBuilder<HudaWidgetWorker>(
                UPDATE_INTERVAL_HOURS,
                TimeUnit.HOURS,
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request,
            )
        }
    }
}
