package com.aw.huda.prayer

import android.content.Context
import android.os.UserManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.aw.huda.prayer.core.*
import org.json.JSONObject
import java.time.*
import java.util.UUID
import java.util.concurrent.TimeUnit

class PrayerCoverageRenewalWorker(context: Context, parameters: WorkerParameters) : Worker(context, parameters) {
    override fun doWork(): Result {
        if (!applicationContext.getSystemService(UserManager::class.java).isUserUnlocked) return Result.success()
        val runtime = PrayerNotificationRuntime.get(applicationContext)
        return try {
            runtime.maintenance.submit {
                runtime.initialize()
                if (inputData.getBoolean("repair", true)) runtime.plans.repair(preserveDispatchWindow = true)
                NativePrayerRenewal(runtime).extend(inputData.getInt("maxAppend", 300))
            }.get(5, TimeUnit.MINUTES)
            Result.success()
        } catch (error: Exception) {
            val reason = generateSequence(error as Throwable) { it.cause }.mapNotNull { it.message }
                .firstOrNull { it in listOf("configurationUnavailable", "unfinalizedConfiguration", "calculationParityUnavailable", "invalidConfiguration", "localizedLabelsUnavailable") }
                ?: "renewalFailed"
            runtime.delivery.execute {
                runCatching { runtime.store.putText("repair", reason); runtime.diagnostic(0, "failed", reason) }
                runtime.emit("snapshotChanged")
            }
            Result.retry()
        }
    }
}

