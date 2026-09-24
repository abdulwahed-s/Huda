package com.aw.huda.location

import android.annotation.SuppressLint
import android.content.Context
import com.aw.huda.location.LocationSupport.toResultMap
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import android.os.Looper

class LocationSource(context: Context) {
    private val client = LocationServices.getFusedLocationProviderClient(context)
    private var updatesCallback: LocationCallback? = null

    @SuppressLint("MissingPermission")
    fun getLastKnownPosition(onResult: (Map<String, Any?>?) -> Unit) {
        client.lastLocation
            .addOnSuccessListener { loc -> onResult(loc?.toResultMap()) }
            .addOnFailureListener { onResult(null) }
    }

    @SuppressLint("MissingPermission")
    fun getCurrentPosition(
        onResult: (Map<String, Any?>?) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        val request = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .setMaxUpdateAgeMillis(60_000L)
            .setDurationMillis(20_000L)
            .build()
        client.getCurrentLocation(request, null)
            .addOnSuccessListener { loc ->
                if (loc != null) onResult(loc.toResultMap())
                else fallbackToLast(onResult, onError)
            }
            .addOnFailureListener { fallbackToLast(onResult, onError) }
    }

    @SuppressLint("MissingPermission")
    fun startPositionUpdates(
        distanceFilterMeters: Float,
        onResult: (Map<String, Any?>) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        stopPositionUpdates()
        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (location in result.locations) onResult(location.toResultMap())
            }
        }
        updatesCallback = callback
        val request = LocationRequest.Builder(
            Priority.PRIORITY_LOW_POWER,
            STREAM_INTERVAL_MILLIS,
        ).setMinUpdateIntervalMillis(STREAM_MIN_INTERVAL_MILLIS)
            .setMinUpdateDistanceMeters(distanceFilterMeters)
            .build()
        client.requestLocationUpdates(request, callback, Looper.getMainLooper())
            .addOnFailureListener { error ->
                if (updatesCallback === callback) updatesCallback = null
                onError("UNAVAILABLE", error.message ?: "Location updates unavailable")
            }
    }

    fun stopPositionUpdates() {
        val callback = updatesCallback ?: return
        updatesCallback = null
        client.removeLocationUpdates(callback)
    }

    @SuppressLint("MissingPermission")
    private fun fallbackToLast(
        onResult: (Map<String, Any?>?) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        client.lastLocation
            .addOnSuccessListener { last ->
                if (last != null) onResult(last.toResultMap())
                else onError("UNAVAILABLE", "Location unavailable")
            }
            .addOnFailureListener { onError("UNAVAILABLE", "Location unavailable") }
    }

    private companion object {
        const val STREAM_INTERVAL_MILLIS = 60_000L
        const val STREAM_MIN_INTERVAL_MILLIS = 30_000L
    }
}
