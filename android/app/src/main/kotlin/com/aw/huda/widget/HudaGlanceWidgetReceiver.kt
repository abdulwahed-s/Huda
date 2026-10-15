package com.aw.huda.widget

import android.content.Context
import android.appwidget.AppWidgetManager
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit
import com.aw.huda.widget.lockscreen.SamsungLockWidgetRegistry

class HudaGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    
    override val glanceAppWidget: GlanceAppWidget = HudaGlanceWidget()
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        ensureHourlyUpdates(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        ensureHourlyUpdates(context)
    }
    
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        super.onUpdate(context, manager, ids)
        ensureHourlyUpdates(context)
    }

    companion object {
        const val WORK_NAME = "huda_widget_update_work"
        const val UPDATE_INTERVAL_HOURS = 1L

        fun ensureHourlyUpdates(context: Context) {
            if (SamsungLockWidgetRegistry.quran(context).count == 0) {
                WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
                WorkManager.getInstance(context).cancelUniqueWork(QuranWidgetUpdater.IMMEDIATE_WORK_NAME)
                return
            }
            val request = PeriodicWorkRequestBuilder<HudaWidgetWorker>(
                UPDATE_INTERVAL_HOURS,
                TimeUnit.HOURS,
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }
    }
}
