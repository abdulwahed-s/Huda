package com.aw.huda.widget.prayer

import java.util.Date
import com.google.gson.JsonElement

internal const val PRAYER_GRACE_MILLIS = 25L * 60L * 1_000L

internal object PrayerIqamahWindows {
    val defaults = mapOf("fajr" to 25, "dhuhr" to 20, "asr" to 20, "maghrib" to 5, "isha" to 20)

    fun parse(raw: JsonElement?): Map<String, Int> {
        val values = raw?.takeIf { it.isJsonObject }?.asJsonObject
        return defaults.mapValues { (key, fallback) ->
            val value = values?.get(key)?.takeIf { it.isJsonPrimitive && it.asJsonPrimitive.isNumber }
            val number = value?.let { runCatching { it.asDouble }.getOrNull() }
            if (number != null && number.isFinite()) number.coerceIn(0.0, 60.0).toInt() else fallback
        }
    }

    fun millis(kind: PrayerKind, minutes: Map<String, Int> = defaults): Long {
        val key = kind.name.lowercase(java.util.Locale.ROOT)
        val fallback = defaults[key] ?: return 0L
        return (minutes[key] ?: fallback).coerceIn(0, 60) * 60_000L
    }
}

internal sealed interface PrayerWidgetMoment {
    val event: PrayerWidgetCalculator.PrayerEvent
    val stateEnd: Date

    data class Countdown(
        override val event: PrayerWidgetCalculator.PrayerEvent,
    ) : PrayerWidgetMoment {
        override val stateEnd: Date = event.time
    }

    data class Elapsed(
        override val event: PrayerWidgetCalculator.PrayerEvent,
        override val stateEnd: Date,
    ) : PrayerWidgetMoment
}

internal object PrayerWidgetMomentResolver {
    fun resolve(
        now: Date,
        events: Iterable<PrayerWidgetCalculator.PrayerEvent>,
        iqamahMinutes: Map<String, Int> = PrayerIqamahWindows.defaults,
    ): PrayerWidgetMoment? {
        val ordered = events.filter { it.kind != PrayerKind.SUNRISE }.sortedWith(
            compareBy<PrayerWidgetCalculator.PrayerEvent> { it.time.time }
                .thenBy { it.kind.ordinal },
        )
        val latest = ordered.lastOrNull { !it.time.after(now) }
        if (latest != null) {
            val end = Date(latest.time.time + PrayerIqamahWindows.millis(latest.kind, iqamahMinutes))
            if (now.before(end)) return PrayerWidgetMoment.Elapsed(latest, end)
        }
        return ordered.firstOrNull { it.time.after(now) }
            ?.let { PrayerWidgetMoment.Countdown(it) }
    }

    fun resolve(snapshot: PrayerWidgetSnapshot, now: Date): PrayerWidgetMoment? =
        resolve(now, PrayerWidgetCalculator.eventTimeline(snapshot, now), snapshot.iqamahMinutes)
}
