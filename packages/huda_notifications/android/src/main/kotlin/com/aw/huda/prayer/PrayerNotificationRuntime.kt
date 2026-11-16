package com.aw.huda.prayer

import android.content.*
import android.os.*
import android.util.AtomicFile
import androidx.work.*
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.*
import java.util.concurrent.atomic.AtomicLong

/** Application-scoped; no Activity, engine or messenger is retained here. */
internal class PrayerNotificationRuntime private constructor(val context: Context) {
    val store = PrayerStore(PrayerAlarmDatabase.open(context))
    val maintenance = Executors.newSingleThreadExecutor { Thread(it, "prayer-maintenance") }
    val delivery = Executors.newSingleThreadExecutor { Thread(it, "prayer-delivery") }
    val audioIo = Executors.newSingleThreadExecutor { Thread(it, "prayer-audio-io") }
    val main = Handler(Looper.getMainLooper())
    val alarms = PrayerAlarmScheduler(context)
    val plans = PrayerPlanCoordinator(this)
    val audio = PrayerAudioStore(this)
    val assetLock = Any()
    private val advanceLock = Any()
    val notifications = PrayerNotifications(this)
    val playback = AdhanSessionCoordinator(this)
    val reminders = ReminderScheduler(this)
    val sahur = SahurScheduler(this)
    fun effective(prayer: String) = if (prayer == "sahur") sahur.policy() else PrayerPolicy.effective(livePolicy, prayer)
    private val subscribers = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()
    private val runtimeInstance = UUID.randomUUID().toString()
    private val sequence = AtomicLong(0)
    @Volatile private var initialized = false
    @Volatile var liveSession: SessionData? = null
    @Volatile var navigationToken: String? = null
    /** The payload of a tapped reminder, until Flutter takes it. */
    @Volatile var reminderTap: String? = null
    @Volatile var livePolicy = PrayerPolicy.initial()
    @Volatile private var epochValue = ""
    internal var wallClock: () -> Long = System::currentTimeMillis
    fun nowMillis() = wallClock()

