package com.aw.huda.widget.lockscreen

import android.app.Application
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.work.Configuration
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import com.aw.huda.R
import com.aw.huda.widget.HudaGlanceWidgetReceiver
import com.aw.huda.widget.QuranWidgetUpdater
import com.aw.huda.widget.prayer.PrayerWidgetReceiver
import com.aw.huda.widget.prayer.PrayerWidgetUpdater
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.util.ReflectionHelpers

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class SamsungLockLifecycleTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val manager: AppWidgetManager get() = AppWidgetManager.getInstance(context)

    @Before fun initializeWorkManager() {
        WorkManagerTestInitHelper.initializeTestWorkManager(context,
            Configuration.Builder().setExecutor(SynchronousExecutor()).build())
    }

    private fun bind(id: Int, provider: Class<*>, layout: Int) {
        shadowOf(manager).addBoundWidget(id, AppWidgetProviderInfo().apply {
            this.provider = ComponentName(context, provider)
            initialLayout = layout
        })
    }

    private fun remove(id: Int) {
        // Robolectric 4.16 exposes binding but no removal helper. Change only
        // its host inventory so production discovery observes actual absence.
        ReflectionHelpers.getField<MutableMap<Int, Any>>(shadowOf(manager), "widgetInfos").remove(id)
    }

    private fun activeWork(name: String) = WorkManager.getInstance(context)
        .getWorkInfosForUniqueWork(name).get(5, TimeUnit.SECONDS).any { !it.state.isFinished }

    @Test fun eachLockPrayerVariantWorksWithoutHomeWidgetsAndSharesOneJob() {
        bind(1, SamsungPrayerCompactReceiver::class.java, R.layout.samsung_prayer_compact)
        bind(2, SamsungPrayerExpandedReceiver::class.java, R.layout.samsung_prayer_expanded)
        val first = PrayerWidgetUpdater.updateAll(context)
        assertEquals(2, first.widgetCount)
        assertEquals(2, first.successfulUpdates)
        assertEquals(0, first.failedUpdates)
        assertTrue(activeWork("prayer_widget_reliability"))
        remove(1)
        val remaining = PrayerWidgetUpdater.updateAll(context)
        assertEquals(1, remaining.widgetCount)
        assertTrue(activeWork("prayer_widget_reliability"))
        remove(2)
        assertEquals(0, PrayerWidgetUpdater.updateAll(context).widgetCount)
        assertFalse(activeWork("prayer_widget_reliability"))
    }

    @Test fun removingLastHomeWidgetDoesNotStopNativePrayerOrQuranWork() = runBlocking {
        bind(1, PrayerWidgetReceiver::class.java, R.layout.prayer_widget_bitmap_container)
        bind(2, SamsungPrayerCompactReceiver::class.java, R.layout.samsung_prayer_compact)
        bind(3, SamsungVerseReceiver::class.java, R.layout.samsung_verse)
        PrayerWidgetUpdater.updateAll(context)
        QuranWidgetUpdater.refreshAll(context)
        remove(1)
        assertEquals(1, PrayerWidgetUpdater.updateAll(context).widgetCount)
        assertTrue(activeWork("prayer_widget_reliability"))
        assertTrue(activeWork(HudaGlanceWidgetReceiver.WORK_NAME))
        remove(2)
        PrayerWidgetUpdater.updateAll(context)
        assertFalse(activeWork("prayer_widget_reliability"))
        assertTrue(activeWork(HudaGlanceWidgetReceiver.WORK_NAME))
        remove(3)
        QuranWidgetUpdater.refreshAll(context)
        assertFalse(activeWork(HudaGlanceWidgetReceiver.WORK_NAME))
    }

    @Test fun verseOnlyInstallationKeepsHourlyWorkAfterHomeRemoval() = runBlocking {
        bind(1, HudaGlanceWidgetReceiver::class.java, R.layout.samsung_verse)
        bind(2, SamsungVerseReceiver::class.java, R.layout.samsung_verse)
        HudaGlanceWidgetReceiver.ensureHourlyUpdates(context)
        remove(1)
        HudaGlanceWidgetReceiver.ensureHourlyUpdates(context)
        assertTrue(activeWork(HudaGlanceWidgetReceiver.WORK_NAME))
        QuranWidgetUpdater.refreshAll(context)
        assertNotNull(shadowOf(manager).getViewFor(2))
    }

    @Test fun pluginBroadcastWithEmptyHomeIdsRefreshesBoundLockInstances() {
        bind(1, SamsungPrayerCompactReceiver::class.java, R.layout.samsung_prayer_compact)
        bind(2, SamsungPrayerExpandedReceiver::class.java, R.layout.samsung_prayer_expanded)
        context.sendBroadcast(Intent(context, PrayerWidgetReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf())
            putExtra("es.antonborri.home_widget.TRIGGERED_FROM_HOME_WIDGET", true)
        })
        shadowOf(Looper.getMainLooper()).idle()
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(6)
        while (shadowOf(manager).getViewFor(2) == null && System.nanoTime() < deadline) {
            Thread.sleep(10)
        }
        assertNotNull("Empty-home-ID broadcast must reach compact lock widget", shadowOf(manager).getViewFor(1))
        assertNotNull("Empty-home-ID broadcast must reach expanded lock widget", shadowOf(manager).getViewFor(2))
    }
}
