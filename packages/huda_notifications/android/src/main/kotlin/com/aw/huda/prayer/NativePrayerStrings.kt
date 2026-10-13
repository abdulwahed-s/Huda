package com.aw.huda.prayer

/** App-selected locale, available before unlock (no Flutter strings at alarm time). */
internal data class NativePrayerStrings(val stop: String, val open: String,
    val preparing: String, val playing: String) {
    companion object {
        fun test(locale: String): String = when (locale.substringBefore('-').substringBefore('_')) {
            "ar" -> "اختبار الأذان"
            "fr" -> "Test de l’adhan"
            "de" -> "Adhan-Test"
            "es" -> "Prueba del adhan"
            "tr" -> "Ezan testi"
            "ru" -> "Проверка азана"
            "ur" -> "اذان کی آزمائش"
            "bn" -> "আজান পরীক্ষা"
            "ms" -> "Ujian azan"
            else -> "Adhan test"
        }
        fun labels(locale: String): NativePrayerLabels = when (locale.substringBefore('-').substringBefore('_')) {
            "ar" -> NativePrayerLabels("أوقات الصلاة", "صوت الأذان", "آخر تنبيه صلاة", "معاينة", "قبل الصلاة")
            "fr" -> NativePrayerLabels("Heures de prière", "Son de l’adhan", "Dernière alerte de prière", "Écouter", "Avant la prière")
            "de" -> NativePrayerLabels("Gebetszeiten", "Adhan-Ton", "Letzte Gebetsmeldung", "Anhören", "Vor dem Gebet")
            "es" -> NativePrayerLabels("Horarios de oración", "Sonido del adhan", "Último aviso de oración", "Escuchar", "Antes de la oración")
            "tr" -> NativePrayerLabels("Namaz Vakitleri", "Ezan sesi", "Son namaz bildirimi", "Ön dinleme", "Namazdan önce")
            "ru" -> NativePrayerLabels("Времена намазов", "Звук азана", "Последнее уведомление о молитве", "Прослушать", "Перед молитвой")
            "ur" -> NativePrayerLabels("نماز کے اوقات", "اذان کی آواز", "نماز کی آخری اطلاع", "سن کر دیکھیں", "نماز سے پہلے")
            "bn" -> NativePrayerLabels("নামাজের সময়", "আজানের শব্দ", "নামাজের শেষ বিজ্ঞপ্তি", "শুনে দেখুন", "নামাজের আগে")
            "ms" -> NativePrayerLabels("Waktu Solat", "Bunyi azan", "Peringatan solat terakhir", "Dengar dahulu", "Sebelum solat")
            else -> NativePrayerLabels("Prayer Times", "Adhan sound", "Last prayer alert", "Preview", "Before prayer")
        }
        fun mode(locale: String, mode: String): String {
            val names = when (locale.substringBefore('-').substringBefore('_')) {
                "ar" -> listOf("أذان كامل", "أذان قصير")
                "fr" -> listOf("Adhan complet", "Adhan court")
                "de" -> listOf("Vollständiger Adhan", "Kurzer Adhan")
                "es" -> listOf("Adhan completo", "Adhan corto")
                "tr" -> listOf("Tam ezan", "Kısa ezan")
                "ru" -> listOf("Полный азан", "Короткий азан")
                "ur" -> listOf("مکمل اذان", "مختصر اذان")
                "bn" -> listOf("সম্পূর্ণ আজান", "সংক্ষিপ্ত আজান")
                "ms" -> listOf("Azan penuh", "Azan pendek")
                else -> listOf("Full Adhan", "Short Adhan")
            }
            return names[if (mode == "short") 1 else 0]
        }
        /** The reminder before a prayer: its title and "{prayer} in {minutes} minutes". */
        fun advance(locale: String, prayer: String, minutes: Int): Pair<String, String> {
            val language = locale.substringBefore('-').substringBefore('_')
            val index = PrayerRules.prayers.indexOf(prayer).coerceAtLeast(0)
            // Arabic-script and Bengali locales show their own digits, as Huda does.
            val zero = when (language) { "ar" -> '٠'; "ur" -> '۰'; "bn" -> '০'; else -> '0' }
            val n = minutes.toString().map { zero + (it - '0') }.joinToString("")
            fun name(vararg names: String) = names[index]
            return when (language) {
                "ar" -> "تذكير بالصلاة" to "${name("الفجر", "الظهر", "العصر", "المغرب", "العشاء")} بعد $n ${if (minutes <= 10) "دقائق" else "دقيقة"}"
                "fr" -> "Rappel de prière" to "${name("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")} dans $n minutes"
                "de" -> "Gebetserinnerung" to "${name("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")} in $n Minuten"
                "es" -> "Recordatorio de oración" to "${name("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")} en $n minutos"
                "tr" -> "Namaz hatırlatması" to "${name("Sabah", "Öğle", "İkindi", "Akşam", "Yatsı")} namazına $n dakika kaldı"
                "ru" -> "Напоминание о молитве" to "${name("Фаджр", "Зухр", "Аср", "Магриб", "Иша")} через $n минут"
                "ur" -> "نماز کی یاد دہانی" to "${name("فجر", "ظہر", "عصر", "مغرب", "عشاء")} میں $n منٹ باقی ہیں"
                "bn" -> "নামাজের অনুস্মারক" to "${name("ফজর", "জুহর", "আসর", "মাগরিব", "ইশা")} $n মিনিট পরে"
                "ms" -> "Peringatan solat" to "${name("Subuh", "Zohor", "Asar", "Maghrib", "Isyak")} dalam $n minit"
                else -> "Prayer reminder" to "${name("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")} in $n minutes"
            }
        }
        private val english = NativePrayerStrings("Stop sound", "Open prayer times", "Preparing Adhan", "Playing Adhan")
        fun forLocale(locale: String): NativePrayerStrings = when (locale.substringBefore('-').substringBefore('_')) {
            "ar" -> NativePrayerStrings("إيقاف الصوت", "فتح أوقات الصلاة", "جارٍ تجهيز الأذان", "الأذان قيد التشغيل")
            "fr" -> NativePrayerStrings("Arrêter le son", "Ouvrir les heures de prière", "Préparation de l’adhan", "Lecture de l’adhan")
            "de" -> NativePrayerStrings("Ton stoppen", "Gebetszeiten öffnen", "Adhan wird vorbereitet", "Adhan wird abgespielt")
            "es" -> NativePrayerStrings("Detener sonido", "Abrir horarios de oración", "Preparando el adhan", "Reproduciendo el adhan")
            "tr" -> NativePrayerStrings("Sesi durdur", "Namaz vakitlerini aç", "Ezan hazırlanıyor", "Ezan çalıyor")
            "ru" -> NativePrayerStrings("Остановить звук", "Время молитв", "Подготовка азана", "Воспроизведение азана")
            "ur" -> NativePrayerStrings("آواز بند کریں", "نماز کے اوقات کھولیں", "اذان تیار ہو رہی ہے", "اذان چل رہی ہے")
            "bn" -> NativePrayerStrings("শব্দ বন্ধ করুন", "নামাজের সময় খুলুন", "আজান প্রস্তুত হচ্ছে", "আজান চলছে")
            "ms" -> NativePrayerStrings("Hentikan bunyi", "Buka waktu solat", "Menyediakan azan", "Memainkan azan")
            else -> english
        }
    }
}

internal data class NativePrayerLabels(val prayers: String, val adhan: String,
    val status: String, val preview: String, val before: String)
