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
            println("🔄 HudaWidgetWorker: Starting periodic update...")

            val newVerse = WidgetDataRepository.getRandomVerse(context)

            WidgetDataRepository.saveNewQuote(context, newVerse)
            
            println("📖 New verse selected: ${newVerse.take(30)}...")

            HudaGlanceWidget().updateAll(context)
            
            println("✅ Widget updated successfully")
            
            Result.success()
        } catch (e: Exception) {
            println("❌ Widget update failed: ${e.message}")
            Result.retry()
        }
    }
}
