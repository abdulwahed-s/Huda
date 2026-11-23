package com.aw.huda.countdown

import android.content.Context
import com.aw.huda.widget.prayer.PrayerWidgetLocalization

internal enum class PrayerCountdownStyle(val storage: String) {
    PROGRESS("progress"), TIMETABLE("timetable"), MINIMAL("minimal");

    companion object {
        fun fromStorage(raw: String?): PrayerCountdownStyle =
            entries.firstOrNull { it.storage == raw } ?: PROGRESS
    }
}

/** What the user chose in Huda. Dart writes these through shared_preferences. */
internal data class PrayerCountdownSettings(
    val enabled: Boolean,
    val style: PrayerCountdownStyle,
    val lockScreen: Boolean,
    val showSunrise: Boolean,
    val liveUpdate: Boolean,
    val language: String,
) {
    companion object {
        private const val PREFIX = "flutter."

        // Kept from the Dart foreground service so upgraders stay on.
        const val ENABLED_KEY = "persistent_prayer_countdown_enabled"
        const val STYLE_KEY = "prayer_countdown_style"
        const val LOCK_SCREEN_KEY = "prayer_countdown_lock_screen"
        const val SHOW_SUNRISE_KEY = "prayer_countdown_show_sunrise"
        const val LIVE_UPDATE_KEY = "prayer_countdown_live_update"
        private const val LOCALE_KEY = "locale"

        fun read(context: Context): PrayerCountdownSettings = fromPrefs(
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).all,
        )

        internal fun fromPrefs(values: Map<String, *>): PrayerCountdownSettings {
            fun bool(key: String, default: Boolean) = values["$PREFIX$key"] as? Boolean ?: default
            return PrayerCountdownSettings(
                enabled = bool(ENABLED_KEY, true),
                style = PrayerCountdownStyle.fromStorage(values["$PREFIX$STYLE_KEY"] as? String),
                lockScreen = bool(LOCK_SCREEN_KEY, true),
                showSunrise = bool(SHOW_SUNRISE_KEY, true),
                liveUpdate = bool(LIVE_UPDATE_KEY, false),
                language = PrayerWidgetLocalization.canonical(
                    (values["$PREFIX$LOCALE_KEY"] as? String)?.ifBlank { null } ?: "en",
                ),
            )
        }
    }
}
