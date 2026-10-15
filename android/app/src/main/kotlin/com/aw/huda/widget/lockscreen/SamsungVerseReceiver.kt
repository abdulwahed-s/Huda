package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.aw.huda.widget.QuranWidgetUpdater
import com.aw.huda.widget.WidgetBroadcastDispatcher

class SamsungVerseReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        refresh(context, "update ids=${ids.joinToString()}")

    override fun onEnabled(context: Context) = refresh(context, "enabled")

    override fun onDisabled(context: Context) = refresh(context, "disabled")

    override fun onDeleted(context: Context, ids: IntArray) =
        refresh(context, "deleted ids=${ids.joinToString()}")

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) = refresh(context, "options id=$appWidgetId $newOptions")

    override fun onReceive(context: Context, intent: Intent) {
        Log.i("SamsungVerseWidget", "action=${intent.action}")
        super.onReceive(context, intent)
    }

    private fun refresh(context: Context, event: String) {
        WidgetBroadcastDispatcher.launch(
            context, goAsync(), "SamsungVerseWidget", event,
            QuranWidgetUpdater::enqueueImmediateUpdate,
        ) { appContext -> QuranWidgetUpdater.refreshAll(appContext) }
    }
}
