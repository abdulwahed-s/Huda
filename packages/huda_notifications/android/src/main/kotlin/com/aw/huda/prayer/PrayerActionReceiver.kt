package com.aw.huda.prayer

import android.content.*

class PrayerActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in listOf("com.aw.huda.prayer.STOP", "com.aw.huda.prayer.DISMISS", "com.aw.huda.prayer.FOLLOWUP")) return
        val runtime = PrayerNotificationRuntime.get(context)
        val pending = goAsync()
        runtime.delivery.execute {
            try {
                runtime.initialize()
                if (intent.getStringExtra("epoch") != runtime.epoch()) return@execute
                val id = intent.getStringExtra("session") ?: return@execute
                runtime.main.post {
                    val session = runtime.liveSession
                    if (session?.id != id || session.occurrenceId != intent.getLongExtra("id", -1)) return@post
                    when (intent.action) {
                        "com.aw.huda.prayer.STOP", "com.aw.huda.prayer.DISMISS",
                        "com.aw.huda.prayer.FOLLOWUP" -> runtime.playback.stop(id)
                    }
                }
            } finally { pending.finish() }
        }
    }
}
