package com.aw.huda.prayer

import android.content.Context
import android.util.AtomicFile
import com.aw.huda.prayer.core.PrayerOccurrenceIdentity
import com.google.gson.Gson
import org.json.JSONObject
import java.io.File
import java.time.*
import java.util.UUID

/** Mutations run on maintenance only. The Dart file lock is acquired before this queue. */
internal class PrayerPlanCoordinator(private val runtime: PrayerNotificationRuntime) {
    private val store get() = runtime.store
    private val dao get() = store.dao
    private val scheduler get() = runtime.alarms
    fun active() = store.read("activePlan", PlanReceipt::class.java)
    fun receipt(id: String) = store.read("plan:$id", PlanReceipt::class.java)
    fun generation() = active()?.generation ?: 0L
    fun preparing() = store.text("preparingOperation").takeIf { it.isNotBlank() }?.let { receipt(it) }

    fun prepare(request: PlanRequest): PlanReceipt {
        require(request.operationId.matches(Regex("^[a-zA-Z0-9-]{1,100}$"))) { "invalidPlan" }
        val existing = receipt(request.operationId)
        require(existing == null || existing.configurationDigest == request.configurationDigest &&
            existing.eventDigest == request.eventDigest && existing.locationRevision == request.locationRevision &&
            existing.scheduleRevision == request.scheduleRevision && existing.eligibilitySignature == request.eligibilitySignature) { "stalePlan" }
        if (existing?.state in listOf("activated", "finalized")) {
            require(active()?.operationId == request.operationId) { "stalePlan" }
            return active()!!
        }
        require(request.expectedGeneration == generation()) { "stalePlan" }
        val policy = runtime.policy()
        require(request.expectedPolicyRevision == policy.revision && request.eligibilitySignature == PrayerPolicy.eligibility(policy)) { "stalePolicy" }
        require(PrayerRules.digestPattern.matches(request.configurationDigest) &&
            PrayerRules.digestPattern.matches(request.eventDigest)) { "invalidPlan" }
        require(request.quota in 0..runtime.quota() && request.events.size <= request.quota) { "quotaExceeded" }
        require(request.locationRevision > 0 && request.scheduleRevision > 0) { "invalidPlan" }
        require(request.events.map { it.id }.toSet().size == request.events.size) { "invalidPlan" }
        val now = runtime.nowMillis()
        request.events.forEach { event ->
            require(event.prayer in PrayerRules.prayers && PrayerRules.prayerId(event.id)) { "invalidPlan" }
            val zone = ZoneId.of(event.timeZone)
            val local = Instant.ofEpochMilli(event.utcMillis).atZone(zone).toLocalDate()
            require(event.id == PrayerOccurrenceIdentity.idFor(local, event.prayer) && event.localDate == local.toString()) { "invalidPlan" }
            require(event.utcMillis > now && event.utcMillis <= now + PrayerRules.HORIZON_DAYS * 86400_000 &&
                event.title.isNotBlank() && event.title.length <= 512 && event.body.length <= 2048) { "invalidPlan" }
        }
        val pending = preparing()
        if (pending != null && pending.operationId != request.operationId) {
            val superseded = abort(pending.operationId)
            require(superseded.state == "aborted") { superseded.error ?: "migrationRecoveryRequired" }
        }
        // A durable, stripped request allows interrupted preparation to resume without CE data.
        val stripped = request.copy(events = request.events.map { it.copy(compatiblePayload = null) },
            legacyEvents = request.legacyEvents.map { it.copy(compatiblePayload = null) })
        val nextGeneration = existing?.generation ?: maxOf(generation(), dao.events().maxOfOrNull { it.generation } ?: 0) + 1
        var result = existing?.copy(quota = request.quota) ?: PlanReceipt(request.operationId, runtime.epoch(), nextGeneration,
            request.locationRevision, request.scheduleRevision, request.configurationDigest, request.eventDigest,
            request.eligibilitySignature, "preparing", request.quota, emptyList(), emptyList(), null, null)
        if (existing == null) store.transaction {
            store.putText("strictLegacyGate", "true")
            store.write("request:${request.operationId}", stripped)
            store.write("plan:${request.operationId}", result)
            store.putText("planCreated:${request.operationId}", now.toString())
            store.putText("preparingOperation", request.operationId)
            request.suppressedHistory.forEach { record ->
                require(PrayerRules.prayerId(record.id)) { "invalidHistory" }
                if (dao.claim(record.id) == null) dao.insertClaim(ClaimRow(record.id, store.nextCursor(),
                    record.utcMillis, record.receivedMillis, record.locationRevision, record.scheduleRevision,
                    "dart", record.outcome, record.reason))
            }
            request.legacyEvents.forEach { event ->
                require(PrayerRules.legacyPrayerId(event.id)) { "invalidLegacyEvent" }
                // Modern payloads preserve canonical identity; old aliases must be explicitly verified by Dart.
                val canonical = if (PrayerRules.prayerId(event.id)) event.id else
                    PrayerOccurrenceIdentity.idFor(LocalDate.parse(event.localDate), event.prayer)
                require(event.prayer in PrayerRules.prayers && event.utcMillis > now) { "invalidLegacyEvent" }
                dao.putAlias(AliasRow(event.id, canonical, event.utcMillis))
                if (dao.owner(canonical) == null) dao.putOwner(OwnerRow(canonical, "legacy", 0))
            }
            val desired = request.events.map { it.id }.toSet()
            val obsoleteLegacy = request.legacyEvents.filter { dao.alias(it.id)?.id !in desired }
            require(obsoleteLegacy.none { it.utcMillis - now <= PrayerRules.PROTECTED_WINDOW_MS }) { "deadlineProtected" }
            if (obsoleteLegacy.isNotEmpty()) {
                obsoleteLegacy.forEach { event -> dao.alias(event.id)?.let { alias ->
                    if (dao.owner(alias.id)?.backend == "legacy") dao.putOwner(OwnerRow(alias.id, "disabled", 0))
                } }
                result = result.copy(legacyCleanupIds = obsoleteLegacy.map { it.id })
                store.write("plan:${request.operationId}", result)
                store.putText("backend", "migrating")
            }
        }
        if (result.legacyCleanupIds.isNotEmpty()) return result
        // Preserve CE payloads separately; the DP copy has no raw signature or coordinates.
        if (existing == null) runtime.writeCompanion("payloads-${request.operationId}.json", store.gson.toJson(request.events.associate {
            it.id.toString() to it.compatiblePayload
        }))
        val existingRows = runtime.ownedFuture()
        val desiredIds = request.events.map { it.id }.toSet()
        val obsolete = existingRows.filter { it.purpose == "prayer" && it.id !in desiredIds }
        val changing = request.events.filter { event -> existingRows.firstOrNull { it.id == event.id }?.let {
            it.utcMillis != event.utcMillis || it.configurationDigest != request.configurationDigest
        } == true }
        if (obsolete.any { it.utcMillis - now <= PrayerRules.PROTECTED_WINDOW_MS } ||
            changing.any { event -> event.utcMillis - now <= PrayerRules.PROTECTED_WINDOW_MS ||
                existingRows.first { it.id == event.id }.utcMillis - now <= PrayerRules.PROTECTED_WINDOW_MS }) {
            return save(result.copy(state = "deferred", error = "deadlineProtected"))
        }
        // Free only genuinely obsolete slots. Rows remain journaled for abort/recovery.
        for (row in obsolete) {
            scheduler.cancel(row)
            dao.putEvent(row.copy(registration = "preparationCancelled"))
        }
        for (event in request.events) {
            val mutationNow = runtime.nowMillis()
            val retained = existingRows.firstOrNull { it.id == event.id && it.utcMillis == event.utcMillis &&
                it.configurationDigest == request.configurationDigest }
            if (retained != null) continue
            if (event.utcMillis - mutationNow <= PrayerRules.PROTECTED_WINDOW_MS) {
                return save(result.copy(state = "deferred", error = "deadlineProtected"))
            }
            if (dao.claim(event.id) != null || PrayerPolicy.effective(runtime.policy(), event.prayer).mode == "off") continue
            val key = "$nextGeneration:${event.id}"
            val owner = dao.owner(event.id)
            val previous = dao.event(key)
            if (previous?.registration == "registered" && owner?.backend == "native" && owner.generation == nextGeneration) continue
            var row = previous ?: AlarmRow(key, event.id, event.prayer, event.utcMillis, event.timeZone, event.localDate,
                event.title, event.body, runtime.epoch(), nextGeneration, request.locationRevision,
                request.scheduleRevision, request.configurationDigest, UUID.randomUUID().toString())
            dao.putEvent(row) // Stage before touching AlarmManager.
            try {
                row = scheduler.register(row)
                dao.putEvent(row)
            } catch (_: Exception) {
                dao.putEvent(row.copy(registration = "uncertain"))
                return save(result.copy(state = "failed", error = "registrationFailed"))
            }
            if (owner?.backend == "legacy") {
                val legacyId = request.legacyEvents.firstOrNull { legacy ->
                    dao.alias(legacy.id)?.id == event.id
                }?.id ?: event.id
                store.transaction {
                    dao.putOwner(OwnerRow(event.id, "native", nextGeneration))
                    store.putText("backend", "migrating")
                    result = result.copy(legacyCleanupIds = listOf(legacyId))
                    result = save(result)
                }
                // One overlap reservation. Dart durably cancels FLN before the next transfer.
                return result
            }
        }
        return save(result.copy(state = "prepared", error = null))
    }

