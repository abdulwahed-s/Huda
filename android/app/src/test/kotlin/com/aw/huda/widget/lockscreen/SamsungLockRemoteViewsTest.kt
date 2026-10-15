package com.aw.huda.widget.lockscreen

import android.app.Application
import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.widget.Chronometer
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.RemoteViews
import com.aw.huda.R
import com.aw.huda.widget.QuranWidgetConfiguration
import com.aw.huda.widget.QuranWidgetSize
import com.aw.huda.widget.WidgetDataRepository
import com.aw.huda.widget.prayer.NextPrayer
import com.aw.huda.widget.prayer.PrayerKind
import com.aw.huda.widget.prayer.PrayerWidgetLanguage
import com.aw.huda.widget.prayer.PrayerWidgetNumerals
import java.io.File
import java.time.Duration
import java.util.Date
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class, qualifiers = "en-rUS-xhdpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class SamsungLockRemoteViewsTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()

    private fun target(now: Date): NextPrayer {
        val snapshot = lockPrayerSnapshot()
        val day = com.aw.huda.widget.prayer.PrayerWidgetCalculator.computeDay(snapshot,
            java.util.Calendar.getInstance(snapshot.displayTimeZone).apply { time = now })!!
        return NextPrayer(PrayerKind.ASR, Date(now.time + 2_538_000L), day)
    }

    @Test fun productionAndPreviewLayoutsInflateThroughRemoteViews() {
        for (layout in listOf(R.layout.samsung_prayer_compact, R.layout.samsung_prayer_expanded,
            R.layout.samsung_prayer_compact_preview, R.layout.samsung_prayer_expanded_preview)) {
            val root = RemoteViews(context.packageName, layout).apply(context, FrameLayout(context))
            assertNotNull(root.findViewById<View>(R.id.samsung_lock_root))
        }
    }

    @Test fun awakeAndroidHostTicksAndAnEmptyStateCanBeReboundToLive() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val now = Date()
        val snapshot = lockPrayerSnapshot()
        val empty = SamsungPrayerWidgetUpdater.buildViews(activity, false, LockWidgetViewport(56f, 56f),
            snapshot.copy(latitude = null, longitude = null), null, now).first
        val root = empty.apply(activity, FrameLayout(activity))
        activity.setContentView(root)
        assertEquals(View.GONE, root.findViewById<View>(R.id.samsung_prayer_countdown).visibility)
        val (liveViews, live) = SamsungPrayerWidgetUpdater.buildViews(activity, false,
            LockWidgetViewport(56f, 56f), snapshot, target(now), now)
        assertTrue(live)
        liveViews.reapply(activity, root)
        val timer = root.findViewById<Chronometer>(R.id.samsung_prayer_countdown)
        assertTrue(timer.isCountDown)
        assertEquals(View.VISIBLE, timer.visibility)
        assertNull(root.contentDescription)
        assertEquals("%s", timer.format)
        assertTrue(timer.base > SystemClock.elapsedRealtime())
        val before = timer.text.toString()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(2))
        assertNotEquals(before, timer.text.toString())
        activity.finish()
    }

    @Test fun expiredTargetStopsThePreviouslyLiveTimer() {
        val now = Date()
        val snapshot = lockPrayerSnapshot()
        val next = target(now)
        val root = SamsungPrayerWidgetUpdater.buildViews(context, true,
            LockWidgetViewport(124f, 56f), snapshot, next, now).first.apply(context, FrameLayout(context))
        val expired = next.copy(time = Date(now.time - 1))
        SamsungPrayerWidgetUpdater.buildViews(context, true, LockWidgetViewport(124f, 56f),
            snapshot, expired, now).first.reapply(context, root)
        assertEquals(View.GONE, root.findViewById<View>(R.id.samsung_prayer_countdown).visibility)
        assertEquals(View.VISIBLE, root.findViewById<View>(R.id.samsung_prayer_static_counter).visibility)
    }

    private fun measure(root: View, widthDp: Int, heightDp: Int) {
        val density = context.resources.displayMetrics.density
        val width = (widthDp * density).toInt()
        val height = (heightDp * density).toInt()
        root.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        root.layout(0, 0, width, height)
    }

    private fun assertTextFits(text: TextView) {
        val layout = requireNotNull(text.layout)
        assertEquals(text.text.length, layout.getLineEnd(layout.lineCount - 1))
        assertTrue("Text '${text.text}' needs ${layout.height}px, but its view has ${text.height}px",
            layout.height <= text.height - text.compoundPaddingTop - text.compoundPaddingBottom)
        assertTrue((0 until layout.lineCount).all {
            layout.getEllipsisCount(it) == 0 &&
                layout.getLineWidth(it) <= text.width - text.compoundPaddingLeft - text.compoundPaddingRight
        })
    }

    private fun save(root: View, name: String) {
        val directory = System.getProperty("huda.widget.previewDir") ?: return
        val file = File(directory, "$name.png")
        file.parentFile.mkdirs()
        val bitmap = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.BLACK)
        root.draw(canvas)
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }
}
