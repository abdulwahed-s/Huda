package com.aw.huda.prayer

import android.app.Service
import android.content.*
import android.os.*
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

internal class AdhanSessionCoordinator(private val runtime: PrayerNotificationRuntime) {
    private data class Dispatch(val row: AlarmRow, val session: SessionData)
    private val dispatches = ConcurrentHashMap<String, Dispatch>()
    private var controller: AdhanAudioController? = null
    private var currentRow: AlarmRow? = null
    private var service: AdhanPlaybackService? = null
    private var dismissing = false

    fun automatic(row: AlarmRow, sessionId: String) {
        val policy = runtime.effective(row.prayer)
        val session = SessionData(sessionId, row.id, row.prayer, "dispatching", policy.mode,
            policy.reciterId, policy.gain, true, row.utcMillis, 0, null, null)
        dispatches[sessionId] = Dispatch(row, session)
        runtime.main.post {
            try {
                val intent = Intent(runtime.context, AdhanPlaybackService::class.java)
                    .putExtra("session", sessionId).putExtra("title", row.title).putExtra("body", row.body)
                if (Build.VERSION.SDK_INT >= 26) runtime.context.startForegroundService(intent)
                else runtime.context.startService(intent)
            } catch (_: Exception) {
                dispatches.remove(sessionId)
                runtime.delivery.execute { runtime.outcome(row.id, "failed", "foregroundStartDenied") }
                runtime.notifications.summary(row, "foregroundStartDenied")
            }
        }
    }
    fun dispatchSession(id: String) = dispatches[id]?.session
    fun rejectDispatch(id: String, reason: String) {
        dispatches.remove(id)?.let { dispatch ->
            runtime.delivery.execute { runtime.outcome(dispatch.row.id, "suppressed", reason) }
            runtime.notifications.summary(dispatch.row, reason)
        }
    }
    fun attachService(id: String, playbackService: AdhanPlaybackService) {
        val dispatch = dispatches.remove(id) ?: return playbackService.finishSession()
        val latest = runtime.effective(dispatch.row.prayer)
        if (latest.mode in listOf("off", "silent")) {
            runtime.delivery.execute { runtime.outcome(dispatch.row.id, "suppressed", "policyDisabled") }
            if (latest.mode == "silent") runtime.notifications.summary(dispatch.row)
            if (runtime.liveSession?.automatic != true) playbackService.finishSession()
            return
        }
        val current = runtime.liveSession
        if (current != null && current.automatic &&
            (current.scheduledUtcMillis > dispatch.row.utcMillis ||
                current.scheduledUtcMillis == dispatch.row.utcMillis && current.occurrenceId >= dispatch.row.id)) {
            runtime.delivery.execute { runtime.outcome(dispatch.row.id, "skipped", "overlapSuppressed") }
            runtime.notifications.summary(dispatch.row)
            // Keep the already playing service and its foreground notification.
            currentRow?.let { playbackService.promote(current, it.title, it.body) }
            return
        }
        begin(dispatch.row, dispatch.session.copy(mode = latest.mode, reciterId = latest.reciterId, gain = latest.gain), playbackService, latest)
    }
    fun preview(prayer: String): SessionData {
        require(prayer in PrayerRules.prayers) { "invalidPrayer" }
        require(runtime.liveSession?.automatic != true) { "automaticSessionActive" }
        val previewPolicy = runtime.livePolicy.copy(values = runtime.livePolicy.values + ("enabled" to true))
        val chosen = PrayerPolicy.effective(previewPolicy, prayer)
        val resolved = if (chosen.mode in listOf("off", "silent")) chosen.copy(mode = "short") else chosen
        val id = UUID.randomUUID().toString()
        val now = runtime.nowMillis()
        val session = SessionData(id, 410_000_002, prayer, "preparing", resolved.mode, resolved.reciterId,
            resolved.gain, false, now, 0, null, null)
        val title = NativePrayerStrings.labels(runtime.livePolicy.values["localeCode"] as? String ?: "en").preview
        val row = AlarmRow("preview:$id", session.occurrenceId, prayer, now, "UTC", "", title, "", "", 0, 0, 0, "", id, purpose = "preview")
        begin(row, session, null, resolved)
        return session
    }
    private fun begin(row: AlarmRow, session: SessionData, playbackService: AdhanPlaybackService?, override: EffectivePolicy? = null) {
        // An incoming prayer supersedes preview or an older occurrence, without stopping the reused service.
        val previousService = service
        service = null
        stopCurrent("superseded", false)
        if (previousService != null && previousService !== playbackService) previousService.finishSession()
        service = playbackService
        currentRow = row
        dismissing = false
        runtime.liveSession = session
        val policy = override ?: runtime.effective(row.prayer)
        runtime.delivery.execute { runtime.store.write("session", session) }
        controller = AdhanAudioController(runtime, session, policy, { elapsed, limit, asset, fallback ->
            if (runtime.liveSession?.id == session.id) {
                val started = runtime.liveSession!!.copy(phase = "playing", reciterId = asset.reciterId, startedElapsedMillis = elapsed, limitMillis = limit)
                runtime.liveSession = started
                runtime.delivery.execute {
                    runtime.store.write("session", started)
                    if (session.automatic) runtime.outcome(row.id, "started", if (fallback) "bundledFallbackStarted" else "playerStarted")
                    runtime.diagnostic(row.id, "started", "playerStarted", mapOf("session" to session.id,
                        "reciter" to asset.reciterId, "version" to asset.version, "variant" to asset.variant,
                        "fallback" to fallback, "gain" to policy.gain, "limitMillis" to limit,
                        "elapsedMillis" to elapsed, "precision" to row.precision))
                }
                runtime.emit("playbackStarted", mapOf("sessionId" to session.id))
            }
        }, { reason -> ended(session, row, reason) })
        controller!!.start()
    }
    fun stop(id: String, reason: String = "stopped", dismiss: Boolean = false) {
        if (runtime.liveSession?.id != id) return
        dismissing = dismiss
        controller?.finish(reason)
    }
    fun stopCurrent(reason: String, dismiss: Boolean) { runtime.liveSession?.let { stop(it.id, reason, dismiss) } }
    fun stopAll(reason: String, dismiss: Boolean) { dispatches.clear(); stopCurrent(reason, dismiss) }
    fun setGain(id: String, gain: Double) {
        require(gain.isFinite() && gain in 0.0..1.0) { "invalidGain" }
        if (runtime.liveSession?.id != id) return
        controller?.setGain(gain)
        runtime.liveSession = runtime.liveSession?.copy(gain = gain)
    }
    fun policyChanged(policy: PolicyData) {
        val session = runtime.liveSession ?: return
        val effective = if (session.prayer == "sahur") runtime.sahur.policy() else PrayerPolicy.effective(policy, session.prayer)
        if (session.automatic && effective.mode in listOf("off", "silent")) { stop(session.id, "policyDisabled"); return }
        setGain(session.id, effective.gain)
        controller?.shortenCutoff(effective.cutoffSeconds)
    }
    private fun ended(session: SessionData, row: AlarmRow, reason: String) {
        if (runtime.liveSession?.id != session.id) return
        runtime.liveSession = null
        controller = null; currentRow = null
        val oldService = service; service = null
        oldService?.finishSession()
        if (session.automatic) {
            if (dismissing) runtime.notifications.dismiss(row.id) else runtime.notifications.summary(row, reason)
        }
        runtime.delivery.execute {
            // The serial control executor orders this cleanup before a newer session's persistence.
            runtime.store.dao.deleteState("session")
            if (session.automatic) runtime.outcome(row.id, when (reason) {
                "completed", "cutoff" -> "completed"
                "focusDenied", "playerError", "preparationTimeout", "watchdogTimeout" -> "failed"
                else -> "stopped"
            }, reason)
        }
        runtime.emit("playbackEnded", mapOf("sessionId" to session.id, "reason" to reason))
    }
    fun serviceDestroyed(playbackService: AdhanPlaybackService) {
        if (service === playbackService) stopCurrent("serviceDestroyed", false)
    }
}
