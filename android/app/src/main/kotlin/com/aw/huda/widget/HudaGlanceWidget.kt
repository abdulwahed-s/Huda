package com.aw.huda.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.layout.size
import androidx.glance.layout.wrapContentHeight
import androidx.glance.layout.wrapContentWidth
import androidx.glance.ColorFilter
import androidx.glance.unit.ColorProvider
import com.aw.huda.MainActivity
import com.aw.huda.R

class HudaGlanceWidget : GlanceAppWidget() {
    
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val quote = WidgetDataRepository.getCurrentQuote(context)
        val themeName = WidgetDataRepository.getThemeName(context)
        val isDarkMode = WidgetDataRepository.isDarkMode(context)
        val themeColors = WidgetThemeColors.getThemeColors(themeName, isDarkMode)

        val quoteBitmap = GlanceText.createTextBitmap(
            context = context,
            text = quote,
            textColor = themeColors.quoteTextColor,
            maxFontSize = 15f,
            maxWidth = 600
        )
        
        provideContent {
            GlanceTheme {
                WidgetContent(
                    quoteBitmap = quoteBitmap,
                    themeColors = themeColors
                )
            }
        }
    }
    
    @Composable
    private fun WidgetContent(
        quoteBitmap: android.graphics.Bitmap,
        themeColors: WidgetThemeColors.ThemeColors
    ) {
        val context = LocalContext.current
        val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(20.dp)
                .background(Color(themeColors.borderColor))
                .clickable(actionStartActivity(launchIntent))
                .padding(2.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .cornerRadius(18.dp)
                    .background(Color(themeColors.gradientStart))
                    .padding(14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                HeaderSection(themeColors = themeColors)
                
                Spacer(modifier = GlanceModifier.height(8.dp))

                QuoteCard(
                    quoteBitmap = quoteBitmap, 
                    themeColors = themeColors
                )
                
                Spacer(modifier = GlanceModifier.height(8.dp))

                BottomDecoration(themeColors = themeColors)
            }
        }
    }
    
    @Composable
    private fun HeaderSection(themeColors: WidgetThemeColors.ThemeColors) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .wrapContentHeight(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier
                    .width(50.dp)
                    .height(2.dp)
                    .background(Color(themeColors.accent))
            ) {}
            
            Spacer(modifier = GlanceModifier.width(8.dp))

            Box(
                modifier = GlanceModifier
                    .wrapContentWidth()
                    .wrapContentHeight()
                    .cornerRadius(16.dp)
                    .background(Color(themeColors.badgeBackground))
                    .padding(horizontal = 12.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(R.drawable.huda_icon),
                    contentDescription = "Huda",
                    modifier = GlanceModifier.size(28.dp),
                    contentScale = ContentScale.Fit,
                    colorFilter = ColorFilter.tint(ColorProvider(Color(themeColors.accent)))
                )
            }
            
            Spacer(modifier = GlanceModifier.width(8.dp))

            Box(
                modifier = GlanceModifier
                    .width(50.dp)
                    .height(2.dp)
                    .background(Color(themeColors.accent))
            ) {}
        }
    }
    
    @Composable
    private fun QuoteCard(
        quoteBitmap: android.graphics.Bitmap,
        themeColors: WidgetThemeColors.ThemeColors
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(120.dp)
                .cornerRadius(16.dp)
                .background(Color(themeColors.quoteCardBackground))
                .padding(8.dp),
            contentAlignment = Alignment.Center
        ) {
            Image(
                provider = ImageProvider(quoteBitmap),
                contentDescription = "Quote",
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .wrapContentHeight(),
                contentScale = ContentScale.Fit
            )
        }
    }
    
    @Composable
    private fun BottomDecoration(themeColors: WidgetThemeColors.ThemeColors) {
        Box(
            modifier = GlanceModifier
                .width(60.dp)
                .height(4.dp)
                .cornerRadius(2.dp)
                .background(Color(themeColors.accent).copy(alpha = 0.5f))
        ) {}
    }
}
