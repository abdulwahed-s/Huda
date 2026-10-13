package com.aw.huda.prayer

import android.app.Activity
import android.content.*
import android.os.*
import android.view.*
import android.util.TypedValue
import android.widget.*
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import java.time.*
import java.time.format.DateTimeFormatter

/** Overview and Stop remain usable without a Flutter engine or first unlock. */
class AdhanAlarmActivity : Activity() {
    private val runtime get() = PrayerNotificationRuntime.get(this)
    private var sessionId = ""
    private val observer: (Map<String, Any?>) -> Unit = { event ->
        if (event["type"] == "playbackEnded" && event["sessionId"] == sessionId) finish()
        else render()
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sessionId = savedInstanceState?.getString("session") ?: intent.getStringExtra("session").orEmpty()
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        else @Suppress("DEPRECATION") window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        runtime.subscribe(observer)
        render()
    }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); sessionId = intent.getStringExtra("session").orEmpty(); render() }
    override fun onSaveInstanceState(outState: Bundle) { outState.putString("session", sessionId); super.onSaveInstanceState(outState) }
    override fun onDestroy() { runtime.unsubscribe(observer); super.onDestroy() }
    private fun render() {
        val session = runtime.liveSession
        if (session == null || session.id != sessionId) { finish(); return }
        val locale = runtime.livePolicy.values["localeCode"] as? String ?: "en"
        val strings = NativePrayerStrings.forLocale(locale)
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        val accent = with(TypedValue()) {
            theme.resolveAttribute(android.R.attr.colorAccent, this, true); data
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(48), dp(28), dp(32))
            layoutDirection = if (locale.startsWith("ar") || locale.startsWith("ur")) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LOCALE
        }
        fun label(size: Float, bold: Boolean = false, alpha: Float = 1f) = TextView(this).apply {
            textSize = size; gravity = Gravity.CENTER; this.alpha = alpha
            if (bold) typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        val phase = label(16f, alpha = 0.7f).apply {
            text = if (session.phase == "playing") strings.playing else strings.preparing
        }
        val title = label(34f, bold = true).apply {
            text = session.prayer; ViewCompat.setAccessibilityHeading(this, true)
        }
        val time = label(56f).apply { typeface = android.graphics.Typeface.create("sans-serif-light", 0) }
        val recording = label(16f, alpha = 0.7f).apply { text = NativePrayerStrings.mode(locale, session.mode) }
        root.addView(phase)
        root.addView(title, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })
        root.addView(time, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(4) })
        root.addView(recording, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(4); bottomMargin = dp(40) })
        root.addView(Button(this).apply {
            text = strings.stop; textSize = 20f; isAllCaps = false; setTextColor(android.graphics.Color.WHITE)
            minHeight = dp(64)
            background = android.graphics.drawable.GradientDrawable().apply { cornerRadius = dp(32).toFloat(); setColor(accent) }
            setOnClickListener { runtime.playback.stop(sessionId) }
        }, LinearLayout.LayoutParams(-1, -2))
        fun secondary(label: String, click: () -> Unit) = root.addView(Button(this, null, android.R.attr.borderlessButtonStyle).apply {
            text = label; textSize = 16f; isAllCaps = false; setTextColor(accent); minHeight = dp(52)
            setOnClickListener { click() }
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })
        runtime.notifications.launch(session.occurrenceId, session.id)?.let { navigation ->
            secondary(strings.open) { navigation.send(); finish() }
        }
        val scroll = ScrollView(this).apply { isFillViewport = true; addView(root) }
        ViewCompat.setOnApplyWindowInsetsListener(scroll) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        setContentView(scroll)
        ViewCompat.requestApplyInsets(scroll)
        runtime.delivery.execute {
            val row = runtime.ownedRows().firstOrNull { it.id == session.occurrenceId }
            val asset = runtime.audio.asset(session.reciterId,
                PrayerPolicy.effective(runtime.livePolicy, session.prayer).version, if (session.mode == "short") "short" else "full")
            val name = if (session.reciterId == "huda-default") "Huda" else
                (if (locale.startsWith("ar")) asset?.nameArabic else asset?.nameEnglish) ?: "Adhan"
            runtime.main.post {
                if (!isFinishing && runtime.liveSession?.id == sessionId) {
                    title.text = row?.title ?: session.prayer
                    recording.text = "$name · ${NativePrayerStrings.mode(locale, session.mode)}"
                    time.text = row?.let { Instant.ofEpochMilli(it.utcMillis).atZone(ZoneId.of(it.timeZone))
                        .format(DateTimeFormatter.ofPattern("HH:mm")) }.orEmpty()
                }
            }
        }
    }
}
