import Foundation

struct WidgetDataLoader {

    private static let appGroupId = "group.hudaHomeApp"

    private static let keyQuote = "quote"
    private static let keyThemeName = "themeName"
    private static let keyThemeMode = "themeMode"

    static let defaultVerses: [String] = [
        "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        "وَٱللَّهُ غَفُورٌ رَّحِيمٌ",
        "وَٱلَّذِينَ صَبَرُوا۟ ٱبْتِغَآءَ وَجْهِ رَبِّهِمْ",
        "قَدْ أُجِيبَت دَّعْوَتُكُمَا",
        "فَاسْتَجَابَ لَكُمْ",
        "يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا",
        "سَيَجعَلُ اللَّهُ بَعدَ عُسرٍ يُسرًا",
        "لَا تَدْرِي لَعَلَّ اللَّهَ يُحْدِثُ بَعْدَ ذَٰلِكَ أَمْرًا",
        "رَبِّ اشْرَحْ لِي صَدْرِي",
        "وَتَوَكَّلْ عَلَى ٱللَّهِ ۚ وَكَفَىٰ بِٱللَّهِ وَكِيلًا",
        "نَصْرٌ مِنَ اللَّهِ وَفَتْحٌ قَرِيبٌ",
        "ادْعُونِي أَسْتَجِبْ لَكُمْ",
        "فَاسْتَجَابَ لَهُ رَبُّهُ",
        "عَسَىٰ أَنْ يَكُونَ قَرِيبًا",
        "اذْكُرُوا نِعْمَةَ اللَّهِ عَلَيْكُمْ",
        "وَأَثَابَهُمْ فَتْحًا قَرِيبًا",
        "فَنِعْمَ الْمَوْلَىٰ وَنِعْمَ النَّصِيرُ",
        "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا مَا آتَاهَا",
        "فَإِن تُبْتُمْ فَهُوَ خَيْرٌ لَّكُمْ",
        "إِنَّ وَعْدَ اللَّهِ حَقٌّ"
    ]
    
    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }

    static func getCurrentQuote() -> String {
        guard let defaults = sharedDefaults else {
            return getRandomVerse()
        }
        return defaults.string(forKey: keyQuote) ?? getRandomVerse()
    }

    static func getThemeName() -> String {
        guard let defaults = sharedDefaults else {
            return "purple"
        }
        return defaults.string(forKey: keyThemeName) ?? "purple"
    }

    static func isDarkMode() -> Bool {
        guard let defaults = sharedDefaults else {
            return false
        }
        
        let themeMode = defaults.string(forKey: keyThemeMode) ?? "light"
        
        switch themeMode {
        case "dark":
            return true
        case "light":
            return false
        default:
            return false
        }
    }

    static func getRandomVerse() -> String {
        return defaultVerses.randomElement() ?? defaultVerses[0]
    }

    static func getThemeColors() -> ThemeColors {
        let themeName = getThemeName()
        let isDark = isDarkMode()
        return WidgetThemeColors.getThemeColors(themeName: themeName, isDarkMode: isDark)
    }
}
