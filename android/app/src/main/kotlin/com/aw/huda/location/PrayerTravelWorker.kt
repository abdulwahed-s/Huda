package com.aw.huda.location

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.aw.huda.widget.prayer.PrayerTravelStatus
import com.aw.huda.widget.prayer.PrayerWidgetTravelManager

internal class PrayerTravelWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val context = applicationContext
        if (!PrayerTravelReliabilityManager.canRun(context)) {
            PrayerTravelReliabilityManager.stop(context)
            return Result.success()
        }
        return try {
            val travel = PrayerWidgetTravelManager.refreshIfNeeded(context)
            Log.d("PrayerTravelWorker", "Travel validation: ${travel.status}")
            when (travel.status) {
                PrayerTravelStatus.CANDIDATE_SUBMITTED -> {
                    PrayerTravelReliabilityManager.enqueueReconciliation(
                        context,
                        "android-background-travel",
                    )
                    Result.success()
                }

                PrayerTravelStatus.COMMIT_FAILED,
                PrayerTravelStatus.LOCATION_UNAVAILABLE,
                PrayerTravelStatus.TIME_ZONE_UNAVAILABLE -> Result.retry()

                else -> Result.success()
            }
        } catch (error: Exception) {
            Log.w("PrayerTravelWorker", "Travel validation failed", error)
            Result.retry()
        }
    }
}