    @Synchronized fun initialize() {
        if (initialized) return
        store.transaction {
            if (store.text("epoch").isEmpty()) store.putText("epoch", UUID.randomUUID().toString())
            if (store.read("policy", PolicyData::class.java) == null) store.write("policy", PrayerPolicy.initial())
            if (store.text("backend").isEmpty()) store.putText("backend", "legacy")
            if (store.text("backend") in setOf("rollingBack", "legacyRollback")) {
                store.putText("backend", "legacy"); store.dao.deleteState("rollback")
            }
        }
        livePolicy = PrayerPolicy.validate(policy())
        epochValue = store.text("epoch")
        sahur.load()
        recoverInterruptedSession()
        notifications.createChannels()
        initialized = true
    }
    fun epoch() = epochValue.ifEmpty { store.text("epoch") }
    fun backend() = store.text("backend", "legacy")
    fun policy() = store.read("policy", PolicyData::class.java) ?: PrayerPolicy.initial()
    fun digest(text: String) = MessageDigest.getInstance("SHA-256").digest(text.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
    fun subscribe(listener: (Map<String, Any?>) -> Unit) { subscribers.add(listener) }
    fun unsubscribe(listener: (Map<String, Any?>) -> Unit) { subscribers.remove(listener) }
    fun emit(type: String, data: Map<String, Any?> = emptyMap()) {
        val event = mapOf("type" to type, "runtimeInstance" to runtimeInstance,
            "sequence" to sequence.incrementAndGet()) + data
        main.post { subscribers.forEach { it(event) } }
    }
    fun snapshot(): RuntimeSnapshot {
        initialize()
        val pending = ownedFuture().map { it.receipt() }
        val prayers = pending.filter { PrayerRules.prayerId(it.event.id) }
        val active = plans.active()?.copy(registrations = prayers,
            coverageUtcMillis = prayers.maxOfOrNull { it.event.utcMillis })
        return RuntimeSnapshot(1, runtimeInstance, sequence.get(), epoch(), backend(), policy(),
            PrayerCapabilities.read(context), pending, store.dao.latest(10).map { it.data() }, active,
            liveSession, store.text("repair").ifBlank { null }, navigationToken, plans.preparing())
    }
    fun ownedRows() = store.dao.events().filter { row ->
        row.epoch == epoch() && (row.purpose != "prayer" || store.dao.owner(row.id)?.let {
            it.backend == "native" && it.generation == row.generation
        } == true)
    }
    fun ownedFuture() = ownedRows().filter {
        it.utcMillis > nowMillis() && it.registration == "registered" &&
            (it.purpose != "prayer" || store.dao.claim(it.id) == null)
    }
    /** Alarms other than prayers and their reminders: plugin and app reminders plus external reservations. */
    private fun committedAlarms(): Long {
        val q = store.read("quota", QuotaData::class.java) ?: QuotaData(100, 30, 8, 4, 1)
        // App-owned reminders share the alarm budget with plugin reminders.
        val standard = maxOf(q.standardCount, store.dao.states("standard:%").size.toLong()) +
            store.dao.states("${ReminderScheduler.KEY}%").size
        return standard + q.sahurReservation + q.widgetReservation + q.auxiliaryReservation + q.migrationReservation
    }
    fun quota(): Long {
        // Reminders before prayers reserve their 14-day window only while one is on.
        val advance = if (PrayerPolicy.advanceActive(policy())) PrayerRules.ADVANCE_RESERVATION else 0L
        return (PrayerRules.TOTAL_QUOTA - committedAlarms() - advance).coerceIn(0, PrayerRules.MAX_PRAYERS.toLong())
    }
    fun updateQuota(quota: QuotaData): Long = store.transaction {
        require(listOf(quota.standardCount, quota.sahurReservation, quota.widgetReservation,
            quota.auxiliaryReservation, quota.migrationReservation).all { it in 0..450 }) { "invalidQuota" }
        // Conservative external reservations cannot be removed by an unaware caller.
        store.write("quota", quota.copy(sahurReservation = maxOf(30, quota.sahurReservation),
            widgetReservation = maxOf(8, quota.widgetReservation), auxiliaryReservation = maxOf(4, quota.auxiliaryReservation),
            migrationReservation = maxOf(1, quota.migrationReservation)))
        quota()
    }
    fun reservePluginAlarm(id: Long, prayer: Boolean = PrayerRules.legacyPrayerId(id)) = store.transaction {
        if (prayer) {
            store.putText("legacyAlarm:$id", "reserved")
        } else {
            val key = "standard:$id"
            if (store.dao.state(key) == null) {
                val q = store.read("quota", QuotaData::class.java) ?: QuotaData(0, 30, 8, 4, 1)
                val nativeCount = store.dao.events().filter { it.purpose != "sahur" && it.utcMillis > nowMillis() && it.registration == "registered" }
                    .distinctBy { "${it.purpose}:${it.id}" }.size
                val legacyCount = store.dao.states("legacyAlarm:%").size
                require(store.dao.states("standard:%").size + store.dao.states("${ReminderScheduler.KEY}%").size +
                    nativeCount + legacyCount +
                    q.sahurReservation + q.widgetReservation + q.auxiliaryReservation + q.migrationReservation < 450) { "quotaExceeded" }
                store.putText(key, "reserved")
            }
        }
    }
    fun releasePluginAlarm(id: Long) {
        store.dao.deleteState("standard:$id")
        store.dao.deleteState("legacyAlarm:$id")
    }

    fun setPolicy(request: PolicyData, expected: Long): PolicyData {
        val normalized = PrayerPolicy.validate(request)
        val result = synchronized(assetLock) { store.transaction {
            val current = policy()
            require(current.revision == expected) { "stalePolicy" }
            PrayerRules.prayers.forEach {
                val resolved = PrayerPolicy.effective(normalized, it)
                require(audio.selectionReady(resolved.reciterId, resolved.version)) { "assetUnavailable" }
            }
            normalized.copy(revision = current.revision + 1).also { store.write("policy", it) }
        } }
        livePolicy = result
        notifications.createChannels()
        maintenance.execute { runCatching { syncAdvance() } }
        main.post { playback.policyChanged(result) }
        emit("policyChanged", mapOf("policyRevision" to result.revision))
        return result
    }

    /** Ownership and the unique canonical claim are committed together. Never replay uncertain attempts. */
    fun claim(row: AlarmRow, backend: String, outcome: String, reason: String, sessionId: String?): Boolean = store.transaction {
        if (row.purpose != "prayer") {
            // A reminder before a prayer is claimed by its occurrence, so a
            // re-created row (new token) can never show it twice.
            val key = when (row.purpose) {
                "advance" -> "auxclaim:advance:${row.id}"
                "sahur" -> "auxclaim:sahur:${row.localDate}"
                else -> "auxclaim:${row.token}"
            }
            if (store.dao.state(key) != null) return@transaction false
            store.putText(key, nowMillis().toString())
            diagnostic(row.id, outcome, reason, mapOf("purpose" to row.purpose, "precision" to row.precision))
            return@transaction true
        }
        val owner = store.dao.owner(row.id)
        if ((owner?.backend ?: "legacy") != backend ||
            (backend == "native" && owner?.generation != row.generation) || store.dao.claim(row.id) != null) return@transaction false
        val inserted = store.dao.insertClaim(ClaimRow(row.id, store.nextCursor(), row.utcMillis, nowMillis(),
            row.locationRevision, row.scheduleRevision, backend, outcome, reason, sessionId)) != -1L
        if (inserted) diagnostic(row.id, outcome, reason, mapOf("session" to sessionId, "backend" to backend,
            "scheduledUtcMillis" to row.utcMillis, "precision" to row.precision))
        inserted
    }
    fun outcome(id: Long, outcome: String, reason: String) {
        store.transaction {
            store.dao.claim(id)?.let { store.dao.updateClaim(it.copy(cursor = store.nextCursor(), outcome = outcome, reason = reason)) }
            diagnostic(id, outcome, reason)
        }
        emit("deliveryRecorded", mapOf("occurrenceId" to id, "outcome" to outcome, "reason" to reason))
    }
    /** Bounded local trace, separate from the 400-day canonical suppression ledger. */
    fun diagnostic(id: Long, outcome: String, reason: String, details: Map<String, Any?> = emptyMap()) = store.transaction {
        val ordinal = store.text("diagnosticOrdinal", "0").toLong() + 1
        store.putText("diagnosticOrdinal", ordinal.toString())
        store.write("diagnostic:$ordinal", mapOf("id" to id, "utcMillis" to nowMillis(), "outcome" to outcome,
            "reason" to reason, "policyRevision" to livePolicy.revision) + details)
        val records = store.dao.states("diagnostic:%").sortedByDescending { it.key.substringAfter(':').toLong() }
        records.forEachIndexed { index, record ->
            val timestamp = org.json.JSONObject(record.value).optLong("utcMillis")
            if (index >= 200 || timestamp < nowMillis() - 7 * 86400_000L) store.dao.deleteState(record.key)
        }
    }
    fun saveSession(session: SessionData?) {
        liveSession = session
        if (session == null) store.dao.deleteState("session") else store.write("session", session)
    }
    fun recoverInterruptedSession() {
        if (liveSession != null) return
        store.read("session", SessionData::class.java)?.let { old ->
            if (old.automatic) outcome(old.occurrenceId, "uncertain", "processInterrupted")
            store.dao.deleteState("session")
        }
    }
    fun writeCompanion(name: String, contents: String) {
        require(context.getSystemService(UserManager::class.java).isUserUnlocked) { "userLocked" }
        val directory = File(context.noBackupFilesDir, "PrayerConfiguration").apply { mkdirs() }
        val file = AtomicFile(File(directory, name))
        val stream = file.startWrite()
        try { stream.write(contents.toByteArray(Charsets.UTF_8)); file.finishWrite(stream) }
        catch (error: Exception) { file.failWrite(stream); throw error }
    }
    fun readCompanion(name: String): String? {
        if (!context.getSystemService(UserManager::class.java).isUserUnlocked) return null
        return try { AtomicFile(File(context.noBackupFilesDir, "PrayerConfiguration/$name"))
            .openRead().bufferedReader().use { it.readText() } } catch (_: Exception) { null }
    }
    fun enqueueRenewal() {
        if (!context.getSystemService(UserManager::class.java).isUserUnlocked) return
        try {
            WorkManager.getInstance(context).enqueueUniquePeriodicWork("huda-native-prayer-renewal",
                ExistingPeriodicWorkPolicy.KEEP,
                PeriodicWorkRequestBuilder<PrayerCoverageRenewalWorker>(12, TimeUnit.HOURS).build())
        } catch (_: IllegalStateException) { store.putText("repair", "renewalUnavailable"); emit("snapshotChanged") }
    }
    fun enqueueAfterDelivery() {
        if (!context.getSystemService(UserManager::class.java).isUserUnlocked) return
        try {
            WorkManager.getInstance(context).enqueueUniqueWork("huda-native-prayer-after-delivery",
                ExistingWorkPolicy.KEEP, OneTimeWorkRequestBuilder<PrayerCoverageRenewalWorker>()
                    .setInputData(workDataOf("maxAppend" to 5, "repair" to false)).build())
        } catch (_: IllegalStateException) { store.putText("repair", "renewalUnavailable"); emit("snapshotChanged") }
    }
    fun requestRepair() {
        maintenance.execute {
            try { initialize(); plans.repair(preserveDispatchWindow = true); enqueueRenewal() }
            catch (_: Exception) { emit("snapshotChanged", mapOf("reason" to "storageUnavailable")) }
        }
    }
    /**
     * Derives the reminders before prayers from the owned prayer rows: one per
     * future prayer whose reminder falls in the next 14 days, at the prayer
     * minus its minutes. Cancels every other reminder row. Idempotent; runs on
     * maintenance after any change to the prayer rows or the policy.
     */
    fun syncAdvance(): Unit = synchronized(advanceLock) {
        val now = nowMillis()
        val policy = policy()
        val locale = policy.values["localeCode"] as? String ?: "en"
        val parents = ownedFuture().filter { it.purpose == "prayer" }
        val current = store.dao.events().filter { it.purpose == "advance" }.associateBy { it.key }
        // Reminders only use room prayers leave, so they never displace a prayer.
        val room = (PrayerRules.TOTAL_QUOTA - committedAlarms() - parents.size)
            .coerceIn(0, PrayerRules.ADVANCE_RESERVATION).toInt()
        val desired = parents.mapNotNull { parent ->
            val resolved = PrayerPolicy.effective(policy, parent.prayer)
            if (resolved.mode == "off" || resolved.advanceMinutes == 0) return@mapNotNull null
            val id = PrayerRules.advanceId(parent.id)
            val at = parent.utcMillis - resolved.advanceMinutes * 60_000L
            // Claimed by occurrence: a reminder already shown is never re-created.
            if (at > now + PrayerRules.ADVANCE_WINDOW_MS || store.dao.state("auxclaim:advance:$id") != null) return@mapNotNull null
            val (title, body) = NativePrayerStrings.advance(locale, parent.prayer, resolved.advanceMinutes)
            val installed = current["advance:$id"]?.takeIf {
                it.registration == "registered" && it.epoch == parent.epoch && it.generation == parent.generation &&
                    it.utcMillis == at && it.title == title && it.body == body
            }
            // A registered reminder stays even when due; a new one is never made inside the protected window.
            installed ?: if (at - now <= PrayerRules.PROTECTED_WINDOW_MS) null else parent.copy(key = "advance:$id",
                id = id, utcMillis = at, title = title, body = body, token = UUID.randomUUID().toString(),
                precision = "unknown", registration = "staged", purpose = "advance")
        }.sortedBy { it.utcMillis }.take(room)
        val kept = desired.map { it.token }.toSet()
        current.values.filter { it.token !in kept }.forEach { alarms.cancel(it); store.dao.deleteEvent(it.key) }
        for (row in desired) {
            if (row.registration == "registered") continue
            store.dao.putEvent(row) // Stage before touching AlarmManager.
            try { store.dao.putEvent(alarms.register(row)) }
            catch (_: Exception) { store.dao.putEvent(row.copy(registration = "uncertain")) }
        }
    }
    fun reset(clearHistory: Boolean) {
        val previousBackend = backend()
        val stopped = CountDownLatch(1)
        main.post { try { playback.stopAll("reset", true) } finally { stopped.countDown() } }
        require(stopped.await(1, TimeUnit.SECONDS)) { "stopPending" }
        store.dao.events().forEach { alarms.cancel(it); store.dao.putOwner(OwnerRow(it.id, "disabled", it.generation)); store.dao.deleteEvent(it.key) }
        store.transaction {
            store.dao.deleteState("activePlan")
            store.dao.deleteState("preparingOperation")
            listOf("plan:%", "planCreated:%", "request:%", "auxclaim:%", "followup:%").forEach { prefix ->
                store.dao.states(prefix).forEach { store.dao.deleteState(it.key) }
            }
            if (clearHistory) {
                store.dao.clearClaims()
                store.dao.states("diagnostic:%").forEach { store.dao.deleteState(it.key) }
                epochValue = UUID.randomUUID().toString(); store.putText("epoch", epochValue)
            }
            // An app-wide reset must not opt a legacy installation into rollout.
            store.putText("backend", if (previousBackend == "legacy") "legacy" else "native")
        }
        // Callers reset the whole app, so app-owned reminders go too.
        reminders.clear()
        sahur.apply(SahurSettings())
        notifications.clearPrayerSummaries()
        emit("planChanged")
    }

    companion object {
        @Volatile private var instance: PrayerNotificationRuntime? = null
        fun get(context: Context): PrayerNotificationRuntime = instance ?: synchronized(this) {
            instance ?: PrayerNotificationRuntime(context.applicationContext).also { instance = it }
        }
        internal fun clearForTesting() {
            instance?.let { it.maintenance.shutdownNow(); it.delivery.shutdownNow(); it.audioIo.shutdownNow(); it.store.database.close() }
            instance = null
        }
    }
}
