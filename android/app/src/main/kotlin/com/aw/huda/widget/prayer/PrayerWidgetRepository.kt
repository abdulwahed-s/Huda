package com.aw.huda.widget.prayer

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import java.time.Instant
import java.time.ZoneId
import java.util.TimeZone
import kotlin.math.max

internal object PrayerWidgetRepository {
    private const val TAG = "PrayerWidgetRepository"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    internal const val SETTINGS_PAYLOAD_KEY = "prayer_widget_settings_v2"
    private const val K_PAYLOAD = "${PREFIX}$SETTINGS_PAYLOAD_KEY"
    private const val K_LAT = "${PREFIX}latitude"
    private const val K_LON = "${PREFIX}longitude"
    private const val K_COUNTRY = "${PREFIX}country_code"
    private const val K_LOCALITY = "${PREFIX}prayer_location_locality"
    private const val K_COUNTRY_NAME = "${PREFIX}prayer_location_country"
    private const val K_TIME_ZONE = "${PREFIX}prayer_time_zone_id"
    private const val K_LOCATION_MODE = "${PREFIX}prayer_location_mode"
    private const val K_LOCATION_VALIDATED_AT =
        "${PREFIX}prayer_location_last_validation_ms"
    private const val K_METHOD = "${PREFIX}calculation_method"
    private const val K_MADHAB = "${PREFIX}madhab"
    private const val K_HIGH_LAT = "${PREFIX}high_latitude_rule"
    private const val K_CUSTOM_FAJR = "${PREFIX}custom_fajr_angle"
    private const val K_CUSTOM_MAGHRIB = "${PREFIX}custom_maghrib_angle"
    private const val K_CUSTOM_ISHA = "${PREFIX}custom_isha_angle"
    private const val K_THEME_NAME = "${PREFIX}themeName"
    private const val K_THEME_MODE = "${PREFIX}themeMode"
    private const val K_LOCALE = "${PREFIX}locale"
    private const val K_DESIGN = "${PREFIX}prayerWidgetDesign"
    private const val K_LANGUAGE = "${PREFIX}prayerWidgetLanguage"
    private const val K_NUMERALS = "${PREFIX}prayerWidgetNumerals"
    private const val K_TIME_FORMAT = "${PREFIX}prayer_widget_time_format"
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
    private val gson = Gson()

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)

    fun readSnapshot(context: Context): PrayerWidgetSnapshot {
        val p = prefs(context)
        val committed = p.getString(K_PAYLOAD, null)
            ?.let(PrayerWidgetSettingsPayload::decode)
        if (committed != null) return committed.toSnapshot()
        if (!p.getString(K_PAYLOAD, null).isNullOrBlank()) {
            Log.w(TAG, "Ignoring invalid committed settings payload; using legacy generation")
        }
        return readLegacySnapshot(p)
    }

    fun commitAutomaticLocation(
        context: Context,
        latitude: Double,
        longitude: Double,
        timeZoneId: String,
        countryCode: String?,
        validatedAtMillis: Long,
    ): PrayerWidgetSnapshot? {
        if (!validCoordinates(latitude, longitude) || !validZoneId(timeZoneId)) {
            return null
        }
        val p = prefs(context)
        val current = p.getString(K_PAYLOAD, null)
            ?.let(PrayerWidgetSettingsPayload::decode)
            ?: PrayerWidgetSettingsPayload.fromSnapshot(readLegacySnapshot(p))
        if (current.locationMode != PrayerLocationMode.AUTOMATIC) return null

        val nowMicros = System.currentTimeMillis() * 1_000L
        val normalizedCountryCode = countryCode?.trim()?.takeIf { it.isNotEmpty() }
        val next = current.copy(
            revision = max(nowMicros, current.revision + 1L),
            committedAt = Instant.ofEpochMilli(validatedAtMillis).toString(),
            latitude = latitude,
            longitude = longitude,
            timeZoneId = timeZoneId,
            countryCode = normalizedCountryCode,
        )
        val editor = p.edit()
            .putString(K_PAYLOAD, next.encode())
            .putString(K_LAT, latitude.toString())
            .putString(K_LON, longitude.toString())
            .putString(K_TIME_ZONE, timeZoneId)
            .putString(K_LOCATION_MODE, PrayerLocationMode.AUTOMATIC.storage)
            .putLong(K_LOCATION_VALIDATED_AT, validatedAtMillis)
            .remove(K_LOCALITY)
            .remove(K_COUNTRY_NAME)
        if (normalizedCountryCode == null) editor.remove(K_COUNTRY)
        else editor.putString(K_COUNTRY, normalizedCountryCode)
        if (!editor.commit()) return null
        return next.toSnapshot()
    }

    fun markLocationValidated(context: Context, validatedAtMillis: Long) {
        prefs(context).edit().putLong(K_LOCATION_VALIDATED_AT, validatedAtMillis).apply()
    }

    fun lastLocationValidationMillis(context: Context): Long =
        prefs(context).readLongCompat(K_LOCATION_VALIDATED_AT, 0L)

    private fun readLegacySnapshot(p: SharedPreferences): PrayerWidgetSnapshot {
        val latitude = p.readDouble(K_LAT)?.takeIf { it in -90.0..90.0 }
        val longitude = p.readDouble(K_LON)?.takeIf { it in -180.0..180.0 }
        val offsets = OFFSET_KEYS.associateWith {
            sanitizeOffset(p.readIntCompat("${PREFIX}prayer_offset_$it", 0))
        }
        return PrayerWidgetSnapshot(
            latitude = if (latitude != null && longitude != null) latitude else null,
            longitude = if (latitude != null && longitude != null) longitude else null,
            countryCode = p.getString(K_COUNTRY, null),
            timeZoneId = p.getString(K_TIME_ZONE, null)?.takeIf(::validZoneId),
            locationMode = PrayerLocationMode.fromStorage(p.getString(K_LOCATION_MODE, null)),
            revision = 0L,
            committedAt = null,
            source = PrayerWidgetSettingsSource.LEGACY,
            calculationMethod = p.getString(K_METHOD, null),
            madhab = p.getString(K_MADHAB, null),
            highLatitudeRule = p.getString(K_HIGH_LAT, null),
            customFajrAngle = p.readAngle(K_CUSTOM_FAJR, 18.0, false),
            customMaghribAngle = p.readAngle(K_CUSTOM_MAGHRIB, 0.0, true),
            customIshaAngle = p.readAngle(K_CUSTOM_ISHA, 17.0, false),
            offsets = offsets,
            themeName = p.getString(K_THEME_NAME, "teal") ?: "teal",
            themeMode = p.getString(K_THEME_MODE, "light") ?: "light",
            appLocale = p.getString(K_LOCALE, "en") ?: "en",
            design = PrayerWidgetDesign.fromStorage(p.getString(K_DESIGN, null)),
            language = PrayerWidgetLanguage.fromStorage(p.getString(K_LANGUAGE, null)),
            numerals = PrayerWidgetNumerals.fromStorage(p.getString(K_NUMERALS, null)),
            timeFormat = PrayerWidgetTimeFormat.fromStorage(p.getString(K_TIME_FORMAT, null)),
            backgroundEnabled = p.readBoolCompat(K_BG_ENABLED, true),
            backgroundColor = p.getString(K_BG_COLOR, null),
            glassify = p.readBoolCompat(K_BG_GLASSIFY, false),
            rounded = p.readBoolCompat(K_BG_ROUNDED, false),
            contentColor = p.getString(K_CONTENT_COLOR, null),
            highlightColor = p.getString(K_HIGHLIGHT_COLOR, null),
            contentSize = p.readIntCompat(K_CONTENT_SIZE, 100),
        )
    }

    private fun SharedPreferences.readIntCompat(key: String, default: Int): Int {
        val raw = all[key] ?: return default
        return (raw as? Number)?.toInt() ?: (raw as? String)?.toIntOrNull() ?: default
    }

    private fun SharedPreferences.readLongCompat(key: String, default: Long): Long {
        val raw = all[key] ?: return default
        return (raw as? Number)?.toLong() ?: (raw as? String)?.toLongOrNull() ?: default
    }

    private fun SharedPreferences.readDouble(key: String): Double? {
        val raw = all[key]
        return when (raw) {
            is Number -> raw.toDouble()
            is String -> raw.trim().toDoubleOrNull()
            else -> null
        }?.takeIf(Double::isFinite)
    }

    private fun SharedPreferences.readBoolCompat(key: String, default: Boolean): Boolean =
        (all[key] as? Boolean) ?: default

    private fun SharedPreferences.readAngle(
        key: String,
        default: Double,
        allowsZero: Boolean,
    ): Double = sanitizeAngle(readDouble(key), default, allowsZero)

    internal fun validZoneId(raw: String): Boolean = try {
        ZoneId.of(raw)
        true
    } catch (_: Exception) {
        false
    }

    private fun validCoordinates(latitude: Double, longitude: Double): Boolean =
        latitude.isFinite() && longitude.isFinite() &&
                latitude in -90.0..90.0 && longitude in -180.0..180.0

    private fun sanitizeAngle(value: Double?, default: Double, allowsZero: Boolean): Double {
        if (value == null || !value.isFinite() || value > 30.0) return default
        return if (value > 0.0 || allowsZero && value == 0.0) value else default
    }

    private fun sanitizeOffset(value: Int): Int = value.coerceIn(
        -7 * 24 * 60,
        7 * 24 * 60,
    )

    internal data class PrayerWidgetSettingsPayload(
        val version: Int,
        val revision: Long,
        val committedAt: String,
        val latitude: Double?,
        val longitude: Double?,
        val locationMode: PrayerLocationMode,
        val timeZoneId: String?,
        val countryCode: String?,
        val calculationMethod: String,
        val madhab: String,
        val highLatitudeRule: String,
        val customFajrAngle: Double,
        val customMaghribAngle: Double,
        val customIshaAngle: Double,
        val offsets: Map<String, Int>,
        val timeFormat: PrayerWidgetTimeFormat,
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
        fun toSnapshot() = PrayerWidgetSnapshot(
            latitude = latitude,
            longitude = longitude,
            countryCode = countryCode,
            calculationMethod = calculationMethod,
            madhab = madhab,
            highLatitudeRule = highLatitudeRule,
            customFajrAngle = customFajrAngle,
            customMaghribAngle = customMaghribAngle,
            customIshaAngle = customIshaAngle,
            offsets = offsets,
            themeName = themeName,
            themeMode = themeMode,
            appLocale = appLocale,
            design = design,
            language = language,
            numerals = numerals,
            backgroundEnabled = backgroundEnabled,
            backgroundColor = backgroundColor,
            glassify = glassify,
            rounded = rounded,
            contentColor = contentColor,
            highlightColor = highlightColor,
            contentSize = contentSize,
            timeZoneId = timeZoneId,
            locationMode = locationMode,
            timeFormat = timeFormat,
            revision = revision,
            committedAt = committedAt,
            source = PrayerWidgetSettingsSource.COMMITTED_PAYLOAD,
        )

        fun encode(): String = gson.toJson(toJson())

        private fun toJson() = JsonObject().apply {
            addProperty("version", version)
            addProperty("revision", revision)
            addProperty("committedAt", committedAt)
            if (latitude != null && longitude != null) {
                add("coordinates", JsonObject().apply {
                    addProperty("latitude", latitude)
                    addProperty("longitude", longitude)
                })
            }
            addProperty("locationMode", locationMode.storage)
            timeZoneId?.let { addProperty("timeZoneId", it) }
            countryCode?.let { addProperty("countryCode", it) }
            addProperty("calculationMethod", calculationMethod)
            addProperty("madhab", madhab)
            addProperty("highLatitudeRule", highLatitudeRule)
            add("customAngles", JsonObject().apply {
                addProperty("custom_fajr_angle", customFajrAngle)
                addProperty("custom_maghrib_angle", customMaghribAngle)
                addProperty("custom_isha_angle", customIshaAngle)
            })
            add("offsets", gson.toJsonTree(offsets))
            addProperty("timeFormat", timeFormat.storage)
            add("appearance", JsonObject().apply {
                addProperty("themeName", themeName)
                addProperty("themeMode", themeMode)
                addProperty("locale", appLocale)
                addProperty("design", design.storage)
                addProperty("language", language.code)
                addProperty("numerals", numerals.storage)
                addProperty("backgroundEnabled", backgroundEnabled)
                backgroundColor?.let { addProperty("backgroundColor", it) }
                addProperty("glassify", glassify)
                addProperty("rounded", rounded)
                contentColor?.let { addProperty("contentColor", it) }
                highlightColor?.let { addProperty("highlightColor", it) }
                addProperty("contentSize", contentSize)
            })
        }

        companion object {
            fun decode(raw: String): PrayerWidgetSettingsPayload? = runCatching {
                val root = JsonParser.parseString(raw).asJsonObject
                val version = root.requiredInt("version")
                val revision = root.requiredLong("revision")
                val committedAt = root.requiredString("committedAt")
                require(version >= 2 && revision > 0L && committedAt.isNotBlank())
                Instant.parse(committedAt)

                val coordinates = root.get("coordinates")
                    ?.takeUnless(JsonElement::isJsonNull)?.asJsonObject
                val latitude = coordinates?.requiredDouble("latitude")
                val longitude = coordinates?.requiredDouble("longitude")
                require((latitude == null) == (longitude == null))
                if (latitude != null && longitude != null) {
                    require(validCoordinates(latitude, longitude))
                }
                val locationMode = PrayerLocationMode.fromStorage(
                    root.requiredString("locationMode"),
                )
                val zone = root.optionalString("timeZoneId")?.takeIf { it.isNotBlank() }
                require(zone == null || validZoneId(zone))
                val custom = root.requiredObject("customAngles")
                val offsetsObject = root.requiredObject("offsets")
                val offsets = OFFSET_KEYS.associateWith {
                    sanitizeOffset(offsetsObject.requiredInt(it))
                }
                val appearance = root.requiredObject("appearance")

                PrayerWidgetSettingsPayload(
                    version = version,
                    revision = revision,
                    committedAt = committedAt,
                    latitude = latitude,
                    longitude = longitude,
                    locationMode = locationMode,
                    timeZoneId = zone,
                    countryCode = root.optionalString("countryCode"),
                    calculationMethod = root.requiredString("calculationMethod"),
                    madhab = root.requiredString("madhab"),
                    highLatitudeRule = root.requiredString("highLatitudeRule"),
                    customFajrAngle = sanitizeAngle(
                        custom.requiredDouble("custom_fajr_angle"), 18.0, false,
                    ),
                    customMaghribAngle = sanitizeAngle(
                        custom.requiredDouble("custom_maghrib_angle"), 0.0, true,
                    ),
                    customIshaAngle = sanitizeAngle(
                        custom.requiredDouble("custom_isha_angle"), 17.0, false,
                    ),
                    offsets = offsets,
                    timeFormat = PrayerWidgetTimeFormat.fromStorage(
                        root.requiredString("timeFormat"),
                    ),
                    themeName = appearance.requiredString("themeName"),
                    themeMode = appearance.requiredString("themeMode"),
                    appLocale = appearance.requiredString("locale"),
                    design = PrayerWidgetDesign.fromStorage(appearance.requiredString("design")),
                    language = PrayerWidgetLanguage.fromStorage(
                        appearance.requiredString("language"),
                    ),
                    numerals = PrayerWidgetNumerals.fromStorage(
                        appearance.requiredString("numerals"),
                    ),
                    backgroundEnabled = appearance.requiredBoolean("backgroundEnabled"),
                    backgroundColor = appearance.optionalString("backgroundColor"),
                    glassify = appearance.requiredBoolean("glassify"),
                    rounded = appearance.requiredBoolean("rounded"),
                    contentColor = appearance.optionalString("contentColor"),
                    highlightColor = appearance.optionalString("highlightColor"),
                    contentSize = appearance.requiredInt("contentSize"),
                )
            }.getOrNull()

            fun fromSnapshot(snapshot: PrayerWidgetSnapshot) =
                PrayerWidgetSettingsPayload(
                    version = 2,
                    revision = snapshot.revision,
                    committedAt = snapshot.committedAt ?: Instant.now().toString(),
                    latitude = snapshot.latitude,
                    longitude = snapshot.longitude,
                    locationMode = snapshot.locationMode,
                    timeZoneId = snapshot.timeZoneId,
                    countryCode = snapshot.countryCode,
                    calculationMethod = snapshot.calculationMethod ?: "auto",
                    madhab = snapshot.madhab ?: "shafi",
                    highLatitudeRule = snapshot.highLatitudeRule ?: "automatic",
                    customFajrAngle = snapshot.customFajrAngle,
                    customMaghribAngle = snapshot.customMaghribAngle,
                    customIshaAngle = snapshot.customIshaAngle,
                    offsets = snapshot.offsets,
                    timeFormat = snapshot.timeFormat,
                    themeName = snapshot.themeName,
                    themeMode = snapshot.themeMode,
                    appLocale = snapshot.appLocale,
                    design = snapshot.design,
                    language = snapshot.language,
                    numerals = snapshot.numerals,
                    backgroundEnabled = snapshot.backgroundEnabled,
                    backgroundColor = snapshot.backgroundColor,
                    glassify = snapshot.glassify,
                    rounded = snapshot.rounded,
                    contentColor = snapshot.contentColor,
                    highlightColor = snapshot.highlightColor,
                    contentSize = snapshot.contentSize,
                )
        }
    }

    private fun JsonObject.requiredObject(key: String): JsonObject =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asJsonObject
            ?: error("Missing $key")

    private fun JsonObject.requiredString(key: String): String =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asString
            ?: error("Missing $key")

    private fun JsonObject.optionalString(key: String): String? =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asString

    private fun JsonObject.requiredInt(key: String): Int =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asInt
            ?: error("Missing $key")

    private fun JsonObject.requiredLong(key: String): Long =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asLong
            ?: error("Missing $key")

    private fun JsonObject.requiredDouble(key: String): Double =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asDouble
            ?.takeIf(Double::isFinite) ?: error("Missing $key")

    private fun JsonObject.requiredBoolean(key: String): Boolean =
        get(key)?.takeUnless(JsonElement::isJsonNull)?.asBoolean
            ?: error("Missing $key")
}

