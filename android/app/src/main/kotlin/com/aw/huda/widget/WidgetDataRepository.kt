package com.aw.huda.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import java.lang.Math.floorMod

object WidgetDataRepository {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val ASSET_PATH = "flutter_assets/assets/json/quran_widget_verses.json"

    private const val KEY_LANGUAGE = "flutter.quranWidgetTranslationLanguage"
    private const val KEY_VISUAL_THEME = "flutter.quranWidgetVisualTheme"
    private const val KEY_AYAH_TEXT_SIZE = "flutter.quranWidgetAyahTextSize"
    private const val KEY_TRANSLATION_TEXT_SIZE = "flutter.quranWidgetTranslationTextSize"
    private const val KEY_AYAH_AUTO_FIT = "flutter.quranWidgetAyahAutoFit"
    private const val KEY_TRANSLATION_AUTO_FIT = "flutter.quranWidgetTranslationAutoFit"
    private const val KEY_AYAH_BOLD = "flutter.quranWidgetAyahBold"
    private const val KEY_TRANSLATION_BOLD = "flutter.quranWidgetTranslationBold"
    private const val KEY_ROTATION_OFFSET = "flutter.quranWidgetRotationOffset"
    private const val KEY_LOCALE = "flutter.locale"
    private const val KEY_THEME_NAME = "flutter.themeName"
    private const val KEY_THEME_MODE = "flutter.themeMode"

    private val supportedLanguages = setOf("en", "tr", "fr", "de", "es", "ur", "ru", "ms", "bn")

    @Volatile
    private var catalog: Catalog? = null

    data class Verse(
        val surah: Int,
        val ayah: Int,
        val arabic: String,
        val translations: Map<String, String>,
    )

    data class Surah(val displayNames: Map<String, String>)

    data class Snapshot(
        val verse: Verse,
        val translation: String?,
        val translationLanguage: String?,
        val translationSource: String?,
        val displayReference: String,
        val appLanguage: String,
        val palette: QuranWidgetPalette,
        val ayahTextSize: Int,
        val translationTextSize: Int,
        val ayahAutoFit: Boolean,
        val translationAutoFit: Boolean,
        val ayahBold: Boolean,
        val translationBold: Boolean,
    )

    private data class Catalog(
        val surahs: Map<Int, Surah>,
        val verses: List<Verse>,
        val sources: Map<String, String>,
    )

    fun snapshot(context: Context, timeMillis: Long = System.currentTimeMillis()): Snapshot {
        val prefs = prefs(context)
        val data = loadCatalog(context)
        val offset = prefs.getLongCompat(KEY_ROTATION_OFFSET)
        val hour = Math.floorDiv(timeMillis, 3_600_000L)
        val verse = data.verses[floorMod(hour + offset, data.verses.size.toLong()).toInt()]
        val language = resolveLanguage(prefs)
        val appLanguage = resolveAppLanguage(prefs)
        val surahName = data.surahs[verse.surah]
            ?.displayNames
            ?.let { names -> names[appLanguage] ?: names["en"] }
            ?.takeIf { it.isNotBlank() }
        return Snapshot(
            verse = verse,
            translation = language?.let(verse.translations::get),
            translationLanguage = language,
            translationSource = language?.let(data.sources::get),
            displayReference = surahName?.let { "$it • ${verse.ayah}" } ?: "${verse.surah}:${verse.ayah}",
            appLanguage = appLanguage,
            palette = resolvePalette(context, prefs),
            ayahTextSize = prefs.getLongCompat(KEY_AYAH_TEXT_SIZE, 100L).toInt().coerceIn(70, 140),
            translationTextSize = prefs.getLongCompat(KEY_TRANSLATION_TEXT_SIZE, 100L).toInt().coerceIn(70, 140),
            ayahAutoFit = prefs.getBoolean(KEY_AYAH_AUTO_FIT, true),
            translationAutoFit = prefs.getBoolean(KEY_TRANSLATION_AUTO_FIT, true),
            ayahBold = prefs.getBoolean(KEY_AYAH_BOLD, false),
            translationBold = prefs.getBoolean(KEY_TRANSLATION_BOLD, false),
        )
    }

    fun getThemeName(context: Context): String = prefs(context).getString(KEY_THEME_NAME, "teal") ?: "teal"

    fun isDarkMode(context: Context): Boolean {
        return when (prefs(context).getString(KEY_THEME_MODE, "light")) {
            "dark" -> true
            "light" -> false
            else -> {
                val mode = context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
                mode == android.content.res.Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    private fun resolveLanguage(prefs: SharedPreferences): String? {
        val selected = prefs.getString(KEY_LANGUAGE, "auto") ?: "auto"
        if (selected != "auto") return selected.takeIf(supportedLanguages::contains) ?: "en"
        val locale = (prefs.getString(KEY_LOCALE, "en") ?: "en").substringBefore('-').substringBefore('_')
        if (locale == "ar") return null
        return locale.takeIf(supportedLanguages::contains) ?: "en"
    }

    private fun resolveAppLanguage(prefs: SharedPreferences): String {
        val locale = (prefs.getString(KEY_LOCALE, "en") ?: "en")
            .substringBefore('-')
            .substringBefore('_')
            .lowercase()
        return locale.takeIf { it in supportedLanguages || it == "ar" } ?: "en"
    }

    private fun resolvePalette(context: Context, prefs: SharedPreferences): QuranWidgetPalette =
        QuranWidgetPaletteResolver.resolve(
            visualTheme = prefs.getString(KEY_VISUAL_THEME, "auto"),
            appThemeName = getThemeName(context),
            isDarkMode = isDarkMode(context),
        )

    private fun loadCatalog(context: Context): Catalog {
        catalog?.let { return it }
        return synchronized(this) {
            catalog ?: context.assets.open(ASSET_PATH).bufferedReader().use { reader ->
                val root = JSONObject(reader.readText())
                val surahObject = root.optJSONObject("surahs")
                val surahs = surahObject?.keys()?.asSequence()?.associate { rawId ->
                    val namesObject = surahObject
                        .getJSONObject(rawId)
                        .getJSONObject("displayNames")
                    rawId.toInt() to Surah(
                        namesObject.keys().asSequence().associateWith(namesObject::getString),
                    )
                }.orEmpty()
                val sourceObject = root.getJSONObject("sources")
                val sources = sourceObject.keys().asSequence().associateWith { code ->
                    sourceObject.getJSONObject(code).getString("name")
                }
                val array = root.getJSONArray("verses")
                val verses = buildList {
                    for (index in 0 until array.length()) {
                        val item = array.getJSONObject(index)
                        val translationsObject = item.getJSONObject("translations")
                        val translations = translationsObject.keys().asSequence().associateWith(translationsObject::getString)
                        add(Verse(item.getInt("surah"), item.getInt("ayah"), item.getString("arabic"), translations))
                    }
                }
                Catalog(surahs, verses, sources).also { catalog = it }
            }
        }
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun SharedPreferences.getLongCompat(key: String, defaultValue: Long = 0L): Long = try {
        getLong(key, defaultValue)
    } catch (_: ClassCastException) {
        getInt(key, defaultValue.toInt()).toLong()
    }

}