    private fun save(receipt: PlanReceipt): PlanReceipt {
        val request = store.read("request:${receipt.operationId}", PlanRequest::class.java)
        val retained = runtime.ownedFuture().filter { row -> row.purpose == "prayer" &&
            row.configurationDigest == receipt.configurationDigest && request?.events?.any { it.id == row.id && it.utcMillis == row.utcMillis } == true }
        val staged = store.dao.events().filter { it.generation == receipt.generation && it.purpose == "prayer" }
        val rows = (retained + staged).associateBy { it.id }.values.toList()
        val result = receipt.copy(registrations = rows.map { it.receipt() },
            coverageUtcMillis = rows.filter { it.registration == "registered" }.maxOfOrNull { it.utcMillis })
        store.write("plan:${result.operationId}", result)
        runtime.emit("planChanged")
        return result
    }

    fun acknowledgeCleanup(id: String, ids: List<Long>): PlanReceipt {
        val result = receipt(id) ?: error("stalePlan")
        require(ids.all { it in result.legacyCleanupIds }) { "stalePlan" }
        return save(result.copy(legacyCleanupIds = result.legacyCleanupIds - ids.toSet()))
    }

    fun activate(id: String, expected: Long): PlanReceipt {
        val result = receipt(id) ?: error("stalePlan")
        if (active()?.operationId == id) return active()!!
        require(generation() == expected && result.state == "prepared" && result.legacyCleanupIds.isEmpty()) { "stalePlan" }
        require(result.eligibilitySignature == PrayerPolicy.eligibility(runtime.policy())) { "stalePolicy" }
        val request = store.read("request:$id", PlanRequest::class.java) ?: error("storageUnavailable")
        val rows = result.registrations.mapNotNull { dao.eventByToken(it.token) }.filter { it.registration == "registered" }
        val claimedIds = request.events.filter { dao.claim(it.id) != null }.map { it.id }.toSet()
        require(request.events.filter { it.id !in claimedIds && PrayerPolicy.effective(runtime.policy(), it.prayer).mode != "off" }
            .all { event -> rows.any { it.id == event.id && it.utcMillis == event.utcMillis } }) { "registrationIncomplete" }
        val accepted = result.copy(state = "activated")
        val obsolete = runtime.ownedRows().filter { it.purpose == "prayer" && it.id !in request.events.map { e -> e.id }.toSet() }
        store.transaction {
            rows.forEach { dao.putOwner(OwnerRow(it.id, "native", it.generation)) }
            obsolete.forEach {
                dao.putOwner(OwnerRow(it.id, "disabled", result.generation))
            }
            store.write("activePlan", accepted)
            store.write("plan:$id", accepted)
            store.putText("backend", "native")
            dao.deleteState("preparingOperation")
        }
        obsolete.forEach { scheduler.cancel(it); dao.putEvent(it.copy(registration = "cancelled")) }
        runCatching { runtime.syncAdvance() }
        runCatching { runtime.sahur.sync() }
        runtime.emit("migrationChanged")
        return accepted
    }

