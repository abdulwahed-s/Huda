package com.aw.huda.widget.lockscreen

import android.content.Context
import android.graphics.Typeface
import androidx.core.content.res.ResourcesCompat
import com.aw.huda.R
import com.aw.huda.widget.QuranWidgetConfiguration
import com.aw.huda.widget.WidgetDataRepository
import java.lang.Math.floorMod

internal data class FittedLockVerse(
    val snapshot: WidgetDataRepository.Snapshot,
    val ayahSp: Float,
    val reference: String,
    val referenceSp: Float,
)

internal object SamsungVerseFitter {
    const val MIN_AYAH_SP = 12f
    const val REFERENCE_SP = 9f

    fun choose(
        context: Context,
        candidates: List<WidgetDataRepository.Snapshot>,
        configuration: QuranWidgetConfiguration,
        viewport: LockWidgetViewport,
        timeMillis: Long,
    ): FittedLockVerse? {
        val fitting = candidates.mapNotNull { fit(context, it, configuration, viewport) }
        return select(fitting, timeMillis, configuration.rotationOffset)
    }

    fun <T> select(fitting: List<T>, timeMillis: Long, offset: Long): T? {
        if (fitting.isEmpty()) return null
        val count = fitting.size.toLong()
        val hour = Math.floorDiv(timeMillis, 3_600_000L)
        // Reduce before adding so malformed extreme offsets cannot overflow the hour.
        val index = floorMod(floorMod(hour, count) + floorMod(offset, count), count).toInt()
        return fitting[index]
    }

    internal fun fit(
        context: Context,
        snapshot: WidgetDataRepository.Snapshot,
        configuration: QuranWidgetConfiguration,
        viewport: LockWidgetViewport,
    ): FittedLockVerse? {
        val density = context.resources.displayMetrics.density
        val widthPx = ((viewport.widthDp - 12f) * density).toInt()
        val heightPx = ((viewport.heightDp - 4f) * density).toInt()
        if (widthPx <= 0 || heightPx <= 0) return null
        val font = ResourcesCompat.getFont(context,
            if (configuration.ayahBold) R.font.amiri_bold else R.font.amiri) ?: return null
        val referencePaint = LockWidgetTextMetrics.paint(context, REFERENCE_SP, Typeface.DEFAULT)
        val reference = snapshot.displayReference.takeIf { referencePaint.measureText(it) <= widthPx }
            ?: "${snapshot.verse.surah}:${snapshot.verse.ayah}"
        if (referencePaint.measureText(reference) > widthPx) return null
        val referenceHeight = LockWidgetTextMetrics.layout(context, reference, widthPx,
            REFERENCE_SP, Typeface.DEFAULT).height
        var size = (14f * configuration.ayahTextSize / 100f).coerceAtLeast(MIN_AYAH_SP)
        while (true) {
            // No maxLines or ellipsis while measuring: every character must fit.
            val layout = LockWidgetTextMetrics.layout(context, snapshot.verse.arabic, widthPx, size, font)
            val complete = layout.lineCount in 1..2 &&
                layout.getLineEnd(layout.lineCount - 1) == snapshot.verse.arabic.length &&
                (0 until layout.lineCount).all { layout.getLineWidth(it) <= widthPx }
            if (complete && layout.height + referenceHeight <= heightPx) {
                return FittedLockVerse(snapshot, size, reference, REFERENCE_SP)
            }
            if (!configuration.ayahAutoFit || size <= MIN_AYAH_SP) return null
            size = (size - 0.5f).coerceAtLeast(MIN_AYAH_SP)
        }
    }
}
