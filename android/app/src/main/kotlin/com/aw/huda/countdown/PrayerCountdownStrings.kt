package com.aw.huda.countdown

import com.aw.huda.widget.prayer.PrayerWidgetLocalization

/** Text the countdown shows while Huda is closed, in Huda's 10 languages. */
internal object PrayerCountdownStrings {
    private val translations: Map<String, Map<String, String>> = mapOf(
        "channel" to mapOf(
            "en" to "Prayer countdown", "ar" to "العد التنازلي للصلاة",
            "tr" to "Namaz geri sayımı", "fr" to "Compte à rebours des prières",
            "es" to "Cuenta regresiva de oración", "de" to "Gebets-Countdown",
            "ru" to "Обратный отсчёт до намаза", "ur" to "نماز کی الٹی گنتی",
            "ms" to "Kira detik solat", "bn" to "নামাজের কাউন্টডাউন",
        ),
        "channel_description" to mapOf(
            "en" to "The ongoing countdown to the next prayer",
            "ar" to "العد المستمر حتى الصلاة القادمة",
            "tr" to "Sonraki namaza kalan süre",
            "fr" to "Le compte à rebours jusqu'à la prochaine prière",
            "es" to "La cuenta regresiva hasta la próxima oración",
            "de" to "Countdown bis zum nächsten Gebet",
            "ru" to "Отсчёт до следующего намаза",
            "ur" to "اگلی نماز تک کی گنتی",
            "ms" to "Kira detik ke solat seterusnya",
            "bn" to "পরবর্তী নামাজ পর্যন্ত কাউন্টডাউন",
        ),
        // Chronometer formats: %s is the ticking time.
        "in_format" to mapOf(
            "en" to "{prayer} in %s", "ar" to "{prayer} بعد %s", "tr" to "{prayer} vaktine %s",
            "fr" to "{prayer} dans %s", "es" to "{prayer} en %s", "de" to "{prayer} in %s",
            "ru" to "{prayer} через %s", "ur" to "{prayer} تک %s", "ms" to "{prayer} dalam %s",
            "bn" to "{prayer} %s পরে",
        ),
        "started_ago_format" to mapOf(
            "en" to "{prayer} started %s ago", "ar" to "دخل وقت {prayer} منذ %s",
            "tr" to "{prayer} %s önce başladı", "fr" to "{prayer} a commencé il y a %s",
            "es" to "{prayer} empezó hace %s", "de" to "{prayer} begann vor %s",
            "ru" to "{prayer} начался %s назад", "ur" to "{prayer} کا وقت %s پہلے شروع ہوا",
            "ms" to "{prayer} bermula %s lalu", "bn" to "{prayer} শুরু হয়েছে %s আগে",
        ),
        // Titles when Android's header and status-bar chip show the timer.
        "at_format" to mapOf(
            "en" to "{prayer} at {time}", "ar" to "{prayer} الساعة {time}", "tr" to "{prayer} {time}",
            "fr" to "{prayer} à {time}", "es" to "{prayer} a las {time}", "de" to "{prayer} um {time}",
            "ru" to "{prayer} в {time}", "ur" to "{prayer} {time} بجے", "ms" to "{prayer} pada {time}",
            "bn" to "{prayer} {time}-এ",
        ),
        "started_at_format" to mapOf(
            "en" to "{prayer} started at {time}", "ar" to "دخل وقت {prayer} الساعة {time}",
            "tr" to "{prayer} {time} itibarıyla başladı", "fr" to "{prayer} a commencé à {time}",
            "es" to "{prayer} empezó a las {time}", "de" to "{prayer} begann um {time}",
            "ru" to "{prayer} начался в {time}", "ur" to "{prayer} {time} بجے شروع ہوا",
            "ms" to "{prayer} bermula pada {time}", "bn" to "{prayer} {time}-এ শুরু হয়েছে",
        ),
        "prayer_times" to mapOf(
            "en" to "Prayer times", "ar" to "مواقيت الصلاة", "tr" to "Namaz vakitleri",
            "fr" to "Horaires de prière", "es" to "Horarios de oración",
            "de" to "Gebetszeiten", "ru" to "Время намаза", "ur" to "نماز کے اوقات",
            "ms" to "Waktu solat", "bn" to "নামাজের সময়",
        ),
    )

    /** "Asr in %s" for a Chronometer, or "Asr at 3:19 PM" with [time]. */
    fun phrase(key: String, language: String, prayer: String, time: String? = null): String {
        val text = string(key, language).replace("{prayer}", prayer.replace("%", "%%"))
        return if (time == null) text else text.replace("{time}", time)
    }

    fun string(key: String, language: String): String {
        val lang = PrayerWidgetLocalization.canonical(language)
        return translations[key]?.let { it[lang] ?: it["en"] }
            ?: PrayerWidgetLocalization.string(key, lang)
    }
}
