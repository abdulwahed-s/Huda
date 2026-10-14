package com.aw.huda.countdown

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.aw.huda.widget.WidgetBroadcastDispatcher

/** The countdown's alarms, and its dismissal: a swiped-away countdown comes straight back. */
class PrayerCountdownReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PrayerCountdownRx"
        private const val DISMISSED_REQUEST = 0xC03
        const val ACTION_TRANSITION = "com.aw.huda.countdown.TRANSITION"
        const val ACTION_TICK = "com.aw.huda.countdown.TICK"
        const val ACTION_DISMISSED = "com.aw.huda.countdown.DISMISSED"

        internal fun dismissedIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            DISMISSED_REQUEST,
            PrayerCountdownNotification.receiverIntent(context, ACTION_DISMISSED),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != ACTION_TRANSITION && action != ACTION_TICK && action != ACTION_DISMISSED) return
        Log.d(TAG, "onReceive: $action")
        WidgetBroadcastDispatcher.launch(
            context, goAsync(), TAG, action,
            PrayerCountdownController::scheduleRetry,
        ) { appContext -> PrayerCountdownController.refresh(appContext) }
    }
}
