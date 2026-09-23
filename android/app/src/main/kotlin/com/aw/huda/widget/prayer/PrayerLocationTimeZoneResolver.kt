package com.aw.huda.widget.prayer

import android.util.Log
import net.iakovlev.timeshape.TimeZoneEngine

internal object PrayerLocationTimeZoneResolver {
    private const val TAG = "PrayerTimeZone"

    private val engine: TimeZoneEngine by lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
        val started = System.currentTimeMillis()
        TimeZoneEngine.initialize().also {
            runCatching {
                Log.i(
                    TAG,
                    "Offline timezone boundary index ready in ${System.currentTimeMillis() - started}ms"
                )
            }
        }
    }

    fun resolve(
        latitude: Double,
        longitude: Double,
        preferredZoneId: String? = null,
    ): String? {
        if (!latitude.isFinite() || !longitude.isFinite() ||
            latitude !in -90.0..90.0 || longitude !in -180.0..180.0
        ) {
            return null
        }
        return runCatching {
            val zones = engine.queryAll(latitude, longitude)
            val preferred = preferredZoneId?.let { preferred ->
                zones.firstOrNull { it.id == preferred }
            }
            (preferred ?: zones.minByOrNull { it.id })?.id
        }.onFailure { error ->
            runCatching { Log.e(TAG, "Coordinate timezone resolution failed", error) }
                .onFailure { error.printStackTrace() }
        }.getOrNull()
    }
}
