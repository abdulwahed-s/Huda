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
            R.layout.samsung_prayer_compact_preview, R.layout.samsung_prayer_expanded_preview,
            R.layout.samsung_verse, R.layout.samsung_verse_bold)) {
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

    @Test fun versesAreCompleteAndTheirTextBoundsFitTheNativeLayout() {
        val configuration = QuranWidgetConfiguration(locale = "ar")
        val candidates = WidgetDataRepository.candidates(context, QuranWidgetSize.SMALL, configuration)
        assertEquals(13, candidates.size)
        var fittingCount = 0
        for (candidate in candidates) {
            val fitted = SamsungVerseFitter.fit(context, candidate, configuration,
                LockWidgetViewport(124f, 56f)) ?: continue
            fittingCount++
            val root = SamsungVerseWidgetUpdater.buildViews(context, configuration, fitted)
                .apply(context, FrameLayout(context))
            measure(root, 124, 56)
            val ayah = root.findViewById<TextView>(R.id.samsung_verse_text)
            val reference = root.findViewById<TextView>(R.id.samsung_verse_reference)
            assertEquals(candidate.verse.arabic, ayah.text.toString())
            assertEquals(ayah.text.length, ayah.layout.getLineEnd(ayah.layout.lineCount - 1))
            assertEquals(0, ayah.layout.getEllipsisCount(ayah.layout.lineCount - 1))
            assertTrue(ayah.top >= root.paddingTop)
            assertTrue(reference.bottom <= root.height - root.paddingBottom)
            assertEquals(fitted.reference, reference.text.toString())
            assertTextFits(ayah)
            assertTextFits(reference)
        }
        assertTrue("At least two complete verses should rotate at the nominal size", fittingCount >= 2)
        assertNull(SamsungVerseFitter.choose(context, candidates, configuration,
            LockWidgetViewport(10f, 10f), 0))
    }

    @Test fun verseFallbackThenFittingTextReapplyWithoutOldVisibility() {
        val configuration = QuranWidgetConfiguration()
        val root = SamsungVerseWidgetUpdater.buildViews(context, configuration, null)
            .apply(context, FrameLayout(context))
        assertEquals(View.GONE, root.findViewById<View>(R.id.samsung_verse_reference).visibility)
        val fitted = requireNotNull(SamsungVerseFitter.choose(context,
            WidgetDataRepository.candidates(context, QuranWidgetSize.SMALL, configuration),
            configuration, LockWidgetViewport(124f, 56f), 0))
        SamsungVerseWidgetUpdater.buildViews(context, configuration, fitted).reapply(context, root)
        assertEquals(View.VISIBLE, root.findViewById<View>(R.id.samsung_verse_reference).visibility)
        root.performClick()
        val intent = shadowOf(RuntimeEnvironment.getApplication()).nextStartedActivity
        assertEquals("huda://quran", intent.data.toString())
        assertEquals("es.antonborri.home_widget.action.LAUNCH", intent.action)
    }

    @Test fun boldVersesAndLongCountdownsFitTheirCompleteText() {
        val configuration = QuranWidgetConfiguration(locale = "ar", ayahBold = true)
        val candidates = WidgetDataRepository.candidates(context, QuranWidgetSize.SMALL, configuration)
        val fitted = candidates.mapNotNull {
            SamsungVerseFitter.fit(context, it, configuration, LockWidgetViewport(124f, 56f))
        }
        assertTrue("Bold text must leave a rotating subset", fitted.size >= 2)
        println("NATIVE_VERSE_FITTING bold=true count=${fitted.size} ids=${fitted.map { it.snapshot.verse.id }}")
        for (verse in fitted) {
            val root = SamsungVerseWidgetUpdater.buildViews(context, configuration, verse)
                .apply(context, FrameLayout(context))
            measure(root, 124, 56)
            assertTextFits(root.findViewById(R.id.samsung_verse_text))
            assertTextFits(root.findViewById(R.id.samsung_verse_reference))
        }
        val now = Date()
        val longTarget = target(now).copy(time = Date(now.time + 36_000_000L))
        for (expanded in listOf(false, true)) {
            val width = if (expanded) 124 else 56
            val (views, live) = SamsungPrayerWidgetUpdater.buildViews(context, expanded,
                LockWidgetViewport(width.toFloat(), 56f), lockPrayerSnapshot(), longTarget, now)
            val root = views.apply(context, FrameLayout(context))
            measure(root, width, 56)
            assertTextFits(root.findViewById(
                if (live) R.id.samsung_prayer_countdown else R.id.samsung_prayer_static_counter))
            save(root, "prayer-${if (expanded) "expanded" else "compact"}-long")
        }
    }

    @Test fun originalPrayerAndVerseCompositionsRenderInEnglishAndArabic() {
        val now = Date()
        for (arabic in listOf(false, true)) {
            val language = if (arabic) "ar" else "en"
            val snapshot = lockPrayerSnapshot().copy(
                language = if (arabic) PrayerWidgetLanguage.AR else PrayerWidgetLanguage.EN,
                numerals = if (arabic) PrayerWidgetNumerals.ARABIC else PrayerWidgetNumerals.LATIN)
            for (expanded in listOf(false, true)) {
                val width = if (expanded) 124 else 56
                val (views, live) = SamsungPrayerWidgetUpdater.buildViews(context, expanded,
                    LockWidgetViewport(width.toFloat(), 56f), snapshot, target(now), now)
                assertTrue(live)
                val root = views.apply(context, FrameLayout(context))
                measure(root, width, 56)
                val timer = root.findViewById<Chronometer>(R.id.samsung_prayer_countdown)
                assertTrue(timer.bottom <= root.height - root.paddingBottom)
                assertTextFits(timer)
                save(root, "prayer-${if (expanded) "expanded" else "compact"}-$language")
            }
            val configuration = QuranWidgetConfiguration(locale = language)
            val fitted = requireNotNull(SamsungVerseFitter.choose(context,
                WidgetDataRepository.candidates(context, QuranWidgetSize.SMALL, configuration),
                configuration, LockWidgetViewport(124f, 56f), 0))
            val root = SamsungVerseWidgetUpdater.buildViews(context, configuration, fitted)
                .apply(context, FrameLayout(context))
            measure(root, 124, 56)
            save(root, "verse-$language")
        }
    }

    @Test fun increasedFontScaleKeepsPrayerAndCompleteVerseContentInsideTheViewport() {
        val now = Date()
        for (fontScale in listOf(1.3f, 2f)) {
            val scaled = context.createConfigurationContext(
                android.content.res.Configuration(context.resources.configuration).apply {
                    this.fontScale = fontScale
                })
            for (expanded in listOf(false, true)) {
                val width = if (expanded) 124 else 56
                val root = SamsungPrayerWidgetUpdater.buildViews(scaled, expanded,
                    LockWidgetViewport(width.toFloat(), 56f), lockPrayerSnapshot(), target(now), now)
                    .first.apply(scaled, FrameLayout(scaled))
                measure(root, width, 56)
                for (id in listOf(R.id.samsung_prayer_name, R.id.samsung_prayer_time,
                    R.id.samsung_prayer_countdown, R.id.samsung_prayer_static_counter)) {
                    val text = root.findViewById<TextView>(id)
                    if (text.visibility != View.VISIBLE) continue
                    val bounds = android.graphics.Rect(0, 0, text.width, text.height)
                    (root as android.view.ViewGroup).offsetDescendantRectToMyCoords(text, bounds)
                    assertTrue("Prayer text clips at scale=$fontScale expanded=$expanded id=$id",
                        bounds.bottom <= root.height - root.paddingBottom)
                    assertTrue(bounds.top >= root.paddingTop)
                    assertTrue((0 until text.layout.lineCount).all {
                        text.layout.getLineWidth(it) <= text.width - text.paddingLeft - text.paddingRight
                    })
                    assertTextFits(text)
                }
            }
            for (language in listOf("en", "ar")) {
                val configuration = QuranWidgetConfiguration(locale = language)
                val candidates = WidgetDataRepository.candidates(scaled, QuranWidgetSize.SMALL, configuration)
                val fitted = SamsungVerseFitter.choose(scaled, candidates, configuration,
                    LockWidgetViewport(124f, 56f), 0)
                val root = SamsungVerseWidgetUpdater.buildViews(scaled, configuration, fitted)
                    .apply(scaled, FrameLayout(scaled))
                measure(root, 124, 56)
                val text = root.findViewById<TextView>(
                    if (fitted == null) R.id.samsung_verse_empty else R.id.samsung_verse_text)
                assertTrue("Verse or no-fit text clips at scale=$fontScale language=$language",
                    text.bottom <= root.height - root.paddingBottom && text.top >= root.paddingTop)
                assertEquals(text.text.length, text.layout.getLineEnd(text.layout.lineCount - 1))
                assertTextFits(text)
            }
        }
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
