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
) {
    companion object {
        fun build(context: Context, snapshot: PrayerWidgetSnapshot, now: Date): PrayerWidgetRenderState {
            val locale = snapshot.effectiveLocale
            val rtl = PrayerWidgetLocalization.isRTL(locale)
            val arabicNumerals = snapshot.useArabicNumeralsForWidget()
            val emptyLabel = PrayerWidgetLocalization.string("empty_message", locale)
            if (!snapshot.hasCoordinates) {
                return empty(snapshot, now, locale, rtl, arabicNumerals, emptyLabel)
            }

            val next = PrayerWidgetCalculator.nextAfter(snapshot, now)
                ?: return empty(snapshot, now, locale, rtl, arabicNumerals, emptyLabel)
            val previous = PrayerWidgetCalculator.previousBefore(snapshot, now)
            val timeZone = snapshot.displayTimeZone
            val activeDate = next.time
            val formatterLocale = Locale.forLanguageTag(locale)

            fun clock(date: Date): String = PrayerTimeFormatter.formatForDevice(
                context = context,
                date = date,
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

            val schedule = PrayerWidgetCalculator.displayList(next.day).map { item(it.first, it.second) }
            val current = previous?.let { item(it.kind, it.time) }
            val nextItem = item(next.kind, next.time)
            val afterNext = findAfterNext(snapshot, next, ::item)

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

            val countdown = PrayerTimeFormatter.formatHHMMSS(
                from = now,
                to = next.time,
                useArabicNumerals = arabicNumerals,
            )
            val compactCountdown = countdown

            val nightCalendar = nightAnchor(snapshot, now)
            val sunnah = PrayerWidgetCalculator.computeSunnah(snapshot, nightCalendar)
            val middle = sunnah?.middleOfNight?.let(::clock)
            val lastThird = sunnah?.lastThirdOfNight?.let(::clock)
            val accessibility = buildString {
                append(PrayerWidgetLocalization.string("next_prayer", locale))
                append(": ")
                append(nextItem.name)
                append(", ")
                append(nextItem.formattedTime)
                append(". ")
                append(PrayerWidgetLocalization.string("remaining", locale))
                append(": ")
                append(countdown)
            }

            return PrayerWidgetRenderState(
                now = now,
                locale = locale,
                rtl = rtl,
                arabicNumerals = arabicNumerals,
                design = snapshot.design,
                contentScale = snapshot.contentSize.coerceIn(60, 140) / 100f,
                current = current,
                next = nextItem,
                afterNext = afterNext,
                schedule = schedule,
                weekday = weekday,
                dateBadge = dateBadge,
                monthYear = monthYear,
                dateLong = dateLong,
                countdown = countdown,
                compactCountdown = compactCountdown,
                middleOfNight = middle,
                lastThirdOfNight = lastThird,
                empty = false,
                accessibilityLabel = accessibility,
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
        )

        private fun findAfterNext(
            snapshot: PrayerWidgetSnapshot,
            next: NextPrayer,
            makeItem: (PrayerKind, Date) -> PrayerWidgetRenderItem,
        ): PrayerWidgetRenderItem? {
            val daily = next.day.ordered
            val index = daily.indexOfFirst { it.first == next.kind }
            if (index >= 0 && index + 1 < daily.size) {
                return daily[index + 1].let { makeItem(it.first, it.second) }
            }
            val calendar = Calendar.getInstance(snapshot.displayTimeZone).apply {
                time = next.time
                add(Calendar.DATE, 1)
            }
            val tomorrow = PrayerWidgetCalculator.computeDay(snapshot, calendar) ?: return null
            return makeItem(PrayerKind.FAJR, tomorrow.fajr)
        }

        private fun nightAnchor(snapshot: PrayerWidgetSnapshot, now: Date): Calendar {
            val calendar = Calendar.getInstance(snapshot.displayTimeZone).apply { time = now }
            val today = PrayerWidgetCalculator.computeDay(snapshot, calendar)
            if (today != null && now.before(today.fajr)) calendar.add(Calendar.DATE, -1)
            return calendar
        }
    }
}

internal fun PrayerWidgetSnapshot.useArabicNumeralsForWidget(): Boolean = when (numerals) {
    PrayerWidgetNumerals.ARABIC -> true
    PrayerWidgetNumerals.LATIN -> false
    PrayerWidgetNumerals.AUTO -> effectiveLocale.startsWith("ar")
}
