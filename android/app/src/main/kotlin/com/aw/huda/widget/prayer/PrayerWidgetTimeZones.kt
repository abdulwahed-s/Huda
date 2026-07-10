package com.aw.huda.widget.prayer

import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.TimeZone

internal object PrayerWidgetTimeZones {
    private val countryZones = mapOf(
        "AE" to "Asia/Dubai",
        "BH" to "Asia/Bahrain",
        "DE" to "Europe/Berlin",
        "EG" to "Africa/Cairo",
        "ES" to "Europe/Madrid",
        "FR" to "Europe/Paris",
        "GB" to "Europe/London",
        "ID" to "Asia/Jakarta",
        "KW" to "Asia/Kuwait",
        "MY" to "Asia/Kuala_Lumpur",
        "OM" to "Asia/Muscat",
        "PK" to "Asia/Karachi",
        "QA" to "Asia/Qatar",
        "SA" to "Asia/Riyadh",
        "TR" to "Europe/Istanbul",
        "UK" to "Europe/London",
    )

    fun zoneIdFor(countryCode: String?): ZoneId {
        val zoneName = countryZones[countryCode?.trim()?.uppercase().orEmpty()]
        return zoneName?.let { runCatching { ZoneId.of(it) }.getOrNull() }
            ?: ZoneId.systemDefault()
    }

    fun timeZoneFor(countryCode: String?): TimeZone =
        TimeZone.getTimeZone(zoneIdFor(countryCode))

    fun zoneOffsetFor(countryCode: String?, instant: Instant): ZoneOffset =
        zoneIdFor(countryCode).rules.getOffset(instant)
}
