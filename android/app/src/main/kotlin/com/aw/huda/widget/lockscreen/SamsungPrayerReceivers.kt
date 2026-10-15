package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.aw.huda.widget.WidgetBroadcastDispatcher
import com.aw.huda.widget.prayer.PrayerWidgetReliabilityManager
import com.aw.huda.widget.prayer.PrayerWidgetUpdater

class SamsungPrayerCompactReceiver : SamsungPrayerReceiver()
class SamsungPrayerExpandedReceiver : SamsungPrayerReceiver()

abstract class SamsungPrayerReceiver : AppWidgetProvider() {
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
        Log.i("SamsungPrayerWidget", "${javaClass.simpleName} action=${intent.action}")
        super.onReceive(context, intent)
    }

    protected fun refresh(context: Context, event: String) {
        WidgetBroadcastDispatcher.launch(
            context, goAsync(), "SamsungPrayerWidget", "${javaClass.simpleName} $event",
            PrayerWidgetReliabilityManager::enqueueImmediateUpdate,
        ) { appContext ->
            val report = PrayerWidgetUpdater.updateAll(appContext)
            if (report.failedUpdates > 0 || report.alarm?.error != null) {
                PrayerWidgetReliabilityManager.enqueueImmediateUpdate(appContext)
            }
        }
    }
}
