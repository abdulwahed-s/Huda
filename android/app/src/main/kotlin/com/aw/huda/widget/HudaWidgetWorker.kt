package com.aw.huda.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class HudaWidgetWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {
    
    override suspend fun doWork(): Result {
        return try {
            HudaGlanceWidget().updateAll(context)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
