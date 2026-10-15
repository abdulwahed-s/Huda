package com.aw.huda.widget.prayer

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.aw.huda.countdown.PrayerCountdownController
import com.aw.huda.location.PrayerTravelReliabilityManager
import com.aw.huda.widget.QuranWidgetUpdater
import com.aw.huda.widget.WidgetBroadcastDispatcher

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

        PrayerTravelReliabilityManager.sync(context)
        PrayerTravelReliabilityManager.enqueueReconciliation(
            context,
            "android-system-${intent.action ?: "unknown"}",
        )

        WidgetBroadcastDispatcher.launch(context, goAsync(), TAG,
            "system ${intent.action}", { appContext ->
                PrayerWidgetReliabilityManager.enqueueImmediateUpdate(appContext)
            }) { appContext ->
            // Boot, an update or a clock change: bring the countdown back without Huda.
            runCatching { PrayerCountdownController.refresh(appContext) }
                .onFailure { Log.w(TAG, "Countdown refresh failed", it) }
            try {
                val report = PrayerWidgetUpdater.updateAll(appContext)
                if (report.failedUpdates > 0 || report.alarm?.error != null) {
                    PrayerWidgetReliabilityManager.enqueueImmediateUpdate(appContext)
                }
            } finally {
                if (intent.action != AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED) {
                    QuranWidgetUpdater.refreshAll(appContext)
                }
            }
        }
    }
}
