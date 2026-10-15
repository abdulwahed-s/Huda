package com.aw.huda.widget.lockscreen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.aw.huda.MainActivity
import com.aw.huda.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.util.Locale

internal data class LockWidgetViewport(val widthDp: Float, val heightDp: Float)

internal object SamsungLockWidgetLayouts {
    fun viewport(options: Bundle, expanded: Boolean): LockWidgetViewport {
        val defaultWidth = if (expanded) 124f else 56f
        val widths = mutableListOf<Float>()
        val heights = mutableListOf<Float>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            @Suppress("DEPRECATION")
            options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                ?.forEach { size ->
                    if (size.width > 0) widths += size.width
                    if (size.height > 0) heights += size.height
                }
        }
        options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 }
            ?.let { widths += it.toFloat() }
        options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT).takeIf { it > 0 }
            ?.let { heights += it.toFloat() }
        return LockWidgetViewport(widths.minOrNull() ?: defaultWidth, heights.minOrNull() ?: 56f)
    }

    fun bindTap(context: Context, views: RemoteViews, uri: String) {
        views.setOnClickPendingIntent(
            R.id.samsung_lock_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri)),
        )
    }

    fun bindDirection(views: RemoteViews, rtl: Boolean) {
        views.setInt(R.id.samsung_lock_root, "setLayoutDirection",
            if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
    }

    fun text(context: Context, id: Int, language: String): String {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(language))
        return context.createConfigurationContext(configuration).getString(id)
    }
}
