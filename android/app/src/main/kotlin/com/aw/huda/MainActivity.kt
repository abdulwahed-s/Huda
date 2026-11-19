package com.aw.huda

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.aw.huda.countdown.PrayerCountdownController
import com.aw.huda.countdown.PrayerCountdownSettingsIntents
import com.aw.huda.widget.QuranWidgetUpdater
import com.aw.huda.widget.prayer.PrayerWidgetUpdater
import com.aw.huda.widget.prayer.PrayerLocationTimeZoneResolver
import com.aw.huda.miqaat.MiqaatLockMethodHandler
import com.aw.huda.share.GalleryImageSaver
import com.aw.huda.location.LocationSource
import com.aw.huda.location.LocationSupport
import com.aw.huda.location.PrayerTravelReliabilityManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.aw.huda/widget"
    private val LOCATION_CHANNEL = "com.aw.huda/location"
    private val LOCATION_UPDATES_CHANNEL = "com.aw.huda/location_updates"
    private val PRAYER_LOCATION_CHANNEL = "com.aw.huda/prayer_location"
    private val PRAYER_LOCATION_MONITOR_CHANNEL =
        "com.aw.huda/prayer_location_monitor"
    private val PRAYER_COUNTDOWN_CHANNEL = "com.aw.huda/prayer_countdown"
    private var galleryImageSaver: GalleryImageSaver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val locationSource = LocationSource(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isLocationServiceEnabled" ->
                            result.success(
                                LocationSupport.isLocationServiceEnabled(applicationContext)
                            )

                        "openLocationSettings" ->
                            result.success(LocationSupport.openLocationSettings(this))

                        "getLastKnownPosition" ->
                            locationSource.getLastKnownPosition { map ->
                                runOnUiThread { result.success(map) }
                            }

                        "getCurrentPosition" ->
                            locationSource.getCurrentPosition(
                                { map -> runOnUiThread { result.success(map) } },
                                { code, msg -> runOnUiThread { result.error(code, msg, null) } },
                            )

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    android.util.Log.e("HudaLocation", "location channel error", e)
                    runOnUiThread { result.error("LOCATION_ERROR", e.message, null) }
                }
            }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LOCATION_UPDATES_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                val distanceFilter = ((arguments as? Map<*, *>)
                    ?.get("distanceFilter") as? Number)?.toFloat() ?: 0f
                locationSource.startPositionUpdates(
                    distanceFilterMeters = distanceFilter.coerceAtLeast(0f),
                    onResult = { map -> runOnUiThread { events.success(map) } },
                    onError = { code, message ->
                        runOnUiThread { events.error(code, message, null) }
                    },
                )
            }

            override fun onCancel(arguments: Any?) {
                locationSource.stopPositionUpdates()
            }
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRAYER_LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "resolveTimeZone") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val latitude = call.argument<Number>("latitude")?.toDouble()
                val longitude = call.argument<Number>("longitude")?.toDouble()
                val countryCode = call.argument<String>("countryCode")
                if (latitude == null || longitude == null) {
                    result.error("INVALID_COORDINATES", "Missing latitude/longitude", null)
                    return@setMethodCallHandler
                }
                CoroutineScope(Dispatchers.IO).launch {
                    val zone = PrayerLocationTimeZoneResolver.resolve(
                        latitude,
                        longitude,
                        countryCode = countryCode,
                    )
                    withContext(Dispatchers.Main) {
                        if (zone == null) {
                            result.error(
                                "TIME_ZONE_UNAVAILABLE",
                                "No IANA timezone boundary found for the coordinates",
                                null,
                            )
                        } else {
                            result.success(zone)
                        }
                    }
                }
            }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRAYER_LOCATION_MONITOR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> result.success(
                    PrayerTravelReliabilityManager.sync(
                        applicationContext,
                        requestedEnabled = call.argument<Boolean>("enabled"),
                        requestedMode = call.argument<String>("locationMode"),
                    ),
                )

                "consumeCandidate" -> result.success(
                    com.aw.huda.widget.prayer.PrayerWidgetRepository.consumeCandidate(applicationContext, call.arguments as? String),
                )
                "status" -> result.success(
                    PrayerTravelReliabilityManager.status(applicationContext),
                )

                "backgroundPermissionOptionLabel" -> result.success(
                    LocationSupport.backgroundPermissionOptionLabel(applicationContext),
                )

                else -> result.notImplemented()
            }
        }

        // Widget channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "refreshQuranWidget" -> {
                    CoroutineScope(Dispatchers.Main.immediate).launch {
                        try {
                            QuranWidgetUpdater.refreshAll(applicationContext)
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("HudaQuranWidget", "Failed to refresh widget", e)
                            result.error("UPDATE_ERROR", e.message, null)
                        }
                    }
                }

                "updatePrayerWidget" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val appCtx = applicationContext
                            // Every committed prayer setting comes through here.
                            runCatching { PrayerCountdownController.refresh(appCtx) }
                                .onFailure { android.util.Log.w("PrayerCountdown", "refresh failed", it) }
                            val update = PrayerWidgetUpdater.updateAll(appCtx)
                            val response = update.toPlatformMap()
                            withContext(Dispatchers.Main) { result.success(response) }
                        } catch (e: Exception) {
                            println("❌ Failed to update prayer widget: ${e.message}")
                            e.printStackTrace()
                            withContext(Dispatchers.Main) {
                                result.error("PRAYER_UPDATE_ERROR", e.message, null)
                            }
                        }
                    }
                }

                "syncPrayerTravelMonitoring" -> {
                    PrayerTravelReliabilityManager.sync(applicationContext)
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRAYER_COUNTDOWN_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "apply" -> CoroutineScope(Dispatchers.IO).launch {
                    try {
                        PrayerCountdownController.refresh(applicationContext)
                        val status = PrayerCountdownController.status(applicationContext)
                        withContext(Dispatchers.Main) { result.success(status) }
                    } catch (e: Exception) {
                        android.util.Log.e("PrayerCountdown", "apply failed", e)
                        withContext(Dispatchers.Main) {
                            result.error("COUNTDOWN_ERROR", e.message, null)
                        }
                    }
                }

                "status" -> CoroutineScope(Dispatchers.IO).launch {
                    val status = PrayerCountdownController.status(applicationContext)
                    withContext(Dispatchers.Main) { result.success(status) }
                }

                "openSettings" -> {
                    val intent = PrayerCountdownSettingsIntents.forTarget(
                        applicationContext,
                        call.argument<String>("target"),
                    )
                    result.success(
                        runCatching { startActivity(intent); true }.getOrDefault(false),
                    )
                }

                else -> result.notImplemented()
            }
        }

        // Miqaat Lock channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MiqaatLockMethodHandler.CHANNEL_NAME
        ).setMethodCallHandler(MiqaatLockMethodHandler(this))

        // Share sheets: "Save image" to Pictures/Huda.
        val gallery = GalleryImageSaver(this)
        galleryImageSaver = gallery
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GalleryImageSaver.CHANNEL_NAME,
        ).setMethodCallHandler(gallery)

        PrayerTravelReliabilityManager.sync(applicationContext)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (galleryImageSaver?.onPermissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
