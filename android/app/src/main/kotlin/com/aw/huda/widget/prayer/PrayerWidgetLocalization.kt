package com.aw.huda.widget.prayer

import java.text.DateFormatSymbols
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

internal object PrayerWidgetLocalization {
    val supported: Set<String> = setOf(
        "en", "ar", "tr", "fr", "es", "de", "ru", "ur", "ms", "bn",
    )

    private val translations: Map<String, Map<String, String>> = mapOf(
        "fajr" to mapOf(
            "en" to "Fajr", "ar" to "الفجر", "tr" to "İmsak", "fr" to "Fajr",
            "es" to "Fajr", "de" to "Fadschr", "ru" to "Фаджр", "ur" to "فجر",
            "ms" to "Subuh", "bn" to "ফজর",
        ),
        "sunrise" to mapOf(
            "en" to "Sunrise", "ar" to "الشروق", "tr" to "Güneş",
            "fr" to "Lever du soleil", "es" to "Amanecer",
            "de" to "Sonnenaufgang", "ru" to "Восход", "ur" to "طلوع",
            "ms" to "Syuruk", "bn" to "সূর্যোদয়",
        ),
        "dhuhr" to mapOf(
            "en" to "Dhuhr", "ar" to "الظهر", "tr" to "Öğle", "fr" to "Dhouhr",
            "es" to "Dhuhr", "de" to "Dhuhr", "ru" to "Зухр", "ur" to "ظہر",
            "ms" to "Zohor", "bn" to "যোহর",
        ),
        "asr" to mapOf(
            "en" to "Asr", "ar" to "العصر", "tr" to "İkindi", "fr" to "Asr",
            "es" to "Asr", "de" to "Asr", "ru" to "Аср", "ur" to "عصر",
            "ms" to "Asar", "bn" to "আসর",
        ),
        "maghrib" to mapOf(
            "en" to "Maghrib", "ar" to "المغرب", "tr" to "Akşam",
            "fr" to "Maghrib", "es" to "Magrib", "de" to "Maghrib",
            "ru" to "Магриб", "ur" to "مغرب", "ms" to "Maghrib",
            "bn" to "মাগরিব",
        ),
        "isha" to mapOf(
            "en" to "Isha", "ar" to "العشاء", "tr" to "Yatsı",
            "fr" to "Icha", "es" to "Isha", "de" to "Ischa",
            "ru" to "Иша", "ur" to "عشاء", "ms" to "Isyak",
            "bn" to "ইশা",
        ),
        "next_prayer" to mapOf(
            "en" to "Next prayer", "ar" to "الصلاة القادمة",
            "tr" to "Sonraki namaz", "fr" to "Prochaine prière",
            "es" to "Próxima oración", "de" to "Nächstes Gebet",
            "ru" to "Следующая молитва", "ur" to "اگلی نماز",
            "ms" to "Solat seterusnya", "bn" to "পরবর্তী নামাজ",
        ),
        "previous_prayer" to mapOf(
            "en" to "Previous", "ar" to "السابقة", "tr" to "Önceki",
            "fr" to "Précédent", "es" to "Anterior", "de" to "Vorherig",
            "ru" to "Предыдущая", "ur" to "پچھلی", "ms" to "Sebelum",
            "bn" to "পূর্ববর্তী",
        ),
        "in_word" to mapOf(
            "en" to "in", "ar" to "خلال", "tr" to "içinde", "fr" to "dans",
            "es" to "en", "de" to "in", "ru" to "через", "ur" to "میں",
            "ms" to "dalam", "bn" to "এ",
        ),
        "remaining_until" to mapOf(
            "en" to "Remaining until", "ar" to "باقي على",
            "tr" to "Kalan süre", "fr" to "Restant avant",
            "es" to "Queda para", "de" to "Verbleibend bis",
            "ru" to "Осталось до", "ur" to "باقی ہے",
            "ms" to "Baki hingga", "bn" to "বাকি আছে",
        ),
        "last_third_night" to mapOf(
            "en" to "Last third", "ar" to "الثلث الأخير",
            "tr" to "Son üçte bir", "fr" to "Dernier tiers",
            "es" to "Último tercio", "de" to "Letztes Drittel",
            "ru" to "Последняя треть", "ur" to "آخری تہائی",
            "ms" to "Sepertiga akhir", "bn" to "শেষ তৃতীয়াংশ",
        ),
        "middle_of_night" to mapOf(
            "en" to "Midnight", "ar" to "منتصف الليل",
            "tr" to "Gece yarısı", "fr" to "Minuit",
            "es" to "Medianoche", "de" to "Mitternacht",
            "ru" to "Полночь", "ur" to "آدھی رات",
            "ms" to "Tengah malam", "bn" to "মধ্যরাত",
        ),
        "empty_message" to mapOf(
            "en" to "Open the Prayer Time page to set your location",
            "ar" to "افتح صفحة مواقيت الصلاة لتحديد موقعك",
            "tr" to "Konumunuzu ayarlamak için Namaz Vakitleri sayfasını açın",
            "fr" to "Ouvrez la page des horaires de prière pour définir votre position",
            "es" to "Abre la página de horarios de oración para establecer tu ubicación",
            "de" to "Öffnen Sie die Gebetszeiten-Seite, um Ihren Standort festzulegen",
            "ru" to "Откройте страницу времён молитв, чтобы указать местоположение",
            "ur" to "اپنا مقام مقرر کرنے کے لیے نماز کے اوقات کا صفحہ کھولیں",
            "ms" to "Buka halaman Waktu Solat untuk menetapkan lokasi anda",
            "bn" to "আপনার অবস্থান সেট করতে নামাজের সময় পৃষ্ঠা খুলুন",
        ),

        "unit_hour_short" to mapOf(
            "en" to "h", "ar" to "س", "tr" to "sa", "fr" to "h",
            "es" to "h", "de" to "Std.", "ru" to "ч", "ur" to "گھ",
            "ms" to "j", "bn" to "ঘ",
        ),
        "unit_minute_short" to mapOf(
            "en" to "m", "ar" to "د", "tr" to "dk", "fr" to "m",
            "es" to "m", "de" to "Min.", "ru" to "м", "ur" to "م",
            "ms" to "m", "bn" to "মি",
        ),
    )

