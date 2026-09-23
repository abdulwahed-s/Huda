package com.aw.huda.widget.prayer

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PrayerWidgetSystemReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PrayerWidgetSystemRx"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")
        val handled = when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED -> true

            else -> false
        }
        if (!handled) return

        val update = PrayerWidgetUpdater.updateAll(context)
        if (update.widgetCount > 0) {
            PrayerWidgetScheduler.scheduleNext(context)
            if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
                intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
            ) {
                PrayerWidgetReliabilityManager.start(context)
            }
        } else {
            PrayerWidgetReliabilityManager.stop(context)
            PrayerWidgetScheduler.cancel(context)
        }
    }
}
