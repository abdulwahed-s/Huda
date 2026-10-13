package com.aw.huda.prayer

import android.app.*
import android.content.Context
import android.hardware.*
import android.media.AudioManager
import android.os.*
import androidx.core.app.NotificationManagerCompat

internal object PrayerCapabilities {
    fun read(context: Context): CapabilityData {
        val notifications = context.getSystemService(NotificationManager::class.java)
        val alarms = context.getSystemService(AlarmManager::class.java)
        val audio = context.getSystemService(AudioManager::class.java)
        val sensors = context.getSystemService(SensorManager::class.java)
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_GRAVITY, true)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER, true)
            ?: sensors.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        fun channel(id: String) = Build.VERSION.SDK_INT < 26 ||
            notifications.getNotificationChannel(id)?.importance != NotificationManager.IMPORTANCE_NONE
        val dnd = try {
            when (notifications.currentInterruptionFilter) {
                NotificationManager.INTERRUPTION_FILTER_ALL, NotificationManager.INTERRUPTION_FILTER_ALARMS -> true
                NotificationManager.INTERRUPTION_FILTER_NONE -> false
                NotificationManager.INTERRUPTION_FILTER_PRIORITY -> if (notifications.isNotificationPolicyAccessGranted) {
                    notifications.notificationPolicy.priorityCategories and NotificationManager.Policy.PRIORITY_CATEGORY_ALARMS != 0
                } else null
                else -> null
            }
        } catch (_: SecurityException) { null }
        return CapabilityData(NotificationManagerCompat.from(context).areNotificationsEnabled(),
            channel(PrayerNotifications.SILENT_CHANNEL), channel(PrayerNotifications.ADHAN_CHANNEL),
            Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms(),
            Build.VERSION.SDK_INT < 34 || notifications.canUseFullScreenIntent(),
            sensor != null, sensor?.isWakeUpSensor == true,
            context.getSystemService(UserManager::class.java).isUserUnlocked,
            context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName),
            audio.ringerMode.toLong(), dnd,
            audio.getStreamVolume(AudioManager.STREAM_ALARM).toDouble() /
                audio.getStreamMaxVolume(AudioManager.STREAM_ALARM).coerceAtLeast(1))
    }
    fun audioBlockReason(capabilities: CapabilityData, policy: EffectivePolicy): String? = when {
        !capabilities.notifications || !capabilities.adhanChannel -> "notificationsBlocked"
        !capabilities.exactAlarms -> "exactAccessDenied"
        policy.respectRinger && capabilities.ringerMode != AudioManager.RINGER_MODE_NORMAL.toLong() -> "ringerSuppressed"
        capabilities.dndAllowsAlarms != true -> "dndSuppressed"
        capabilities.alarmVolume == 0.0 || policy.gain == 0.0 -> "volumeMuted"
        else -> null
    }
}
