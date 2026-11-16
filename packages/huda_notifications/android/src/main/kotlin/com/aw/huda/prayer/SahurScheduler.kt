package com.aw.huda.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.UserManager
import org.json.JSONObject
import java.time.*
import java.util.UUID

internal data class SahurSettings(
    val enabled: Boolean = false,
    val type: Int = 0,
    val hour: Int = 4,
    val minute: Int = 0,
    val minutesBeforeFajr: Int = 30,
    val locale: String = "en",
    val title: String = "Sahur alarm",
    val body: String = "Time to wake up for Sahur",
    val stop: String = "Stop",
) {
    fun validate() {
        require(type in 0..1 && hour in 0..23 && minute in 0..59 && minutesBeforeFajr in 10..150 &&
            locale.length in 2..16 && listOf(title, body, stop).all { it.isNotBlank() && it.length <= 4096 }) { "invalidSahur" }
    }
}

/** Uses the existing thirty reserved slots, with stable IDs across a rolling window. */
internal class SahurScheduler(private val runtime: PrayerNotificationRuntime) {
    @Volatile var settings = SahurSettings()
        private set

    fun load() { settings = runtime.store.read("sahur", SahurSettings::class.java) ?: SahurSettings() }

    fun apply(value: SahurSettings): Boolean {
        value.validate()
        if (!value.enabled || value.type != settings.type || value.minutesBeforeFajr != settings.minutesBeforeFajr) {
            runtime.store.dao.deleteState("sahurLegacySeed")
        }
        runtime.store.write("sahur", value)
        settings = value
        sync()
        LegacySahurAlarms.cancel(runtime.context)
        runtime.enqueueRenewal()
        if (!value.enabled) runtime.main.post {
            runtime.liveSession?.takeIf { it.prayer == "sahur" }?.let { runtime.playback.stop(it.id, "policyDisabled", true) }
        }
        val caps = PrayerCapabilities.read(runtime.context)
        return !value.enabled || caps.notifications && caps.adhanChannel && caps.exactAlarms &&
            rows().any { it.registration == "registered" && it.precision == "exact" && it.utcMillis > runtime.nowMillis() }
    }

    fun rows() = runtime.store.dao.events().filter { it.purpose == "sahur" }

    fun policy(): EffectivePolicy = PrayerPolicy.effective(runtime.livePolicy, "fajr").copy(
        mode = if (settings.enabled) "full" else "off", reciterId = "system-alarm", gain = 1.0,
        fadeSeconds = 3, cutoffSeconds = null, screen = true, respectRinger = false,
    )

    fun sync() {
        val value = settings
        val now = runtime.nowMillis()
        val current = rows().associateBy { it.localDate }
        val parents = runtime.ownedFuture().filter { it.purpose == "prayer" && it.prayer == "fajr" }
        val zone = ZoneId.systemDefault()
        val today = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
        val candidates = if (!value.enabled) emptyList() else if (value.type == 0) {
            (0L..30L).map { offset ->
                val day = today.plusDays(offset)
                Triple(day.toString(), day.atTime(value.hour, value.minute).atZone(zone).toInstant().toEpochMilli(), zone.id)
            }
        } else if (parents.isNotEmpty()) {
            runtime.store.dao.deleteState("sahurLegacySeed")
            parents.map { Triple(it.localDate, it.utcMillis - value.minutesBeforeFajr * 60_000L, it.timeZone) }
        } else if (runtime.store.text("sahurLegacySeed") == "true") {
            // An upgrade can precede the first native prayer plan. Keep the imported
            // package dates until owned Fajr rows are available; never invent a Fajr.
            current.values.map { Triple(it.localDate, it.utcMillis, it.timeZone) }
        } else emptyList()
        val desired = candidates.distinctBy { it.first }.filter {
            (it.second > now || current[it.first]?.let { row -> row.registration == "registered" &&
                now - it.second <= PrayerRules.LATE_WINDOW_MS } == true) &&
                runtime.store.dao.state("auxclaim:sahur:${it.first}") == null
        }.sortedBy { it.second }.take(30).map { (date, at, timeZone) ->
            val id = 114L + Math.floorMod(LocalDate.parse(date).toEpochDay(), 30L)
            current[date]?.takeIf { it.id == id && it.utcMillis == at && it.title == value.title &&
                it.body == value.body && it.timeZone == timeZone && it.epoch == runtime.epoch() && it.registration == "registered" }
                ?: AlarmRow("sahur:$date", id, "sahur", at, timeZone, date, value.title, value.body,
                    runtime.epoch(), 0, 0, 0, "", UUID.randomUUID().toString(), purpose = "sahur")
        }
        val kept = desired.map { it.token }.toSet()
        current.values.filter { it.token !in kept }.forEach { runtime.alarms.cancel(it); runtime.store.dao.deleteEvent(it.key) }
        for (row in desired) {
            if (row.registration == "registered") continue
            runtime.store.dao.putEvent(row)
            try { runtime.store.dao.putEvent(runtime.alarms.register(row)) }
            catch (_: Exception) { runtime.store.dao.putEvent(row.copy(registration = "uncertain")) }
        }
    }

