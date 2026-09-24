package com.aw.huda.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.work.BackoffPolicy
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.aw.huda.widget.prayer.PrayerWidgetRepository
import dev.fluttercommunity.workmanager.BackgroundWorker
import java.util.concurrent.TimeUnit

internal object PrayerTravelReliabilityManager {
    private const val PERIODIC_WORK_NAME = "huda_prayer_travel_monitor"
    private const val RECONCILIATION_WORK_NAME = "huda_prayer_location_reconciliation"
    private const val INTERVAL_MINUTES = 30L
    const val DART_RECONCILIATION_TASK = "reconcilePrayerLocationCandidate"

    fun sync(
        context: Context,
        requestedEnabled: Boolean? = null,
        requestedMode: String? = null,
    ): Map<String, Any> {
        if (requestedEnabled == false ||
            requestedMode != null && requestedMode != "automatic"
        ) {
            stop(context)
            return mapOf("state" to "disabled", "enrolled" to false)
        }
        val status = status(context)
        if (status["state"] != "enabled") {
            stop(context)
            return status
        }
        val request = PeriodicWorkRequestBuilder<PrayerTravelWorker>(
            INTERVAL_MINUTES,
            TimeUnit.MINUTES,
        ).setBackoffCriteria(
            BackoffPolicy.EXPONENTIAL,
            15,
            TimeUnit.MINUTES,
        ).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
        return status
    }

    fun status(context: Context): Map<String, Any> {
        val requested = PrayerWidgetRepository.shouldEnrollTravel(context)
        if (!requested) return mapOf("state" to "disabled", "enrolled" to false)
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE)
                as LocationManager
        val serviceEnabled = runCatching {
            locationManager.getProviders(true).isNotEmpty()
        }.getOrDefault(false)
        if (!serviceEnabled) {
            return mapOf("state" to "unavailable", "enrolled" to false)
        }
        if (!hasForegroundPermission(context)) {
            return mapOf("state" to "permissionRequired", "enrolled" to false)
        }
        if (!hasBackgroundPermission(context)) {
            return mapOf("state" to "foregroundOnly", "enrolled" to false)
        }
        return mapOf("state" to "enabled", "enrolled" to true)
    }

    fun canRun(context: Context): Boolean = status(context)["state"] == "enabled"

    fun stop(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_NAME)
    }

    fun enqueueReconciliation(context: Context, reason: String) {
        val data = Data.Builder()
            .putString(BackgroundWorker.DART_TASK_KEY, DART_RECONCILIATION_TASK)
            .putString("reason", reason)
            .build()
        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(data)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            RECONCILIATION_WORK_NAME,
            ExistingWorkPolicy.KEEP,
            request,
        )
    }

    private fun hasForegroundPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED

    private fun hasBackgroundPermission(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
}
