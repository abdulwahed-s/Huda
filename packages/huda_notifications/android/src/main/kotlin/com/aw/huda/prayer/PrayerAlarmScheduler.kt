package com.aw.huda.prayer

import android.app.*
import android.content.*
import android.net.Uri
import android.os.Build

internal class PrayerAlarmScheduler(private val context: Context) {
    private val alarms = context.getSystemService(AlarmManager::class.java)
    fun intent(row: AlarmRow) = Intent(context, PrayerAlarmReceiver::class.java).apply {
        action = ACTION
        data = Uri.parse("huda-prayer://alarm/${row.epoch}/${row.purpose}/${row.id}")
        putExtra("token", row.token)
        putExtra("epoch", row.epoch)
        putExtra("id", row.id)
        putExtra("purpose", row.purpose)
    }
    private fun pending(row: AlarmRow, flags: Int = PendingIntent.FLAG_UPDATE_CURRENT) =
        PendingIntent.getBroadcast(context, row.id.toInt(), intent(row), flags or PendingIntent.FLAG_IMMUTABLE)

    fun register(row: AlarmRow): AlarmRow {
        require(row.utcMillis > System.currentTimeMillis()) { "deadlineProtected" }
        val intent = pending(row)
        if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
            try {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, row.utcMillis, intent)
                return row.copy(precision = "exact", registration = "registered")
            } catch (_: SecurityException) { /* Permission changed between check and registration. */ }
        }
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, row.utcMillis, intent)
        return row.copy(precision = "inexact", registration = "registered")
    }
    fun cancel(row: AlarmRow) {
        pending(row, PendingIntent.FLAG_NO_CREATE)?.let { alarms.cancel(it); it.cancel() }
    }
    companion object { const val ACTION = "com.aw.huda.prayer.DELIVER" }
}
