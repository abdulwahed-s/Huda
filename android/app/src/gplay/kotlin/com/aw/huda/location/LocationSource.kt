package com.aw.huda.location

import android.annotation.SuppressLint
import android.content.Context
import com.aw.huda.location.LocationSupport.toResultMap
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class LocationSource(context: Context) {
    private val client = LocationServices.getFusedLocationProviderClient(context)

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
}
