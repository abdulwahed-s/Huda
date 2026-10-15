package com.aw.huda.widget.prayer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import com.aw.huda.countdown.PrayerCountdownController
import com.aw.huda.widget.lockscreen.SamsungPrayerReceiver

class PrayerWidgetReceiver : SamsungPrayerReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // HomeWidget also sends this with an empty home-ID array in headless
            // engines. Native lock widgets must still receive that refresh.
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                // Settings committed by a headless engine arrive here, not on MainActivity.
                runCatching { PrayerCountdownController.refresh(context) }
                    .onFailure { android.util.Log.w("PrayerCountdown", "refresh failed", it) }
                refresh(context, "home/bridge update")
            }
            ACTION_PRAYER_WIDGET_UPDATE, ACTION_HOME_WIDGET_UPDATE -> {
                PrayerWidgetScheduler.logDelivery(intent)
                refresh(context, "transition expected=${intent.getLongExtra(PrayerWidgetScheduler.EXTRA_EXPECTED_TRIGGER, 0L)}")
            }
            ACTION_PRAYER_WIDGET_MINUTE_TICK -> {
                PrayerWidgetScheduler.cancelMinuteTick(context)
                refresh(context, "legacy minute alarm recovery")
            }
            else -> super.onReceive(context, intent)
        }
    }
}

internal const val ACTION_PRAYER_WIDGET_UPDATE =
    "com.aw.huda.widget.prayer.ACTION_PRAYER_WIDGET_UPDATE"
internal const val ACTION_PRAYER_WIDGET_MINUTE_TICK =
    "com.aw.huda.widget.prayer.ACTION_PRAYER_WIDGET_MINUTE_TICK"
internal const val ACTION_HOME_WIDGET_UPDATE =
    "es.antonborri.home_widget.action.BACKGROUND"
