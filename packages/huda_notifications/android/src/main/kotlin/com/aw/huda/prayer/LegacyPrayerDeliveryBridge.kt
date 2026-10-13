package com.aw.huda.prayer

import android.content.Context
import org.json.JSONObject
import java.time.*

object LegacyPrayerDeliveryBridge {
    internal fun isPrayer(id: Long, payload: String?, channelId: String?): Boolean {
        if (!PrayerRules.legacyPrayerId(id)) return false
        if (channelId == "event_reminder") return false
        val type = try { JSONObject(payload ?: "").optString("type") } catch (_: Exception) { "" }
        return type.isEmpty() || type == "prayer_time"
    }
    private fun legacyRow(runtime: PrayerNotificationRuntime, id: Long, payload: String?): AlarmRow? {
        val alias = runtime.store.dao.alias(id)
        val json = try { JSONObject(payload ?: "") } catch (_: Exception) { null }
        if (alias != null && (json == null || json.optString("prayer") !in PrayerRules.prayers)) {
            val prayer = PrayerRules.prayers.getOrNull((alias.id % 10).toInt() - 1) ?: return null
            val zone = inventory(runtime.context, listOf(id)).firstOrNull()?.timeZone ?: return null
            return AlarmRow("legacy:$id", alias.id, prayer, alias.utcMillis, zone,
                Instant.ofEpochMilli(alias.utcMillis).atZone(ZoneId.of(zone)).toLocalDate().toString(),
                "", "", runtime.epoch(), 0, 0, 0, "", "legacy:$id")
        }
        val prayer = json?.optString("prayer")?.takeIf { it in PrayerRules.prayers } ?: return null
        val utc = try { Instant.parse(json.getString("scheduledUtc")).toEpochMilli() } catch (_: Exception) { return null }
        val zone = json.optString("timeZone").takeIf { it.isNotBlank() } ?: return null
        val date = try { Instant.ofEpochMilli(utc).atZone(ZoneId.of(zone)).toLocalDate() } catch (_: Exception) { return null }
        val canonical = com.aw.huda.prayer.core.PrayerOccurrenceIdentity.idFor(date, prayer)
        if (PrayerRules.prayerId(id) && canonical != id || alias != null && (alias.id != canonical || alias.utcMillis != utc)) return null
        if (json.optString("type") != "prayer_time") return null
        runtime.store.dao.putAlias(AliasRow(id, canonical, utc))
        return AlarmRow("legacy:$id", canonical, prayer, utc, zone, date.toString(), "", "", runtime.epoch(), 0,
            json.optLong("locationRevision", 0), json.optLong("scheduleRevision", 0), "", "legacy:$id")
    }
    @JvmStatic @JvmOverloads fun allowDelivery(context: Context, id: Int, payload: String?, channelId: String? = null): Boolean {
        if (!isPrayer(id.toLong(), payload, channelId)) return true
        return try {
            val runtime = PrayerNotificationRuntime.get(context)
            runtime.initialize()
            val row = legacyRow(runtime, id.toLong(), payload)
            if (row == null) {
                runtime.store.text("strictLegacyGate") != "true" && runtime.backend() == "legacy"
            } else {
                val now = runtime.nowMillis()
                if (now < row.utcMillis) false
                else {
                    val mode = PrayerPolicy.effective(runtime.livePolicy, row.prayer).mode
                    val late = now - row.utcMillis > PrayerRules.LATE_WINDOW_MS
                    val outcome = if (late) "skippedLate" else if (mode in listOf("off", "short")) "suppressed" else "displayed"
                    val reason = if (mode == "off") "policyOff" else if (mode == "short") "legacyShortUnavailable" else "legacyCallback"
                    val claimed = runtime.claim(row, "legacy", outcome, reason, null)
                    if (claimed && !late && mode in listOf("silent", "short")) {
                        val metadata = inventory(context, listOf(id.toLong())).firstOrNull()
                        runtime.notifications.summary(row.copy(title = metadata?.title ?: row.title, body = metadata?.body ?: row.body))
                    }
                    claimed && !late && mode == "full"
                }
            }
        } catch (_: Exception) { false }
    }
    @JvmStatic @JvmOverloads fun allowRestore(context: Context, id: Int, payload: String?, channelId: String? = null): Boolean {
        if (!isPrayer(id.toLong(), payload, channelId)) return true
        return try {
            val runtime = PrayerNotificationRuntime.get(context)
            runtime.initialize()
            val row = legacyRow(runtime, id.toLong(), payload)
            if (row == null) runtime.store.text("strictLegacyGate") != "true" && runtime.backend() == "legacy"
            else row.utcMillis > runtime.nowMillis() && runtime.store.dao.claim(row.id) == null &&
                (runtime.store.dao.owner(row.id)?.backend ?: "legacy") == "legacy"
        } catch (_: Exception) { false }
    }
    /** An early callback must retain the original future cache entry for repair. */
    @JvmStatic @JvmOverloads fun shouldDeferDelivery(context: Context, id: Int, payload: String?, channelId: String? = null): Boolean {
        if (!isPrayer(id.toLong(), payload, channelId)) return false
        return try {
            val runtime = PrayerNotificationRuntime.get(context)
            runtime.initialize()
            val row = legacyRow(runtime, id.toLong(), payload) ?: return false
            row.utcMillis > runtime.nowMillis() && runtime.store.dao.claim(row.id) == null &&
                (runtime.store.dao.owner(row.id)?.backend ?: "legacy") == "legacy"
        } catch (_: Exception) { false }
    }
    @JvmStatic @JvmOverloads fun reserveAlarm(context: Context, id: Int, payload: String? = null, channelId: String? = null) {
        val runtime = PrayerNotificationRuntime.get(context)
        runtime.initialize(); runtime.reservePluginAlarm(id.toLong(), isPrayer(id.toLong(), payload, channelId))
    }
    @JvmStatic fun releaseAlarm(context: Context, id: Int) {
        try { PrayerNotificationRuntime.get(context).releasePluginAlarm(id.toLong()) } catch (_: Exception) { /* Retain a conservative reservation. */ }
    }
    internal fun inventory(context: Context, ids: List<Long>): List<EventData> =
        LegacyPluginAlarms.list(context).filter { it.id in ids && PrayerRules.legacyPrayerId(it.id) }
}
