package com.aw.huda.widget.prayer

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

internal object PrayerWidgetReliabilityManager {
    private const val TAG = "PrayerReliability"
    private const val WORK_NAME = "prayer_widget_reliability"
    private const val TRANSITION_WORK_NAME = "prayer_widget_transition_safety"
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
            WorkManager.getInstance(context).cancelUniqueWork(TRANSITION_WORK_NAME)
            Log.d(TAG, "WorkManager safety net cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel WorkManager safety net", e)
        }
    }

    fun scheduleTransitionSafetyNet(context: Context, triggerAtMillis: Long) {
        try {
            val delay = (triggerAtMillis - System.currentTimeMillis()).coerceAtLeast(0L)
            val request = OneTimeWorkRequestBuilder<PrayerWidgetReliabilityWorker>()
                .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                TRANSITION_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                request,
            )
        } catch (e: Exception) {
            Log.w(TAG, "Could not enroll transition safety net", e)
        }
    }

    fun cancelTransitionSafetyNet(context: Context) {
        runCatching {
            WorkManager.getInstance(context).cancelUniqueWork(TRANSITION_WORK_NAME)
        }.onFailure { Log.w(TAG, "Could not cancel transition safety net", it) }
    }
}
