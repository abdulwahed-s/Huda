package com.aw.huda.widget

object WidgetThemeColors {
    
    data class ThemeColors(
        // Main theme colors
        val primary: Int,
        val accent: Int,
        // Background colors
        val gradientStart: Int,
        val gradientEnd: Int,
        val borderColor: Int,
        // Badge colors
        val badgeBackground: Int,
        // Quote card colors
        val quoteCardBackground: Int,
        val quoteTextColor: Int,
        // Text colors
        val textColor: Int,
        val secondaryTextColor: Int
    )
    
    private val lightThemes = mapOf(
        "purple" to ThemeColors(
            primary = 0xFF7C3AED.toInt(),
            accent = 0xFF8B5CF6.toInt(),
            gradientStart = 0xFFF3EAFA.toInt(),
            gradientEnd = 0xFFE0D3E0.toInt(),
            borderColor = 0xFFC4B3D4.toInt(),
            badgeBackground = 0xFFE8DEFF.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "green" to ThemeColors(
            primary = 0xFF166534.toInt(),
            accent = 0xFF10B981.toInt(),
            gradientStart = 0xFFE6F7F2.toInt(),
            gradientEnd = 0xFFD1FAE5.toInt(),
            borderColor = 0xFF9DC7B8.toInt(),
            badgeBackground = 0xFFD1FAE5.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "blue" to ThemeColors(
            primary = 0xFF1E3A8A.toInt(),
            accent = 0xFF2563EB.toInt(),
            gradientStart = 0xFFE8F0FE.toInt(),
            gradientEnd = 0xFFDBEAFE.toInt(),
            borderColor = 0xFFA3C0F4.toInt(),
            badgeBackground = 0xFFDBEAFE.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "red" to ThemeColors(
            primary = 0xFF991B1B.toInt(),
            accent = 0xFFDC2626.toInt(),
            gradientStart = 0xFFFEF2F2.toInt(),
            gradientEnd = 0xFFFEE2E2.toInt(),
            borderColor = 0xFFF4A3A3.toInt(),
            badgeBackground = 0xFFFEE2E2.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "orange" to ThemeColors(
            primary = 0xFF9A3412.toInt(),
            accent = 0xFFEA580C.toInt(),
            gradientStart = 0xFFFFF5EB.toInt(),
            gradientEnd = 0xFFFED7AA.toInt(),
            borderColor = 0xFFF4C899.toInt(),
            badgeBackground = 0xFFFED7AA.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "teal" to ThemeColors(
            primary = 0xFF134E4A.toInt(),
            accent = 0xFF0D9488.toInt(),
            gradientStart = 0xFFE6FAF8.toInt(),
            gradientEnd = 0xFFCCFDF7.toInt(),
            borderColor = 0xFF99D7D0.toInt(),
            badgeBackground = 0xFFCCFDF7.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "indigo" to ThemeColors(
            primary = 0xFF312E81.toInt(),
            accent = 0xFF4F46E5.toInt(),
            gradientStart = 0xFFEEECFA.toInt(),
            gradientEnd = 0xFFE0E7FF.toInt(),
            borderColor = 0xFFB3B8E8.toInt(),
            badgeBackground = 0xFFE0E7FF.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "pink" to ThemeColors(
            primary = 0xFF9D174D.toInt(),
            accent = 0xFFDB2777.toInt(),
            gradientStart = 0xFFFDF2F8.toInt(),
            gradientEnd = 0xFFFCE7F3.toInt(),
            borderColor = 0xFFF4A8C9.toInt(),
            badgeBackground = 0xFFFCE7F3.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "yellow" to ThemeColors(
            primary = 0xFFA16207.toInt(),
            accent = 0xFFEAB308.toInt(),
            gradientStart = 0xFFFEFCE8.toInt(),
            gradientEnd = 0xFFFEF9C3.toInt(),
            borderColor = 0xFFFDE68A.toInt(),
            badgeBackground = 0xFFFEF9C3.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "brown" to ThemeColors(
            primary = 0xFF5D4037.toInt(),
            accent = 0xFF795548.toInt(),
            gradientStart = 0xFFF7F3F1.toInt(),
            gradientEnd = 0xFFEFEBE9.toInt(),
            borderColor = 0xFFD7CCC8.toInt(),
            badgeBackground = 0xFFEFEBE9.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        ),
        "cream" to ThemeColors(
            primary = 0xFF8A6D3B.toInt(),
            accent = 0xFFB08D57.toInt(),
            gradientStart = 0xFFFFFCF2.toInt(),
            gradientEnd = 0xFFFFF8E7.toInt(),
            borderColor = 0xFFE6D5AE.toInt(),
            badgeBackground = 0xFFFFF3D6.toInt(),
            quoteCardBackground = 0xFFFFFFFF.toInt(),
            quoteTextColor = 0xFF2C2C2C.toInt(),
            textColor = 0xFF2C2C2C.toInt(),
            secondaryTextColor = 0xFF666666.toInt()
        )
    )
    
    private val darkThemes = mapOf(
        "purple" to ThemeColors(
            primary = 0xFF9333EA.toInt(),
            accent = 0xFF8B5CF6.toInt(),
            gradientStart = 0xFF1E1533.toInt(),
            gradientEnd = 0xFF2D1B4E.toInt(),
            borderColor = 0xFF6B46A3.toInt(),
            badgeBackground = 0xFF3D2A5C.toInt(),
            quoteCardBackground = 0xFF2A1F40.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "green" to ThemeColors(
            primary = 0xFF22C55E.toInt(),
            accent = 0xFF10B981.toInt(),
            gradientStart = 0xFF0F2820.toInt(),
            gradientEnd = 0xFF1B3D30.toInt(),
            borderColor = 0xFF2D7A5E.toInt(),
            badgeBackground = 0xFF1A4031.toInt(),
            quoteCardBackground = 0xFF162D24.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "blue" to ThemeColors(
            primary = 0xFF3B82F6.toInt(),
            accent = 0xFF2563EB.toInt(),
            gradientStart = 0xFF0F1A2E.toInt(),
            gradientEnd = 0xFF1B2A45.toInt(),
            borderColor = 0xFF3D5A9E.toInt(),
            badgeBackground = 0xFF1A3050.toInt(),
            quoteCardBackground = 0xFF152540.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "red" to ThemeColors(
            primary = 0xFFEF4444.toInt(),
            accent = 0xFFDC2626.toInt(),
            gradientStart = 0xFF2E0F0F.toInt(),
            gradientEnd = 0xFF451B1B.toInt(),
            borderColor = 0xFF9E3D3D.toInt(),
            badgeBackground = 0xFF501A1A.toInt(),
            quoteCardBackground = 0xFF401515.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "orange" to ThemeColors(
            primary = 0xFFF97316.toInt(),
            accent = 0xFFEA580C.toInt(),
            gradientStart = 0xFF2E1A0F.toInt(),
            gradientEnd = 0xFF45281B.toInt(),
            borderColor = 0xFF9E633D.toInt(),
            badgeBackground = 0xFF50301A.toInt(),
            quoteCardBackground = 0xFF402515.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "teal" to ThemeColors(
            primary = 0xFF14B8A6.toInt(),
            accent = 0xFF0D9488.toInt(),
            gradientStart = 0xFF0F2825.toInt(),
            gradientEnd = 0xFF1B3D38.toInt(),
            borderColor = 0xFF2D7A72.toInt(),
            badgeBackground = 0xFF1A4038.toInt(),
            quoteCardBackground = 0xFF162D2A.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "indigo" to ThemeColors(
            primary = 0xFF6366F1.toInt(),
            accent = 0xFF4F46E5.toInt(),
            gradientStart = 0xFF151533.toInt(),
            gradientEnd = 0xFF1E1E4E.toInt(),
            borderColor = 0xFF4646A3.toInt(),
            badgeBackground = 0xFF2A2A5C.toInt(),
            quoteCardBackground = 0xFF1F1F40.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "pink" to ThemeColors(
            primary = 0xFFEC4899.toInt(),
            accent = 0xFFDB2777.toInt(),
            gradientStart = 0xFF2E0F1E.toInt(),
            gradientEnd = 0xFF451B30.toInt(),
            borderColor = 0xFF9E3D6D.toInt(),
            badgeBackground = 0xFF501A35.toInt(),
            quoteCardBackground = 0xFF40152A.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "yellow" to ThemeColors(
            primary = 0xFFFACC15.toInt(),
            accent = 0xFFEAB308.toInt(),
            gradientStart = 0xFF2E290F.toInt(),
            gradientEnd = 0xFF453D1B.toInt(),
            borderColor = 0xFF9E893D.toInt(),
            badgeBackground = 0xFF50461A.toInt(),
            quoteCardBackground = 0xFF403815.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "brown" to ThemeColors(
            primary = 0xFF8D6E63.toInt(),
            accent = 0xFF795548.toInt(),
            gradientStart = 0xFF2B1D18.toInt(),
            gradientEnd = 0xFF3E2A23.toInt(),
            borderColor = 0xFF795548.toInt(),
            badgeBackground = 0xFF4A332B.toInt(),
            quoteCardBackground = 0xFF34241E.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        ),
        "cream" to ThemeColors(
            primary = 0xFFD8C59A.toInt(),
            accent = 0xFFB08D57.toInt(),
            gradientStart = 0xFF261F13.toInt(),
            gradientEnd = 0xFF3A3020.toInt(),
            borderColor = 0xFF80683F.toInt(),
            badgeBackground = 0xFF443720.toInt(),
            quoteCardBackground = 0xFF302719.toInt(),
            quoteTextColor = 0xFFF8FAFC.toInt(),
            textColor = 0xFFF8FAFC.toInt(),
            secondaryTextColor = 0xFFCCCCCC.toInt()
        )
    )
    
    fun getThemeColors(themeName: String, isDarkMode: Boolean): ThemeColors {
        val themes = if (isDarkMode) darkThemes else lightThemes
        return themes[themeName] ?: themes["teal"]!!
    }
}
