package com.aw.huda.location

import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.provider.Settings

object LocationSupport {

    fun isLocationServiceEnabled(context: Context): Boolean {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm.isLocationEnabled
        } else {
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    fun openLocationSettings(context: Context): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun Location.toResultMap(): Map<String, Any?> {
        val map = HashMap<String, Any?>()
        map["latitude"] = latitude
        map["longitude"] = longitude
        map["timestamp"] = time
        map["accuracy"] = if (hasAccuracy()) accuracy.toDouble() else 0.0
        map["altitude"] = if (hasAltitude()) altitude else 0.0
        map["heading"] = if (hasBearing()) bearing.toDouble() else 0.0
        map["speed"] = if (hasSpeed()) speed.toDouble() else 0.0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            map["altitudeAccuracy"] =
                if (hasVerticalAccuracy()) verticalAccuracyMeters.toDouble() else 0.0
            map["headingAccuracy"] =
                if (hasBearingAccuracy()) bearingAccuracyDegrees.toDouble() else 0.0
            map["speedAccuracy"] =
                if (hasSpeedAccuracy()) speedAccuracyMetersPerSecond.toDouble() else 0.0
        } else {
            map["altitudeAccuracy"] = 0.0
            map["headingAccuracy"] = 0.0
            map["speedAccuracy"] = 0.0
        }
        return map
    }
}
