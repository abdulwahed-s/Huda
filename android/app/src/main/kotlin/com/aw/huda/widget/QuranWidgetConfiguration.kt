package com.aw.huda.widget

internal data class QuranWidgetConfiguration(
    val language: String = "auto",
    val visualTheme: String = "auto",
    val ayahTextSize: Int = 100,
    val translationTextSize: Int = 100,
    val ayahAutoFit: Boolean = true,
    val translationAutoFit: Boolean = true,
    val ayahBold: Boolean = false,
    val translationBold: Boolean = false,
    val rotationOffset: Long = 0L,
    val locale: String = "en",
    val appThemeName: String = "teal",
    val appThemeMode: String = "light",
)

internal data class QuranWidgetReactiveState(
    val configuration: QuranWidgetConfiguration,
    val refreshRevision: Long,
)
