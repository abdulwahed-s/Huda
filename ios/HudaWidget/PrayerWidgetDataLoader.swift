import Foundation

enum PrayerWidgetDataLoader {
    private static let appGroupId = "group.hudaHomeApp"

    private static let keyLatitude = "latitude"
    private static let keyLongitude = "longitude"
    private static let keyCountryCode = "country_code"
    private static let keyCalculationMethod = "calculation_method"
    private static let keyMadhab = "madhab"
    private static let keyHighLatitudeRule = "high_latitude_rule"
    private static let keyCustomFajrAngle = "custom_fajr_angle"
    private static let keyCustomMaghribAngle = "custom_maghrib_angle"
    private static let keyCustomIshaAngle = "custom_isha_angle"
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
    private static let keyTimeZoneId = "prayer_time_zone_id"
    private static let keyLocationMode = "prayer_location_mode"
    private static let keyTimeFormat = "prayer_widget_time_format"
    private static let keySettingsPayload = "prayer_widget_settings_v2"

    private static let offsetKeys: [Prayer: String] = [
        .fajr: "prayer_offset_fajr",
        .sunrise: "prayer_offset_sunrise",
        .dhuhr: "prayer_offset_dhuhr",
        .asr: "prayer_offset_asr",
        .maghrib: "prayer_offset_maghrib",
        .isha: "prayer_offset_isha",
    ]

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func loadSettings() -> PrayerWidgetSettings {
        loadSettings(from: sharedDefaults)
    }

    static func loadSettings(from defaults: UserDefaults?) -> PrayerWidgetSettings {
        let payload = settingsPayload(defaults)
        let payloadCoordinates = payload?["coordinates"] as? [String: Any]
        let payloadOffsets = payload?["offsets"] as? [String: Any]
        let payloadAngles = payload?["customAngles"] as? [String: Any]
        let appearance = payload?["appearance"] as? [String: Any]
        let hasPayload = payload != nil

        func string(
            _ payloadValue: Any?,
            legacyKey: String,
            default fallback: String = ""
        ) -> String {
            if hasPayload { return readString(payloadValue) ?? fallback }
            return defaults?.string(forKey: legacyKey) ?? fallback
        }

        func optionalString(_ payloadValue: Any?, legacyKey: String) -> String? {
            if hasPayload { return readString(payloadValue) }
            return defaults?.string(forKey: legacyKey)
        }

        let lat = hasPayload
            ? readDouble(payloadCoordinates?["latitude"])
            : readDouble(defaults, keyLatitude)
        let lon = hasPayload
            ? readDouble(payloadCoordinates?["longitude"])
            : readDouble(defaults, keyLongitude)
        let coordinates: Coordinates? = {
            guard let lat,
                  let lon,
                  lat.isFinite,
                  lon.isFinite,
                  (-90.0 ... 90.0).contains(lat),
                  (-180.0 ... 180.0).contains(lon)
            else { return nil }
            return Coordinates(latitude: lat, longitude: lon)
        }()

        var offsets: [Prayer: Int] = [:]
        for (prayer, key) in offsetKeys {
            let prayerKey = key.replacingOccurrences(of: "prayer_offset_", with: "")
            offsets[prayer] = hasPayload
                ? readInt(payloadOffsets?[prayerKey]) ?? 0
                : defaults?.integer(forKey: key) ?? 0
        }

        return PrayerWidgetSettings(
            coordinates: coordinates,
            offsets: offsets,
            countryCode: string(
                payload?["countryCode"],
                legacyKey: keyCountryCode
            ),
            timeZoneIdentifier: optionalString(
                payload?["timeZoneId"],
                legacyKey: keyTimeZoneId
            ),
            locationMode: string(
                payload?["locationMode"],
                legacyKey: keyLocationMode,
                default: "manual"
            ),
            calculationMethod: string(
                payload?["calculationMethod"],
                legacyKey: keyCalculationMethod,
                default: "auto"
            ),
            madhab: string(
                payload?["madhab"],
                legacyKey: keyMadhab,
                default: "shafi"
            ),
            highLatitudeRule: string(
                payload?["highLatitudeRule"],
                legacyKey: keyHighLatitudeRule,
                default: "automatic"
            ),
            customFajrAngle: readAngle(
                payloadAngles?[keyCustomFajrAngle],
                legacyDefaults: hasPayload ? nil : defaults,
                legacyKey: keyCustomFajrAngle,
                default: 18,
                allowsZero: false
            ),
            customMaghribAngle: readAngle(
                payloadAngles?[keyCustomMaghribAngle],
                legacyDefaults: hasPayload ? nil : defaults,
                legacyKey: keyCustomMaghribAngle,
                default: 0,
                allowsZero: true
            ),
            customIshaAngle: readAngle(
                payloadAngles?[keyCustomIshaAngle],
                legacyDefaults: hasPayload ? nil : defaults,
                legacyKey: keyCustomIshaAngle,
                default: 17,
                allowsZero: false
            ),
            themeName: string(
                appearance?["themeName"],
                legacyKey: keyThemeName,
                default: "teal"
            ),
            themeMode: string(
                appearance?["themeMode"],
                legacyKey: keyThemeMode,
                default: "light"
            ),
            locale: string(
                appearance?["locale"],
                legacyKey: keyLocale,
                default: "en"
            ),
            design: PrayerWidgetDesign(
                rawValue: string(
                    appearance?["design"],
                    legacyKey: keyDesign,
                    default: "hero"
                )
            ) ?? .hero,
            language: string(
                appearance?["language"],
                legacyKey: keyLanguage,
                default: "auto"
            ),
            numerals: PrayerWidgetNumerals(
                rawValue: string(
                    appearance?["numerals"],
                    legacyKey: keyNumerals,
                    default: "auto"
                )
            ) ?? .auto,
            backgroundEnabled: hasPayload
                ? readBool(appearance?["backgroundEnabled"]) ?? true
                : readBool(defaults, keyBgEnabled, default: true),
            backgroundColor: optionalString(
                appearance?["backgroundColor"],
                legacyKey: keyBgColor
            ),
            glassify: hasPayload
                ? readBool(appearance?["glassify"]) ?? false
                : readBool(defaults, keyBgGlassify, default: false),
            rounded: hasPayload
                ? readBool(appearance?["rounded"]) ?? false
                : readBool(defaults, keyBgRounded, default: false),
            contentColor: optionalString(
                appearance?["contentColor"],
                legacyKey: keyContentColor
            ),
            highlightColor: optionalString(
                appearance?["highlightColor"],
                legacyKey: keyHighlightColor
            ),
            contentSize: hasPayload
                ? readInt(appearance?["contentSize"]) ?? 100
                : readInt(defaults, keyContentSize, default: 100),
            timeFormat: PrayerWidgetTimeFormat(
                rawValue: string(
                    payload?["timeFormat"],
                    legacyKey: keyTimeFormat,
                    default: "system"
                )
            ) ?? .system
        )
    }