internal enum class PrayerWidgetSettingsSource { COMMITTED_PAYLOAD, LEGACY }

internal enum class PrayerLocationMode(val storage: String) {
    AUTOMATIC("automatic"), MANUAL("manual");

    companion object {
        fun fromStorage(raw: String?): PrayerLocationMode =
            if (raw == AUTOMATIC.storage) AUTOMATIC else MANUAL
    }
}

internal enum class PrayerWidgetTimeFormat(val storage: String) {
    SYSTEM("system"), TWELVE_HOUR("12h"), TWENTY_FOUR_HOUR("24h");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetTimeFormat = when (raw) {
            TWELVE_HOUR.storage -> TWELVE_HOUR
            TWENTY_FOUR_HOUR.storage -> TWENTY_FOUR_HOUR
            else -> SYSTEM
        }
    }
}

internal data class PrayerWidgetSnapshot(
    val latitude: Double?,
    val longitude: Double?,
    val countryCode: String?,
    val calculationMethod: String?,
    val madhab: String?,
    val highLatitudeRule: String?,
    val customFajrAngle: Double = 18.0,
    val customMaghribAngle: Double = 0.0,
    val customIshaAngle: Double = 17.0,
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
    val timeZoneId: String? = null,
    val locationMode: PrayerLocationMode = PrayerLocationMode.MANUAL,
    val timeFormat: PrayerWidgetTimeFormat = PrayerWidgetTimeFormat.SYSTEM,
    val revision: Long = 0L,
    val committedAt: String? = null,
    val source: PrayerWidgetSettingsSource = PrayerWidgetSettingsSource.LEGACY,
) {
    val hasCoordinates: Boolean get() = latitude != null && longitude != null
    val displayTimeZone: TimeZone
        get() = timeZoneId?.takeIf(PrayerWidgetRepository::validZoneId)
            ?.let(TimeZone::getTimeZone)
            ?: PrayerWidgetTimeZones.timeZoneFor(countryCode)
    val effectiveLocale: String
        get() = when (language) {
            PrayerWidgetLanguage.AUTO -> appLocale.ifBlank { "en" }
            else -> language.code
        }
}

internal enum class PrayerWidgetDesign(val storage: String) {
    HERO("hero"), COMPACT("compact");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetDesign =
            values().firstOrNull { it.storage == raw } ?: HERO
    }
}

internal enum class PrayerWidgetLanguage(val code: String) {
    AUTO("auto"), AR("ar"), EN("en"), TR("tr"), FR("fr"), ES("es"),
    DE("de"), RU("ru"), UR("ur"), MS("ms"), BN("bn");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetLanguage =
            values().firstOrNull { it.code == raw } ?: AUTO
    }
}

internal enum class PrayerWidgetNumerals(val storage: String) {
    AUTO("auto"), LATIN("latin"), ARABIC("arabic");

    companion object {
        fun fromStorage(raw: String?): PrayerWidgetNumerals =
            values().firstOrNull { it.storage == raw } ?: AUTO
    }
}
