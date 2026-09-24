package com.aw.huda.widget.prayer

import android.util.Log
import android.icu.util.TimeZone as IcuTimeZone
import net.iakovlev.timeshape.TimeZoneEngine
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

internal object PrayerLocationTimeZoneResolver {
    private const val TAG = "PrayerTimeZone"

    fun resolve(
        latitude: Double,
        longitude: Double,
        preferredZoneId: String? = null,
        countryCode: String? = null,
    ): String? {
        if (!latitude.isFinite() || !longitude.isFinite() ||
            latitude !in -90.0..90.0 || longitude !in -180.0..180.0
        ) {
            return null
        }
        val preferred = preferredZoneId?.let { runCatching { ZoneId.of(it) }.getOrNull() }
        val countryZones = zonesForCountry(countryCode).toMutableSet().apply {
            preferred?.let(::add)
        }
        val candidateGroups = buildList {
            if (countryZones.isNotEmpty()) add(countryZones)
            val offsetZones = zonesNearSolarOffset(longitude).toMutableSet().apply {
                preferred?.let(::add)
            }
            if (offsetZones.isNotEmpty() && offsetZones != countryZones) add(offsetZones)
        }
        for (candidates in candidateGroups) {
            val resolved = resolveWithZoneIds(
                latitude = latitude,
                longitude = longitude,
                preferredZoneId = preferredZoneId,
                candidateZoneIds = candidates,
            )
            if (resolved != null) return resolved
        }
        return null
    }

    internal fun resolveWithZoneIds(
        latitude: Double,
        longitude: Double,
        preferredZoneId: String? = null,
        candidateZoneIds: Set<ZoneId>,
    ): String? = runCatching {
        val started = System.currentTimeMillis()
        val engine = TimeZoneEngine.initialize(candidateZoneIds, false)
        val zones = engine.queryAll(latitude, longitude)
        runCatching {
            Log.i(
                TAG,
                "Coordinate timezone index ready in ${System.currentTimeMillis() - started}ms"
            )
        }
        val preferred = preferredZoneId?.let { preferredId ->
            zones.firstOrNull { it.id == preferredId }
        }
        (preferred ?: zones.minByOrNull { it.id })?.id
    }.onFailure { error ->
        runCatching { Log.e(TAG, "Coordinate timezone resolution failed", error) }
            .onFailure { error.printStackTrace() }
    }.getOrNull()

    private fun zonesForCountry(countryCode: String?): Set<ZoneId> {
        val normalized = countryCode?.trim()?.uppercase(Locale.ROOT)
            ?.takeIf { it.length == 2 } ?: return emptySet()
        return runCatching { IcuTimeZone.getAvailableIDs(normalized).asIterable() }
            .getOrDefault(emptyList())
            .mapNotNullTo(linkedSetOf()) { id -> runCatching { ZoneId.of(id) }.getOrNull() }
    }

    private fun zonesNearSolarOffset(longitude: Double): Set<ZoneId> {
        val now = ZonedDateTime.now()
        val instants = listOf(
            Instant.now(),
            ZonedDateTime.of(now.year, 1, 15, 12, 0, 0, 0, ZoneId.of("UTC")).toInstant(),
            ZonedDateTime.of(now.year, 7, 15, 12, 0, 0, 0, ZoneId.of("UTC")).toInstant(),
        )
        val solarMinutes = (longitude / 15.0 * 60.0).roundToInt()
        return ZoneId.getAvailableZoneIds().asSequence()
            .mapNotNull { id -> runCatching { ZoneId.of(id) }.getOrNull() }
            .filter { zone ->
                instants.any { instant ->
                    circularMinuteDifference(
                        zone.rules.getOffset(instant).totalSeconds / 60,
                        solarMinutes,
                    ) <= 180
                }
            }
            .toCollection(linkedSetOf())
    }

    private fun circularMinuteDifference(first: Int, second: Int): Int {
        val direct = abs(first - second) % (24 * 60)
        return minOf(direct, 24 * 60 - direct)
    }
}