    private static func settingsPayload(_ defaults: UserDefaults?) -> [String: Any]? {
        guard
            let raw = defaults?.string(forKey: keySettingsPayload),
            let data = raw.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let payload = object as? [String: Any],
            readInt(payload["version"]) == 2,
            readInt(payload["revision"]) != nil,
            readString(payload["committedAt"]) != nil
        else { return nil }
        return payload
    }

    private static func readBool(
        _ defaults: UserDefaults?,
        _ key: String,
        default fallback: Bool
    ) -> Bool {
        guard let defaults else { return fallback }
        if defaults.object(forKey: key) == nil { return fallback }
        return defaults.bool(forKey: key)
    }

    private static func readBool(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let number = value as? NSNumber { return number.boolValue }
        return nil
    }

    private static func readInt(
        _ defaults: UserDefaults?,
        _ key: String,
        default fallback: Int
    ) -> Int {
        guard let defaults else { return fallback }
        if defaults.object(forKey: key) == nil { return fallback }
        return defaults.integer(forKey: key)
    }

    private static func readInt(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func readDouble(
        _ defaults: UserDefaults?,
        _ key: String
    ) -> Double? {
        readDouble(defaults?.object(forKey: key))
    }

    private static func readDouble(_ value: Any?) -> Double? {
        guard let value else { return nil }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func readString(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func readAngle(
        _ value: Any?,
        legacyDefaults defaults: UserDefaults?,
        legacyKey key: String,
        default fallback: Double,
        allowsZero: Bool
    ) -> Double {
        guard let value = readDouble(value) ?? readDouble(defaults, key), value.isFinite else {
            return fallback
        }
        let minimumIsValid = value > 0 || (allowsZero && value == 0)
        return minimumIsValid && value <= 30 ? value : fallback
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

enum PrayerWidgetTimeFormat: String {
    case system
    case twelveHour = "12h"
    case twentyFourHour = "24h"
}

struct PrayerWidgetSettings {
    let coordinates: Coordinates?
    let offsets: [Prayer: Int]
    let countryCode: String
    let timeZoneIdentifier: String?
    let locationMode: String
    let calculationMethod: String
    let madhab: String
    let highLatitudeRule: String
    let customFajrAngle: Double
    let customMaghribAngle: Double
    let customIshaAngle: Double
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
    let timeFormat: PrayerWidgetTimeFormat

    var effectiveLanguage: String {
        if language == "auto" || language.isEmpty {
            return locale
        }
        return language
    }

    var isDarkMode: Bool {
        themeMode == "dark"
    }

    var useArabicNumerals: Bool {
        switch numerals {
        case .arabic:
            true
        case .latin:
            false
        case .auto:
            effectiveLanguage.hasPrefix("ar")
        }
    }

    var displayTimeZone: TimeZone {
        if let identifier = timeZoneIdentifier,
           let timeZone = TimeZone(identifier: identifier)
        {
            return timeZone
        }
        let zonesByCountry = [
            "AE": "Asia/Dubai",
            "BH": "Asia/Bahrain",
            "DE": "Europe/Berlin",
            "EG": "Africa/Cairo",
            "ES": "Europe/Madrid",
            "FR": "Europe/Paris",
            "GB": "Europe/London",
            "ID": "Asia/Jakarta",
            "IN": "Asia/Kolkata",
            "JP": "Asia/Tokyo",
            "KW": "Asia/Kuwait",
            "MY": "Asia/Kuala_Lumpur",
            "NP": "Asia/Kathmandu",
            "OM": "Asia/Muscat",
            "PK": "Asia/Karachi",
            "QA": "Asia/Qatar",
            "SA": "Asia/Riyadh",
            "TR": "Europe/Istanbul",
            "UK": "Europe/London",
        ]
        let key = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let identifier = zonesByCountry[key],
              let timeZone = TimeZone(identifier: identifier)
        else {
            return .current
        }
        return timeZone
    }
}
