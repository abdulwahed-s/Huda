package com.aw.huda.widget.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar
import java.util.Date

internal object PrayerWidgetScheduler {
    private const val TAG = "PrayerWidgetScheduler"
    private const val REQUEST_CODE = 0xA01
    private const val REQUEST_CODE_MINUTE_TICK = 0xA02

    fun scheduleNext(context: Context) {
        try {
            val snapshot = PrayerWidgetRepository.readSnapshot(context)
            val target = computeTargetTimeMillis(snapshot) ?: run {
                Log.d(TAG, "No coordinates / no next prayer; skipping schedule.")
                return
            }
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildPendingIntent(context)

            am.cancel(pi)
            scheduleAt(am, target, pi)
            Log.d(TAG, "Scheduled prayer widget refresh at $target")
        } catch (e: Exception) {
            Log.e(TAG, "scheduleNext failed", e)
        }
    }

    fun cancel(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPendingIntent(context))
        } catch (_: Exception) {  }
    }

    fun isAlarmPending(context: Context): Boolean {
        val intent = Intent(ACTION_PRAYER_WIDGET_UPDATE).apply {
            component = ComponentName(context, PrayerWidgetReceiver::class.java)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_NO_CREATE
        }
        return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags) != null
    }

    fun ensureAlarmsActive(context: Context) {
        if (!isAlarmPending(context)) {
            Log.w(TAG, "Prayer alarm NOT pending — self-healing: rescheduling")
            scheduleNext(context)
        }
        scheduleMinuteTick(context)
    }

    fun scheduleMinuteTick(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildMinuteTickPendingIntent(context)
            am.cancel(pi)
            val nextMinuteMillis = (System.currentTimeMillis() / 60_000L + 1) * 60_000L
            am.setExact(AlarmManager.RTC, nextMinuteMillis, pi)
        } catch (e: Exception) {
            Log.e(TAG, "scheduleMinuteTick failed", e)
        }
    }

    fun cancelMinuteTick(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildMinuteTickPendingIntent(context))
        } catch (_: Exception) {  }
    }

    private fun buildMinuteTickPendingIntent(context: Context): PendingIntent {
        val intent = Intent(ACTION_PRAYER_WIDGET_MINUTE_TICK).apply {
            component = ComponentName(context, PrayerWidgetReceiver::class.java)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, REQUEST_CODE_MINUTE_TICK, intent, flags)
    }

    private fun scheduleAt(
        am: AlarmManager,
        triggerAtMillis: Long,
        pi: PendingIntent,
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !am.canScheduleExactAlarms()) {
                am.setWindow(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    60_000L,
                    pi,
                )
            } else {
                am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pi,
                )
            }
        } catch (e: SecurityException) {
            am.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
    }

    private fun computeTargetTimeMillis(snapshot: PrayerWidgetSnapshot): Long? {
        val now = Date()
        val next = PrayerWidgetCalculator.nextAfter(snapshot, now) ?: return null

        val withSlack = Calendar.getInstance().apply {
            time = next.time
            add(Calendar.SECOND, 1)
        }.timeInMillis

        val maxMillis = System.currentTimeMillis() + 24 * 60 * 60 * 1000L
        return withSlack.coerceAtMost(maxMillis)
    }

    private fun buildPendingIntent(context: Context): PendingIntent {
        val intent = Intent(ACTION_PRAYER_WIDGET_UPDATE).apply {
            component = ComponentName(context, PrayerWidgetReceiver::class.java)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)
    }
}
