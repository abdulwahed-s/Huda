package com.aw.huda.countdown

import com.aw.huda.widget.prayer.PrayerIqamahWindows
import com.aw.huda.widget.prayer.PrayerKind
import com.aw.huda.widget.prayer.PrayerWidgetCalculator
import com.aw.huda.widget.prayer.PrayerWidgetCalculator.PrayerEvent
import com.aw.huda.widget.prayer.PrayerWidgetMoment
import com.aw.huda.widget.prayer.PrayerWidgetMomentResolver
import com.aw.huda.widget.prayer.PrayerWidgetSnapshot
import com.aw.huda.widget.prayer.PreviousPrayer
import com.aw.huda.widget.prayer.progressStart
import java.util.Date

internal data class PrayerCountdownRow(
    val kind: PrayerKind,
    val time: Date,
    val highlighted: Boolean,
)

/**
 * One state of the countdown notification. Android's Chronometer draws the
 * seconds, so the notification only changes at [nextRefresh].
 */
internal data class PrayerCountdownContent(
    /** The adhan of [focus] was within its Iqamah window; the timer counts up. */
    val elapsed: Boolean,
    /** The prayer the title is about: the one just called, or the next one. */
    val focus: PrayerEvent,
    val next: PrayerEvent,
    val previous: PrayerEvent?,
    val progressStart: Date,
    val progressEnd: Date,
    val rows: List<PrayerCountdownRow>,
    val nextRefresh: Date,
) {
    fun progress(now: Date, max: Int = PROGRESS_MAX): Int {
        val span = progressEnd.time - progressStart.time
        if (span <= 0L) return max
        val done = (now.time - progressStart.time).coerceIn(0L, span)
        return (done * max / span).toInt()
    }

    companion object {
        const val PROGRESS_MAX = 1_000
    }
}

internal object PrayerCountdownModel {
    fun build(
        snapshot: PrayerWidgetSnapshot,
        settings: PrayerCountdownSettings,
        now: Date,
    ): PrayerCountdownContent? {
        if (!snapshot.hasCoordinates) return null
        return build(
            now = now,
            timeline = PrayerWidgetCalculator.eventTimeline(snapshot, now),
            showSunrise = settings.showSunrise,
            iqamahMinutes = snapshot.iqamahMinutes,
        )
    }

    internal fun build(
        now: Date,
        timeline: List<PrayerEvent>,
        showSunrise: Boolean,
        iqamahMinutes: Map<String, Int> = PrayerIqamahWindows.defaults,
    ): PrayerCountdownContent? {
        val moment = PrayerWidgetMomentResolver.resolve(now, timeline, iqamahMinutes) ?: return null
        val next = timeline.firstOrNull { it.time.after(now) } ?: return null
        val previous = timeline.lastOrNull { !it.time.after(now) }
        val elapsed = moment is PrayerWidgetMoment.Elapsed
        val focus = moment.event
        val start = if (elapsed) focus.time
        else progressStart(previous?.let { PreviousPrayer(it.kind, it.time) }, next.time)
        // The table is the day of the prayer the timer is about, and highlights
        // that prayer, so the timer and the highlight always agree.
        val rows = PrayerWidgetCalculator.displayList(focus.day)
            .filter { showSunrise || it.first != PrayerKind.SUNRISE }
            .map { (kind, time) -> PrayerCountdownRow(kind, time, kind == focus.kind) }
        return PrayerCountdownContent(
            elapsed = elapsed,
            focus = focus,
            next = next,
            previous = previous,
            progressStart = start,
            progressEnd = moment.stateEnd,
            rows = rows,
            nextRefresh = minOf(moment.stateEnd, next.time),
        )
    }
}