    fun finalize(request: FinalizeRequest): PlanReceipt {
        val result = active() ?: error("stalePlan")
        require(result.operationId == request.operationId && result.generation == request.generation &&
            request.applicationDigest == result.eventDigest &&
            runtime.digest(request.configurationSignature) == result.configurationDigest) { "stalePlan" }
        val json = JSONObject(request.configurationJson)
        require(json.getJSONObject("location").getLong("revision") == result.locationRevision) { "invalidConfiguration" }
        // CE is flushed before a matching DP publication. Worker verifies both identities.
        runtime.writeCompanion("accepted.json", JSONObject().put("generation", result.generation)
            .put("digest", result.configurationDigest).put("signature", request.configurationSignature)
            .put("configuration", json).toString())
        val finalized = result.copy(state = "finalized")
        val parity = NativePrayerRenewal(runtime).verify(json, result)
        store.transaction {
            store.write("activePlan", finalized); store.write("plan:${result.operationId}", finalized)
            store.putText("finalizedSourceGeneration", result.generation.toString())
            if (parity) store.putText("calculationParity", result.configurationDigest)
            else { dao.deleteState("calculationParity"); store.putText("repair", "calculationParityUnavailable") }
        }
        if (parity) runtime.enqueueRenewal()
        runCatching { runtime.syncAdvance() }
        runCatching { runtime.sahur.sync() }
        runtime.emit("planChanged")
        return finalized
    }

