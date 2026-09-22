package com.aw.huda.widget

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.CancellationException

class HudaWidgetWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            QuranWidgetUpdater.refreshAll(context)
            Result.success()
        } catch (error: CancellationException) {
            throw error
        } catch (e: Exception) {
            Log.e("HudaQuranWidget", "Periodic widget refresh failed", e)
            Result.retry()
        }
    }
}
