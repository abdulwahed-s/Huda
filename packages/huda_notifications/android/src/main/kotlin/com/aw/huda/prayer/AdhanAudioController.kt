package com.aw.huda.prayer

import android.content.*
import android.media.*
import android.os.*
import java.io.File
import kotlin.math.min

/** Local, bounded, once-only player. All controls and MediaPlayer callbacks use the main looper. */
internal class AdhanAudioController(
    private val runtime: PrayerNotificationRuntime,
    private val session: SessionData,
    private val policy: EffectivePolicy,
    private val onStarted: (Long, Long, AudioAssetData, Boolean) -> Unit,
    private val onEnded: (String) -> Unit,
) {
    private val audioManager = runtime.context.getSystemService(AudioManager::class.java)
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var player: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var flip: FlipToStopController? = null
    private var noisyRegistered = false
    private var ended = false
    private var startedAt: Long? = null
    private var requestedAt = SystemClock.elapsedRealtime()
    private var gain = policy.gain
    private var limit = policy.cutoffSeconds?.times(1000L) ?: PrayerRules.MAX_DURATION_MS
    private var fallbackUsed = false
    private val callbacks = Handler(Looper.getMainLooper())
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT ||
            change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) finish("focusInterrupted")
    }
    private val noisy = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY && policy.stopOnNoisy) finish("headsetDisconnected")
        }
    }
    fun start() {
        runtime.delivery.execute {
            val selected = runtime.audio.asset(policy.reciterId, policy.version, if (policy.mode == "short") "short" else "full")
            val usable = selected?.takeIf { it.path.startsWith("android-resource:") || File(it.path).isFile }
                ?: runtime.audio.asset("huda-default", "v1", "full")!!
            callbacks.post {
                if (!ended) {
                    if (policy.mode == "short" && selected != null) limit = min(limit, selected.durationMillis)
                    prepare(usable)
                }
            }
        }
        callbacks.postDelayed({ if (startedAt == null) finish("preparationTimeout") }, 30_000)
    }
    private fun prepare(asset: AudioAssetData) {
        val bundled = asset.path.startsWith("android-resource:")
        val assetBound = if (policy.mode == "short" && bundled) PrayerRules.SHORT_FALLBACK_MS else asset.durationMillis
        limit = min(limit, assetBound)
        fallbackUsed = bundled
        try {
            val focusGranted = if (Build.VERSION.SDK_INT >= 26) {
                focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener, callbacks)
                    .setAcceptsDelayedFocusGain(false).build()
                audioManager.requestAudioFocus(focusRequest!!) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                @Suppress("DEPRECATION")
                (audioManager.requestAudioFocus(focusListener, AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
            }
            if (!focusGranted) { finish("focusDenied"); return }
            wakeLock = runtime.context.getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Huda:AdhanPlayback").apply {
                    setReferenceCounted(false); acquire((limit + 30_000).coerceAtMost(PrayerRules.MAX_DURATION_MS))
                }
            val media = MediaPlayer()
            player = media
            media.setAudioAttributes(attributes)
            media.isLooping = false
            media.setVolume(0f, 0f)
            media.setOnCompletionListener { finish("completed") }
            media.setOnErrorListener { _, _, _ -> preparationFailure(); true }
            media.setOnPreparedListener {
                try {
                if (ended) return@setOnPreparedListener
                val capabilities = PrayerCapabilities.read(runtime.context)
                if (session.automatic) {
                    PrayerCapabilities.audioBlockReason(capabilities, policy)?.let { reason -> finish(reason); return@setOnPreparedListener }
                    if (runtime.nowMillis() - session.scheduledUtcMillis > PrayerRules.LATE_WINDOW_MS) {
                        finish("skippedLate"); return@setOnPreparedListener
                    }
                }
                startedAt = SystemClock.elapsedRealtime()
                it.start()
                if (policy.stopOnNoisy) {
                    if (Build.VERSION.SDK_INT >= 33) runtime.context.registerReceiver(noisy,
                        IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY), Context.RECEIVER_NOT_EXPORTED)
                    else @Suppress("DEPRECATION") runtime.context.registerReceiver(noisy, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
                    noisyRegistered = true
                }
                if (policy.flip) flip = FlipToStopController(runtime.context) {
                    runtime.notifications.tick()
                    finish("stoppedByFlip")
                }.also { it.start() }
                if (policy.vibrate) vibrate()
                onStarted(startedAt!!, limit, asset, asset.reciterId != policy.reciterId)
                tick()
                } catch (_: Exception) { finish("playerError") }
            }
            if (bundled) {
                val resource = runtime.context.resources.getIdentifier("azan_sound", "raw", runtime.context.packageName)
                require(resource != 0) { "assetUnavailable" }
                runtime.context.resources.openRawResourceFd(resource).use { fd -> media.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length) }
            } else media.setDataSource(asset.path)
            media.prepareAsync()
            callbacks.postDelayed({ finish("watchdogTimeout") }, (asset.durationMillis + 30_000).coerceAtMost(PrayerRules.MAX_DURATION_MS))
        } catch (_: Exception) { preparationFailure() }
    }
    private fun preparationFailure() {
        if (!fallbackUsed && startedAt == null && SystemClock.elapsedRealtime() - requestedAt < 30_000) {
            releasePlayer()
            prepare(runtime.audio.asset("huda-default", "v1", "full")!!)
        } else finish("playerError")
    }
    private fun tick() {
        if (ended) return
        val elapsed = SystemClock.elapsedRealtime() - (startedAt ?: return)
        if (elapsed >= limit) { finish("cutoff"); return }
        val fade = if (policy.fadeSeconds == 0) 1.0 else (elapsed / (policy.fadeSeconds * 1000.0)).coerceIn(0.0, 1.0)
        val actual = (gain * fade).toFloat()
        player?.setVolume(actual, actual)
        callbacks.postDelayed({ tick() }, min(100L, limit - elapsed))
    }
    fun setGain(value: Double) { require(value.isFinite() && value in 0.0..1.0); gain = value }
    fun shortenCutoff(seconds: Int?) {
        if (seconds != null) limit = min(limit, seconds * 1000L)
        if (startedAt != null && SystemClock.elapsedRealtime() - startedAt!! >= limit) finish("cutoff")
    }
    private fun vibrate() {
        @Suppress("DEPRECATION") val vibrator = runtime.context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= 26) vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
        else @Suppress("DEPRECATION") vibrator.vibrate(500)
    }
    private fun releasePlayer() {
        try { player?.release() } catch (_: Exception) { }
        player = null
        runCatching {
            if (Build.VERSION.SDK_INT >= 26) focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            else @Suppress("DEPRECATION") audioManager.abandonAudioFocus(focusListener)
        }
        focusRequest = null
        runCatching { wakeLock?.let { if (it.isHeld) it.release() } }; wakeLock = null
    }
    fun finish(reason: String) {
        if (ended) return
        ended = true
        callbacks.removeCallbacksAndMessages(null)
        runCatching { flip?.close() }; flip = null
        if (noisyRegistered) { runCatching { runtime.context.unregisterReceiver(noisy) }; noisyRegistered = false }
        runCatching { @Suppress("DEPRECATION") (runtime.context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).cancel() }
        releasePlayer()
        onEnded(reason)
    }
}