    fun abort(id: String): PlanReceipt {
        val result = receipt(id) ?: error("stalePlan")
        require(active()?.operationId != id && result.state != "activated" && result.state != "finalized") { "alreadyActivated" }
        if (result.legacyCleanupIds.isNotEmpty()) return save(result.copy(state = "deferred", error = "migrationRecoveryRequired"))
        val staged = dao.events().filter { it.generation == result.generation }
        for (row in staged) {
            val now = runtime.nowMillis()
            if (dao.claim(row.id) == null && row.utcMillis > now - PrayerRules.LATE_WINDOW_MS &&
                row.utcMillis - now <= PrayerRules.PROTECTED_WINDOW_MS) {
                return save(result.copy(state = "deferred", error = "deadlineProtected"))
            }
        }
        // Migrated future registrations can be superseded only after durable
        // legacy cleanup, while retaining every consumed occurrence claim.
        for (row in staged) {
            if (row.utcMillis <= runtime.nowMillis() && dao.claim(row.id) == null) {
                val owner = dao.owner(row.id)
                if (owner?.backend in listOf("native", "legacy")) runtime.claim(row, owner!!.backend, "skippedLate", "supersededPastDue", null)
            }
            if (dao.owner(row.id)?.generation == row.generation) {
                dao.putOwner(OwnerRow(row.id, "disabled", row.generation))
            }
            scheduler.cancel(row); dao.deleteEvent(row.key)
        }
        dao.deleteState("preparingOperation")
        if (runtime.backend() == "migrating") store.putText("backend", "native")
        repair()
        return save(result.copy(state = "aborted"))
    }

    fun repair(deadlineElapsed: Long = Long.MAX_VALUE, preserveDispatchWindow: Boolean = false) {
        runtime.recoverInterruptedSession()
        val now = runtime.nowMillis()
        var repairError: String? = null
        for (row in runtime.ownedRows()) {
            if (android.os.SystemClock.elapsedRealtime() >= deadlineElapsed) {
                repairError = "coverageRepairIncomplete"
                break
            }
            if (row.registration in listOf("consumed", "cancelled", "rollbackCancelled")) continue
            // A normal resume/worker can race an already dispatched callback. Let
            // that original callback claim it; system recovery still never replays past audio.
            if (preserveDispatchWindow && row.registration == "registered" && dao.claim(row.id) == null &&
                row.utcMillis <= now && now - row.utcMillis <= PrayerRules.LATE_WINDOW_MS) continue
            if (dao.claim(row.id) != null || row.utcMillis <= now) {
                if (row.purpose == "prayer" && dao.claim(row.id) == null && row.utcMillis <= now) {
                    runtime.claim(row, "native", "skippedLate", "recoveryPastDue", null)
                    if (runtime.livePolicy.values["showMissedSummary"] == true) runtime.notifications.summary(row, "recoveryPastDue")
                }
                scheduler.cancel(row)
                dao.putEvent(row.copy(registration = "consumed"))
            } else {
                try { dao.putEvent(scheduler.register(row)) }
                catch (_: Exception) { dao.putEvent(row.copy(registration = "uncertain")); repairError = "registrationFailed" }
            }
        }
        if (repairError != null) store.putText("repair", repairError)
        else if (store.text("repair") in listOf("coverageRepairIncomplete", "registrationFailed")) dao.deleteState("repair")
        dao.pruneClaims(now - PrayerRules.HISTORY_RETENTION_MS)
        dao.events().filter { it.utcMillis < now - PrayerRules.HISTORY_RETENTION_MS }.forEach { dao.deleteEvent(it.key) }
        val protectedOperations = listOfNotNull(active()?.operationId, preparing()?.operationId).toSet()
        dao.states("planCreated:%").filter {
            it.key.substringAfter(':') !in protectedOperations && (it.value.toLongOrNull() ?: now) < now - 30 * 86400_000L
        }.forEach {
            val id = it.key.substringAfter(':')
            store.transaction { dao.deleteState("plan:$id"); dao.deleteState("request:$id"); dao.deleteState(it.key) }
            if (runtime.context.getSystemService(android.os.UserManager::class.java).isUserUnlocked) {
                AtomicFile(File(runtime.context.noBackupFilesDir, "PrayerConfiguration/payloads-$id.json")).delete()
            }
        }
        dao.states("auxclaim:%").filter { (it.value.toLongOrNull() ?: now) < now - 7 * 86400_000L }
            .forEach { dao.deleteState(it.key) }
        // Reminders follow the repaired prayers (and roll their 14-day window).
        runCatching { runtime.syncAdvance() }
        runCatching { runtime.sahur.sync() }
        runtime.emit("planChanged")
    }
}
