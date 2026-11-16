package com.aw.huda.prayer

import android.content.*

class PrayerActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in listOf("com.aw.huda.prayer.STOP", "com.aw.huda.prayer.DISMISS", "com.aw.huda.prayer.FOLLOWUP")) return
        val runtime = PrayerNotificationRuntime.get(context)
        // The sounding session lives in this process: stop it now, on this main
        // thread callback, rather than behind delivery or storage work. Its
        // random ID only exists in the current epoch, since a reset stops it.
        val live = runtime.liveSession
        val id = intent.getStringExtra("session")
        if (live != null && live.id == id && live.occurrenceId == intent.getLongExtra("id", -1)) {
            runtime.playback.stop(live.id); return
        }
        val pending = goAsync()
        runtime.delivery.execute {
            try {
                runtime.initialize()
                if (intent.getStringExtra("epoch") != runtime.epoch()) return@execute
                if (id == null) return@execute
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
