package com.aw.huda.widget.prayer

import java.util.Date

internal const val PRAYER_GRACE_MILLIS = 25L * 60L * 1_000L

internal sealed interface PrayerWidgetMoment {
    val event: PrayerWidgetCalculator.PrayerEvent
    val stateEnd: Date

    data class Countdown(
        override val event: PrayerWidgetCalculator.PrayerEvent,
    ) : PrayerWidgetMoment {
        override val stateEnd: Date = event.time
    }

    data class Elapsed(
        override val event: PrayerWidgetCalculator.PrayerEvent,
    ) : PrayerWidgetMoment {
        override val stateEnd: Date = Date(event.time.time + PRAYER_GRACE_MILLIS)
    }
}

internal object PrayerWidgetMomentResolver {
    fun resolve(
        now: Date,
        events: Iterable<PrayerWidgetCalculator.PrayerEvent>,
    ): PrayerWidgetMoment? {
        val ordered = events.sortedWith(
            compareBy<PrayerWidgetCalculator.PrayerEvent> { it.time.time }
                .thenBy { it.kind.ordinal },
        )
        val latest = ordered.lastOrNull { !it.time.after(now) }
        if (latest != null && now.time < latest.time.time + PRAYER_GRACE_MILLIS) {
            return PrayerWidgetMoment.Elapsed(latest)
        }
        return ordered.firstOrNull { it.time.after(now) }
            ?.let { PrayerWidgetMoment.Countdown(it) }
    }

    fun resolve(snapshot: PrayerWidgetSnapshot, now: Date): PrayerWidgetMoment? =
        resolve(now, PrayerWidgetCalculator.eventTimeline(snapshot, now))
}
