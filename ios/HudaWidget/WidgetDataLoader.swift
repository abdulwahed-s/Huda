import Foundation
import SwiftUI

enum QuranWidgetSize: String, Codable {
    case small
    case medium
    case large
}

struct QuranWidgetVerse: Codable {
    let id: String
    let surah: Int
    let ayah: Int
    let widgetSizes: Set<QuranWidgetSize>
    let arabic: String
    let translations: [String: String]
}

struct QuranWidgetSurah: Codable {
    let displayNames: [String: String]
}

struct QuranWidgetPalette {
    let background: Color
    let surface: Color
    let ayah: Color
    let translation: Color
    let accent: Color
    let ornament: Color
    let isLight: Bool
}

struct QuranWidgetSnapshot {
    let verse: QuranWidgetVerse
    let translation: String?
    let translationLanguage: String?
    let translationSource: String?
    let displayReference: String
    let appLanguage: String
    let palette: QuranWidgetPalette
    let ayahTextScale: CGFloat
    let translationTextScale: CGFloat
    let ayahAutoFit: Bool
    let translationAutoFit: Bool
    let ayahBold: Bool
    let translationBold: Bool
}

struct WidgetDataLoader {
    private static let appGroupId = "group.hudaHomeApp"
    private static let supportedLanguages = Set(["en", "tr", "fr", "de", "es", "ur", "ru", "ms", "bn"])

    private struct TranslationSource: Codable { let name: String }
    private struct Catalog: Codable {
        let surahs: [String: QuranWidgetSurah]?
        let sources: [String: TranslationSource]
        let verses: [QuranWidgetVerse]
    }

    private static let fallbackVerse = QuranWidgetVerse(
        id: "94:6",
        surah: 94,
        ayah: 6,
        widgetSizes: [.small, .medium, .large],
        arabic: "إِنَّ مَعَ ٱلۡعُسۡرِ يُسۡرٗا",
        translations: [
            "en": "Indeed, with hardship [will be] ease.",
            "tr": "Gerçekten, güçlükle beraber bir kolaylık vardır.",
            "fr": "A côté de la difficulté est, certes, une facilité!",
            "de": "gewiß, mit der Erschwernis ist Erleichterung.",
            "es": "¡La adversidad y la felicidad van a una!",
            "ur": "(اور) بے شک مشکل کے ساتھ آسانی ہے",
            "ru": "За каждой тягостью наступает облегчение.",
            "ms": "(Sekali lagi ditegaskan): bahawa sesungguhnya tiap-tiap kesukaran disertai kemudahan.",
            "bn": "নিশ্চয় কষ্টের সাথে স্বস্তি রয়েছে।",
        ]
    )

