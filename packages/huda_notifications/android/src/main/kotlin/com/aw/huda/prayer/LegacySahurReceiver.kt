package com.aw.huda.prayer

import android.content.Context
import android.content.Intent

object LegacySahurReceiver {
    fun deliver(context: Context, intent: Intent, finished: () -> Unit) {
        val runtime = PrayerNotificationRuntime.get(context)
        runtime.maintenance.execute {
            try {
                runtime.initialize()
                if (intent.action == "com.gdelataillade.alarm.ACTION_STOP") {
                    runtime.main.post { runtime.liveSession?.takeIf { it.prayer == "sahur" }?.let { runtime.playback.stop(it.id) } }
                } else if (intent.getIntExtra("id", -1) in 114..143) {
                    val row = runtime.sahur.migrate(intent)
                    if (row != null) {
                        runtime.store.dao.event(row.key)?.let { runtime.alarms.cancel(it) }
                        runtime.store.dao.putEvent(row)
                        PrayerAlarmReceiver.deliver(context, runtime.alarms.intent(row))
                    }
                }
            } finally { finished() }
        }
    }
}
