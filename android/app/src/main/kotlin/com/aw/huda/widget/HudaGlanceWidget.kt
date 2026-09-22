package com.aw.huda.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.ContentScale
import androidx.glance.layout.fillMaxSize
import com.aw.huda.MainActivity

class HudaGlanceWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = WidgetDataRepository.snapshot(context)
        provideContent {
            GlanceTheme {
                WidgetContent(snapshot)
            }
        }
    }

    @Composable
    private fun WidgetContent(snapshot: WidgetDataRepository.Snapshot) {
        val context = LocalContext.current
        val size = LocalSize.current
        val bitmap = QuranWidgetRenderer.render(
            context = context,
            widthDp = size.width.value,
            heightDp = size.height.value,
            snapshot = snapshot,
        )
        val accessibilityText = listOfNotNull(
            snapshot.verse.arabic,
            snapshot.translation,
            snapshot.displayReference,
        ).joinToString(". ")
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("huda://quran")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        Image(
            provider = ImageProvider(bitmap),
            contentDescription = accessibilityText,
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(26.dp)
                .clickable(actionStartActivity(launchIntent)),
            contentScale = ContentScale.FillBounds,
        )
    }
}
