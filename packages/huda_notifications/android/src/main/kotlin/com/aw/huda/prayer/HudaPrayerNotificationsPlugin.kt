package com.aw.huda.prayer

import android.Manifest
import android.app.*
import android.content.*
import android.net.Uri
import android.os.*
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.*
import io.flutter.plugin.common.*
import java.time.*
import java.util.UUID
import java.util.concurrent.Executor

class HudaPrayerNotificationsPlugin : FlutterPlugin, ActivityAware, PrayerHostApi, Application.ActivityLifecycleCallbacks {
    private lateinit var runtime: PrayerNotificationRuntime
    private var activity: Activity? = null
    private var messenger: BinaryMessenger? = null
    private var eventChannel: EventChannel? = null
    private var sahurChannel: MethodChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val intentListener = PluginRegistry.NewIntentListener { intent -> acceptNavigation(intent); false }
    private val listener: (Map<String, Any?>) -> Unit = { sink?.success(it) }
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        runtime = PrayerNotificationRuntime.get(binding.applicationContext)
        messenger = binding.binaryMessenger
        PrayerHostApi.setUp(binding.binaryMessenger, this)
        sahurChannel = MethodChannel(binding.binaryMessenger, "com.aw.huda/sahur_alarm").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "configure") { result.notImplemented(); return@setMethodCallHandler }
                val args = call.arguments as? Map<*, *>
                runtime.maintenance.execute {
                    try {
                        runtime.initialize()
                        require(args?.get("schemaVersion") == 1) { "invalidSahur" }
                        val value = SahurSettings(args["enabled"] == true, (args["type"] as Number).toInt(),
                            (args["hour"] as Number).toInt(), (args["minute"] as Number).toInt(),
                            (args["minutesBeforeFajr"] as Number).toInt(), args["locale"] as String,
                            args["title"] as String, args["body"] as String, args["stop"] as String)
                        val accepted = runtime.sahur.apply(value)
                        runtime.main.post { result.success(mapOf("accepted" to accepted, "supportsAlarms" to true)) }
                    } catch (error: Exception) {
                        runtime.main.post { result.error("sahurUnavailable", error.message, null) }
                    }
                }
            }
        }
        eventChannel = EventChannel(binding.binaryMessenger, "com.aw.huda/prayer_notifications/events").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    sink = events; runtime.subscribe(listener); runtime.emit("snapshotChanged")
                }
                override fun onCancel(arguments: Any?) { runtime.unsubscribe(listener); sink = null }
            })
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        runtime.main.post { stopFlipProbe(emit = false) }
        detach()
        runtime.unsubscribe(listener); sink = null
        eventChannel?.setStreamHandler(null); eventChannel = null
        sahurChannel?.setMethodCallHandler(null); sahurChannel = null
        messenger?.let { PrayerHostApi.setUp(it, null) }; messenger = null
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(this)
        acceptNavigation(binding.activity.intent)
        binding.addOnNewIntentListener(intentListener)
    }
    private fun acceptNavigation(intent: Intent?) {
        intent?.getStringExtra("hudaPrayerNavigation")?.let {
            runtime.navigationToken = it; runtime.emit("snapshotChanged", mapOf("navigationToken" to it))
        }
        // Plugin notification taps carry the launch action and `payload` extra.
        val tapExtra = if (intent?.action == LEGACY_TAP_ACTION) "payload" else ReminderScheduler.TAP_EXTRA
        intent?.getStringExtra(tapExtra)?.let {
            // Taken once: the same launch intent is offered again after a configuration change.
            intent.removeExtra(tapExtra)
            runtime.reminderTap = it; runtime.emit("reminderTapped")
        }
    }
    override fun onDetachedFromActivityForConfigChanges() = detach()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromActivity() = detach()
    private fun detach() {
        activityBinding?.removeOnNewIntentListener(intentListener)
        activityBinding = null
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        activity = null
        runtime.liveSession?.takeIf { !it.automatic }?.let { runtime.main.post { runtime.playback.stop(it.id, "previewActivityDetached") } }
    }
    private fun <T> run(callback: (Result<T>) -> Unit, executor: Executor = runtime.delivery, action: () -> T) {
        executor.execute {
            val result = try { runtime.initialize(); Result.success(action()) } catch (error: Exception) {
                val code = error.message?.takeIf { it.matches(Regex("^[A-Za-z]+$")) } ?: "storageUnavailable"
                Result.failure(FlutterError(code, "Prayer operation could not be completed.", mapOf("recoverable" to (code != "unsupportedContract"))))
            }
            runtime.main.post { callback(result) }
        }
    }
    private fun <T> foreground(callback: (Result<T>) -> Unit, action: (Activity) -> T) {
        runtime.main.post {
            val result = try {
                val attached = activity?.takeIf { !it.isFinishing } ?: error("activityUnavailable")
                Result.success(action(attached))
            } catch (error: Exception) { Result.failure(FlutterError(error.message ?: "activityUnavailable", null, mapOf("recoverable" to true))) }
            callback(result)
        }
    }
    override fun initialize(contractVersion: Long, callback: (Result<RuntimeSnapshot>) -> Unit) = run(callback) {
        require(contractVersion == PrayerRules.CONTRACT) { "unsupportedContract" }
        runtime.snapshot().also { runtime.requestRepair() }
    }
    override fun getCapabilities(callback: (Result<CapabilityData>) -> Unit) = run(callback) { PrayerCapabilities.read(runtime.context) }
    override fun getSnapshot(callback: (Result<RuntimeSnapshot>) -> Unit) = run(callback) { runtime.snapshot() }
    override fun getPolicy(callback: (Result<PolicyData>) -> Unit) = run(callback) { runtime.policy() }
    override fun setPolicy(policy: PolicyData, expectedRevision: Long, callback: (Result<PolicyData>) -> Unit) = run(callback) { runtime.setPolicy(policy, expectedRevision) }
    override fun updateQuota(quota: QuotaData, callback: (Result<Long>) -> Unit) = run(callback) { runtime.updateQuota(quota) }
    override fun preparePlan(request: PlanRequest, callback: (Result<PlanReceipt>) -> Unit) = run(callback, runtime.maintenance) { runtime.plans.prepare(request) }
    override fun getPlanReceipt(operationId: String, callback: (Result<PlanReceipt?>) -> Unit) = run(callback) { runtime.plans.receipt(operationId) }
    override fun activatePlan(operationId: String, expectedGeneration: Long, callback: (Result<PlanReceipt>) -> Unit) = run(callback, runtime.maintenance) { runtime.plans.activate(operationId, expectedGeneration) }
    override fun finalizePlan(request: FinalizeRequest, callback: (Result<PlanReceipt>) -> Unit) = run(callback, runtime.maintenance) { runtime.plans.finalize(request) }
    override fun abortPlan(operationId: String, callback: (Result<PlanReceipt>) -> Unit) = run(callback, runtime.maintenance) { runtime.plans.abort(operationId) }
    override fun acknowledgeLegacyCleanup(operationId: String, ids: List<Long>, callback: (Result<PlanReceipt>) -> Unit) = run(callback, runtime.maintenance) { runtime.plans.acknowledgeCleanup(operationId, ids) }
    override fun getDeliveryHistory(afterCursor: Long, limit: Long, callback: (Result<HistoryPage>) -> Unit) = run(callback) {
        require(afterCursor >= 0 && limit in 1..1000) { "invalidHistoryCursor" }
        val history = runtime.store.dao.history(afterCursor, limit.toInt())
        HistoryPage(history.lastOrNull()?.cursor ?: afterCursor, history.map { it.data() })
    }
    override fun acknowledgeHistory(cursor: Long, callback: (Result<Unit>) -> Unit) = run(callback) {
        require(cursor >= 0 && cursor <= runtime.store.text("historyCursor", "0").toLong()) { "invalidHistoryCursor" }
        runtime.store.putText("historyAcknowledged", maxOf(cursor, runtime.store.text("historyAcknowledged", "0").toLong()).toString())
    }
    override fun getLegacyInventory(ids: List<Long>, callback: (Result<List<EventData>>) -> Unit) = run(callback) {
        LegacyPrayerDeliveryBridge.inventory(runtime.context, ids)
    }
    override fun suppressUnmappedLegacy(ids: List<Long>, callback: (Result<Unit>) -> Unit) = run(callback, runtime.maintenance) {
        val inventory = LegacyPrayerDeliveryBridge.inventory(runtime.context, ids)
        require(inventory.map { it.id }.toSet() == ids.toSet() && inventory.all {
            it.utcMillis > 0 && (it.utcMillis <= runtime.nowMillis() ||
                it.utcMillis - runtime.nowMillis() > PrayerRules.PROTECTED_WINDOW_MS)
        }) { "deadlineProtected" }
        runtime.store.transaction {
            runtime.store.putText("strictLegacyGate", "true")
            ids.forEach { runtime.store.putText("unmappedLegacy:$it", "suppressedUncertain") }
        }
    }
    override fun getLegacyNotifications(callback: (Result<List<EventData>>) -> Unit) = run(callback) {
        LegacyPluginAlarms.list(runtime.context)
    }
    override fun cancelLegacyNotifications(ids: List<Long>, callback: (Result<Unit>) -> Unit) = run(callback, runtime.maintenance) {
        LegacyPluginAlarms.cancel(runtime.context, ids)
    }
    override fun cancelOccurrences(ids: List<Long>, expectedGeneration: Long, callback: (Result<Unit>) -> Unit) = run(callback, runtime.maintenance) {
        require(expectedGeneration == runtime.plans.generation()) { "stalePlan" }
        runtime.ownedRows().filter { it.id in ids }.forEach {
            runtime.store.dao.putOwner(OwnerRow(it.id, "disabled", it.generation))
            runtime.alarms.cancel(it); runtime.store.dao.deleteEvent(it.key); runtime.notifications.dismiss(it.id)
        }
        runCatching { runtime.syncAdvance() }
        runCatching { runtime.sahur.sync() }
    }
    override fun resetPrayerBackend(clearHistory: Boolean, callback: (Result<Unit>) -> Unit) = run(callback, runtime.maintenance) { runtime.reset(clearHistory) }
    override fun getAudioStorage(callback: (Result<AudioStorageData>) -> Unit) = run(callback) { runtime.audio.storage() }
    override fun isAudioReady(reciterId: String, version: String, callback: (Result<Boolean>) -> Unit) = run(callback) {
        require(PrayerRules.idPattern.matches(reciterId) && PrayerRules.versionPattern.matches(version)) { "invalidAsset" }
        runtime.audio.selectionReady(reciterId, version)
    }
    override fun registerVerifiedAudio(pair: List<AudioAssetData>, callback: (Result<Unit>) -> Unit) = run(callback, runtime.audioIo) { runtime.audio.register(pair) }
    override fun removeUnreferencedAudio(callback: (Result<List<String>>) -> Unit) = run(callback, runtime.audioIo) { runtime.audio.removeUnreferenced() }
    override fun removeAudio(reciterId: String, version: String, callback: (Result<List<String>>) -> Unit) =
        run(callback, runtime.audioIo) { runtime.audio.removeUnreferenced(reciterId to version) }
    private var flipProbe: FlipToStopController? = null
    private val flipProbeTimeout = Runnable { stopFlipProbe(emit = true) }
    override fun startFlipProbe(callback: (Result<Boolean>) -> Unit) = run(callback) {
        runtime.main.post { stopFlipProbe(emit = false) }
        val probe = FlipToStopController(runtime.context, onState = { state ->
            runtime.emit("flipProbe", mapOf("state" to state.name.lowercase()))
        }) {
            runtime.notifications.tick()
            runtime.main.post { stopFlipProbe(emit = false) }
        }
        if (!probe.available) return@run false
        runtime.main.post {
            flipProbe = probe
            probe.start()
            runtime.emit("flipProbe", mapOf("state" to "waiting"))
            runtime.main.postDelayed(flipProbeTimeout, 60_000)
        }
        true
    }
    override fun stopFlipProbe(callback: (Result<Unit>) -> Unit) = run(callback) {
        runtime.main.post { stopFlipProbe(emit = false) }
    }
    private fun stopFlipProbe(emit: Boolean) {
        runtime.main.removeCallbacks(flipProbeTimeout)
        val probe = flipProbe ?: return
        flipProbe = null
        probe.close()
        if (emit) runtime.emit("flipProbe", mapOf("state" to "stopped"))
    }
    override fun startPreview(prayer: String, callback: (Result<SessionData>) -> Unit) = foreground(callback) { runtime.playback.preview(prayer) }
    override fun stopPreview(sessionId: String, callback: (Result<Unit>) -> Unit) = foreground(callback) { if (runtime.liveSession?.automatic == false) runtime.playback.stop(sessionId, "previewStopped") }
    override fun runDeliveryTest(prayer: String, delaySeconds: Long, callback: (Result<EventData>) -> Unit) = run(callback, runtime.maintenance) {
        require(activity != null) { "activityUnavailable" }
        require(prayer in PrayerRules.prayers && delaySeconds in 5..60) { "invalidTest" }
        val caps = PrayerCapabilities.read(runtime.context)
        val mode = PrayerPolicy.effective(runtime.livePolicy, prayer).mode
        require(mode != "off") { "prayerDisabled" }
        require(caps.notifications && if (mode == "silent") caps.silentChannel else caps.adhanChannel) { "notificationsBlocked" }
        require(caps.exactAlarms) { "exactAccessDenied" }
        val locale = runtime.livePolicy.values["localeCode"] as? String ?: "en"
        val labels = NativePrayerStrings.labels(locale)
        val row = AlarmRow("test:410000003", 410_000_003, prayer, runtime.nowMillis() + delaySeconds * 1000,
            ZoneId.systemDefault().id, LocalDate.now().toString(), "Huda · ${NativePrayerStrings.test(locale)}", labels.prayers,
            runtime.epoch(), 0, 0, 0, "", UUID.randomUUID().toString(), purpose = "test")
        runtime.store.dao.putEvent(row); runtime.store.dao.putEvent(runtime.alarms.register(row)); row.event()
    }
    override fun stopSession(sessionId: String, callback: (Result<Unit>) -> Unit) { runtime.main.post { runtime.playback.stop(sessionId); callback(Result.success(Unit)) } }
    override fun dismissSession(sessionId: String, callback: (Result<Unit>) -> Unit) { runtime.main.post { runtime.playback.stop(sessionId, "dismissed", true); callback(Result.success(Unit)) } }
    override fun setSessionGain(sessionId: String, gain: Double, callback: (Result<Unit>) -> Unit) = foreground(callback) { runtime.playback.setGain(sessionId, gain) }
    override fun openAlarmOverview(sessionId: String, callback: (Result<Unit>) -> Unit) = foreground(callback) {
        val session = runtime.liveSession?.takeIf { it.id == sessionId } ?: error("staleSession")
        it.startActivity(Intent(it, AdhanAlarmActivity::class.java).putExtra("session", session.id))
    }
    override fun openSettings(target: String, callback: (Result<CapabilityData>) -> Unit) = foreground(callback) { attached ->
        val intent = when (target) {
            "exact" -> if (Build.VERSION.SDK_INT >= 31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${attached.packageName}")) else error("settingsUnavailable")
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:${attached.packageName}")) else error("settingsUnavailable")
            "adhanChannel", "silentChannel" -> if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, attached.packageName).putExtra(Settings.EXTRA_CHANNEL_ID,
                    if (target == "adhanChannel") PrayerNotifications.ADHAN_CHANNEL else PrayerNotifications.SILENT_CHANNEL)
                else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${attached.packageName}"))
            else -> error("invalidSettingsTarget")
        }
        require(intent.resolveActivity(attached.packageManager) != null) { "settingsUnavailable" }
        attached.startActivity(intent); PrayerCapabilities.read(attached)
    }
    override fun requestNotificationPermission(callback: (Result<Unit>) -> Unit) = foreground(callback) {
        if (Build.VERSION.SDK_INT >= 33) ActivityCompat.requestPermissions(it, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4519)
    }
    override fun applyReminders(batch: ReminderBatch, callback: (Result<List<Long>>) -> Unit) =
        run(callback, runtime.maintenance) { runtime.reminders.apply(batch) }
    override fun getReminders(callback: (Result<List<ReminderData>>) -> Unit) =
        run(callback, runtime.maintenance) { runtime.reminders.list() }
    override fun takeReminderTap(callback: (Result<String?>) -> Unit) =
        run(callback) { runtime.reminderTap.also { runtime.reminderTap = null } }
    override fun onActivityStopped(activity: Activity) {
        if (activity === this.activity) runtime.liveSession?.takeIf { !it.automatic }?.let { runtime.playback.stop(it.id, "previewBackgrounded") }
    }
    override fun onActivityResumed(activity: Activity) { if (activity === this.activity) runtime.emit("capabilitiesChanged") }
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
    override fun onActivityStarted(activity: Activity) = Unit
    override fun onActivityPaused(activity: Activity) = Unit
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
    override fun onActivityDestroyed(activity: Activity) = Unit
    companion object { private const val LEGACY_TAP_ACTION = "SELECT_NOTIFICATION" }
}
