package com.aw.huda.prayer

import android.content.*
import android.os.UserManager

class PrayerSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in ACTIONS) return
        val runtime = PrayerNotificationRuntime.get(context)
        // Bounded handoff only. A system broadcast never starts media playback.
        val pending = goAsync()
        runtime.maintenance.execute {
            try {
                runtime.initialize()
                runtime.sahur.migrate()
                runtime.plans.repair(android.os.SystemClock.elapsedRealtime() + 7500)
                runtime.reminders.repair()
                // Re-arm stored plugin alarms after system changes.
                if (intent.action in RESTART_ACTIONS) LegacyPluginAlarms.repair(runtime.context)
                if (context.getSystemService(UserManager::class.java).isUserUnlocked) runtime.enqueueRenewal()
            } finally { pending.finish() }
        }
    }
    companion object {
        private val ACTIONS = setOf(Intent.ACTION_LOCKED_BOOT_COMPLETED, Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_USER_UNLOCKED, Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_LOCALE_CHANGED,
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED")
        private val RESTART_ACTIONS = setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_USER_UNLOCKED,
            Intent.ACTION_MY_PACKAGE_REPLACED)
    }
}
