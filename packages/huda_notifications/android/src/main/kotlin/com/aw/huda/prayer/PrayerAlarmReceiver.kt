package com.aw.huda.prayer

import android.content.*
import java.util.UUID

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != PrayerAlarmScheduler.ACTION) return
        val pending = goAsync()
        PrayerNotificationRuntime.get(context).delivery.execute {
            try { deliver(context, intent) } finally { pending.finish() }
        }
    }

    companion object {
        /** Delivers one alarm on the calling thread (the delivery executor in production). */
        internal fun deliver(context: Context, intent: Intent) {
            val runtime = PrayerNotificationRuntime.get(context)
            try {
                runtime.initialize()
                val row = runtime.store.dao.eventByToken(intent.getStringExtra("token").orEmpty()) ?: return
                if (row.epoch != runtime.epoch() || row.epoch != intent.getStringExtra("epoch") ||
                    row.id != intent.getLongExtra("id", -1) || row.purpose != intent.getStringExtra("purpose") ||
                    row.registration != "registered") return
                val now = runtime.nowMillis()
                if (now < row.utcMillis) { runtime.store.dao.putEvent(runtime.alarms.register(row)); return }
                if (row.purpose == "followup") { runtime.store.dao.putEvent(row.copy(registration = "consumed")); return }
                val policy = PrayerPolicy.effective(runtime.policy(), row.prayer)
                if (row.purpose == "advance") {
                    // A reminder before a prayer: one plain notification, never audio,
                    // the alarm screen or a missed summary.
                    val late = now - row.utcMillis > PrayerRules.LATE_WINDOW_MS
                    val wanted = policy.mode != "off" && policy.advanceMinutes > 0
                    if (!runtime.claim(row, "native", if (late || !wanted) "skipped" else "displayed",
                        if (late) "lateCallback" else if (!wanted) "policyOff" else "received", null)) return
                    runtime.store.dao.putEvent(row.copy(registration = "consumed"))
                    if (!late && wanted) runtime.notifications.summary(row)
                    return
                }
                if (row.purpose == "prayer" && policy.mode == "off") {
                    if (runtime.claim(row, "native", "suppressed", "policyOff", null)) {
                        runtime.store.dao.putEvent(row.copy(registration = "consumed"))
                        runtime.emit("deliveryRecorded", mapOf("occurrenceId" to row.id))
                    }
                    return
                }
                val late = now - row.utcMillis > PrayerRules.LATE_WINDOW_MS
                val sessionId = UUID.randomUUID().toString()
                if (!runtime.claim(row, "native", if (late) "skippedLate" else "attempted",
                    if (late) "lateCallback" else "received", sessionId)) return
                runtime.store.dao.putEvent(row.copy(registration = "consumed"))
                if (late) {
                    if (runtime.policy().values["showMissedSummary"] == true) runtime.notifications.summary(row, "lateCallback")
                    return
                }
                val capabilities = PrayerCapabilities.read(context)
                if (!capabilities.notifications ||
                    (policy.mode == "silent" || row.precision != "exact") && !capabilities.silentChannel ||
                    policy.mode != "silent" && row.precision == "exact" && !capabilities.adhanChannel) {
                    runtime.outcome(row.id, "skipped", "notificationsBlocked"); return
                }
                val suppression = PrayerCapabilities.audioBlockReason(capabilities, policy)
                if (policy.mode == "silent" || row.precision != "exact" || suppression != null) {
                    runtime.notifications.summary(row, if (row.precision != "exact") "inexactNotificationOnly" else suppression)
                    if (policy.vibrate && capabilities.dndAllowsAlarms == true) runtime.notifications.vibrate()
                    runtime.outcome(row.id, if (policy.mode == "silent") "displayed" else "skipped",
                        if (row.precision != "exact") "inexactNotificationOnly" else suppression ?: "silent")
                } else runtime.playback.automatic(row, sessionId)
                runtime.emit("deliveryRecorded", mapOf("occurrenceId" to row.id))
                runtime.enqueueRenewal()
                runtime.enqueueAfterDelivery()
            } catch (_: Exception) {
                runtime.emit("snapshotChanged", mapOf("reason" to "storageUnavailable"))
            }
        }
    }
}
