package com.aw.huda.widget.prayer

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

internal object PrayerWidgetReliabilityManager {
    private const val TAG = "PrayerReliability"
    private const val WORK_NAME = "prayer_widget_reliability"
    private const val INTERVAL_MINUTES = 15L

    fun start(context: Context) {
        try {
            val request = PeriodicWorkRequestBuilder<PrayerWidgetReliabilityWorker>(
                INTERVAL_MINUTES, TimeUnit.MINUTES,
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
            Log.d(TAG, "WorkManager safety net enrolled (${INTERVAL_MINUTES}m)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enroll WorkManager safety net", e)
        }
    }

    fun stop(context: Context) {
        try {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "WorkManager safety net cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel WorkManager safety net", e)
        }
    }
}
