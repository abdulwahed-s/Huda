package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import com.aw.huda.widget.HudaGlanceWidgetReceiver
import com.aw.huda.widget.prayer.PrayerWidgetReceiver

internal data class PrayerWidgetPresence(
    val home: Int = 0,
    val compact: Int = 0,
    val expanded: Int = 0,
) {
    val count: Int get() = home + compact + expanded
    val hasHome: Boolean get() = home > 0
    val hasLock: Boolean get() = compact + expanded > 0
}

internal data class PrayerWidgetInstances(
    val home: IntArray,
    val compact: IntArray,
    val expanded: IntArray,
) {
    val presence: PrayerWidgetPresence
        get() = PrayerWidgetPresence(home.size, compact.size, expanded.size)
}

internal data class QuranWidgetInstances(val home: IntArray, val lock: IntArray) {
    val count: Int get() = home.size + lock.size
}

/** Native instances use the same AppWidgetManager ownership as home widgets.
 * Samsung picker discovery and these IDs still require OEM device verification.
 */
internal object SamsungLockWidgetRegistry {
    fun prayers(context: Context): PrayerWidgetInstances = PrayerWidgetInstances(
        ids(context, PrayerWidgetReceiver::class.java),
        ids(context, SamsungPrayerCompactReceiver::class.java),
        ids(context, SamsungPrayerExpandedReceiver::class.java),
    )

    fun quran(context: Context): QuranWidgetInstances = QuranWidgetInstances(
        ids(context, HudaGlanceWidgetReceiver::class.java),
        intArrayOf(),
    )

    private fun ids(context: Context, provider: Class<*>): IntArray =
        AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, provider))
}
