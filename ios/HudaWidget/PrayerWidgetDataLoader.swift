import Foundation

struct PrayerWidgetDataLoader {

    private static let appGroupId = "group.hudaHomeApp"

    private static let keyLatitude = "latitude"
    private static let keyLongitude = "longitude"
    private static let keyCountryCode = "country_code"
    private static let keyCalculationMethod = "calculation_method"
    private static let keyMadhab = "madhab"
    private static let keyHighLatitudeRule = "high_latitude_rule"
    private static let keyThemeName = "themeName"
    private static let keyThemeMode = "themeMode"
    private static let keyLocale = "locale"
    private static let keyDesign = "prayerWidgetDesign"
    private static let keyLanguage = "prayerWidgetLanguage"
    private static let keyNumerals = "prayerWidgetNumerals"
    private static let keyBgEnabled = "prayerWidgetBgEnabled"
    private static let keyBgColor = "prayerWidgetBgColor"
    private static let keyBgGlassify = "prayerWidgetBgGlassify"
    private static let keyBgRounded = "prayerWidgetBgRounded"
    private static let keyContentColor = "prayerWidgetContentColor"
    private static let keyHighlightColor = "prayerWidgetHighlightColor"
    private static let keyContentSize = "prayerWidgetContentSize"

    private static let offsetKeys: [Prayer: String] = [
        .fajr: "prayer_offset_fajr",
        .sunrise: "prayer_offset_sunrise",
        .dhuhr: "prayer_offset_dhuhr",
        .asr: "prayer_offset_asr",
        .maghrib: "prayer_offset_maghrib",
        .isha: "prayer_offset_isha"
    ]

    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }

    static func loadSettings() -> PrayerWidgetSettings {
        let defaults = sharedDefaults

        let latString = defaults?.string(forKey: keyLatitude)
        let lonString = defaults?.string(forKey: keyLongitude)
        let lat = latString.flatMap(Double.init)
        let lon = lonString.flatMap(Double.init)
        let coordinates: Coordinates? = {
            guard let lat = lat, let lon = lon else { return nil }
            return Coordinates(latitude: lat, longitude: lon)
        }()

        var offsets: [Prayer: Int] = [:]
        for (prayer, key) in offsetKeys {
            offsets[prayer] = defaults?.integer(forKey: key) ?? 0
        }

        return PrayerWidgetSettings(
            coordinates: coordinates,
            offsets: offsets,
            countryCode: defaults?.string(forKey: keyCountryCode) ?? "",
            calculationMethod: defaults?.string(forKey: keyCalculationMethod) ?? "auto",
            madhab: defaults?.string(forKey: keyMadhab) ?? "shafi",
            highLatitudeRule: defaults?.string(forKey: keyHighLatitudeRule) ?? "automatic",
            themeName: defaults?.string(forKey: keyThemeName) ?? "purple",
            themeMode: defaults?.string(forKey: keyThemeMode) ?? "light",
            locale: defaults?.string(forKey: keyLocale) ?? "en",
            design: PrayerWidgetDesign(
                rawValue: defaults?.string(forKey: keyDesign) ?? "hero"
            ) ?? .hero,
            language: defaults?.string(forKey: keyLanguage) ?? "auto",
            numerals: PrayerWidgetNumerals(
                rawValue: defaults?.string(forKey: keyNumerals) ?? "auto"
            ) ?? .auto,
            backgroundEnabled: readBool(defaults, keyBgEnabled, default: true),
            backgroundColor: defaults?.string(forKey: keyBgColor),
            glassify: readBool(defaults, keyBgGlassify, default: false),
            rounded: readBool(defaults, keyBgRounded, default: false),
            contentColor: defaults?.string(forKey: keyContentColor),
            highlightColor: defaults?.string(forKey: keyHighlightColor),
            contentSize: readInt(defaults, keyContentSize, default: 100)
        )
    }

    private static func readBool(
        _ defaults: UserDefaults?,
        _ key: String,
        default fallback: Bool
    ) -> Bool {
        guard let defaults = defaults else { return fallback }
        if defaults.object(forKey: key) == nil { return fallback }
        return defaults.bool(forKey: key)
    }

    private static func readInt(
        _ defaults: UserDefaults?,
        _ key: String,
        default fallback: Int
    ) -> Int {
        guard let defaults = defaults else { return fallback }
        if defaults.object(forKey: key) == nil { return fallback }
        return defaults.integer(forKey: key)
    }
}

enum PrayerWidgetDesign: String {
    case hero
    case compact
}

enum PrayerWidgetNumerals: String {
    case auto
    case latin
    case arabic
}

struct PrayerWidgetSettings {
    let coordinates: Coordinates?
    let offsets: [Prayer: Int]
    let countryCode: String
    let calculationMethod: String
    let madhab: String
    let highLatitudeRule: String
    let themeName: String
    let themeMode: String
    let locale: String
    let design: PrayerWidgetDesign
    let language: String
    let numerals: PrayerWidgetNumerals
    let backgroundEnabled: Bool
    let backgroundColor: String?
    let glassify: Bool
    let rounded: Bool
    let contentColor: String?
    let highlightColor: String?
    let contentSize: Int

    var effectiveLanguage: String {
        if language == "auto" || language.isEmpty {
            return locale
        }
        return language
    }

    var isDarkMode: Bool {
        return themeMode == "dark"
    }

    var useArabicNumerals: Bool {
        switch numerals {
        case .arabic:
            return true
        case .latin:
            return false
        case .auto:
            return effectiveLanguage.hasPrefix("ar")
        }
    }

    var displayTimeZone: TimeZone {
        let zonesByCountry = [
            "AE": "Asia/Dubai",
            "BH": "Asia/Bahrain",
            "DE": "Europe/Berlin",
            "EG": "Africa/Cairo",
            "ES": "Europe/Madrid",
            "FR": "Europe/Paris",
            "GB": "Europe/London",
            "ID": "Asia/Jakarta",
            "KW": "Asia/Kuwait",
            "MY": "Asia/Kuala_Lumpur",
            "OM": "Asia/Muscat",
            "PK": "Asia/Karachi",
            "QA": "Asia/Qatar",
            "SA": "Asia/Riyadh",
            "TR": "Europe/Istanbul",
            "UK": "Europe/London"
        ]
        let key = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let identifier = zonesByCountry[key],
              let timeZone = TimeZone(identifier: identifier) else {
            return .current
        }
        return timeZone
    }
}