internal class NativePrayerRenewal(private val runtime: PrayerNotificationRuntime) {
    private fun input(configuration: JSONObject): PrayerCalculationInput {
        val location = configuration.getJSONObject("location")
        val angles = configuration.getJSONObject("customAngles")
        val offsets = configuration.getJSONObject("offsets")
        val method = configuration.getString("methodToken")
        val country = location.optString("countryCode", "")
        require(country.isNotBlank() || method !in listOf("auto", "ummAlQura")) { "invalidConfiguration" }
        require(NativePrayerCalculator.isKnownMethod(method) &&
            configuration.getString("madhabToken") in listOf("shafi", "hanafi") &&
            configuration.getString("highLatitudeRuleToken") in listOf("automatic", "middleOfTheNight", "seventhOfTheNight", "twilightAngle", "none")) { "invalidConfiguration" }
        require(location.getDouble("latitude").isFinite() && location.getDouble("latitude") in -90.0..90.0 &&
            location.getDouble("longitude").isFinite() && location.getDouble("longitude") in -180.0..180.0) { "invalidConfiguration" }
        ZoneId.of(location.getString("timeZoneId"))
        require(listOf("fajr", "maghrib", "isha").all { angles.getDouble(it).isFinite() && angles.getDouble(it) in 0.0..30.0 } &&
            offsets.keys().asSequence().all { it in PrayerRules.prayers + "sunrise" && offsets.getInt(it) in -10080..10080 }) { "invalidConfiguration" }
        return PrayerCalculationInput(location.getDouble("latitude"), location.getDouble("longitude"), country,
            location.getString("timeZoneId"), method, configuration.getString("madhabToken"),
            configuration.getString("highLatitudeRuleToken"), angles.getDouble("fajr"),
            angles.getDouble("maghrib"), angles.getDouble("isha"),
            offsets.keys().asSequence().associateWith { offsets.getInt(it) })
    }
    fun verify(configuration: JSONObject, receipt: PlanReceipt): Boolean {
        val accepted = input(configuration)
        return receipt.registrations.all { registration ->
            val event = registration.event
            // Offset can move the event to another civil date. Search the bounded accepted input dates.
            (-7L..7L).any { shift ->
                val date = LocalDate.parse(event.localDate).plusDays(shift)
                val instant = NativePrayerCalculator.adjustedTimes(accepted, date)[event.prayer]
                instant != null && kotlin.math.abs(instant.toEpochMilli() - event.utcMillis) <= 1000
            }
        }
    }
    fun extend(maxAppend: Int) {
        val plan = runtime.plans.active() ?: return
        if (plan.state != "finalized" || runtime.backend() != "native" || runtime.plans.preparing() != null) return
        val raw = runtime.readCompanion("accepted.json") ?: error("configurationUnavailable")
        val envelope = JSONObject(raw)
        require(envelope.getString("digest") == plan.configurationDigest &&
            runtime.store.text("finalizedSourceGeneration") == envelope.getLong("generation").toString()) { "unfinalizedConfiguration" }
        val configuration = envelope.getJSONObject("configuration")
        // Both broad fixture parity and this user's accepted events gate autonomous calculation.
        require(runtime.store.text("calculationParity") == plan.configurationDigest) { "calculationParityUnavailable" }
        val calculation = input(configuration)
        val now = Instant.ofEpochMilli(runtime.nowMillis())
        val through = now.plusSeconds(PrayerRules.HORIZON_DAYS * 86400)
        val policy = runtime.policy()
        val eligibility = PrayerPolicy.eligibility(policy)
        val budget = minOf(plan.quota, runtime.quota()).toInt()
        val candidates = mutableListOf<EventData>()
        val labels = configuration.optJSONObject("androidLabels")
        val existing = runtime.ownedFuture().filter { it.purpose == "prayer" }
        var date = now.atZone(ZoneId.of(calculation.timeZoneId)).toLocalDate().minusDays(7)
        val last = through.atZone(ZoneId.of(calculation.timeZoneId)).toLocalDate().plusDays(7)
        while (date <= last) {
            val times = NativePrayerCalculator.adjustedTimes(calculation, date)
            for (prayer in PrayerRules.prayers) {
                if (PrayerPolicy.effective(policy, prayer).mode == "off") continue
                val instant = times[prayer] ?: continue
                if (instant <= now || instant > through) continue
                val localDate = instant.atZone(ZoneId.of(calculation.timeZoneId)).toLocalDate()
                val id = PrayerOccurrenceIdentity.idFor(localDate, prayer)
                if (runtime.store.dao.claim(id) != null) continue
                val reference = existing.firstOrNull { it.prayer == prayer }
                val title = labels?.optJSONObject(prayer)?.optString("title")?.takeIf { it.isNotBlank() }
                    ?: reference?.title ?: error("localizedLabelsUnavailable")
                val body = labels?.optJSONObject(prayer)?.optString("body")?.takeIf { it.isNotBlank() }
                    ?: reference?.body ?: error("localizedLabelsUnavailable")
                candidates.add(EventData(id, prayer, instant.toEpochMilli(), calculation.timeZoneId,
                    localDate.toString(), title, body, null))
            }
            date = date.plusDays(1)
        }
        val desired = candidates.distinctBy { it.id }.sortedWith(compareBy<EventData> { it.utcMillis }.thenBy { it.id }).take(budget)
        val desiredIds = desired.map { it.id }.toSet()
        val obsolete = existing.filter { it.id !in desiredIds }
        for (row in obsolete) {
            if (row.utcMillis - runtime.nowMillis() <= PrayerRules.PROTECTED_WINDOW_MS) continue
            runtime.store.dao.putOwner(OwnerRow(row.id, "disabled", row.generation))
            runtime.alarms.cancel(row); runtime.store.dao.deleteEvent(row.key)
        }
        val generation = maxOf(plan.generation, runtime.store.dao.events().maxOfOrNull { it.generation } ?: 0) + 1
        var appended = 0
        for (event in desired) {
            if (existing.any { it.id == event.id && it.utcMillis == event.utcMillis }) continue
            if (appended >= maxAppend) break
            if (event.utcMillis - runtime.nowMillis() <= PrayerRules.PROTECTED_WINDOW_MS) continue
            require(runtime.plans.active()?.generation == plan.generation &&
                PrayerPolicy.eligibility(runtime.policy()) == eligibility && runtime.quota() >= desired.size) { "stalePlan" }
            val row = AlarmRow("$generation:${event.id}", event.id, event.prayer, event.utcMillis, event.timeZone,
                event.localDate, event.title, event.body, runtime.epoch(), generation, plan.locationRevision,
                plan.scheduleRevision, plan.configurationDigest, UUID.randomUUID().toString())
            runtime.store.dao.putEvent(row)
            val registered = runtime.alarms.register(row)
            runtime.store.transaction {
                runtime.store.dao.putEvent(registered)
                runtime.store.dao.putOwner(OwnerRow(row.id, "native", generation))
            }
            appended++
        }
        val rows = runtime.ownedFuture().filter { it.purpose == "prayer" }
        val extended = plan.copy(generation = maxOf(plan.generation, rows.maxOfOrNull { it.generation } ?: 0),
            registrations = rows.map { it.receipt() }, coverageUtcMillis = rows.maxOfOrNull { it.utcMillis },
            quota = budget.toLong())
        runtime.store.transaction {
            runtime.store.write("activePlan", extended)
            runtime.store.write("plan:${plan.operationId}", extended)
            if (runtime.store.text("repair") in listOf("renewalFailed", "renewalUnavailable", "configurationUnavailable",
                "unfinalizedConfiguration", "calculationParityUnavailable", "invalidConfiguration", "localizedLabelsUnavailable")) {
                runtime.store.dao.deleteState("repair")
            }
        }
        runCatching { runtime.syncAdvance() }
        runtime.emit("planChanged")
    }
}
