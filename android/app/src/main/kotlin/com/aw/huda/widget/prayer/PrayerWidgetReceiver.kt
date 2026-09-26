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
        PrayerWidgetReliabilityManager.enqueueImmediateUpdate(context)
        PrayerWidgetReliabilityManager.start(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "onEnabled")
        PrayerWidgetReliabilityManager.enqueueImmediateUpdate(context)
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
        PrayerWidgetReliabilityManager.enqueueImmediateUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PRAYER_WIDGET_UPDATE,
            ACTION_HOME_WIDGET_UPDATE -> {
                PrayerWidgetScheduler.logDelivery(intent)
                PrayerWidgetReliabilityManager.enqueueImmediateUpdate(context)
            }

            ACTION_PRAYER_WIDGET_MINUTE_TICK -> {
                PrayerWidgetScheduler.cancelMinuteTick(context)
                PrayerWidgetReliabilityManager.enqueueImmediateUpdate(context)
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
