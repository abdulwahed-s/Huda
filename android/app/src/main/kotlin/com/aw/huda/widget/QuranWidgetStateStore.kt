package com.aw.huda.widget

import android.content.Context
import androidx.datastore.core.handlers.ReplaceFileCorruptionHandler
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import java.io.IOException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private const val QURAN_WIDGET_STATE_STORE_NAME = "quran_widget_state"
private const val QURAN_WIDGET_STATE_SCHEMA_VERSION = 1

private val Context.quranWidgetStateDataStore by preferencesDataStore(
    name = QURAN_WIDGET_STATE_STORE_NAME,
    corruptionHandler = ReplaceFileCorruptionHandler { emptyPreferences() },
)

internal object QuranWidgetStateStore {
    private val schemaVersion = intPreferencesKey("schema_version")
    private val refreshRevision = longPreferencesKey("refresh_revision")
    private val language = stringPreferencesKey("translation_language")
    private val visualTheme = stringPreferencesKey("visual_theme")
    private val ayahTextSize = intPreferencesKey("ayah_text_size")
    private val translationTextSize = intPreferencesKey("translation_text_size")
    private val ayahAutoFit = booleanPreferencesKey("ayah_auto_fit")
    private val translationAutoFit = booleanPreferencesKey("translation_auto_fit")
    private val ayahBold = booleanPreferencesKey("ayah_bold")
    private val translationBold = booleanPreferencesKey("translation_bold")
    private val rotationOffset = longPreferencesKey("rotation_offset")
    private val locale = stringPreferencesKey("locale")
    private val appThemeName = stringPreferencesKey("app_theme_name")
    private val appThemeMode = stringPreferencesKey("app_theme_mode")

    fun states(context: Context): Flow<QuranWidgetReactiveState> =
        dataStore(context).data
            .catch { error ->
                if (error is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw error
                }
            }
            .map(::toReactiveState)

    suspend fun currentOrInitialize(
        context: Context,
        initialConfiguration: () -> QuranWidgetConfiguration,
    ): QuranWidgetReactiveState {
        val store = dataStore(context)
        val current = try {
            store.data.first()
        } catch (error: IOException) {
            emptyPreferences()
        }
        if (current[schemaVersion] == QURAN_WIDGET_STATE_SCHEMA_VERSION) {
            return toReactiveState(current)
        }

        val updated = store.edit { preferences ->
            if (preferences[schemaVersion] != QURAN_WIDGET_STATE_SCHEMA_VERSION) {
                preferences.writeConfiguration(initialConfiguration())
                preferences[schemaVersion] = QURAN_WIDGET_STATE_SCHEMA_VERSION
                preferences.incrementRevision()
            }
        }
        return toReactiveState(updated)
    }

    suspend fun synchronize(
        context: Context,
        configuration: QuranWidgetConfiguration,
    ): QuranWidgetReactiveState {
        val updated = dataStore(context).edit { preferences ->
            preferences.writeConfiguration(configuration)
            preferences[schemaVersion] = QURAN_WIDGET_STATE_SCHEMA_VERSION
            preferences.incrementRevision()
        }
        return toReactiveState(updated)
    }

    private fun dataStore(context: Context) =
        context.applicationContext.quranWidgetStateDataStore

    private fun MutablePreferences.writeConfiguration(
        configuration: QuranWidgetConfiguration,
    ) {
        this[language] = configuration.language
        this[visualTheme] = configuration.visualTheme
        this[ayahTextSize] = configuration.ayahTextSize
        this[translationTextSize] = configuration.translationTextSize
        this[ayahAutoFit] = configuration.ayahAutoFit
        this[translationAutoFit] = configuration.translationAutoFit
        this[ayahBold] = configuration.ayahBold
        this[translationBold] = configuration.translationBold
        this[rotationOffset] = configuration.rotationOffset
        this[locale] = configuration.locale
        this[appThemeName] = configuration.appThemeName
        this[appThemeMode] = configuration.appThemeMode
    }

    private fun MutablePreferences.incrementRevision() {
        val current = this[refreshRevision] ?: 0L
        this[refreshRevision] = if (current == Long.MAX_VALUE) 0L else current + 1L
    }

    private fun toReactiveState(preferences: Preferences) = QuranWidgetReactiveState(
        configuration = QuranWidgetConfiguration(
            language = preferences[language] ?: "auto",
            visualTheme = preferences[visualTheme] ?: "auto",
            ayahTextSize = (preferences[ayahTextSize] ?: 100).coerceIn(70, 140),
            translationTextSize =
                (preferences[translationTextSize] ?: 100).coerceIn(70, 140),
            ayahAutoFit = preferences[ayahAutoFit] ?: true,
            translationAutoFit = preferences[translationAutoFit] ?: true,
            ayahBold = preferences[ayahBold] ?: false,
            translationBold = preferences[translationBold] ?: false,
            rotationOffset = preferences[rotationOffset] ?: 0L,
            locale = preferences[locale] ?: "en",
            appThemeName = preferences[appThemeName] ?: "teal",
            appThemeMode = preferences[appThemeMode] ?: "light",
        ),
        refreshRevision = preferences[refreshRevision] ?: 0L,
    )
}
