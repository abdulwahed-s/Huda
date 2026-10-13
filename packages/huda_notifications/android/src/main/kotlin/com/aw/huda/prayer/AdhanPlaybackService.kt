package com.aw.huda.prayer

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.*

class AdhanPlaybackService : Service() {
    private val runtime get() = PrayerNotificationRuntime.get(this)
    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra("session")
        val session = id?.let { runtime.playback.dispatchSession(it) }
        if (session == null) {
            if (runtime.liveSession?.automatic != true) stopSelf(startId)
            return START_NOT_STICKY
        }
        try {
            // No database, file, hash, focus or plan work precedes foreground promotion.
            promote(session, intent.getStringExtra("title").orEmpty(), intent.getStringExtra("body").orEmpty())
            runtime.playback.attachService(id, this)
        } catch (_: Exception) {
            runtime.playback.rejectDispatch(id, "foregroundPromotionDenied")
            runtime.delivery.execute { runtime.outcome(session.occurrenceId, "failed", "foregroundPromotionDenied") }
            finishSession()
        }
        return START_NOT_STICKY
    }
    internal fun promote(session: SessionData, title: String, body: String) {
        val notification = runtime.notifications.foreground(session, title, body)
        if (Build.VERSION.SDK_INT >= 29) startForeground(PrayerNotifications.FOREGROUND_ID, notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        else startForeground(PrayerNotifications.FOREGROUND_ID, notification)
    }
    internal fun finishSession() { stopForeground(STOP_FOREGROUND_REMOVE); stopSelf() }
    override fun onDestroy() { runtime.playback.serviceDestroyed(this); super.onDestroy() }
}
