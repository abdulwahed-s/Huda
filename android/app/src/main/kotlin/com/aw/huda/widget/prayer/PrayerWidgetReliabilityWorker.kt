package com.aw.huda.widget.prayer

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

internal class PrayerWidgetReliabilityWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    companion object {
        private const val TAG = "PrayerWidgetWorker"
    }

    override suspend fun doWork(): Result {
        return try {
            val context = applicationContext
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PrayerWidgetReceiver::class.java)
            )
            if (ids.isEmpty()) {
                Log.d(TAG, "No prayer widgets pinned; skipping.")
                return Result.success()
            }

            val travel = PrayerWidgetTravelManager.refreshIfNeeded(context)
            Log.d(TAG, "Native travel validation: ${travel.status}")

            Log.d(TAG, "Safety-net tick: refreshing ${ids.size} widget(s)")
            val update = PrayerWidgetUpdater.updateAll(context)
            val alarm = PrayerWidgetScheduler.ensureAlarmsActive(context)

            if (update.failedUpdates > 0 || alarm.error != null) return Result.retry()

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Safety-net worker failed", e)
            Result.retry()
        }
    }
}
