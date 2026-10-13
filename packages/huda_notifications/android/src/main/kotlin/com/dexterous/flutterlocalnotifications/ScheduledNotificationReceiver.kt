package com.dexterous.flutterlocalnotifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.aw.huda.prayer.LegacyPluginAlarms
import com.aw.huda.prayer.PrayerNotificationRuntime

class ScheduledNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        val runtime = PrayerNotificationRuntime.get(context)
        runtime.delivery.execute {
            try {
                runtime.initialize()
                LegacyPluginAlarms.deliver(runtime.context, intent)
            } catch (_: Exception) {
                // Storage before the first unlock; the entry stays and repair re-arms it.
            } finally { pending.finish() }
        }
    }
}
