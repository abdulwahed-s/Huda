import Foundation

struct PrayerWidgetLocalization {

    static let supportedLanguages = [
        "en", "ar", "tr", "fr", "es", "de", "ru", "ur", "ms", "bn"
    ]

    private static let translations: [String: [String: String]] = [
        "fajr": [
            "en": "Fajr", "ar": "الفجر", "tr": "İmsak", "fr": "Fajr",
            "es": "Fajr", "de": "Fadschr", "ru": "Фаджр", "ur": "فجر",
            "ms": "Subuh", "bn": "ফজর"
        ],
        "sunrise": [
            "en": "Sunrise", "ar": "الشروق", "tr": "Güneş", "fr": "Lever du soleil",
            "es": "Amanecer", "de": "Sonnenaufgang", "ru": "Восход", "ur": "طلوع",
            "ms": "Syuruk", "bn": "সূর্যোদয়"
        ],
        "dhuhr": [
            "en": "Dhuhr", "ar": "الظهر", "tr": "Öğle", "fr": "Dhouhr",
            "es": "Dhuhr", "de": "Dhuhr", "ru": "Зухр", "ur": "ظہر",
            "ms": "Zohor", "bn": "যোহর"
        ],
        "asr": [
            "en": "Asr", "ar": "العصر", "tr": "İkindi", "fr": "Asr",
            "es": "Asr", "de": "Asr", "ru": "Аср", "ur": "عصر",
            "ms": "Asar", "bn": "আসর"
        ],
        "maghrib": [
            "en": "Maghrib", "ar": "المغرب", "tr": "Akşam", "fr": "Maghrib",
            "es": "Magrib", "de": "Maghrib", "ru": "Магриб", "ur": "مغرب",
            "ms": "Maghrib", "bn": "মাগরিব"
        ],
        "isha": [
            "en": "Isha", "ar": "العشاء", "tr": "Yatsı", "fr": "Icha",
            "es": "Isha", "de": "Ischa", "ru": "Иша", "ur": "عشاء",
            "ms": "Isyak", "bn": "ইশা"
        ],
        "next_prayer": [
            "en": "Next prayer", "ar": "الصلاة القادمة", "tr": "Sonraki namaz",
            "fr": "Prochaine prière", "es": "Próxima oración", "de": "Nächstes Gebet",
            "ru": "Следующая молитва", "ur": "اگلی نماز", "ms": "Solat seterusnya",
            "bn": "পরবর্তী নামাজ"
        ],
        "previous_prayer": [
            "en": "Previous", "ar": "السابقة", "tr": "Önceki",
            "fr": "Précédent", "es": "Anterior", "de": "Vorherig",
            "ru": "Предыдущая", "ur": "پچھلی", "ms": "Sebelum",
            "bn": "পূর্ববর্তী"
        ],
        "in_word": [
            "en": "in", "ar": "خلال", "tr": "içinde",
            "fr": "dans", "es": "en", "de": "in",
            "ru": "через", "ur": "میں", "ms": "dalam",
            "bn": "এ"
        ],
        "remaining_until": [
            "en": "Remaining until",
            "ar": "باقي على",
            "tr": "Kalan süre",
            "fr": "Restant avant",
            "es": "Queda para",
            "de": "Verbleibend bis",
            "ru": "Осталось до",
            "ur": "باقی ہے",
            "ms": "Baki hingga",
            "bn": "বাকি আছে"
        ],
        "last_third_night": [
            "en": "Last third",
            "ar": "الثلث الأخير",
            "tr": "Son üçte bir",
            "fr": "Dernier tiers",
            "es": "Último tercio",
            "de": "Letztes Drittel",
            "ru": "Последняя треть",
            "ur": "آخری تہائی",
            "ms": "Sepertiga akhir",
            "bn": "শেষ তৃতীয়াংশ"
        ],
        "middle_of_night": [
            "en": "Midnight",
            "ar": "منتصف الليل",
            "tr": "Gece yarısı",
            "fr": "Minuit",
            "es": "Medianoche",
            "de": "Mitternacht",
            "ru": "Полночь",
            "ur": "آدھی رات",
            "ms": "Tengah malam",
            "bn": "মধ্যরাত"
        ],
        "empty_message": [
            "en": "Open the Prayer Time page to set your location",
            "ar": "افتح صفحة مواقيت الصلاة لتحديد موقعك",
            "tr": "Konumunuzu ayarlamak için Namaz Vakitleri sayfasını açın",
            "fr": "Ouvrez la page des horaires de prière pour définir votre position",
            "es": "Abre la página de horarios de oración para establecer tu ubicación",
            "de": "Öffnen Sie die Gebetszeiten-Seite, um Ihren Standort festzulegen",
            "ru": "Откройте страницу времён молитв, чтобы указать местоположение",
            "ur": "اپنا مقام مقرر کرنے کے لیے نماز کے اوقات کا صفحہ کھولیں",
            "ms": "Buka halaman Waktu Solat untuk menetapkan lokasi anda",
            "bn": "আপনার অবস্থান সেট করতে নামাজের সময় পৃষ্ঠা খুলুন"
        ]
    ]

