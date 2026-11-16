package com.gdelataillade.alarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.aw.huda.prayer.LegacySahurReceiver

/** Compatibility for package alarms queued before the native Sahur migration. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        LegacySahurReceiver.deliver(context, intent) { pending.finish() }
    }
}
