package com.aw.huda.widget.prayer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log

class PrayerWidgetReceiver : AppWidgetProvider() {
    companion object {
        private const val TAG = "PrayerWidgetReceiver"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        Log.d(TAG, "onUpdate(${appWidgetIds.size})")
        for (id in appWidgetIds) {
            PrayerWidgetUpdater.update(context, appWidgetManager, id)
        }

        PrayerWidgetScheduler.scheduleNext(context)
        PrayerWidgetScheduler.scheduleMinuteTick(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "onEnabled")
        PrayerWidgetUpdater.updateAll(context)
        PrayerWidgetScheduler.scheduleNext(context)
        PrayerWidgetScheduler.scheduleMinuteTick(context)
        PrayerWidgetReliabilityManager.start(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "onDisabled")
        PrayerWidgetScheduler.cancel(context)
        PrayerWidgetScheduler.cancelMinuteTick(context)
        PrayerWidgetReliabilityManager.stop(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        super.onAppWidgetOptionsChanged(
            context,
            appWidgetManager,
            appWidgetId,
            newOptions,
        )
        PrayerWidgetUpdater.update(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PRAYER_WIDGET_UPDATE,
            ACTION_HOME_WIDGET_UPDATE -> {
                PrayerWidgetUpdater.updateAll(context)
                PrayerWidgetScheduler.scheduleNext(context)
                PrayerWidgetScheduler.scheduleMinuteTick(context)
            }
            ACTION_PRAYER_WIDGET_MINUTE_TICK -> {
                PrayerWidgetUpdater.updateAll(context)
                PrayerWidgetScheduler.scheduleMinuteTick(context)
            }
        }
    }
}

internal const val ACTION_PRAYER_WIDGET_UPDATE =
    "com.aw.huda.widget.prayer.ACTION_PRAYER_WIDGET_UPDATE"
internal const val ACTION_PRAYER_WIDGET_MINUTE_TICK =
    "com.aw.huda.widget.prayer.ACTION_PRAYER_WIDGET_MINUTE_TICK"
internal const val ACTION_HOME_WIDGET_UPDATE =
    "es.antonborri.home_widget.action.BACKGROUND"