    fun canonical(language: String): String {
        val lower = language.lowercase(Locale.ROOT)
        if (supported.contains(lower)) return lower
        val prefix = lower.take(2)
        if (supported.contains(prefix)) return prefix
        return "en"
    }

    fun string(key: String, language: String): String {
        val lang = canonical(language)
        return translations[key]?.get(lang)
            ?: translations[key]?.get("en")
            ?: key
    }

    fun prayerName(kind: PrayerKind, language: String): String {
        val key = when (kind) {
            PrayerKind.FAJR -> "fajr"
            PrayerKind.SUNRISE -> "sunrise"
            PrayerKind.DHUHR -> "dhuhr"
            PrayerKind.ASR -> "asr"
            PrayerKind.MAGHRIB -> "maghrib"
            PrayerKind.ISHA -> "isha"
        }
        return string(key, language)
    }

    fun isRTL(language: String): Boolean {
        val lang = canonical(language)
        return lang == "ar" || lang == "ur"
    }
}

internal object PrayerTimeFormatter {
    fun format(
        date: Date,
        useArabicNumerals: Boolean,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): String {
        val cal = Calendar.getInstance(timeZone).apply { time = date }
        val h = cal.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')
        val m = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
        return "$h:$m".applyNumerals(useArabicNumerals)
    }

    fun format12(
        date: Date,
        useArabicNumerals: Boolean,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): String {
        val cal = Calendar.getInstance(timeZone).apply { time = date }
        val h24 = cal.get(Calendar.HOUR_OF_DAY)
        val h12 = if (h24 == 0) 12 else if (h24 > 12) h24 - 12 else h24
        val m = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
        return "$h12:$m".applyNumerals(useArabicNumerals)
    }

