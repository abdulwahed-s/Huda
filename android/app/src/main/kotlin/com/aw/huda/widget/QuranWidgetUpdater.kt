package com.aw.huda.widget

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.updateAll
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.aw.huda.widget.lockscreen.SamsungLockWidgetRegistry
import com.aw.huda.widget.lockscreen.SamsungVerseWidgetUpdater
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

object QuranWidgetUpdater {
    private val updateMutex = Mutex()
    internal const val IMMEDIATE_WORK_NAME = "huda_quran_widget_immediate_update"

    suspend fun refreshAll(context: Context) {
        updateMutex.withLock {
            withContext(Dispatchers.IO) {
                val appContext = context.applicationContext
                val instances = SamsungLockWidgetRegistry.quran(appContext)
                HudaGlanceWidgetReceiver.ensureHourlyUpdates(appContext)
                val configuration = WidgetDataRepository.readConfiguration(appContext)
                val errors = mutableListOf<String>()
                try {
                    QuranWidgetStateStore.synchronize(appContext, configuration)
                    if (instances.home.isNotEmpty()) HudaGlanceWidget().updateAll(appContext)
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (error: Exception) {
                    Log.e("HudaQuranWidget", "Glance refresh failed", error)
                    errors += "Home Quran widgets: ${error.message}"
                }
                try {
                    errors += SamsungVerseWidgetUpdater.updateAll(appContext, instances.lock, configuration)
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (error: Exception) {
                    Log.e("HudaQuranWidget", "Native verse refresh failed", error)
                    errors += "Lock Quran widgets: ${error.message}"
                }
                if (errors.isNotEmpty()) throw IllegalStateException(errors.joinToString("; "))
            }
        }
    }

    fun enqueueImmediateUpdate(context: Context) {
        WorkManager.getInstance(context.applicationContext).enqueueUniqueWork(
            IMMEDIATE_WORK_NAME, ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<HudaWidgetWorker>().build(),
        )
    }
}
