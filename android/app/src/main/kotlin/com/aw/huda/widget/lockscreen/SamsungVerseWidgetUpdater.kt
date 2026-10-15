package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Typeface
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.aw.huda.R
import com.aw.huda.widget.QuranWidgetConfiguration
import com.aw.huda.widget.QuranWidgetSize
import com.aw.huda.widget.WidgetDataRepository

internal object SamsungVerseWidgetUpdater {
    fun updateAll(
        context: Context,
        ids: IntArray,
        configuration: QuranWidgetConfiguration,
        timeMillis: Long = System.currentTimeMillis(),
    ): List<String> {
        if (ids.isEmpty()) return emptyList()
        val manager = AppWidgetManager.getInstance(context)
        val candidates = WidgetDataRepository.candidates(context, QuranWidgetSize.SMALL, configuration)
        return ids.map { id ->
            try {
                val options = manager.getAppWidgetOptions(id)
                val viewport = SamsungLockWidgetLayouts.viewport(options, expanded = true)
                val fitted = SamsungVerseFitter.choose(context, candidates, configuration, viewport, timeMillis)
                val views = buildViews(context, configuration, fitted, viewport)
                manager.updateAppWidget(id, views)
                Log.i("SamsungVerseWidget", "id=$id viewport=$viewport hour=${Math.floorDiv(timeMillis, 3_600_000L)} verse=${fitted?.snapshot?.verse?.id} ayahSp=${fitted?.ayahSp} options=$options")
                null
            } catch (error: Exception) {
                Log.e("SamsungVerseWidget", "id=$id failed", error)
                "Samsung verse widget $id: ${error.message}"
            }
        }.filterNotNull()
    }

    internal fun buildViews(
        context: Context,
        configuration: QuranWidgetConfiguration,
        fitted: FittedLockVerse?,
        viewport: LockWidgetViewport = LockWidgetViewport(124f, 56f),
    ): RemoteViews {
        val views = RemoteViews(context.packageName,
            if (configuration.ayahBold) R.layout.samsung_verse_bold else R.layout.samsung_verse)
        SamsungLockWidgetLayouts.bindDirection(views, configuration.locale.startsWith("ar") ||
            configuration.locale.startsWith("ur"))
        SamsungLockWidgetLayouts.bindTap(context, views, "huda://quran")
        if (fitted == null) {
            val message = SamsungLockWidgetLayouts.text(context, R.string.samsung_lock_open_quran, configuration.locale)
            val density = context.resources.displayMetrics.density
            val width = ((viewport.widthDp - 12f) * density).toInt().coerceAtLeast(1)
            val height = ((viewport.heightDp - 4f) * density).toInt().coerceAtLeast(1)
            val size = LockWidgetTextMetrics.fitBlock(context, message, width, height,
                11f, 9f, Typeface.DEFAULT)
            views.setTextViewText(R.id.samsung_verse_empty, if (size != null) message else "↗")
            views.setTextViewTextSize(R.id.samsung_verse_empty, TypedValue.COMPLEX_UNIT_SP, size ?: 9f)
            views.setViewVisibility(R.id.samsung_verse_empty, View.VISIBLE)
            views.setViewVisibility(R.id.samsung_verse_text, View.GONE)
            views.setViewVisibility(R.id.samsung_verse_reference, View.GONE)
            views.setContentDescription(R.id.samsung_lock_root, message)
        } else {
            views.setViewVisibility(R.id.samsung_verse_empty, View.GONE)
            views.setViewVisibility(R.id.samsung_verse_text, View.VISIBLE)
            views.setTextViewText(R.id.samsung_verse_text, fitted.snapshot.verse.arabic)
            views.setTextViewTextSize(R.id.samsung_verse_text, TypedValue.COMPLEX_UNIT_SP, fitted.ayahSp)
            views.setTextViewText(R.id.samsung_verse_reference, fitted.reference)
            views.setTextViewTextSize(R.id.samsung_verse_reference, TypedValue.COMPLEX_UNIT_SP, fitted.referenceSp)
            views.setViewVisibility(R.id.samsung_verse_reference, View.VISIBLE)
            views.setContentDescription(R.id.samsung_lock_root, "${fitted.snapshot.verse.arabic}. ${fitted.reference}")
        }
        return views
    }
}
