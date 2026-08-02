import SwiftUI

struct ThemeColors {
    let primary: Color
    let accent: Color
    let gradientStart: Color
    let gradientEnd: Color
    let borderColor: Color
    let badgeBackground: Color
    let quoteCardBackground: Color
    let quoteTextColor: Color
    let textColor: Color
    let secondaryTextColor: Color
}

struct WidgetThemeColors {
    
    private static let lightThemes: [String: ThemeColors] = [
        "purple": ThemeColors(
            primary: Color(hex: 0x7C3AED),
            accent: Color(hex: 0x8B5CF6),
            gradientStart: Color(hex: 0xF3EAFA),
            gradientEnd: Color(hex: 0xE0D3E0),
            borderColor: Color(hex: 0xC4B3D4),
            badgeBackground: Color(hex: 0xE8DEFF),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "green": ThemeColors(
            primary: Color(hex: 0x166534),
            accent: Color(hex: 0x10B981),
            gradientStart: Color(hex: 0xE6F7F2),
            gradientEnd: Color(hex: 0xD1FAE5),
            borderColor: Color(hex: 0x9DC7B8),
            badgeBackground: Color(hex: 0xD1FAE5),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "blue": ThemeColors(
            primary: Color(hex: 0x1E3A8A),
            accent: Color(hex: 0x2563EB),
            gradientStart: Color(hex: 0xE8F0FE),
            gradientEnd: Color(hex: 0xDBEAFE),
            borderColor: Color(hex: 0xA3C0F4),
            badgeBackground: Color(hex: 0xDBEAFE),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "red": ThemeColors(
            primary: Color(hex: 0x991B1B),
            accent: Color(hex: 0xDC2626),
            gradientStart: Color(hex: 0xFEF2F2),
            gradientEnd: Color(hex: 0xFEE2E2),
            borderColor: Color(hex: 0xF4A3A3),
            badgeBackground: Color(hex: 0xFEE2E2),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "orange": ThemeColors(
            primary: Color(hex: 0x9A3412),
            accent: Color(hex: 0xEA580C),
            gradientStart: Color(hex: 0xFFF5EB),
            gradientEnd: Color(hex: 0xFED7AA),
            borderColor: Color(hex: 0xF4C899),
            badgeBackground: Color(hex: 0xFED7AA),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "teal": ThemeColors(
            primary: Color(hex: 0x134E4A),
            accent: Color(hex: 0x0D9488),
            gradientStart: Color(hex: 0xE6FAF8),
            gradientEnd: Color(hex: 0xCCFDF7),
            borderColor: Color(hex: 0x99D7D0),
            badgeBackground: Color(hex: 0xCCFDF7),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "indigo": ThemeColors(
            primary: Color(hex: 0x312E81),
            accent: Color(hex: 0x4F46E5),
            gradientStart: Color(hex: 0xEEECFA),
            gradientEnd: Color(hex: 0xE0E7FF),
            borderColor: Color(hex: 0xB3B8E8),
            badgeBackground: Color(hex: 0xE0E7FF),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "pink": ThemeColors(
            primary: Color(hex: 0x9D174D),
            accent: Color(hex: 0xDB2777),
            gradientStart: Color(hex: 0xFDF2F8),
            gradientEnd: Color(hex: 0xFCE7F3),
            borderColor: Color(hex: 0xF4A8C9),
            badgeBackground: Color(hex: 0xFCE7F3),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "yellow": ThemeColors(
            primary: Color(hex: 0xA16207),
            accent: Color(hex: 0xEAB308),
            gradientStart: Color(hex: 0xFEFCE8),
            gradientEnd: Color(hex: 0xFEF9C3),
            borderColor: Color(hex: 0xFDE68A),
            badgeBackground: Color(hex: 0xFEF9C3),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "brown": ThemeColors(
            primary: Color(hex: 0x5D4037),
            accent: Color(hex: 0x795548),
            gradientStart: Color(hex: 0xF7F3F1),
            gradientEnd: Color(hex: 0xEFEBE9),
            borderColor: Color(hex: 0xD7CCC8),
            badgeBackground: Color(hex: 0xEFEBE9),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        ),
        "cream": ThemeColors(
            primary: Color(hex: 0x8A6D3B),
            accent: Color(hex: 0xB08D57),
            gradientStart: Color(hex: 0xFFFCF2),
            gradientEnd: Color(hex: 0xFFF8E7),
            borderColor: Color(hex: 0xE6D5AE),
            badgeBackground: Color(hex: 0xFFF3D6),
            quoteCardBackground: Color.white,
            quoteTextColor: Color(hex: 0x2C2C2C),
            textColor: Color(hex: 0x2C2C2C),
            secondaryTextColor: Color(hex: 0x666666)
        )
    ]
    
    private static let darkThemes: [String: ThemeColors] = [
        "purple": ThemeColors(
            primary: Color(hex: 0x9333EA),
            accent: Color(hex: 0x8B5CF6),
            gradientStart: Color(hex: 0x1E1533),
            gradientEnd: Color(hex: 0x2D1B4E),
            borderColor: Color(hex: 0x6B46A3),
            badgeBackground: Color(hex: 0x3D2A5C),
            quoteCardBackground: Color(hex: 0x2A1F40),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "green": ThemeColors(
            primary: Color(hex: 0x22C55E),
            accent: Color(hex: 0x10B981),
            gradientStart: Color(hex: 0x0F2820),
            gradientEnd: Color(hex: 0x1B3D30),
            borderColor: Color(hex: 0x2D7A5E),
            badgeBackground: Color(hex: 0x1A4031),
            quoteCardBackground: Color(hex: 0x162D24),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "blue": ThemeColors(
            primary: Color(hex: 0x3B82F6),
            accent: Color(hex: 0x2563EB),
            gradientStart: Color(hex: 0x0F1A2E),
            gradientEnd: Color(hex: 0x1B2A45),
            borderColor: Color(hex: 0x3D5A9E),
            badgeBackground: Color(hex: 0x1A3050),
            quoteCardBackground: Color(hex: 0x152540),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "red": ThemeColors(
            primary: Color(hex: 0xEF4444),
            accent: Color(hex: 0xDC2626),
            gradientStart: Color(hex: 0x2E0F0F),
            gradientEnd: Color(hex: 0x451B1B),
            borderColor: Color(hex: 0x9E3D3D),
            badgeBackground: Color(hex: 0x501A1A),
            quoteCardBackground: Color(hex: 0x401515),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "orange": ThemeColors(
            primary: Color(hex: 0xF97316),
            accent: Color(hex: 0xEA580C),
            gradientStart: Color(hex: 0x2E1A0F),
            gradientEnd: Color(hex: 0x45281B),
            borderColor: Color(hex: 0x9E633D),
            badgeBackground: Color(hex: 0x50301A),
            quoteCardBackground: Color(hex: 0x402515),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "teal": ThemeColors(
            primary: Color(hex: 0x14B8A6),
            accent: Color(hex: 0x0D9488),
            gradientStart: Color(hex: 0x0F2825),
            gradientEnd: Color(hex: 0x1B3D38),
            borderColor: Color(hex: 0x2D7A72),
            badgeBackground: Color(hex: 0x1A4038),
            quoteCardBackground: Color(hex: 0x162D2A),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "indigo": ThemeColors(
            primary: Color(hex: 0x6366F1),
            accent: Color(hex: 0x4F46E5),
            gradientStart: Color(hex: 0x151533),
            gradientEnd: Color(hex: 0x1E1E4E),
            borderColor: Color(hex: 0x4646A3),
            badgeBackground: Color(hex: 0x2A2A5C),
            quoteCardBackground: Color(hex: 0x1F1F40),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "pink": ThemeColors(
            primary: Color(hex: 0xEC4899),
            accent: Color(hex: 0xDB2777),
            gradientStart: Color(hex: 0x2E0F1E),
            gradientEnd: Color(hex: 0x451B30),
            borderColor: Color(hex: 0x9E3D6D),
            badgeBackground: Color(hex: 0x501A35),
            quoteCardBackground: Color(hex: 0x40152A),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "yellow": ThemeColors(
            primary: Color(hex: 0xFACC15),
            accent: Color(hex: 0xEAB308),
            gradientStart: Color(hex: 0x2E290F),
            gradientEnd: Color(hex: 0x453D1B),
            borderColor: Color(hex: 0x9E893D),
            badgeBackground: Color(hex: 0x50461A),
            quoteCardBackground: Color(hex: 0x403815),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "brown": ThemeColors(
            primary: Color(hex: 0x8D6E63),
            accent: Color(hex: 0x795548),
            gradientStart: Color(hex: 0x2B1D18),
            gradientEnd: Color(hex: 0x3E2A23),
            borderColor: Color(hex: 0x795548),
            badgeBackground: Color(hex: 0x4A332B),
            quoteCardBackground: Color(hex: 0x34241E),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        ),
        "cream": ThemeColors(
            primary: Color(hex: 0xD8C59A),
            accent: Color(hex: 0xB08D57),
            gradientStart: Color(hex: 0x261F13),
            gradientEnd: Color(hex: 0x3A3020),
            borderColor: Color(hex: 0x80683F),
            badgeBackground: Color(hex: 0x443720),
            quoteCardBackground: Color(hex: 0x302719),
            quoteTextColor: Color(hex: 0xF8FAFC),
            textColor: Color(hex: 0xF8FAFC),
            secondaryTextColor: Color(hex: 0xCCCCCC)
        )
    ]
    
    static func getThemeColors(themeName: String, isDarkMode: Bool) -> ThemeColors {
        let themes = isDarkMode ? darkThemes : lightThemes
        return themes[themeName] ?? themes["teal"]!
    }
}

extension Color {
    init(hex: UInt) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
