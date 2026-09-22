package com.aw.huda.widget

import android.content.Context
import org.json.JSONObject
import java.lang.Math.floorMod

enum class QuranWidgetSize {
    SMALL,
    MEDIUM,
    LARGE;

    companion object {
        fun fromDimensions(widthDp: Float, heightDp: Float): QuranWidgetSize = when {
            widthDp >= 280f && heightDp >= 311f -> LARGE
            widthDp >= 280f && heightDp >= 140f -> MEDIUM
            else -> SMALL
        }

        fun fromJson(value: String): QuranWidgetSize? = when (value) {
            "small" -> SMALL
            "medium" -> MEDIUM
            "large" -> LARGE
            else -> null
        }
    }
}

internal object WidgetDataRepository {
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
        val id: String,
        val surah: Int,
        val ayah: Int,
        val widgetSizes: Set<QuranWidgetSize>,
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

    fun snapshot(
        context: Context,
        size: QuranWidgetSize,
        configuration: QuranWidgetConfiguration,
        timeMillis: Long = System.currentTimeMillis(),
    ): Snapshot {
        val data = loadCatalog(context)
        val offset = configuration.rotationOffset
        val hour = Math.floorDiv(timeMillis, 3_600_000L)
        val eligibleVerses = data.verses.filter { size in it.widgetSizes }
        val verses = eligibleVerses.ifEmpty {
            listOf(data.verses.firstOrNull { it.id == "94:6" } ?: data.verses.first())
        }
        val verse = verses[floorMod(hour + offset, verses.size.toLong()).toInt()]
        val language = resolveLanguage(configuration)
        val appLanguage = resolveAppLanguage(configuration)
        val surahName = data.surahs[verse.surah]
            ?.displayNames
            ?.let { names -> names[appLanguage] ?: names["en"] }
            ?.takeIf { it.isNotBlank() }
        return Snapshot(
            verse = verse,
            translation = language?.let(verse.translations::get),
            translationLanguage = language,
            translationSource = language?.let(data.sources::get),
            displayReference = surahName?.let { "$it • ${verse.ayah}" }
                ?: "${verse.surah}:${verse.ayah}",
            appLanguage = appLanguage,
            palette = resolvePalette(context, configuration),
            ayahTextSize = configuration.ayahTextSize,
            translationTextSize = configuration.translationTextSize,
            ayahAutoFit = configuration.ayahAutoFit,
            translationAutoFit = configuration.translationAutoFit,
            ayahBold = configuration.ayahBold,
            translationBold = configuration.translationBold,
        )
    }

    fun readConfiguration(context: Context): QuranWidgetConfiguration =
        configurationFrom(
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).all,
        )

    internal fun configurationFrom(values: Map<String, *>): QuranWidgetConfiguration =
        QuranWidgetConfiguration(
            language = values.stringValue(KEY_LANGUAGE, "auto"),
            visualTheme = values.stringValue(KEY_VISUAL_THEME, "auto"),
            ayahTextSize = values.intValue(KEY_AYAH_TEXT_SIZE, 100).coerceIn(70, 140),
            translationTextSize =
                values.intValue(KEY_TRANSLATION_TEXT_SIZE, 100).coerceIn(70, 140),
            ayahAutoFit = values.booleanValue(KEY_AYAH_AUTO_FIT, true),
            translationAutoFit = values.booleanValue(KEY_TRANSLATION_AUTO_FIT, true),
            ayahBold = values.booleanValue(KEY_AYAH_BOLD, false),
            translationBold = values.booleanValue(KEY_TRANSLATION_BOLD, false),
            rotationOffset = values.longValue(KEY_ROTATION_OFFSET, 0L),
            locale = values.stringValue(KEY_LOCALE, "en"),
            appThemeName = values.stringValue(KEY_THEME_NAME, "teal"),
            appThemeMode = values.stringValue(KEY_THEME_MODE, "light"),
        )

    private fun isDarkMode(
        context: Context,
        configuration: QuranWidgetConfiguration,
    ): Boolean {
        return when (configuration.appThemeMode) {
            "dark" -> true
            "light" -> false
            else -> {
                val mode =
                    context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
                mode == android.content.res.Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    private fun resolveLanguage(configuration: QuranWidgetConfiguration): String? {
        val selected = configuration.language
        if (selected != "auto") return selected.takeIf(supportedLanguages::contains) ?: "en"
        val locale = configuration.locale.substringBefore('-').substringBefore('_')
        if (locale == "ar") return null
        return locale.takeIf(supportedLanguages::contains) ?: "en"
    }

    private fun resolveAppLanguage(configuration: QuranWidgetConfiguration): String {
        val locale = configuration.locale
            .substringBefore('-')
            .substringBefore('_')
            .lowercase()
        return locale.takeIf { it in supportedLanguages || it == "ar" } ?: "en"
    }

    private fun resolvePalette(
        context: Context,
        configuration: QuranWidgetConfiguration,
    ): QuranWidgetPalette =
        QuranWidgetPaletteResolver.resolve(
            visualTheme = configuration.visualTheme,
            appThemeName = configuration.appThemeName,
            isDarkMode = isDarkMode(context, configuration),
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
                        val translations = translationsObject.keys().asSequence()
                            .associateWith(translationsObject::getString)
                        val rawWidgetSizes = item.getJSONArray("widgetSizes")
                        val widgetSizes = buildSet {
                            for (sizeIndex in 0 until rawWidgetSizes.length()) {
                                QuranWidgetSize.fromJson(rawWidgetSizes.getString(sizeIndex))
                                    ?.let(::add)
                            }
                        }
                        add(
                            Verse(
                                id = item.getString("id"),
                                surah = item.getInt("surah"),
                                ayah = item.getInt("ayah"),
                                widgetSizes = widgetSizes,
                                arabic = item.getString("arabic"),
                                translations = translations,
                            ),
                        )
                    }
                }
                Catalog(surahs, verses, sources).also { catalog = it }
            }
        }
    }

    private fun Map<String, *>.stringValue(key: String, defaultValue: String): String =
        this[key] as? String ?: defaultValue

    private fun Map<String, *>.booleanValue(key: String, defaultValue: Boolean): Boolean =
        this[key] as? Boolean ?: defaultValue

    private fun Map<String, *>.intValue(key: String, defaultValue: Int): Int =
        (this[key] as? Number)?.toInt() ?: defaultValue

    private fun Map<String, *>.longValue(key: String, defaultValue: Long): Long =
        (this[key] as? Number)?.toLong() ?: defaultValue

}
