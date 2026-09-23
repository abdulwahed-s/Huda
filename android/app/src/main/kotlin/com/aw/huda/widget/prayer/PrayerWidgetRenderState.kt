package com.aw.huda.widget.prayer

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

internal data class PrayerWidgetRenderItem(
    val kind: PrayerKind,
    val name: String,
    val time: Date,
    val formattedTime: String,
)

internal enum class PrayerWidgetCounterMode { COUNTDOWN, ELAPSED }

internal data class PrayerWidgetCounter(
    val mode: PrayerWidgetCounterMode,
    val anchorEpochMillis: Long,
)

internal data class PrayerWidgetRenderState(
    val now: Date,
    val locale: String,
    val rtl: Boolean,
    val arabicNumerals: Boolean,
    val design: PrayerWidgetDesign,
    val contentScale: Float,
    val current: PrayerWidgetRenderItem?,
    val next: PrayerWidgetRenderItem?,
    val afterNext: PrayerWidgetRenderItem?,
    val schedule: List<PrayerWidgetRenderItem>,
    val weekday: String,
    val dateBadge: String,
    val monthYear: String,
    val dateLong: String,
    val countdown: String,
    val compactCountdown: String,
    val middleOfNight: String?,
    val lastThirdOfNight: String?,
    val empty: Boolean,
    val accessibilityLabel: String,
    val counter: PrayerWidgetCounter?,
    val stateTransitionAt: Date?,
    val isElapsed: Boolean,
) {
    val primaryLabelKey: String get() = if (isElapsed) "current" else "next_prayer"
    val counterLabelKey: String get() = if (isElapsed) "current" else "remaining"

    companion object {
        fun build(
            context: Context,
            snapshot: PrayerWidgetSnapshot,
            now: Date
        ): PrayerWidgetRenderState {
            val locale = snapshot.effectiveLocale
            val rtl = PrayerWidgetLocalization.isRTL(locale)
            val arabicNumerals = snapshot.useArabicNumeralsForWidget()
            val emptyLabel = PrayerWidgetLocalization.string("empty_message", locale)
            if (!snapshot.hasCoordinates) {
                return empty(snapshot, now, locale, rtl, arabicNumerals, emptyLabel)
            }

            val events = PrayerWidgetCalculator.eventTimeline(snapshot, now)
            val moment = PrayerWidgetMomentResolver.resolve(now, events)
                ?: return empty(snapshot, now, locale, rtl, arabicNumerals, emptyLabel)
            val event = moment.event
            val timeZone = snapshot.displayTimeZone
            val formatterLocale = Locale.forLanguageTag(locale)

            fun clock(date: Date): String = PrayerTimeFormatter.formatForWidget(
                context = context,
                date = date,
                preference = snapshot.timeFormat,
                useArabicNumerals = arabicNumerals,
                languageCode = locale,
                timeZone = timeZone,
            )

            fun item(kind: PrayerKind, date: Date) = PrayerWidgetRenderItem(
                kind = kind,
                name = PrayerWidgetLocalization.prayerName(kind, locale),
                time = date,
                formattedTime = clock(date),
            )

            val displayed = item(event.kind, event.time)
            val isElapsed = moment is PrayerWidgetMoment.Elapsed
            val previousEvent = if (isElapsed) null else events.lastOrNull {
                it.time.before(event.time)
            }
            val followingEvent = events.firstOrNull { it.time.after(event.time) }
            val current = previousEvent?.let { item(it.kind, it.time) }
            val afterNext = followingEvent?.let { item(it.kind, it.time) }
            val schedule = PrayerWidgetCalculator.displayList(event.day).map {
                item(it.first, it.second)
            }

            val activeDate = event.time
            val activeCalendar = Calendar.getInstance(timeZone).apply { time = activeDate }
            val dateBadge = activeCalendar.get(Calendar.DAY_OF_MONTH).toString()
                .applyNumerals(arabicNumerals)
            val weekday = SimpleDateFormat("EEEE", formatterLocale).apply {
                this.timeZone = timeZone
            }.format(activeDate).uppercase(formatterLocale)
            val monthYear = SimpleDateFormat("MMM · yyyy", formatterLocale).apply {
                this.timeZone = timeZone
            }.format(activeDate).uppercase(formatterLocale).applyNumerals(arabicNumerals)
            val dateLong = SimpleDateFormat("EEEE  •  d MMMM yyyy", formatterLocale).apply {
                this.timeZone = timeZone
            }.format(activeDate).applyNumerals(arabicNumerals)

            val duration = if (isElapsed) {
                PrayerTimeFormatter.formatSignedCounter(
                    from = event.time,
                    to = now,
                    elapsed = true,
                    useArabicNumerals = arabicNumerals,
                )
            } else {
                PrayerTimeFormatter.formatSignedCounter(
                    from = now,
                    to = event.time,
                    elapsed = false,
                    useArabicNumerals = arabicNumerals,
                )
            }

            val nightCalendar = nightAnchor(snapshot, now)
            val sunnah = PrayerWidgetCalculator.computeSunnah(snapshot, nightCalendar)
            val accessibility = buildString {
                append(
                    PrayerWidgetLocalization.string(
                        if (isElapsed) "current" else "next_prayer",
                        locale,
                    )
                )
                append(": ")
                append(displayed.name)
                append(", ")
                append(displayed.formattedTime)
            }

            return PrayerWidgetRenderState(
                now = now,
                locale = locale,
                rtl = rtl,
                arabicNumerals = arabicNumerals,
                design = snapshot.design,
                contentScale = snapshot.contentSize.coerceIn(60, 140) / 100f,
                current = current,
                next = displayed,
                afterNext = afterNext,
                schedule = schedule,
                weekday = weekday,
                dateBadge = dateBadge,
                monthYear = monthYear,
                dateLong = dateLong,
                countdown = duration,
                compactCountdown = duration,
                middleOfNight = sunnah?.middleOfNight?.let(::clock),
                lastThirdOfNight = sunnah?.lastThirdOfNight?.let(::clock),
                empty = false,
                accessibilityLabel = accessibility,
                counter = PrayerWidgetCounter(
                    mode = if (isElapsed) PrayerWidgetCounterMode.ELAPSED
                    else PrayerWidgetCounterMode.COUNTDOWN,
                    anchorEpochMillis = event.time.time,
                ),
                stateTransitionAt = moment.stateEnd,
                isElapsed = isElapsed,
            )
        }

        private fun empty(
            snapshot: PrayerWidgetSnapshot,
            now: Date,
            locale: String,
            rtl: Boolean,
            arabicNumerals: Boolean,
            label: String,
        ) = PrayerWidgetRenderState(
            now = now,
            locale = locale,
            rtl = rtl,
            arabicNumerals = arabicNumerals,
            design = snapshot.design,
            contentScale = snapshot.contentSize.coerceIn(60, 140) / 100f,
            current = null,
            next = null,
            afterNext = null,
            schedule = emptyList(),
            weekday = "",
            dateBadge = "",
            monthYear = "",
            dateLong = "",
            countdown = "--:--:--",
            compactCountdown = "--:--:--",
            middleOfNight = null,
            lastThirdOfNight = null,
            empty = true,
            accessibilityLabel = label,
            counter = null,
            stateTransitionAt = null,
            isElapsed = false,
        )

        private fun nightAnchor(snapshot: PrayerWidgetSnapshot, now: Date): Calendar {
            val calendar = Calendar.getInstance(snapshot.displayTimeZone).apply { time = now }
            val fajr = PrayerWidgetCalculator.computeDay(snapshot, calendar)?.fajr
            if (fajr != null && now.before(fajr)) calendar.add(Calendar.DATE, -1)
            return calendar
        }
    }
}

internal fun PrayerWidgetSnapshot.useArabicNumeralsForWidget(): Boolean = when (numerals) {
    PrayerWidgetNumerals.ARABIC -> true
    PrayerWidgetNumerals.LATIN -> false
    PrayerWidgetNumerals.AUTO -> effectiveLocale.startsWith("ar")
}
