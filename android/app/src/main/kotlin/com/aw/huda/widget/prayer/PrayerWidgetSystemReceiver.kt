package com.aw.huda.widget.prayer

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
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_LOCALE_CHANGED -> {
                PrayerWidgetUpdater.updateAll(context)
                PrayerWidgetScheduler.scheduleNext(context)
                PrayerWidgetScheduler.scheduleMinuteTick(context)
            }
        }
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            PrayerWidgetReliabilityManager.start(context)
        }
    }
}
