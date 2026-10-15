package com.aw.huda.widget.lockscreen

import com.aw.huda.widget.prayer.*
import java.time.Instant

internal fun lockPrayerSnapshot() = PrayerWidgetSnapshot(
    latitude = 23.5880, longitude = 58.3829, countryCode = "OM",
    calculationMethod = "auto", madhab = "shafi", highLatitudeRule = "automatic",
    offsets = emptyMap(), themeName = "teal", themeMode = "dark", appLocale = "en",
    design = PrayerWidgetDesign.HERO, language = PrayerWidgetLanguage.EN,
    numerals = PrayerWidgetNumerals.LATIN, backgroundEnabled = true,
    backgroundColor = null, glassify = false, rounded = false,
    contentColor = null, highlightColor = null, contentSize = 100,
    timeZoneId = "UTC", timeFormat = PrayerWidgetTimeFormat.TWENTY_FOUR_HOUR, revision = 42L,
    precomputedDays = (13..14).associate { day ->
        "2026-10-$day" to mapOf(
            "fajr" to Instant.parse("2026-10-${day}T05:00:00Z").toEpochMilli(),
            "sunrise" to Instant.parse("2026-10-${day}T06:00:00Z").toEpochMilli(),
            "dhuhr" to Instant.parse("2026-10-${day}T12:00:00Z").toEpochMilli(),
            "asr" to Instant.parse("2026-10-${day}T15:00:00Z").toEpochMilli(),
            "maghrib" to Instant.parse("2026-10-${day}T18:00:00Z").toEpochMilli(),
            "isha" to Instant.parse("2026-10-${day}T19:00:00Z").toEpochMilli(),
        )
    },
)
