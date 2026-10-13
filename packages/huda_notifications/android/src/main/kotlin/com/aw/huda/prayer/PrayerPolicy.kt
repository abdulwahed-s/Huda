package com.aw.huda.prayer

internal object PrayerRules {
    const val CONTRACT = 1L
    const val LATE_WINDOW_MS = 120_000L
    const val PROTECTED_WINDOW_MS = 120_000L
    const val SHORT_FALLBACK_MS = 30_000L
    const val MAX_DURATION_MS = 3_600_000L
    const val HISTORY_RETENTION_MS = 400L * 24 * 60 * 60 * 1000
    const val MAX_ASSET_BYTES = 8_388_608L
    const val MAX_PRAYERS = 300
    const val TOTAL_QUOTA = 450
    const val HORIZON_DAYS = 60L
    /** Reminders before a prayer: the prayer's ID + this offset (440,000,000–539,999,999). */
    const val ADVANCE_OFFSET = 140_000_000L
    /** Reminders are kept for the next 14 days only, so prayers keep most of the budget. */
    const val ADVANCE_WINDOW_MS = 14L * 86400_000
    const val ADVANCE_RESERVATION = 70L
    val advanceMinutes = listOf(0, 5, 10, 15, 30)
    val prayers = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
    val idPattern = Regex("^[a-z0-9]+(?:-[a-z0-9]+)*$")
    val versionPattern = Regex("^v[1-9][0-9]*$")
    val digestPattern = Regex("^[a-f0-9]{64}$")
    fun prayerId(id: Long) = id in 300_000_000L until 400_000_000L
    fun legacyPrayerId(id: Long) = prayerId(id) || id in 2000L..2599L
    fun advanceId(id: Long) = id + ADVANCE_OFFSET
    fun isAdvanceId(id: Long) = id in 440_000_000L until 540_000_000L
}

internal data class EffectivePolicy(
    val mode: String, val reciterId: String, val version: String, val gain: Double,
    val fadeSeconds: Int, val cutoffSeconds: Int?, val screen: Boolean, val flip: Boolean,
    val vibrate: Boolean, val respectRinger: Boolean, val stopOnNoisy: Boolean,
    val advanceMinutes: Int = 0,
)

internal object PrayerPolicy {
    private val defaults: Map<String, Any?> = linkedMapOf(
        "enabled" to true, "defaultMode" to "full", "reciterId" to "huda-default", "audioVersion" to "v1",
        "volumeGain" to 1.0, "fadeInSeconds" to 0L, "stopAfterSeconds" to null,
        "alarmScreenEnabled" to false, "flipToStopEnabled" to true,
        "respectRingerMode" to true, "respectDoNotDisturb" to true, "vibrate" to true,
        "stopOnHeadsetDisconnect" to true, "showNextPrayer" to true,
        // Ignore the persisted legacy "followUpEnabled" field.
        "showMissedSummary" to false, "followUpEnabled" to false, "localeCode" to "en",
        "advanceMinutes" to 0L, "perPrayer" to emptyMap<String, Any?>(),
    )
    private val overrideKeys = setOf("mode", "reciterId", "audioVersion", "volumeGain", "fadeInSeconds",
        "stopAfterSeconds", "alarmScreenEnabled", "flipToStopEnabled", "vibrate", "advanceMinutes")
    fun initial() = PolicyData(1, 1, defaults)

    fun validate(policy: PolicyData): PolicyData {
        require(policy.schemaVersion == 1L) { "unsupportedContract" }
        require(policy.values.keys.all { it in defaults }) { "invalidPolicy" }
        val values = defaults + policy.values
        require(values["respectDoNotDisturb"] == true) { "invalidPolicy" }
        for ((key, value) in defaults) {
            if (value is Boolean) require(values[key] is Boolean) { "invalidPolicy" }
        }
        require(values["defaultMode"] in listOf("silent", "short", "full")) { "invalidPolicy" }
        require(values["localeCode"] is String && (values["localeCode"] as String).length in 2..16) { "invalidPolicy" }
        require((values["advanceMinutes"] as? Number)?.toDouble()?.let {
            it % 1 == 0.0 && it.toInt() in PrayerRules.advanceMinutes
        } == true) { "invalidPolicy" }
        val perPrayer = values["perPrayer"] as? Map<*, *> ?: error("invalidPolicy")
        require(perPrayer.keys.all { it in PrayerRules.prayers }) { "invalidPolicy" }
        perPrayer.values.forEach { raw ->
            val override = raw as? Map<*, *> ?: error("invalidPolicy")
            require(override.keys.all { it in overrideKeys }) { "invalidPolicy" }
            require(override.values.none { it == null }) { "invalidPolicy" }
            require(override["mode"] == null || override["mode"] in listOf("off", "silent", "short", "full")) { "invalidPolicy" }
            for (key in listOf("alarmScreenEnabled", "flipToStopEnabled", "vibrate")) {
                require(override[key] == null || override[key] is Boolean) { "invalidPolicy" }
            }
        }
        val normalized = PolicyData(1, policy.revision, values)
        PrayerRules.prayers.forEach { effective(normalized, it) }
        return normalized
    }

    @Suppress("UNCHECKED_CAST")
    fun effective(policy: PolicyData, prayer: String): EffectivePolicy {
        require(prayer in PrayerRules.prayers) { "invalidPrayer" }
        val global = policy.values
        val perPrayer = global["perPrayer"] as? Map<String, Map<String, Any?>> ?: emptyMap()
        val override = perPrayer[prayer] ?: emptyMap()
        fun value(key: String) = override[key] ?: global[key]
        fun bool(key: String) = value(key) as Boolean
        fun number(key: String, min: Double, max: Double): Double {
            val number = (value(key) as? Number)?.toDouble() ?: error("invalidPolicy")
            require(number.isFinite() && number in min..max) { "invalidPolicy" }
            return number
        }
        val reciter = value("reciterId") as? String ?: error("invalidPolicy")
        val version = value("audioVersion") as? String ?: error("invalidPolicy")
        require(PrayerRules.idPattern.matches(reciter) && PrayerRules.versionPattern.matches(version)) { "invalidPolicy" }
        val fade = number("fadeInSeconds", 0.0, 30.0)
        require(fade % 1 == 0.0) { "invalidPolicy" }
        val cutoff = value("stopAfterSeconds")?.let {
            val seconds = number("stopAfterSeconds", 1.0, 3600.0)
            require(seconds % 1 == 0.0) { "invalidPolicy" }
            seconds.toInt()
        }
        val advance = number("advanceMinutes", 0.0, 30.0)
        require(advance % 1 == 0.0 && advance.toInt() in PrayerRules.advanceMinutes) { "invalidPolicy" }
        val mode = if (global["enabled"] != true) "off" else override["mode"] as? String
            ?: global["defaultMode"] as String
        return EffectivePolicy(mode, reciter, version, number("volumeGain", 0.0, 1.0), fade.toInt(), cutoff,
            bool("alarmScreenEnabled"), bool("flipToStopEnabled"), bool("vibrate"),
            global["respectRingerMode"] as Boolean, global["stopOnHeadsetDisconnect"] as Boolean, advance.toInt())
    }
    /** Whether any prayer has a reminder before it; reminders then reserve part of the alarm budget. */
    fun advanceActive(policy: PolicyData) = PrayerRules.prayers.any {
        effective(policy, it).let { resolved -> resolved.mode != "off" && resolved.advanceMinutes > 0 }
    }
    fun eligibility(policy: PolicyData) = PrayerRules.prayers.joinToString(",") {
        "$it:${if (effective(policy, it).mode == "off") 0 else 1}"
    }
}