    fun format12WithMeridiem(
        date: Date,
        useArabicNumerals: Boolean,
        languageCode: String,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): String {
        val cal = Calendar.getInstance(timeZone).apply { time = date }
        val h24 = cal.get(Calendar.HOUR_OF_DAY)
        val h12 = if (h24 == 0) 12 else if (h24 > 12) h24 - 12 else h24
        val m = cal.get(Calendar.MINUTE).toString().padStart(2, '0')

        val markerLocale = if (useArabicNumerals) Locale.forLanguageTag("ar")
            else Locale.forLanguageTag(languageCode)
        val ampm = DateFormatSymbols.getInstance(markerLocale).amPmStrings[
            if (h24 < 12) Calendar.AM else Calendar.PM
        ]
        return "$h12:$m $ampm".applyNumerals(useArabicNumerals)
    }

    fun formatISODate(
        date: Date,
        useArabicNumerals: Boolean,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        sdf.timeZone = timeZone
        return sdf.format(date).applyNumerals(useArabicNumerals)
    }

    fun formatDayOfWeek(
        date: Date,
        languageCode: String,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): String {
        val locale = Locale.forLanguageTag(languageCode)
        val sdf = SimpleDateFormat("EEEE", locale)
        sdf.timeZone = timeZone
        return sdf.format(date)
    }

    fun formatCompactRelative(
        from: Date,
        to: Date,
        useArabicNumerals: Boolean,
        languageCode: String,
    ): String {
        val diffMillis = (to.time - from.time).coerceAtLeast(0L)
        val totalMinutes = TimeUnit.MILLISECONDS.toMinutes(diffMillis)
        val hours = (totalMinutes / 60).toInt()
        val minutes = (totalMinutes % 60).toInt()

        val hUnit = PrayerWidgetLocalization.string("unit_hour_short", languageCode)
        val mUnit = PrayerWidgetLocalization.string("unit_minute_short", languageCode)
        val raw = if (hours > 0) "${hours}$hUnit ${minutes}$mUnit"
            else if (minutes > 0) "${minutes}$mUnit"
            else "0$mUnit"
        return raw.applyNumerals(useArabicNumerals)
    }

    fun formatHHMMRoundedUp(
        from: Date,
        to: Date,
        useArabicNumerals: Boolean,
    ): String {
        val intervalSecs = ((to.time - from.time).coerceAtLeast(0L) / 1000.0)
        val totalMinutes = Math.ceil(intervalSecs / 60.0).toInt()
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        val raw = "${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}"
        return raw.applyNumerals(useArabicNumerals)
    }
}

internal fun String.applyNumerals(useArabicNumerals: Boolean): String {
    if (!useArabicNumerals) return this
    val sb = StringBuilder(length)
    for (c in this) {
        sb.append(when (c) {
            '0' -> '٠'; '1' -> '١'; '2' -> '٢'; '3' -> '٣'; '4' -> '٤'
            '5' -> '٥'; '6' -> '٦'; '7' -> '٧'; '8' -> '٨'; '9' -> '٩'
            else -> c
        })
    }
    return sb.toString()
}

internal object ArabicTatweel {
    private val connectors: Set<Char> = setOf(
        'ب', 'ت', 'ث', 'ج', 'ح', 'خ',
        'س', 'ش', 'ص', 'ض', 'ط', 'ظ',
        'ع', 'غ', 'ف', 'ق', 'ك', 'ل',
        'م', 'ن', 'ه', 'ي', 'ئ', 'ـ',
    )

    fun elongate(text: String, count: Int): String {
        if (count <= 0 || text.isEmpty()) return text
        val sb = StringBuilder(text.length + count * 4)
        val chars = text.toCharArray()
        for (i in chars.indices) {
            sb.append(chars[i])
            if (i + 1 < chars.size) {
                val next = chars[i + 1]
                if (connectors.contains(chars[i]) && next.isLetter()) {
                    repeat(count) { sb.append('ـ') }
                }
            }
        }
        return sb.toString()
    }
}
