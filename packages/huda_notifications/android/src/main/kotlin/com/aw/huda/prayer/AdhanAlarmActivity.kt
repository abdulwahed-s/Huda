package com.aw.huda.prayer

import android.animation.*
import android.app.Activity
import android.content.*
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.*
import android.os.*
import android.text.SpannableString
import android.text.Spanned
import android.text.format.DateFormat
import android.text.style.RelativeSizeSpan
import android.util.TypedValue
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.*
import androidx.core.content.res.ResourcesCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import java.time.*
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Overview and Stop remain usable without a Flutter engine or first unlock.
 * The views are built once per Activity and bound again on every runtime
 * event, so the pulse keeps running through phase changes.
 */
class AdhanAlarmActivity : Activity() {
    private val runtime get() = PrayerNotificationRuntime.get(this)
    private var sessionId = ""
    private var locale = "en"
    private lateinit var palette: AdhanAlarmPalette
    private lateinit var phase: TextView
    private lateinit var title: TextView
    private lateinit var time: TextView
    private lateinit var date: TextView
    private lateinit var recording: TextView
    private lateinit var progress: ProgressBar
    private lateinit var remaining: TextView
    private lateinit var flipHint: TextView
    private lateinit var emblem: FrameLayout
    private lateinit var prayerIcon: ImageView
    private lateinit var rings: List<View>
    private lateinit var dot: GradientDrawable
    private var detailsFor: String? = null
    private val pulses = mutableListOf<Animator>()
    private var visible = false
    private val ticker = Handler(Looper.getMainLooper())
    private val progressTick = object : Runnable {
        override fun run() { updateProgress(); ticker.postDelayed(this, 500) }
    }
    private val observer: (Map<String, Any?>) -> Unit = { event ->
        if (event["type"] == "playbackEnded" && event["sessionId"] == sessionId) finish()
        else bind()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sessionId = savedInstanceState?.getString("session") ?: intent.getStringExtra("session").orEmpty()
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        else @Suppress("DEPRECATION") window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        locale = if (runtime.liveSession?.prayer == "sahur") runtime.sahur.settings.locale else runtime.livePolicy.values["localeCode"] as? String ?: "en"
        palette = AdhanAlarmPalette.read(this)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        @Suppress("DEPRECATION") window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION") window.navigationBarColor = Color.TRANSPARENT
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false; isAppearanceLightNavigationBars = false
        }
        setContentView(build())
        runtime.subscribe(observer)
        bind()
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent); setIntent(intent)
        sessionId = intent.getStringExtra("session").orEmpty(); bind()
    }
    override fun onStart() { super.onStart(); visible = true; bind(); ticker.post(progressTick) }
    override fun onStop() { visible = false; ticker.removeCallbacks(progressTick); pulse(false); super.onStop() }
    override fun onSaveInstanceState(outState: Bundle) { outState.putString("session", sessionId); super.onSaveInstanceState(outState) }
    override fun onDestroy() { runtime.unsubscribe(observer); ticker.removeCallbacksAndMessages(null); pulse(false); super.onDestroy() }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun withAlpha(color: Int, alpha: Int) = (color and 0x00FFFFFF) or (alpha shl 24)
    private val rtl get() = locale.startsWith("ar") || locale.startsWith("ur")
    private fun font(name: String): Typeface? = runCatching {
        resources.getIdentifier(name, "font", packageName).takeIf { it != 0 }?.let { ResourcesCompat.getFont(this, it) }
    }.getOrNull()
    private fun icon(name: String, size: Int): Drawable? = resources.getIdentifier(name, "drawable", packageName)
        .takeIf { it != 0 }?.let { runCatching { getDrawable(it) }.getOrNull() }
        ?.mutate()?.apply { setTint(palette.light); setBounds(0, 0, dp(size), dp(size)) }
    private fun label(size: Float, color: Int = Color.WHITE, alpha: Float = 1f) = TextView(this).apply {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, size); gravity = Gravity.CENTER
        setTextColor(color); this.alpha = alpha
    }
    private fun pill(color: Int) = GradientDrawable().apply { cornerRadius = dp(999).toFloat(); setColor(color) }
    private fun oval(fill: Int, stroke: Int = 0) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL; setColor(fill); if (stroke != 0) setStroke(dp(1), stroke)
    }

    private fun build(): View {
        val strings = NativePrayerStrings.forLocale(locale)
        val amiri = font("amiri")
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(20), dp(28), dp(24))
            layoutDirection = if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LOCALE
        }
        fun add(view: View, top: Int = 0, width: Int = -1, height: Int = -2) =
            column.addView(view, LinearLayout.LayoutParams(width, height).apply { topMargin = dp(top) })
        fun spacer() = column.addView(Space(this), LinearLayout.LayoutParams(-1, 0, 1f))

        add(label(14f, alpha = 0.75f).apply {
            text = applicationInfo.loadLabel(packageManager)
            letterSpacing = 0.08f
            setCompoundDrawablesRelative(icon("ic_widget_crescent", 14), null, null, null)
            compoundDrawablePadding = dp(6)
        }, width = -2)
        date = label(13f, alpha = 0.55f)
        add(date, top = 4)
        spacer()

        rings = List(2) { View(this).apply { background = oval(0, withAlpha(palette.light, 0x80)); alpha = 0f } }
        emblem = FrameLayout(this).apply {
            rings.forEach { addView(it, FrameLayout.LayoutParams(dp(112), dp(112), Gravity.CENTER)) }
            addView(View(this@AdhanAlarmActivity).apply {
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL; gradientType = GradientDrawable.RADIAL_GRADIENT
                    gradientRadius = dp(84).toFloat()
                    colors = intArrayOf(withAlpha(palette.light, 0x38), withAlpha(palette.light, 0x00))
                }
            }, FrameLayout.LayoutParams(dp(176), dp(176), Gravity.CENTER))
            prayerIcon = ImageView(this@AdhanAlarmActivity).apply {
                background = oval(withAlpha(palette.light, 0x1F), withAlpha(palette.light, 0x59))
                scaleType = ImageView.ScaleType.CENTER_INSIDE
                setPadding(dp(26), dp(26), dp(26), dp(26))
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            addView(prayerIcon, FrameLayout.LayoutParams(dp(112), dp(112), Gravity.CENTER))
            // Short landscape windows keep the controls in view without scrolling.
            visibility = if (resources.configuration.screenHeightDp < 520) View.GONE else View.VISIBLE
        }
        add(emblem, width = dp(176), height = dp(176))

        dot = oval(palette.light).apply { setSize(dp(7), dp(7)); setBounds(0, 0, dp(7), dp(7)) }
        phase = label(13f, palette.light).apply {
            background = pill(withAlpha(palette.light, 0x1F))
            setPadding(dp(14), dp(6), dp(14), dp(6))
            setCompoundDrawablesRelative(dot, null, null, null)
            compoundDrawablePadding = dp(8)
        }
        add(phase, top = 16, width = -2)
        title = label(40f).apply {
            typeface = if (rtl) Typeface.create(amiri ?: Typeface.DEFAULT, Typeface.BOLD)
                else Typeface.create("sans-serif-medium", Typeface.NORMAL)
            ViewCompat.setAccessibilityHeading(this, true)
        }
        add(title, top = 14)
        time = label(60f).apply { typeface = Typeface.create("sans-serif-light", Typeface.NORMAL); visibility = View.GONE }
        add(time)
        // The adhan's own call, "come to prayer", in Huda's Quran font.
        add(label(24f, palette.light, 0.9f).apply {
            text = "حَيَّ عَلَى الصَّلَاةِ"; textDirection = View.TEXT_DIRECTION_RTL
            typeface = amiri ?: Typeface.SERIF
            if (runtime.liveSession?.prayer == "sahur") {
                text = runtime.sahur.settings.body; textDirection = View.TEXT_DIRECTION_LOCALE
            }
        }, top = 6)
        recording = label(14f, alpha = 0.6f)
        add(recording, top = 6)
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 1000; isIndeterminate = true
            progressTintList = ColorStateList.valueOf(palette.light)
            indeterminateTintList = ColorStateList.valueOf(palette.light)
            progressBackgroundTintList = ColorStateList.valueOf(withAlpha(Color.WHITE, 0x2E))
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        add(progress, top = 20, width = dp(200), height = dp(4))
        remaining = label(12f, alpha = 0.5f).apply { importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO }
        add(remaining, top = 6)
        spacer()

        add(Button(this).apply {
            text = if (runtime.liveSession?.prayer == "sahur") runtime.sahur.settings.stop else strings.stop
            isAllCaps = false; minHeight = dp(64); stateListAnimator = null
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f); typeface = Typeface.DEFAULT_BOLD
            setTextColor(palette.deep)
            background = RippleDrawable(ColorStateList.valueOf(withAlpha(palette.deep, 0x33)), pill(palette.light), null)
            setOnClickListener {
                performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                runtime.playback.stop(sessionId)
                if (runtime.liveSession?.id != sessionId) finish()
            }
        }, top = 24, width = if (resources.configuration.screenWidthDp > 480) dp(420) else -1)
        flipHint = label(13f, alpha = 0.55f).apply { text = strings.flipHint; visibility = View.GONE }
        add(flipHint, top = 12)
        runtime.liveSession?.takeIf { it.id == sessionId && it.prayer != "sahur" }?.let { session ->
            runtime.notifications.launch(session.occurrenceId, session.id)?.let { navigation ->
                add(Button(this, null, android.R.attr.borderlessButtonStyle).apply {
                    text = strings.open; isAllCaps = false; minHeight = dp(52)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f); setTextColor(palette.light)
                    setOnClickListener { navigation.send(); finish() }
                }, top = 4)
            }
        }

        val scroll = ScrollView(this).apply { isFillViewport = true; addView(column) }
        ViewCompat.setOnApplyWindowInsetsListener(scroll) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        ViewCompat.requestApplyInsets(scroll)
        if (animatorsEnabled()) {
            column.alpha = 0f; column.translationY = dp(24).toFloat()
            column.animate().alpha(1f).translationY(0f).setDuration(450).setInterpolator(DecelerateInterpolator()).start()
        }
        return FrameLayout(this).apply {
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR,
                intArrayOf(palette.gradientStart, palette.gradientMid, palette.gradientEnd))
            addView(scroll, FrameLayout.LayoutParams(-1, -1))
        }
    }

    private fun bind() {
        val session = runtime.liveSession
        if (session == null || session.id != sessionId) { finish(); return }
        val strings = NativePrayerStrings.forLocale(locale)
        val playing = session.phase == "playing"
        phase.text = if (session.prayer == "sahur") runtime.sahur.settings.title else if (!session.automatic) NativePrayerStrings.labels(locale).preview
            else if (playing) strings.playing else strings.preparing
        title.text = if (session.prayer == "sahur") runtime.sahur.settings.title else NativePrayerStrings.prayerName(locale, session.prayer)
        prayerIcon.setImageDrawable(
            icon("ic_prayer_${session.prayer}", 44) ?: icon("ic_widget_crescent", 44))
        val policy = runtime.effective(session.prayer)
        flipHint.visibility = if (session.automatic && policy.flip) View.VISIBLE else View.GONE
        pulse(playing && visible)
        updateProgress()
        if (detailsFor != session.id) { detailsFor = session.id; loadDetails(session) }
    }

    /** The row and reciter name come from storage, off the main thread, once per session. */
    private fun loadDetails(session: SessionData) {
        runtime.delivery.execute {
            val row = runCatching { runtime.ownedRows().firstOrNull { it.id == session.occurrenceId } }.getOrNull()
            val asset = runCatching { runtime.audio.asset(session.reciterId,
                runtime.effective(session.prayer).version, if (session.mode == "short") "short" else "full") }.getOrNull()
            val name = if (session.reciterId == "huda-default") "Huda" else
                (if (locale.startsWith("ar")) asset?.nameArabic else asset?.nameEnglish) ?: "Adhan"
            runtime.main.post {
                if (isFinishing || runtime.liveSession?.id != sessionId) return@post
                recording.text = if (session.prayer == "sahur") "" else "$name · ${NativePrayerStrings.mode(locale, session.mode)}"
                val zoned = row?.let { runCatching { Instant.ofEpochMilli(it.utcMillis).atZone(ZoneId.of(it.timeZone)) }.getOrNull() }
                val language = Locale.forLanguageTag(locale.replace('_', '-'))
                if (zoned != null) {
                    val clock = DateTimeFormatter.ofPattern(DateFormat.getBestDateTimePattern(language,
                        if (DateFormat.is24HourFormat(this)) "Hm" else "hm"), language).format(zoned)
                    val marker = DateTimeFormatter.ofPattern("a", language).format(zoned)
                    time.text = SpannableString(clock).apply {
                        val at = clock.indexOf(marker)
                        if (marker.isNotBlank() && at >= 0 && !DateFormat.is24HourFormat(this@AdhanAlarmActivity))
                            setSpan(RelativeSizeSpan(0.38f), at, at + marker.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                    }
                    time.visibility = View.VISIBLE
                }
                date.text = DateTimeFormatter.ofPattern(DateFormat.getBestDateTimePattern(language, "EEEEdMMMM"), language)
                    .format(zoned ?: ZonedDateTime.now())
            }
        }
    }

    private fun updateProgress() {
        val session = runtime.liveSession?.takeIf { it.id == sessionId } ?: return
        val limit = session.limitMillis?.takeIf { it > 0 }
        if (session.phase != "playing" || limit == null) {
            progress.isIndeterminate = true; remaining.text = ""; return
        }
        val elapsed = (SystemClock.elapsedRealtime() - session.startedElapsedMillis).coerceIn(0L, limit)
        progress.isIndeterminate = false
        progress.progress = (elapsed * 1000 / limit).toInt()
        val left = (limit - elapsed + 999) / 1000
        remaining.text = String.format(Locale.ROOT, "%d:%02d", left / 60, left % 60)
    }

    /** Two rings breathe out of the emblem while the adhan plays; nothing moves when animations are off. */
    private fun pulse(on: Boolean) {
        if (on == pulses.isNotEmpty()) return
        pulses.forEach { it.cancel() }; pulses.clear()
        dot.alpha = 255
        rings.forEach { it.alpha = 0f; it.scaleX = 1f; it.scaleY = 1f }
        if (!on || !animatorsEnabled()) return
        rings.forEachIndexed { index, ring ->
            pulses += ObjectAnimator.ofPropertyValuesHolder(ring,
                PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.55f),
                PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.55f),
                PropertyValuesHolder.ofFloat(View.ALPHA, 0.9f, 0f)).apply {
                duration = 2600; startDelay = index * 1300L
                repeatCount = ValueAnimator.INFINITE; interpolator = DecelerateInterpolator()
                start()
            }
        }
        pulses += ObjectAnimator.ofInt(dot, "alpha", 255, 90).apply {
            duration = 900; repeatMode = ValueAnimator.REVERSE; repeatCount = ValueAnimator.INFINITE
            start()
        }
    }

    /** Battery saver and "Remove animations" set the duration scale to zero. */
    private fun animatorsEnabled() = Build.VERSION.SDK_INT < 26 || ValueAnimator.areAnimatorsEnabled()
}
