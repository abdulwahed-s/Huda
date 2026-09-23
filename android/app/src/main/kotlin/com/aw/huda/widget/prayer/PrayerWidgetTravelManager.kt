package com.aw.huda.widget.prayer

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.icu.util.TimeZone as IcuTimeZone
import android.util.Log
import androidx.core.content.ContextCompat
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

internal enum class PrayerTravelStatus {
    UPDATED,
    NOT_MOVED,
    MANUAL_LOCATION,
    THROTTLED,
    LOCATION_PERMISSION_UNAVAILABLE,
    BACKGROUND_PERMISSION_UNAVAILABLE,
    LOCATION_UNAVAILABLE,
    TIME_ZONE_UNAVAILABLE,
    COMMIT_FAILED,
}

internal data class PrayerTravelResult(
    val status: PrayerTravelStatus,
    val distanceMeters: Double? = null,
    val timeZoneId: String? = null,
    val revision: Long? = null,
)

internal data class PrayerTravelDecision(
    val shouldUpdate: Boolean,
    val distanceMeters: Double,
    val timeZoneChanged: Boolean,
)

internal enum class PrayerLocationAccessPlan {
    NO_PERMISSION,
    CACHED_ONLY,
    CACHED_OR_ACTIVE,
}

internal object PrayerWidgetTravelManager {
    private const val TAG = "PrayerWidgetTravel"
    private const val VALIDATION_INTERVAL_MILLIS = 30L * 60L * 1_000L
    private const val MEANINGFUL_DISTANCE_METERS = 10_000.0
    private const val ACTIVE_FIX_TIMEOUT_MILLIS = 20_000L
    private const val MAX_ACCEPTED_ACCURACY_METERS = 5_000f

    suspend fun refreshIfNeeded(
        context: Context,
        nowMillis: Long = System.currentTimeMillis(),
        force: Boolean = false,
    ): PrayerTravelResult {
        val snapshot = PrayerWidgetRepository.readSnapshot(context)
        if (snapshot.locationMode != PrayerLocationMode.AUTOMATIC) {
            return PrayerTravelResult(PrayerTravelStatus.MANUAL_LOCATION)
        }
        val previousLat = snapshot.latitude
        val previousLon = snapshot.longitude
        if (!force && nowMillis - PrayerWidgetRepository.lastLocationValidationMillis(context) <
            VALIDATION_INTERVAL_MILLIS
        ) {
            return PrayerTravelResult(PrayerTravelStatus.THROTTLED)
        }
        val accessPlan = accessPlan(
            hasForegroundPermission = hasForegroundLocationPermission(context),
            hasBackgroundPermission = hasBackgroundLocationPermission(context),
        )
        if (accessPlan == PrayerLocationAccessPlan.NO_PERMISSION) {
            return PrayerTravelResult(PrayerTravelStatus.LOCATION_PERMISSION_UNAVAILABLE)
        }

        val backgroundAllowed = accessPlan == PrayerLocationAccessPlan.CACHED_OR_ACTIVE
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        var candidate = bestLastKnown(locationManager)
        if (backgroundAllowed && !isFresh(candidate, nowMillis)) {
            candidate = requestBalancedFix(locationManager) ?: candidate
        }
        PrayerWidgetRepository.markLocationValidated(context, nowMillis)
        if (candidate == null || candidate.hasAccuracy() &&
            candidate.accuracy > MAX_ACCEPTED_ACCURACY_METERS
        ) {
            return PrayerTravelResult(
                if (backgroundAllowed) PrayerTravelStatus.LOCATION_UNAVAILABLE
                else PrayerTravelStatus.BACKGROUND_PERMISSION_UNAVAILABLE,
            )
        }

        val zone = PrayerLocationTimeZoneResolver.resolve(
            candidate.latitude,
            candidate.longitude,
            snapshot.timeZoneId,
        ) ?: return PrayerTravelResult(PrayerTravelStatus.TIME_ZONE_UNAVAILABLE)
        val decision = decide(
            locationMode = snapshot.locationMode,
            previousLatitude = previousLat,
            previousLongitude = previousLon,
            candidateLatitude = candidate.latitude,
            candidateLongitude = candidate.longitude,
            previousTimeZoneId = snapshot.timeZoneId,
            candidateTimeZoneId = zone,
        )
        if (!decision.shouldUpdate) {
            return PrayerTravelResult(
                PrayerTravelStatus.NOT_MOVED,
                decision.distanceMeters,
                zone,
                snapshot.revision,
            )
        }

        val countryCode = resolveCountryCode(context, candidate, zone)
        val committed = PrayerWidgetRepository.commitAutomaticLocation(
            context = context,
            latitude = candidate.latitude,
            longitude = candidate.longitude,
            timeZoneId = zone,
            countryCode = countryCode,
            validatedAtMillis = nowMillis,
        ) ?: return PrayerTravelResult(PrayerTravelStatus.COMMIT_FAILED)

        Log.i(
            TAG,
            "Travel committed revision=${committed.revision} distance=${decision.distanceMeters.toLong()}m " +
                    "zone=${snapshot.timeZoneId}->${committed.timeZoneId}",
        )
        return PrayerTravelResult(
            PrayerTravelStatus.UPDATED,
            decision.distanceMeters,
            zone,
            committed.revision,
        )
    }

