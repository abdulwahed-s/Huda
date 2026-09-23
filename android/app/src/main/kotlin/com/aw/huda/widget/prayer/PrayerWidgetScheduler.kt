package com.aw.huda.widget.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Date

internal enum class PrayerAlarmPrecision { EXACT_IDLE, INEXACT_IDLE, NONE }

internal data class PrayerAlarmScheduleResult(
    val scheduled: Boolean,
    val triggerAtMillis: Long?,
    val precision: PrayerAlarmPrecision,
    val error: String? = null,
)

internal object PrayerWidgetScheduler {
    private const val TAG = "PrayerWidgetScheduler"
    private const val REQUEST_CODE = 0xA01
    private const val LEGACY_REQUEST_CODE_MINUTE_TICK = 0xA02
    internal const val EXTRA_EXPECTED_TRIGGER = "expectedTriggerAtMillis"
    internal const val EXTRA_SETTINGS_REVISION = "settingsRevision"

    fun scheduleNext(
        context: Context,
        now: Date = Date(),
    ): PrayerAlarmScheduleResult {
        return try {
            val snapshot = PrayerWidgetRepository.readSnapshot(context)
            val target = computeTargetTimeMillis(snapshot, now) ?: run {
                cancel(context)
                Log.d(TAG, "No future prayer-state transition; alarm cancelled")
                return PrayerAlarmScheduleResult(false, null, PrayerAlarmPrecision.NONE)
            }
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildPendingIntent(context, target, snapshot.revision)
            am.cancel(pi)
            val precision = scheduleAt(am, target, pi)
            PrayerWidgetReliabilityManager.scheduleTransitionSafetyNet(context, target)
            Log.i(
                TAG,
                "Scheduled revision=${snapshot.revision} transition=$target precision=$precision",
            )
            PrayerAlarmScheduleResult(true, target, precision)
        } catch (e: Exception) {
            Log.e(TAG, "scheduleNext failed", e)
            PrayerAlarmScheduleResult(
                scheduled = false,
                triggerAtMillis = null,
                precision = PrayerAlarmPrecision.NONE,
                error = e.message ?: e.javaClass.simpleName,
            )
        }
    }

    fun cancel(context: Context) {
        runCatching {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPendingIntent(context, 0L, 0L))
            am.cancel(buildLegacyMinutePendingIntent(context))
        }.onFailure { Log.w(TAG, "Alarm cancellation failed", it) }
        PrayerWidgetReliabilityManager.cancelTransitionSafetyNet(context)
    }

    fun ensureAlarmsActive(context: Context): PrayerAlarmScheduleResult = scheduleNext(context)

    @Deprecated("The launcher Chronometer makes per-minute process wakeups unnecessary")
    fun scheduleMinuteTick(context: Context) {
        cancelLegacyMinuteTick(context)
    }

    fun cancelMinuteTick(context: Context) = cancelLegacyMinuteTick(context)

    fun logDelivery(intent: Intent, nowMillis: Long = System.currentTimeMillis()) {
        val expected = intent.getLongExtra(EXTRA_EXPECTED_TRIGGER, 0L)
        if (expected <= 0L) return
        val lateness = (nowMillis - expected).coerceAtLeast(0L)
        val revision = intent.getLongExtra(EXTRA_SETTINGS_REVISION, 0L)
        val level = if (lateness >= 60_000L) Log.WARN else Log.INFO
        Log.println(
            level,
            TAG,
            "Transition delivered revision=$revision latenessMs=$lateness expected=$expected",
        )
    }

    internal fun computeTargetTimeMillis(
        snapshot: PrayerWidgetSnapshot,
        now: Date,
    ): Long? {
        val target = PrayerWidgetMomentResolver.resolve(snapshot, now)?.stateEnd?.time
            ?: return null
        return target.takeIf { it > now.time }
    }

    internal fun desiredPrecision(
        sdkInt: Int,
        exactAlarmAccess: Boolean,
    ): PrayerAlarmPrecision = if (sdkInt < Build.VERSION_CODES.S || exactAlarmAccess) {
        PrayerAlarmPrecision.EXACT_IDLE
    } else {
        PrayerAlarmPrecision.INEXACT_IDLE
    }

    private fun scheduleAt(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent,
    ): PrayerAlarmPrecision {
        return if (desiredPrecision(
                Build.VERSION.SDK_INT,
                Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                        alarmManager.canScheduleExactAlarms(),
            ) == PrayerAlarmPrecision.EXACT_IDLE
        ) {
            try {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
                PrayerAlarmPrecision.EXACT_IDLE
            } catch (security: SecurityException) {
                Log.w(
                    TAG,
                    "Exact alarm access changed while scheduling; using inexact idle",
                    security
                )
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
                PrayerAlarmPrecision.INEXACT_IDLE
            }
        } else {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
            PrayerAlarmPrecision.INEXACT_IDLE
        }
    }

    private fun buildPendingIntent(
        context: Context,
        expectedTrigger: Long,
        revision: Long,
    ): PendingIntent {
        val intent = Intent(ACTION_PRAYER_WIDGET_UPDATE).apply {
            component = ComponentName(context, PrayerWidgetReceiver::class.java)
            putExtra(EXTRA_EXPECTED_TRIGGER, expectedTrigger)
            putExtra(EXTRA_SETTINGS_REVISION, revision)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else 0
        return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)
    }

    private fun buildLegacyMinutePendingIntent(context: Context): PendingIntent {
        val intent = Intent(ACTION_PRAYER_WIDGET_MINUTE_TICK).apply {
            component = ComponentName(context, PrayerWidgetReceiver::class.java)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else 0
        return PendingIntent.getBroadcast(
            context,
            LEGACY_REQUEST_CODE_MINUTE_TICK,
            intent,
            flags,
        )
    }

    private fun cancelLegacyMinuteTick(context: Context) {
        runCatching {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildLegacyMinutePendingIntent(context))
        }.onFailure { Log.w(TAG, "Legacy minute alarm cancellation failed", it) }
    }
}