    /** Called after update/boot, and by the old receiver even without Flutter. */
    fun migrate(legacyIntent: Intent? = null): AlarmRow? {
        if (!runtime.context.getSystemService(UserManager::class.java).isUserUnlocked) return null
        val prefs = runtime.context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = legacyIntent?.getStringExtra("alarmSettings")?.let { runCatching { JSONObject(it) }.getOrNull() }
        val old = (114..143).mapNotNull { id -> prefs.getString("flutter.__alarm_id__$id", null)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        } }
        if (runtime.store.dao.state("sahur") == null) {
            val text = raw?.optJSONObject("notificationSettings") ?: old.firstOrNull()?.optJSONObject("notificationSettings")
            val time = prefs.getString("flutter.sahurExactTime", "04:00").orEmpty().split(':')
            val locale = prefs.getString("flutter.app_locale", "en") ?: "en"
            val value = SahurSettings(prefs.getBoolean("flutter.sahurAlarmEnabled", raw != null || old.isNotEmpty()),
                prefs.getLong("flutter.sahurAlarmType", 0).toInt().coerceIn(0, 1),
                (time.getOrNull(0)?.toIntOrNull() ?: 4).coerceIn(0, 23),
                (time.getOrNull(1)?.toIntOrNull() ?: 0).coerceIn(0, 59),
                prefs.getLong("flutter.sahurMinutesBeforeFajr", 30).toInt().coerceIn(10, 150), locale,
                text?.optString("title")?.takeIf { it.isNotBlank() } ?: "Sahur alarm",
                text?.optString("body")?.takeIf { it.isNotBlank() } ?: "Time to wake up for Sahur",
                NativePrayerStrings.forLocale(locale).stop)
            runtime.store.write("sahur", value); settings = value
            if (value.enabled && value.type == 1 && old.isNotEmpty()) runtime.store.putText("sahurLegacySeed", "true")
            if (value.enabled && value.type == 1) for (item in old) {
                val at = legacyTime(item) ?: continue
                if (at <= runtime.nowMillis()) continue
                val date = Instant.ofEpochMilli(at).atZone(ZoneId.systemDefault()).toLocalDate().toString()
                val id = 114L + Math.floorMod(LocalDate.parse(date).toEpochDay(), 30L)
                runtime.store.dao.putEvent(AlarmRow("sahur:$date", id, "sahur", at, ZoneId.systemDefault().id, date,
                    value.title, value.body, runtime.epoch(), 0, 0, 0, "", UUID.randomUUID().toString(), purpose = "sahur"))
            }
        }
        // The callback itself is due; claim by civil day to fence another old
        // callback and any newly armed native row for the same occurrence.
        val due = raw?.takeIf { settings.enabled }?.let {
            val at = legacyTime(it) ?: runtime.nowMillis()
            val parent = if (settings.type == 1) runtime.ownedRows().firstOrNull { row ->
                row.purpose == "prayer" && row.prayer == "fajr" &&
                    kotlin.math.abs(row.utcMillis - settings.minutesBeforeFajr * 60_000L - at) <= 1000
            } else null
            val date = parent?.localDate ?: Instant.ofEpochMilli(at).atZone(ZoneId.systemDefault()).toLocalDate().toString()
            AlarmRow("sahur:$date", 114L + Math.floorMod(LocalDate.parse(date).toEpochDay(), 30L), "sahur", at,
                parent?.timeZone ?: ZoneId.systemDefault().id, date, settings.title, settings.body, runtime.epoch(), 0, 0, 0, "",
                UUID.randomUUID().toString(), precision = "exact", registration = "registered", purpose = "sahur")
        }
        sync()
        LegacySahurAlarms.cancel(runtime.context)
        runtime.enqueueRenewal()
        return due
    }

    private fun legacyTime(value: JSONObject): Long? {
        val raw = value.opt("dateTime")
        if (raw is Number) return raw.toLong()
        return runCatching { Instant.parse(raw as String).toEpochMilli() }.getOrNull()
            ?: runCatching { LocalDateTime.parse(raw as String).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli() }.getOrNull()
    }
}

/** Keep the PendingIntent identity and old receiver class until at least October 2027. */
internal object LegacySahurAlarms {
    fun cancel(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java)
        for (id in 114..143) {
            val intent = Intent().setClassName(context, "com.gdelataillade.alarm.alarm.AlarmReceiver")
            PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE)?.let {
                manager.cancel(it); it.cancel()
            }
        }
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().apply { for (id in 114..143) remove("flutter.__alarm_id__$id") }.apply()
    }
}