    internal fun decide(
        locationMode: PrayerLocationMode,
        previousLatitude: Double?,
        previousLongitude: Double?,
        candidateLatitude: Double,
        candidateLongitude: Double,
        previousTimeZoneId: String?,
        candidateTimeZoneId: String,
    ): PrayerTravelDecision {
        if (locationMode != PrayerLocationMode.AUTOMATIC) {
            return PrayerTravelDecision(false, 0.0, false)
        }
        val distance = if (previousLatitude == null || previousLongitude == null) {
            Double.POSITIVE_INFINITY
        } else {
            distanceMeters(
                previousLatitude,
                previousLongitude,
                candidateLatitude,
                candidateLongitude,
            )
        }
        val zoneChanged = previousTimeZoneId != null &&
                previousTimeZoneId != candidateTimeZoneId
        return PrayerTravelDecision(
            shouldUpdate = distance >= MEANINGFUL_DISTANCE_METERS || zoneChanged,
            distanceMeters = distance,
            timeZoneChanged = zoneChanged,
        )
    }

    internal fun accessPlan(
        hasForegroundPermission: Boolean,
        hasBackgroundPermission: Boolean,
    ): PrayerLocationAccessPlan = when {
        !hasForegroundPermission -> PrayerLocationAccessPlan.NO_PERMISSION
        hasBackgroundPermission -> PrayerLocationAccessPlan.CACHED_OR_ACTIVE
        else -> PrayerLocationAccessPlan.CACHED_ONLY
    }

    internal fun distanceMeters(
        latitudeA: Double,
        longitudeA: Double,
        latitudeB: Double,
        longitudeB: Double,
    ): Double {
        val earthRadius = 6_371_000.0
        fun radians(degrees: Double) = Math.toRadians(degrees)
        val dLat = radians(latitudeB - latitudeA)
        val dLon = radians(longitudeB - longitudeA)
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(radians(latitudeA)) * cos(radians(latitudeB)) *
                sin(dLon / 2) * sin(dLon / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private fun hasForegroundLocationPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) ==
                PackageManager.PERMISSION_GRANTED

    private fun hasBackgroundLocationPermission(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED

    @SuppressLint("MissingPermission")
    private fun bestLastKnown(locationManager: LocationManager): Location? = runCatching {
        locationManager.getProviders(true)
            .mapNotNull { provider ->
                runCatching {
                    locationManager.getLastKnownLocation(provider)
                }.getOrNull()
            }
            .maxWithOrNull(compareBy<Location> { it.time }.thenBy { -it.accuracy })
    }.getOrNull()

    private fun isFresh(location: Location?, nowMillis: Long): Boolean =
        location != null && location.time > 0L &&
                nowMillis - location.time in 0L..VALIDATION_INTERVAL_MILLIS

    @SuppressLint("MissingPermission")
    private suspend fun requestBalancedFix(locationManager: LocationManager): Location? {
        val provider = when {
            runCatching { locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) }
                .getOrDefault(false) -> LocationManager.NETWORK_PROVIDER

            runCatching { locationManager.isProviderEnabled(LocationManager.PASSIVE_PROVIDER) }
                .getOrDefault(false) -> LocationManager.PASSIVE_PROVIDER

            else -> return null
        }
        return suspendCancellableCoroutine { continuation ->
            val handler = Handler(Looper.getMainLooper())
            val completed = AtomicBoolean(false)
            lateinit var listener: LocationListener
            fun finish(location: Location?) {
                if (!completed.compareAndSet(false, true)) return
                handler.removeCallbacksAndMessages(null)
                runCatching { locationManager.removeUpdates(listener) }
                if (continuation.isActive) continuation.resume(location)
            }
            @Suppress("OVERRIDE_DEPRECATION")
            listener = object : LocationListener {
                override fun onLocationChanged(location: Location) = finish(location)
                override fun onProviderDisabled(provider: String) = Unit
                override fun onProviderEnabled(provider: String) = Unit
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
            }
            continuation.invokeOnCancellation { finish(null) }
            handler.post {
                runCatching {
                    @Suppress("DEPRECATION")
                    locationManager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
                }.onFailure { finish(null) }
            }
            handler.postDelayed({ finish(null) }, ACTIVE_FIX_TIMEOUT_MILLIS)
        }
    }

    @Suppress("DEPRECATION")
    private fun resolveCountryCode(
        context: Context,
        location: Location,
        timeZoneId: String,
    ): String? {
        val zoneRegion = runCatching { IcuTimeZone.getRegion(timeZoneId) }
            .getOrNull()
            ?.takeUnless { it == "001" || it.isBlank() }
        if (zoneRegion != null) return zoneRegion.uppercase(Locale.ROOT)
        return runCatching {
            if (!Geocoder.isPresent()) return@runCatching null
            Geocoder(context, Locale.US)
                .getFromLocation(location.latitude, location.longitude, 1)
                ?.firstOrNull()?.countryCode?.trim()?.uppercase(Locale.ROOT)
        }.onFailure { Log.w(TAG, "Country reverse geocoding unavailable", it) }
            .getOrNull()
    }
}
