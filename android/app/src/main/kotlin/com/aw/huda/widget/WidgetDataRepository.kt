package com.aw.huda.widget

import android.content.Context
import android.content.SharedPreferences
import kotlin.random.Random

object WidgetDataRepository {

    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"

    private const val KEY_QUOTE = "flutter.quote"
    private const val KEY_LAST_UPDATE = "flutter.lastUpdate"
    private const val KEY_THEME_NAME = "flutter.themeName"
    private const val KEY_THEME_MODE = "flutter.themeMode"

    private const val KEY_CUSTOM_VERSES = "flutter.widgetCustomVersesNative"

    private const val LIST_IDENTIFIER = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"

    private val defaultVerses = listOf(
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
    )
    
    private fun getFlutterPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    fun getCurrentQuote(context: Context): String {
        val quote = getFlutterPrefs(context).getString(KEY_QUOTE, defaultVerses[0])
            ?: defaultVerses[0]
        return if (quote.startsWith(LIST_IDENTIFIER)) defaultVerses[0] else quote
    }
    
    fun getLastUpdate(context: Context): String {
        return getFlutterPrefs(context).getString(KEY_LAST_UPDATE, "") ?: ""
    }
    
    fun getThemeName(context: Context): String {
        val prefs = getFlutterPrefs(context)
        val theme = prefs.getString(KEY_THEME_NAME, "purple") ?: "purple"
        println("📱 Widget reading themeName: $theme")
        return theme
    }
    
    fun isDarkMode(context: Context): Boolean {
        val prefs = getFlutterPrefs(context)
        val themeMode = prefs.getString(KEY_THEME_MODE, "light") ?: "light"
        println("📱 Widget reading themeMode: $themeMode")
        return when (themeMode) {
            "dark" -> true
            "light" -> false
            else -> {
                val uiMode = context.resources.configuration.uiMode and 
                    android.content.res.Configuration.UI_MODE_NIGHT_MASK
                val isNight = uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES
                println("📱 System mode detected, isNight: $isNight")
                isNight
            }
        }
    }
    
    fun getCustomVerses(context: Context): List<String> {
        val versesString = getFlutterPrefs(context).getString(KEY_CUSTOM_VERSES, null)
        // Guard: if the value is a shared_preferences List<String> blob (wrong
        // key/format), discard it rather than turning the whole blob into a verse.
        if (versesString.isNullOrEmpty() || versesString.startsWith(LIST_IDENTIFIER)) {
            return emptyList()
        }
        return versesString.split("|||").filter { it.isNotEmpty() }
    }
    
    fun getAllVerses(context: Context): List<String> {
        val custom = getCustomVerses(context)
        return custom + defaultVerses
    }
    
    fun getRandomVerse(context: Context): String {
        val allVerses = getAllVerses(context)
        return if (allVerses.isNotEmpty()) {
            allVerses[Random.nextInt(allVerses.size)]
        } else {
            defaultVerses[0]
        }
    }
    
    fun saveNewQuote(context: Context, quote: String) {
        getFlutterPrefs(context).edit().apply {
            putString(KEY_QUOTE, quote)
            putString(KEY_LAST_UPDATE, java.time.Instant.now().toString())
            apply()
        }
    }
    
    fun formatLastUpdate(context: Context): String {
        val lastUpdate = getLastUpdate(context)
        if (lastUpdate.isEmpty()) return "آخر تحديث: الآن"
        
        return try {
            val updateTime = java.time.Instant.parse(lastUpdate)
            val now = java.time.Instant.now()
            val minutes = java.time.Duration.between(updateTime, now).toMinutes()
            
            when {
                minutes < 1 -> "آخر تحديث: الآن"
                minutes < 60 -> "آخر تحديث: $minutes دقيقة"
                minutes < 1440 -> "آخر تحديث: ${minutes / 60} ساعة"
                else -> "آخر تحديث: ${minutes / 1440} يوم"
            }
        } catch (e: Exception) {
            "آخر تحديث: الآن"
        }
    }
}
