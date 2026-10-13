package com.aw.huda.prayer

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.UserManager
import com.aw.huda.prayer.core.PrayerOccurrenceIdentity
import com.aw.huda.prayer.core.NativePrayerCalculator
import com.aw.huda.prayer.core.PrayerCalculationInput
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.time.*
import java.util.concurrent.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class PrayerLedgerAndPlanTest {
    private lateinit var runtime: PrayerNotificationRuntime
    private val io = Executors.newSingleThreadExecutor()
    private fun <T> offMain(action: () -> T): T = io.submit(Callable { action() }).get(120, TimeUnit.SECONDS)
    @Before fun setup() {
        PrayerNotificationRuntime.clearForTesting()
        val context: Context = RuntimeEnvironment.getApplication()
        Shadows.shadowOf(context.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        context.createDeviceProtectedStorageContext().deleteDatabase("huda_prayer_execution.db")
        runtime = PrayerNotificationRuntime.get(context)
        offMain { runtime.initialize() }
    }
    @After fun cleanup() { PrayerNotificationRuntime.clearForTesting(); io.shutdownNow() }
    @Test fun enabledAlarmOverviewRemainsEligibleAfterSystemNotificationGrouping() {
        runtime.livePolicy = runtime.livePolicy.copy(values = runtime.livePolicy.values + mapOf(
            "alarmScreenEnabled" to true, "followUpEnabled" to true))
        val session = SessionData("overview-regression", 410_000_003, "fajr", "playing", "full",
            "huda-default", 0.5, true, System.currentTimeMillis(), 1, null, null)
        val notification = runtime.notifications.foreground(session, "Fajr", "Prayer time")
        assertNotNull(notification.fullScreenIntent)
        // Android may group this with existing prayer summaries. Group suppression
        // would prevent the full-screen intent even on an eligible locked device.
        val grouped = Notification.Builder.recoverBuilder(runtime.context, notification)
            .setGroup("system.autogroup").build()
        assertEquals(Notification.GROUP_ALERT_ALL, grouped.groupAlertBehavior)
        val channel = runtime.context.getSystemService(NotificationManager::class.java)
            .getNotificationChannel(PrayerNotifications.ADHAN_CHANNEL)
        assertNull(channel.sound)
        assertFalse(channel.shouldVibrate())
    }
    @Test fun disabledAlarmOverviewKeepsAnOrdinarySilentNotification() {
        runtime.livePolicy = runtime.livePolicy.copy(values = runtime.livePolicy.values + mapOf(
            "alarmScreenEnabled" to false, "followUpEnabled" to true))
        val session = SessionData("overview-disabled", 410_000_003, "fajr", "playing", "full",
            "huda-default", 0.5, true, System.currentTimeMillis(), 1, null, null)
        val notification = runtime.notifications.foreground(session, "Fajr", "Prayer time")
        assertNull(notification.fullScreenIntent)
        assertEquals(Notification.GROUP_ALERT_SUMMARY, notification.groupAlertBehavior)
        assertNotNull(notification.contentIntent)
        assertEquals(listOf("Stop sound"), notification.actions.map { it.title.toString() })
        assertNull(runtime.context.getSystemService(NotificationManager::class.java)
            .getNotificationChannel(PrayerNotifications.FOLLOWUP_CHANNEL))
    }
    @Test fun lockedBootWithoutHostLauncherStillPostsPlaybackAndTerminalNotifications() {
        Shadows.shadowOf(runtime.context.getSystemService(UserManager::class.java)).setUserUnlocked(false)
        assertNull(runtime.context.packageManager.getLaunchIntentForPackage(runtime.context.packageName))
        runtime.livePolicy = runtime.livePolicy.copy(values = runtime.livePolicy.values + mapOf(
            "alarmScreenEnabled" to false, "followUpEnabled" to false))
        val session = SessionData("locked-boot-regression", 410_000_003, "fajr", "playing", "full",
            "huda-default", 0.5, true, System.currentTimeMillis(), 1, null, null)
        val notification = runtime.notifications.foreground(session, "Fajr", "Prayer time")
        assertNotNull("Native overview remains available before first unlock", notification.contentIntent)
        assertEquals(listOf("Stop sound"), notification.actions.map { it.title.toString() })
        assertNull("Unavailable Flutter navigation is optional", runtime.notifications.launch(session.occurrenceId, session.id))
        val row = AlarmRow("locked-boot", session.occurrenceId, "fajr", System.currentTimeMillis(), "UTC", "",
            "Fajr", "Prayer time", runtime.epoch(), 1, 1, 1, "fixture-digest", "locked-token")
        runtime.notifications.summary(row, "cutoff")
        val posted = runtime.context.getSystemService(NotificationManager::class.java).activeNotifications
            .single { it.tag == PrayerNotifications.TAG && it.id == row.id.toInt() }
        assertEquals("Prayer time", posted.notification.extras.getString(Notification.EXTRA_TEXT))
        assertNull(posted.notification.contentIntent)
    }
    private fun event(offsetHours: Long = 3): EventData {
        val instant = Instant.now().plusSeconds(offsetHours * 3600)
        val date = instant.atZone(ZoneOffset.UTC).toLocalDate()
        return EventData(PrayerOccurrenceIdentity.idFor(date, "fajr"), "fajr", instant.toEpochMilli(), "UTC",
            date.toString(), "Fajr", "Prayer time", "private raw latitude signature")
    }
    private fun request(event: EventData, id: String = "first", legacy: Boolean = false, generation: Long = 0): PlanRequest = PlanRequest(
        id, generation, runtime.livePolicy.revision, 1, generation + 1, runtime.digest("lat:23.588|lon:58.3829"),
        runtime.digest(id), PrayerPolicy.eligibility(runtime.livePolicy), 300, listOf(event), emptyList(),
        if (legacy) listOf(event) else emptyList())

    @Test fun exactlyOneRoomClaimWinsConcurrentNativeCallbacksAndSurvivesReopen() {
        val receipt = offMain { runtime.plans.prepare(request(event())).also { runtime.plans.activate(it.operationId, 0) } }
        val row = offMain { runtime.store.dao.eventByToken(receipt.registrations.single().token)!! }
        val pool = Executors.newFixedThreadPool(12)
        val start = CountDownLatch(1)
        val results = (1..32).map { pool.submit(Callable { start.await(); runtime.claim(row, "native", "attempted", "test", "s$it") }) }
        start.countDown()
        assertEquals(1, results.count { it.get(10, TimeUnit.SECONDS) })
        pool.shutdownNow()
        val context = runtime.context
        PrayerNotificationRuntime.clearForTesting()
        runtime = PrayerNotificationRuntime.get(context)
        offMain { runtime.initialize(); assertFalse(runtime.claim(row, "native", "attempted", "afterRestart", "new")) }
    }
    @Test fun ownershipTransferBlocksLegacyBeforeCleanupAndResumesAtCheckpoint() = offMain {
        val event = event()
        val batch = request(event, legacy = true)
        val partial = runtime.plans.prepare(batch)
        assertEquals(listOf(event.id), partial.legacyCleanupIds)
        assertEquals("native", runtime.store.dao.owner(event.id)?.backend)
        val payload = """{"type":"prayer_time","prayer":"fajr","scheduledUtc":"${Instant.ofEpochMilli(event.utcMillis)}","timeZone":"UTC"}"""
        assertFalse(LegacyPrayerDeliveryBridge.allowRestore(runtime.context, event.id.toInt(), payload))
        assertEquals(partial.legacyCleanupIds, runtime.plans.prepare(batch).legacyCleanupIds)
        runtime.plans.acknowledgeCleanup(batch.operationId, partial.legacyCleanupIds)
        val prepared = runtime.plans.prepare(batch)
        assertEquals("prepared", prepared.state)
        runtime.plans.activate(batch.operationId, 0)
        assertEquals("native", runtime.backend())
    }
    @Test fun staleGenerationAndProtectedTimeChangesCannotReplaceActivePlan() = offMain {
        val first = event()
        runtime.plans.prepare(request(first)); runtime.plans.activate("first", 0)
        try { runtime.plans.prepare(request(first, "stale")); fail("stale generation accepted") }
        catch (_: IllegalArgumentException) { }
        val imminent = first.copy(utcMillis = System.currentTimeMillis() + 30_000)
        // Keep the canonical local date consistent when testing near midnight.
        val local = Instant.ofEpochMilli(imminent.utcMillis).atZone(ZoneOffset.UTC).toLocalDate()
        val changed = imminent.copy(id = PrayerOccurrenceIdentity.idFor(local, "fajr"), localDate = local.toString())
        assertEquals("deadlineProtected", runtime.plans.prepare(request(changed, "protected", generation = 1)).error)
        assertEquals("first", runtime.plans.active()?.operationId)
    }
    @Test fun executionRecordsAndPendingIntentsExcludeRawSignatureAndCoordinates() = offMain {
        val receipt = runtime.plans.prepare(request(event()))
        val serialized = runtime.store.dao.states("%") .joinToString { it.value }
        assertFalse(serialized.contains("lat:23.588"))
        assertFalse(serialized.contains("lon:58.3829"))
        assertFalse(serialized.contains("private raw latitude signature"))
        val row = runtime.store.dao.eventByToken(receipt.registrations.single().token)!!
        val extras = runtime.alarms.intent(row).extras!!
        assertEquals(setOf("token", "epoch", "id", "purpose"), extras.keySet())
        assertEquals(runtime.context.createDeviceProtectedStorageContext().getDatabasePath("huda_prayer_execution.db").absolutePath,
            runtime.store.database.openHelper.writableDatabase.path)
    }
    @Test fun policyCompareAndSetPreventsLostEditsAndKeepsClaimsAfterAcknowledgement() = offMain {
        val first = runtime.setPolicy(runtime.policy().copy(values = runtime.policy().values + ("volumeGain" to 0.4)), 1)
        assertEquals(2, first.revision)
        try { runtime.setPolicy(first, 1); fail("stale policy accepted") } catch (_: IllegalArgumentException) { }
        assertEquals(0.4, PrayerPolicy.effective(runtime.policy(), "fajr").gain, 0.0)
    }
    @Test fun unchangedTimestampsKeepTheirInstalledTokenAcrossAnotherPlan() = offMain {
        val event = event()
        val first = runtime.plans.prepare(request(event)); runtime.plans.activate("first", 0)
        val second = runtime.plans.prepare(request(event, "second", generation = 1))
        assertEquals(first.registrations.single().token, second.registrations.single().token)
        runtime.plans.activate("second", 1)
        assertEquals(first.registrations.single().token, runtime.ownedFuture().single().token)
    }
    @Test fun supersedingPartialMigrationRequiresCleanupAndKeepsTheConsumedLedger() = offMain {
        val first = event()
        val migrating = runtime.plans.prepare(request(first, legacy = true))
        try { runtime.plans.prepare(request(first, "replacement")); fail("unacknowledged overlap superseded") }
        catch (error: IllegalArgumentException) { assertEquals("migrationRecoveryRequired", error.message) }
        runtime.plans.acknowledgeCleanup("first", migrating.legacyCleanupIds)
        val changed = first.copy(utcMillis = first.utcMillis + 3600_000)
        val replacement = runtime.plans.prepare(request(changed, "replacement"))
        assertEquals("aborted", runtime.plans.receipt("first")!!.state)
        assertEquals(changed.utcMillis, replacement.registrations.single().event.utcMillis)
        runtime.plans.activate("replacement", 0)
        assertEquals(changed.utcMillis, runtime.ownedFuture().single().utcMillis)
    }
    @Test fun calendarMetadataBypassesPrayerGuardAndConsumesStandardCapacity() = offMain {
        val id = event().id.toInt()
        runtime.store.putText("strictLegacyGate", "true")
        assertTrue(LegacyPrayerDeliveryBridge.allowDelivery(runtime.context, id, "{\"type\":\"calendar_event\"}", "event_reminder"))
        assertTrue(LegacyPrayerDeliveryBridge.allowRestore(runtime.context, id, null, "event_reminder"))
        LegacyPrayerDeliveryBridge.reserveAlarm(runtime.context, id, "{\"type\":\"calendar_event\"}", "event_reminder")
        assertNotNull(runtime.store.dao.state("standard:$id"))
        assertNull(runtime.store.dao.state("legacyAlarm:$id"))
    }
    @Test fun obsoleteLegacySlotsAreDurablyCleanedBeforeAnyNewNativeRegistration() = offMain {
        val first = event()
        val old = first.copy(id = PrayerOccurrenceIdentity.idFor(LocalDate.parse(first.localDate), "isha"), prayer = "isha",
            utcMillis = first.utcMillis + 3600_000)
        val batch = request(first).copy(legacyEvents = listOf(first, old))
        val cleanup = runtime.plans.prepare(batch)
        assertEquals(listOf(old.id), cleanup.legacyCleanupIds)
        assertTrue(cleanup.registrations.isEmpty())
        assertEquals("disabled", runtime.store.dao.owner(old.id)?.backend)
        runtime.plans.acknowledgeCleanup(batch.operationId, cleanup.legacyCleanupIds)
        val transfer = runtime.plans.prepare(batch)
        assertEquals(listOf(first.id), transfer.legacyCleanupIds)
        assertEquals(1, transfer.registrations.size)
    }
    @Test fun anInvalidReplacementCannotAbortAValidPreparation() = offMain {
        val first = event()
        val prepared = runtime.plans.prepare(request(first))
        val invalid = request(first, "invalid").copy(expectedPolicyRevision = 900)
        try { runtime.plans.prepare(invalid); fail("stale settings accepted") }
        catch (error: IllegalArgumentException) { assertEquals("stalePolicy", error.message) }
        assertEquals("first", runtime.plans.preparing()!!.operationId)
        assertNotNull(runtime.store.dao.eventByToken(prepared.registrations.single().token))
    }
    @Test fun interruptedWorkerRowsCannotCollideWithTheNextDartGeneration() = offMain {
        val first = runtime.plans.prepare(request(event()))
        runtime.plans.activate("first", 0)
        val installed = runtime.store.dao.eventByToken(first.registrations.single().token)!!
        runtime.store.dao.putEvent(installed.copy(key = "7:orphan", token = "orphan-token", generation = 7))
        val second = runtime.plans.prepare(request(event(), "second", generation = 1))
        assertEquals(8, second.generation)
        assertEquals("orphan-token", runtime.store.dao.event("7:orphan")!!.token)
    }
    @Test fun aPastPartialTransferCanBeAbortedAfterGraceAndNeverReplayed() = offMain {
        val first = event()
        val partial = runtime.plans.prepare(request(first, legacy = true))
        runtime.plans.acknowledgeCleanup("first", partial.legacyCleanupIds)
        runtime.wallClock = { first.utcMillis + PrayerRules.LATE_WINDOW_MS + 1 }
        assertEquals("aborted", runtime.plans.abort("first").state)
        assertEquals("skippedLate", runtime.store.dao.claim(first.id)!!.outcome)
        assertTrue(runtime.ownedFuture().isEmpty())
    }
    @Test fun resumeRepairPreservesADispatchedGraceWindowWhileSystemRepairRecordsMissed() = offMain {
        val first = event()
        runtime.plans.prepare(request(first)); runtime.plans.activate("first", 0)
        runtime.wallClock = { first.utcMillis + 1000 }
        runtime.plans.repair(preserveDispatchWindow = true)
        assertNull(runtime.store.dao.claim(first.id))
        runtime.plans.repair()
        assertEquals("recoveryPastDue", runtime.store.dao.claim(first.id)!!.reason)
    }
    @Test fun lockedUserRepairUsesOnlyDeviceProtectedExecutionState() = offMain {
        val first = event()
        runtime.plans.prepare(request(first)); runtime.plans.activate("first", 0)
        Shadows.shadowOf(runtime.context.getSystemService(UserManager::class.java)).setUserUnlocked(false)
        assertNull(runtime.readCompanion("accepted.json"))
        runtime.plans.repair()
        NativePrayerRenewal(runtime).extend(300)
        assertEquals(first.utcMillis, runtime.ownedFuture().single().utcMillis)
        assertFalse(runtime.snapshot().capabilities.userUnlocked)
        assertEquals(java.io.File(runtime.context.createDeviceProtectedStorageContext().filesDir, "PrayerAudio").canonicalPath,
            java.io.File(runtime.audio.storage().root).canonicalPath)
    }
    @Test fun anEarlyLegacyCallbackDefersWithoutClaimingAndShortNeverUsesTheFullLegacySound() = offMain {
        val first = event()
        val payload = """{"type":"prayer_time","prayer":"fajr","scheduledUtc":"${Instant.ofEpochMilli(first.utcMillis)}","timeZone":"UTC"}"""
        assertFalse(LegacyPrayerDeliveryBridge.allowDelivery(runtime.context, first.id.toInt(), payload))
        assertTrue(LegacyPrayerDeliveryBridge.shouldDeferDelivery(runtime.context, first.id.toInt(), payload))
        assertNull(runtime.store.dao.claim(first.id))
        runtime.setPolicy(runtime.policy().copy(values = runtime.policy().values + ("defaultMode" to "short")), runtime.policy().revision)
        runtime.wallClock = { first.utcMillis + 1 }
        assertFalse(LegacyPrayerDeliveryBridge.allowDelivery(runtime.context, first.id.toInt(), payload))
        assertFalse(LegacyPrayerDeliveryBridge.shouldDeferDelivery(runtime.context, first.id.toInt(), payload))
        assertEquals("legacyShortUnavailable", runtime.store.dao.claim(first.id)!!.reason)
    }
    private fun finalizeFirst(first: EventData): PlanReceipt {
        runtime.plans.prepare(request(first))
        val active = runtime.plans.activate("first", 0).copy(state = "finalized")
        runtime.store.write("activePlan", active)
        runtime.writeCompanion("accepted.json", JSONObject().put("digest", active.configurationDigest)
            .put("signature", "lat:23.588|lon:58.3829").toString())
        return active
    }
    @Test fun detailedDiagnosticsExpireWithoutDroppingCanonicalSuppression() = offMain {
        val first = event()
        runtime.plans.prepare(request(first)); runtime.plans.activate("first", 0)
        val row = runtime.ownedFuture().single()
        assertTrue(runtime.claim(row, "native", "attempted", "test", "session"))
        repeat(250) { runtime.outcome(first.id, "stopped", "test") }
        assertEquals(200, runtime.store.dao.states("diagnostic:%").size)
        runtime.wallClock = { System.currentTimeMillis() + 8 * 86400_000L }
        runtime.diagnostic(first.id, "stopped", "expiredTrace")
        assertEquals(1, runtime.store.dao.states("diagnostic:%").size)
        assertNotNull(runtime.store.dao.claim(first.id))
    }
    @Test fun renewalWaitsForDartToFinishPreparingAnotherSource() = offMain {
        val first = event()
        finalizeFirst(first)
        runtime.plans.prepare(request(first, "pending", generation = 1))
        // The deliberately incomplete CE envelope would fail if the worker used
        // it during a staged Dart mutation. It must not touch that source at all.
        NativePrayerRenewal(runtime).extend(300)
        assertEquals("first", runtime.plans.active()!!.operationId)
        assertEquals("pending", runtime.plans.preparing()!!.operationId)
    }
    @Test fun aFailedUserParityCheckCannotReuseAnOlderMarkerForTheSameConfigurationDigest() = offMain {
        val first = event()
        val batch = request(first)
        runtime.plans.prepare(batch)
        val active = runtime.plans.activate("first", 0)
        runtime.store.putText("calculationParity", active.configurationDigest)
        val configuration = JSONObject().put("location", JSONObject().put("revision", 1).put("latitude", 23.588)
            .put("longitude", 58.3829).put("countryCode", "OM").put("timeZoneId", "Asia/Muscat"))
            .put("methodToken", "muslimWorldLeague").put("madhabToken", "shafi").put("highLatitudeRuleToken", "none")
            .put("customAngles", JSONObject().put("fajr", 18).put("maghrib", 0).put("isha", 17))
            .put("offsets", JSONObject())
        // An arbitrary staged UTC instant is not a verified Fajr calculation.
        runtime.plans.finalize(FinalizeRequest("first", active.generation, "lat:23.588|lon:58.3829",
            configuration.toString(), batch.eventDigest))
        assertEquals("calculationParityUnavailable", runtime.store.text("repair"))
        assertEquals("", runtime.store.text("calculationParity"))
        try { NativePrayerRenewal(runtime).extend(300); fail("unverified source extended") }
        catch (error: IllegalArgumentException) { assertEquals("calculationParityUnavailable", error.message) }
    }
    @Test fun retiredPlanReceiptsExpireButActiveAndPreparingReceiptsAndClaimsSurvive() = offMain {
        val first = event()
        runtime.plans.prepare(request(first)); runtime.plans.activate("first", 0)
        runtime.plans.prepare(request(first, "second", generation = 1)); runtime.plans.activate("second", 1)
        runtime.plans.prepare(request(first, "pending", generation = 2))
        runtime.wallClock = { System.currentTimeMillis() + 31 * 86400_000L }
        runtime.plans.repair()
        assertNull(runtime.plans.receipt("first"))
        assertNotNull(runtime.plans.receipt("second"))
        assertEquals("pending", runtime.plans.preparing()!!.operationId)
        assertNotNull(runtime.store.dao.claim(first.id))
    }
    @Test fun nativeCoverageRollsForNinetyDaysWithoutFlutterAndHonorsOffAndReducedQuota() = offMain {
        // The runtime clock is injected, but AlarmManager registration still
        // rejects deadlines before the real clock. Start tomorrow so this
        // fixture remains valid when the suite runs after today's prayers.
        val base = Instant.now().atZone(ZoneOffset.UTC).toLocalDate().plusDays(1)
            .atStartOfDay(ZoneOffset.UTC).toInstant()
        var now = base
        runtime.wallClock = { now.toEpochMilli() }
        val input = PrayerCalculationInput(23.588, 58.3829, "OM", "Asia/Muscat", "muslimWorldLeague", "shafi", "none",
            offsets = mapOf("fajr" to 2880, "isha" to -1440))
        fun events(): List<EventData> = (-7L..67L).flatMap { day ->
            val date = now.atZone(ZoneId.of(input.timeZoneId)).toLocalDate().plusDays(day)
            NativePrayerCalculator.adjustedTimes(input, date).filter { it.key in PrayerRules.prayers }.mapNotNull { (prayer, instant) ->
                if (instant == null || instant <= now || instant > now.plusSeconds(60 * 86400)) null
                else {
                    val local = instant.atZone(ZoneId.of(input.timeZoneId)).toLocalDate()
                    EventData(PrayerOccurrenceIdentity.idFor(local, prayer), prayer, instant.toEpochMilli(), input.timeZoneId,
                        local.toString(), prayer, "Prayer time", null)
                }
            }
        }.sortedBy { it.utcMillis }.take(300)
        val initial = request(events().first()).copy(events = events())
        val prepared = runtime.plans.prepare(initial)
        assertEquals("Initial preparation: ${prepared.error}; first deadline delta: ${initial.events.first().utcMillis - now.toEpochMilli()}",
            "prepared", prepared.state)
        val active = runtime.plans.activate(initial.operationId, 0)
        val configuration = JSONObject().put("location", JSONObject().put("revision", 1).put("latitude", input.latitude)
            .put("longitude", input.longitude).put("countryCode", "OM").put("timeZoneId", input.timeZoneId))
            .put("methodToken", input.method).put("madhabToken", input.madhab).put("highLatitudeRuleToken", input.highLatitude)
            .put("customAngles", JSONObject().put("fajr", 18).put("maghrib", 0).put("isha", 17))
            .put("offsets", JSONObject(input.offsets)).put("androidLabels", JSONObject().apply {
                PrayerRules.prayers.forEach { put(it, JSONObject().put("title", it).put("body", "Prayer time")) }
            })
        runtime.plans.finalize(FinalizeRequest(initial.operationId, active.generation, "lat:23.588|lon:58.3829",
            configuration.toString(), initial.eventDigest))
        val originalEnd = runtime.ownedFuture().maxOf { it.utcMillis }
        for (day in 1..90) {
            now = base.plusSeconds(day * 86400L)
            runtime.plans.repair()
            if (day == 65) runtime.setPolicy(runtime.policy().copy(values = runtime.policy().values +
                ("perPrayer" to mapOf("fajr" to mapOf("mode" to "off")))), runtime.policy().revision)
            if (day == 75) runtime.updateQuota(QuotaData(260, 30, 8, 4, 1))
            NativePrayerRenewal(runtime).extend(300)
            val future = runtime.ownedFuture().filter { it.purpose == "prayer" }
            assertTrue("empty coverage at day $day", future.isNotEmpty())
            assertTrue(future.all { it.utcMillis > now.toEpochMilli() && it.utcMillis <= now.plusSeconds(60 * 86400L).toEpochMilli() })
            assertTrue(future.size <= runtime.quota())
            if (day >= 65) assertTrue(future.none { it.prayer == "fajr" })
        }
        assertTrue(runtime.ownedFuture().maxOf { it.utcMillis } > originalEnd + 50 * 86400_000L)
        assertEquals(147, runtime.plans.active()!!.quota)
        assertTrue(runtime.store.dao.history(0, 1000).isNotEmpty())
        // Moving the wall clock backward cannot restore already consumed prayers.
        now = base
        runtime.plans.repair()
        assertTrue(runtime.ownedFuture().none { runtime.store.dao.claim(it.id) != null })
    }
}
