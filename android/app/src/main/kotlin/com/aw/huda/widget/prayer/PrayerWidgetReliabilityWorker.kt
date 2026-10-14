package com.aw.huda.widget.prayer

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.CancellationException

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
            val update = PrayerWidgetUpdater.updateAll(context)
            Log.d(TAG, "Safety-net tick: refreshed ${update.widgetCount} widget(s)")
            if (update.failedUpdates > 0 || update.alarm?.error != null) return Result.retry()

            Result.success()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (e: Exception) {
            Log.e(TAG, "Safety-net worker failed", e)
            Result.retry()
        }
    }
}