    private static let catalog: Catalog? = {
        guard let url = Bundle.main.url(forResource: "quran_widget_verses", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

    static func snapshot(
        at date: Date = Date(),
        size: QuranWidgetSize
    ) -> QuranWidgetSnapshot {
        let data = catalog
        let catalogVerses = data?.verses.isEmpty == false ? data!.verses : [fallbackVerse]
        let eligibleVerses = catalogVerses.filter { $0.widgetSizes.contains(size) }
        let verses = eligibleVerses.isEmpty ? [fallbackVerse] : eligibleVerses
        let hour = Int64(floor(date.timeIntervalSince1970 / 3600))
        let offset = Int64(defaults?.integer(forKey: "quranWidgetRotationOffset") ?? 0)
        let rawIndex = (hour + offset) % Int64(verses.count)
        let index = Int(rawIndex >= 0 ? rawIndex : rawIndex + Int64(verses.count))
        let verse = verses[index]
        let language = resolvedLanguage()
        let appLanguage = resolvedAppLanguage()
        let surahName =
            data?.surahs?[String(verse.surah)]?.displayNames[appLanguage]
            ?? data?.surahs?[String(verse.surah)]?.displayNames["en"]
        let reference =
            surahName.flatMap { $0.isEmpty ? nil : "\($0) • \(verse.ayah)" }
            ?? "\(verse.surah):\(verse.ayah)"
        return QuranWidgetSnapshot(
            verse: verse,
            translation: language.flatMap { verse.translations[$0] },
            translationLanguage: language,
            translationSource: language.flatMap { data?.sources[$0]?.name },
            displayReference: reference,
            appLanguage: appLanguage,
            palette: resolvedPalette(),
            ayahTextScale: textScale(forKey: "quranWidgetAyahTextSize"),
            translationTextScale: textScale(forKey: "quranWidgetTranslationTextSize"),
            ayahAutoFit: boolValue(forKey: "quranWidgetAyahAutoFit", defaultValue: true),
            translationAutoFit: boolValue(forKey: "quranWidgetTranslationAutoFit", defaultValue: true),
            ayahBold: defaults?.bool(forKey: "quranWidgetAyahBold") ?? false,
            translationBold: defaults?.bool(forKey: "quranWidgetTranslationBold") ?? false
        )
    }

    private static func textScale(forKey key: String) -> CGFloat {
        let storedValue = defaults?.integer(forKey: key) ?? 0
        let percentage = storedValue == 0 ? 100 : min(max(storedValue, 70), 140)
        return CGFloat(percentage) / 100
    }

    private static func boolValue(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults?.object(forKey: key) != nil else { return defaultValue }
        return defaults?.bool(forKey: key) ?? defaultValue
    }

    private static func resolvedLanguage() -> String? {
        let selected = defaults?.string(forKey: "quranWidgetTranslationLanguage") ?? "auto"
        if selected != "auto" { return supportedLanguages.contains(selected) ? selected : "en" }
        let rawLocale = defaults?.string(forKey: "locale") ?? "en"
        let locale = rawLocale.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? "en"
        if locale == "ar" { return nil }
        return supportedLanguages.contains(locale) ? locale : "en"
    }

    private static func resolvedAppLanguage() -> String {
        let rawLocale = defaults?.string(forKey: "locale") ?? "en"
        let locale =
            rawLocale
            .split(whereSeparator: { $0 == "-" || $0 == "_" })
            .first
            .map { String($0).lowercased() } ?? "en"
        return supportedLanguages.contains(locale) || locale == "ar" ? locale : "en"
    }

    private static func resolvedPalette() -> QuranWidgetPalette {
        switch defaults?.string(forKey: "quranWidgetVisualTheme") ?? "auto" {
        case "forest": return palette(0x1B3A2A, 0x244D38, 0xE8F5E9, 0xC9DDCB, 0x81C784)
        case "ocean": return palette(0x1A3A5C, 0x244B73, 0xF0F4F8, 0xD2DEE8, 0x4DD0E1)
        case "sandstone": return palette(
            0xF5E6D3,
            0xFFF8EF,
            0x3E2C1A,
            0x5E4932,
            0xA83D15,
            ornament: 0xC18445,
            isLight: true
        )
        case "midnight": return palette(0x121218, 0x20202A, 0xF3F0FA, 0xC9C6D5, 0x9FA8DA)
        case "burgundy": return palette(0x4A0E1E, 0x62152A, 0xFDE8EF, 0xE6BEC9, 0xFF8A80)
        case "lavender": return palette(0x2E2450, 0x3D3168, 0xEDE7F6, 0xCBC2DE, 0xD59BE6)
        default:
            if themeName() == "teal" && isDarkMode() {
                return palette(0x061821, 0x0A3339, 0xF6F5EA, 0xD7E7E5, 0x62E6D2)
            }
            let app = WidgetThemeColors.getThemeColors(themeName: themeName(), isDarkMode: isDarkMode())
            return QuranWidgetPalette(
                background: app.gradientStart,
                surface: app.gradientEnd,
                ayah: app.quoteTextColor,
                translation: app.secondaryTextColor,
                accent: app.accent,
                ornament: Color(hex: isDarkMode() ? 0xD9BE72 : 0xC18445),
                isLight: !isDarkMode()
            )
        }
    }

    private static func palette(
        _ background: UInt,
        _ cardBackground: UInt,
        _ ayah: UInt,
        _ translation: UInt,
        _ accent: UInt,
        ornament: UInt = 0xD9BE72,
        isLight: Bool = false
    ) -> QuranWidgetPalette {
        QuranWidgetPalette(
            background: Color(hex: background),
            surface: Color(hex: cardBackground),
            ayah: Color(hex: ayah),
            translation: Color(hex: translation),
            accent: Color(hex: accent),
            ornament: Color(hex: ornament),
            isLight: isLight
        )
    }

    private static func themeName() -> String { defaults?.string(forKey: "themeName") ?? "teal" }

    private static func isDarkMode() -> Bool {
        switch defaults?.string(forKey: "themeMode") ?? "light" {
        case "dark": return true
        default: return false
        }
    }
}
