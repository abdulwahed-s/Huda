package com.aw.huda.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.aw.huda.location.LocationSupport.toResultMap
import java.util.concurrent.atomic.AtomicBoolean

class LocationSource(context: Context) {
    private val lm =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    @SuppressLint("MissingPermission")
    fun getLastKnownPosition(onResult: (Map<String, Any?>?) -> Unit) {
        onResult(bestLastKnown()?.toResultMap())
    }

    @SuppressLint("MissingPermission")
    fun getCurrentPosition(
        onResult: (Map<String, Any?>?) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        val providers = lm.getProviders(true).filter {
            it == LocationManager.GPS_PROVIDER || it == LocationManager.NETWORK_PROVIDER
        }

        if (providers.isEmpty()) {
            val last = bestLastKnown()
            if (last != null) onResult(last.toResultMap())
            else onError("UNAVAILABLE", "No location provider enabled")
            return
        }

        val handler = Handler(Looper.getMainLooper())
        val done = AtomicBoolean(false)
        val listeners = ArrayList<LocationListener>()

        fun stopUpdates() {
            for (l in listeners) {
                try {
                    lm.removeUpdates(l)
                } catch (_: Exception) {
                }
            }
            listeners.clear()
        }

        fun finish(loc: Location?) {
            if (!done.compareAndSet(false, true)) return
            handler.removeCallbacksAndMessages(null)
            stopUpdates()
            if (loc != null) {
                onResult(loc.toResultMap())
                return
            }
            val last = bestLastKnown()
            if (last != null) onResult(last.toResultMap())
            else onError("TIMEOUT", "Timed out waiting for a location fix")
        }

        handler.postDelayed({ finish(null) }, TIMEOUT_MS)

        for (provider in providers) {
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) = finish(location)
                override fun onProviderDisabled(provider: String) {}
                override fun onProviderEnabled(provider: String) {}

                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
            }
            listeners.add(listener)
            @Suppress("DEPRECATION")
            lm.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
        }
    }

    @SuppressLint("MissingPermission")
    private fun bestLastKnown(): Location? {
        var best: Location? = null
        for (provider in lm.getProviders(true)) {
            val loc = lm.getLastKnownLocation(provider) ?: continue
            if (best == null || loc.time > best.time) best = loc
        }
        return best
    }

    private companion object {
        const val TIMEOUT_MS = 20_000L
    }
}
