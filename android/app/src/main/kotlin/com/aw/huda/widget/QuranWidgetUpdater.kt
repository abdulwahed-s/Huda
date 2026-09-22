package com.aw.huda.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

object QuranWidgetUpdater {
    private val updateMutex = Mutex()

    suspend fun refreshAll(context: Context) {
        updateMutex.withLock {
            withContext(Dispatchers.IO) {
                val appContext = context.applicationContext
                val configuration = WidgetDataRepository.readConfiguration(appContext)
                QuranWidgetStateStore.synchronize(appContext, configuration)
                HudaGlanceWidget().updateAll(appContext)
            }
        }
    }
}
