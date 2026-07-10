package com.aw.huda.widget.prayer

import android.content.Context
import android.content.SharedPreferences
import java.util.TimeZone

internal object PrayerWidgetRepository {
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    private const val K_LAT = "${PREFIX}latitude"
    private const val K_LON = "${PREFIX}longitude"
    private const val K_COUNTRY = "${PREFIX}country_code"
    private const val K_METHOD = "${PREFIX}calculation_method"
    private const val K_MADHAB = "${PREFIX}madhab"
    private const val K_HIGH_LAT = "${PREFIX}high_latitude_rule"

    private const val K_THEME_NAME = "${PREFIX}themeName"
    private const val K_THEME_MODE = "${PREFIX}themeMode"

    private const val K_LOCALE = "${PREFIX}locale"

    private const val K_DESIGN = "${PREFIX}prayerWidgetDesign"
    private const val K_LANGUAGE = "${PREFIX}prayerWidgetLanguage"
    private const val K_NUMERALS = "${PREFIX}prayerWidgetNumerals"

    private const val K_BG_ENABLED = "${PREFIX}prayerWidgetBgEnabled"
    private const val K_BG_COLOR = "${PREFIX}prayerWidgetBgColor"
    private const val K_BG_GLASSIFY = "${PREFIX}prayerWidgetBgGlassify"
    private const val K_BG_ROUNDED = "${PREFIX}prayerWidgetBgRounded"

    private const val K_CONTENT_COLOR = "${PREFIX}prayerWidgetContentColor"
    private const val K_HIGHLIGHT_COLOR = "${PREFIX}prayerWidgetHighlightColor"
    private const val K_CONTENT_SIZE = "${PREFIX}prayerWidgetContentSize"

    private val OFFSET_KEYS = listOf(
        "fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha",
    )

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)

    private fun SharedPreferences.readIntCompat(key: String, default: Int): Int {
        val raw = all[key] ?: return default
        return (raw as? Number)?.toInt() ?: default
    }

    private fun SharedPreferences.readBoolCompat(key: String, default: Boolean): Boolean {
        val raw = all[key] ?: return default
        return (raw as? Boolean) ?: default
    }

    fun readSnapshot(context: Context): PrayerWidgetSnapshot {
        val p = prefs(context)
        val lat = p.getString(K_LAT, null)?.toDoubleOrNull()
        val lon = p.getString(K_LON, null)?.toDoubleOrNull()
        val offsets = OFFSET_KEYS.associateWith {
            p.readIntCompat("${PREFIX}prayer_offset_$it", 0)
        }

        return PrayerWidgetSnapshot(
            latitude = lat,
            longitude = lon,
            countryCode = p.getString(K_COUNTRY, null),
            calculationMethod = p.getString(K_METHOD, null),
            madhab = p.getString(K_MADHAB, null),
            highLatitudeRule = p.getString(K_HIGH_LAT, null),
            offsets = offsets,
            themeName = p.getString(K_THEME_NAME, "purple") ?: "purple",
            themeMode = p.getString(K_THEME_MODE, "light") ?: "light",
            appLocale = p.getString(K_LOCALE, "en") ?: "en",
            design = PrayerWidgetDesign.fromStorage(p.getString(K_DESIGN, null)),
            language = PrayerWidgetLanguage.fromStorage(p.getString(K_LANGUAGE, null)),
            numerals = PrayerWidgetNumerals.fromStorage(p.getString(K_NUMERALS, null)),
            backgroundEnabled = p.readBoolCompat(K_BG_ENABLED, true),
            backgroundColor = p.getString(K_BG_COLOR, null),
            glassify = p.readBoolCompat(K_BG_GLASSIFY, false),
            rounded = p.readBoolCompat(K_BG_ROUNDED, false),
            contentColor = p.getString(K_CONTENT_COLOR, null),
            highlightColor = p.getString(K_HIGHLIGHT_COLOR, null),
            contentSize = p.readIntCompat(K_CONTENT_SIZE, 100),
        )
    }
}

internal data class PrayerWidgetSnapshot(
    val latitude: Double?,
    val longitude: Double?,
    val countryCode: String?,
    val calculationMethod: String?,
    val madhab: String?,
    val highLatitudeRule: String?,

    val offsets: Map<String, Int>,
    val themeName: String,
    val themeMode: String,
    val appLocale: String,
    val design: PrayerWidgetDesign,
    val language: PrayerWidgetLanguage,
    val numerals: PrayerWidgetNumerals,
    val backgroundEnabled: Boolean,
    val backgroundColor: String?,
    val glassify: Boolean,
    val rounded: Boolean,
    val contentColor: String?,
    val highlightColor: String?,
    val contentSize: Int,
) {
    val hasCoordinates: Boolean get() = latitude != null && longitude != null

    val displayTimeZone: TimeZone
        get() = PrayerWidgetTimeZones.timeZoneFor(countryCode)

    val effectiveLocale: String
        get() = when (language) {
            PrayerWidgetLanguage.AUTO -> appLocale.ifBlank { "en" }
            else -> language.code
        }
}

internal enum class PrayerWidgetDesign(val storage: String) {
    HERO("hero"),
    COMPACT("compact");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetDesign {
            return values().firstOrNull { it.storage == raw } ?: HERO
        }
    }
}

internal enum class PrayerWidgetLanguage(val code: String) {
    AUTO("auto"),
    AR("ar"),
    EN("en"),
    TR("tr"),
    FR("fr"),
    ES("es"),
    DE("de"),
    RU("ru"),
    UR("ur"),
    MS("ms"),
    BN("bn");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetLanguage {
            return values().firstOrNull { it.code == raw } ?: AUTO
        }
    }
}

internal enum class PrayerWidgetNumerals(val storage: String) {
    AUTO("auto"),
    LATIN("latin"),
    ARABIC("arabic");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetNumerals {
            return values().firstOrNull { it.storage == raw } ?: AUTO
        }
    }
}
