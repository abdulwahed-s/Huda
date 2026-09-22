package com.aw.huda.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetDataRepositoryConfigurationTest {
    @Test
    fun flutterPreferenceSnapshotMapsToOneImmutableConfiguration() {
        val configuration = WidgetDataRepository.configurationFrom(
            mapOf(
                "flutter.quranWidgetTranslationLanguage" to "ur",
                "flutter.quranWidgetVisualTheme" to "burgundy",
                "flutter.quranWidgetAyahTextSize" to 118L,
                "flutter.quranWidgetTranslationTextSize" to 91,
                "flutter.quranWidgetAyahAutoFit" to false,
                "flutter.quranWidgetTranslationAutoFit" to true,
                "flutter.quranWidgetAyahBold" to true,
                "flutter.quranWidgetTranslationBold" to false,
                "flutter.quranWidgetRotationOffset" to 42L,
                "flutter.locale" to "ar",
                "flutter.themeName" to "purple",
                "flutter.themeMode" to "dark",
            ),
        )

        assertEquals("ur", configuration.language)
        assertEquals("burgundy", configuration.visualTheme)
        assertEquals(118, configuration.ayahTextSize)
        assertEquals(91, configuration.translationTextSize)
        assertFalse(configuration.ayahAutoFit)
        assertTrue(configuration.translationAutoFit)
        assertTrue(configuration.ayahBold)
        assertFalse(configuration.translationBold)
        assertEquals(42L, configuration.rotationOffset)
        assertEquals("ar", configuration.locale)
        assertEquals("purple", configuration.appThemeName)
        assertEquals("dark", configuration.appThemeMode)
    }

    @Test
    fun malformedOrOutOfRangeValuesUseSafeDefaultsAndBounds() {
        val configuration = WidgetDataRepository.configurationFrom(
            mapOf(
                "flutter.quranWidgetAyahTextSize" to 500L,
                "flutter.quranWidgetTranslationTextSize" to -5,
                "flutter.quranWidgetRotationOffset" to "not-a-number",
                "flutter.quranWidgetAyahAutoFit" to "not-a-boolean",
            ),
        )

        assertEquals("auto", configuration.language)
        assertEquals("auto", configuration.visualTheme)
        assertEquals(140, configuration.ayahTextSize)
        assertEquals(70, configuration.translationTextSize)
        assertEquals(0L, configuration.rotationOffset)
        assertTrue(configuration.ayahAutoFit)
        assertEquals("en", configuration.locale)
    }
}