    static func string(_ key: String, language: String) -> String {
        let lang = canonical(language)
        if let value = translations[key]?[lang] {
            return value
        }
        return translations[key]?["en"] ?? key
    }

    static func prayerName(_ prayer: Prayer, language: String) -> String {
        let key: String
        switch prayer {
        case .fajr: key = "fajr"
        case .sunrise: key = "sunrise"
        case .dhuhr: key = "dhuhr"
        case .asr: key = "asr"
        case .maghrib: key = "maghrib"
        case .isha: key = "isha"
        }
        return string(key, language: language)
    }

    private static func canonical(_ language: String) -> String {
        let lower = language.lowercased()
        if supportedLanguages.contains(lower) { return lower }
        let prefix = String(lower.prefix(2))
        if supportedLanguages.contains(prefix) { return prefix }
        return "en"
    }

    static func canonicalKey(_ language: String) -> String {
        return canonical(language)
    }

    static func isRTL(language: String) -> Bool {
        let lang = canonical(language)
        return lang == "ar" || lang == "ur"
    }
}

struct PrayerTimeFormatter {

    static func format(
        _ date: Date,
        useArabicNumerals: Bool,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        formatter.locale = useArabicNumerals
            ? Locale(identifier: "ar")
            : Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    static func format12(
        _ date: Date,
        useArabicNumerals: Bool,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm"
        formatter.locale = useArabicNumerals
            ? Locale(identifier: "ar")
            : Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    static func format12WithMeridiem(
        _ date: Date,
        useArabicNumerals: Bool,
        languageCode: String,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        if useArabicNumerals {
            formatter.locale = Locale(identifier: "ar")
        } else {
            formatter.locale = Locale(identifier: languageCode)
        }
        return formatter.string(from: date)
    }

    static func formatISODate(
        _ date: Date,
        useArabicNumerals: Bool,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = useArabicNumerals
            ? Locale(identifier: "ar")
            : Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    static func formatDayOfWeek(
        _ date: Date,
        languageCode: String,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: languageCode)
        return formatter.string(from: date)
    }

    static func formatCompactRelative(
        from start: Date,
        to end: Date,
        useArabicNumerals: Bool,
        languageCode: String
    ) -> String {
        let interval = max(0, end.timeIntervalSince(start))
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .dropLeading
        formatter.maximumUnitCount = 2

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(
            identifier: useArabicNumerals ? "ar" : languageCode
        )
        formatter.calendar = calendar

        if let rendered = formatter.string(from: interval), !rendered.isEmpty {
            return rendered
        }
        let minutes = Int(interval / 60)
        let fallback = DateComponentsFormatter()
        fallback.unitsStyle = .abbreviated
        fallback.allowedUnits = [.minute]
        fallback.calendar = calendar
        return fallback.string(from: TimeInterval(minutes * 60)) ?? ""
    }
}
