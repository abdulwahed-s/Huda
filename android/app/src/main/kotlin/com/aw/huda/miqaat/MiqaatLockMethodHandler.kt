package com.aw.huda.miqaat

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.view.accessibility.AccessibilityManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream


class MiqaatLockMethodHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.aw.huda/miqaat_lock"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> getInstalledApps(result)
            "checkPermissions" -> checkPermissions(result)
            "isAccessibilityEnabled" -> isAccessibilityEnabled(result)
            "openAccessibilitySettings" -> openAccessibilitySettings(result)
            "isOverlayPermissionGranted" -> isOverlayPermissionGranted(result)
            "requestOverlayPermission" -> requestOverlayPermission(result)
            "updateSettings" -> updateSettings(call, result)
            "completeTimeSlot" -> completeTimeSlot(call, result)
            "updateSessionProgress" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    private fun getInstalledApps(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val pm = activity.packageManager
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                
                val apps = pm.queryIntentActivities(intent, 0)
                    .filter { it.activityInfo.packageName != activity.packageName }
                    .distinctBy { it.activityInfo.packageName }
                    .sortedBy { it.loadLabel(pm).toString().lowercase() }
                    .map { resolveInfo ->
                        val packageName = resolveInfo.activityInfo.packageName
                        val appName = resolveInfo.loadLabel(pm).toString()
                        val icon = resolveInfo.loadIcon(pm)
                        val iconBase64 = drawableToBase64(icon)
                        
                        mapOf(
                            "packageId" to packageName,
                            "appName" to appName,
                            "iconBase64" to iconBase64
                        )
                    }

                withContext(Dispatchers.Main) {
                    result.success(apps)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("GET_APPS_ERROR", e.message, null)
                }
            }
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            is AdaptiveIconDrawable -> {
                val bmp = Bitmap.createBitmap(
                    drawable.intrinsicWidth.coerceAtLeast(1),
                    drawable.intrinsicHeight.coerceAtLeast(1),
                    Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            else -> {
                val bmp = Bitmap.createBitmap(
                    drawable.intrinsicWidth.coerceAtLeast(1),
                    drawable.intrinsicHeight.coerceAtLeast(1),
                    Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
        }

        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 64, 64, true)
        val outputStream = ByteArrayOutputStream()
        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
        return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        val accessibilityEnabled = isAccessibilityServiceEnabled()
        val overlayGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }

        result.success(mapOf(
            "accessibility" to accessibilityEnabled,
            "overlay" to overlayGranted,
            "batteryOptimization" to true
        ))
    }

    private fun isAccessibilityEnabled(result: MethodChannel.Result) {
        result.success(isAccessibilityServiceEnabled())
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = activity.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_GENERIC)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == activity.packageName &&
            it.resolveInfo.serviceInfo.name == MiqaatLockAccessibilityService::class.java.name
        }
    }

    private fun openAccessibilitySettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun isOverlayPermissionGranted(result: MethodChannel.Result) {
        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }
        result.success(granted)
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                )
                activity.startActivity(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun updateSettings(call: MethodCall, result: MethodChannel.Result) {
        try {
            val isEnabled = call.argument<Boolean>("isEnabled") ?: false
            val lockedApps = call.argument<List<String>>("lockedApps") ?: emptyList()
            val timeSlots = call.argument<List<Map<String, Any>>>("timeSlots") ?: emptyList()
            val goalDuration = call.argument<Int>("goalDurationMinutes") ?: 10

            MiqaatLockAccessibilityService.instance?.updateSettings(
                enabled = isEnabled,
                apps = lockedApps,
                slots = timeSlots,
                goalDuration = goalDuration
            )

            val prefs = activity.getSharedPreferences(
                MiqaatLockAccessibilityService.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            prefs.edit().apply {
                putBoolean(MiqaatLockAccessibilityService.KEY_IS_ENABLED, isEnabled)
                putInt(MiqaatLockAccessibilityService.KEY_GOAL_DURATION, goalDuration)
                putString(
                    MiqaatLockAccessibilityService.KEY_LOCKED_APPS,
                    org.json.JSONArray(lockedApps).toString()
                )
                putString(
                    MiqaatLockAccessibilityService.KEY_TIME_SLOTS,
                    org.json.JSONArray(timeSlots.map { org.json.JSONObject(it) }).toString()
                )
                apply()
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", e.message, null)
        }
    }

    private fun completeTimeSlot(call: MethodCall, result: MethodChannel.Result) {
        try {
            val timeSlotId = call.argument<String>("timeSlotId") ?: ""
            MiqaatLockAccessibilityService.instance?.completeTimeSlot(timeSlotId)
            result.success(true)
        } catch (e: Exception) {
            result.error("COMPLETE_ERROR", e.message, null)
        }
    }
}
