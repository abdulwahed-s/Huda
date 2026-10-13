package com.aw.huda.prayer

import android.content.Context
import android.hardware.*
import android.os.*
import kotlin.math.sqrt

/**
 * A deliberate flip: the phone is seen steady in any pose that isn't face
 * down (flat, tilted in the hand, standing on a stand), then turns face down
 * within [FLIP_WINDOW_MILLIS] and stays there. The first [WARMUP_MILLIS] are
 * ignored (some phones report a default face-up reading when the sensor
 * starts), so a phone already lying face down never stops the adhan.
 */
internal class FlipGestureRecognizer {
    enum class State { WAITING, ARMED, DETECTED }

    private var startedAt: Long? = null
    private var armSince: Long? = null
    private var lastArmPose: Long? = null
    private var faceDownSince: Long? = null
    var state = State.WAITING
        private set

    /** True once, when the flip is complete. */
    fun sample(x: Double, y: Double, z: Double, elapsedMillis: Long): Boolean {
        if (state == State.DETECTED) return false
        val start = startedAt ?: elapsedMillis.also { startedAt = it }
        if (elapsedMillis - start < WARMUP_MILLIS) return false
        val magnitude = sqrt(x * x + y * y + z * z)
        // Only steady readings count: shaking or being picked up is not a pose.
        if (!magnitude.isFinite() || magnitude !in MIN_STEADY..MAX_STEADY) {
            armSince = null; faceDownSince = null; return false
        }
        val normalizedZ = z / magnitude
        if (normalizedZ > ARM_Z) {
            faceDownSince = null
            val since = armSince ?: elapsedMillis.also { armSince = it }
            if (elapsedMillis - since >= ARM_MILLIS) state = State.ARMED
            if (state == State.ARMED) lastArmPose = elapsedMillis
            return false
        }
        armSince = null
        if (state != State.ARMED) return false
        if (normalizedZ <= FACE_DOWN_Z) {
            if (faceDownSince == null) {
                // A slow slide face down (in a bag, on a sofa) is not a flip.
                if (elapsedMillis - (lastArmPose ?: elapsedMillis) > FLIP_WINDOW_MILLIS) {
                    state = State.WAITING; return false
                }
                faceDownSince = elapsedMillis
            }
            if (elapsedMillis - faceDownSince!! >= DOWN_DWELL_MILLIS) {
                state = State.DETECTED; return true
            }
        } else if (normalizedZ > FACE_DOWN_EXIT_Z) faceDownSince = null
        return false
    }

    private companion object {
        const val WARMUP_MILLIS = 1000L
        /** Anything that isn't face down arms: flat, tilted or standing up. */
        const val ARM_Z = -0.3
        const val ARM_MILLIS = 400L
        /** Face down within about 45 degrees of flat. */
        const val FACE_DOWN_Z = -0.7
        const val FACE_DOWN_EXIT_Z = -0.5
        const val FLIP_WINDOW_MILLIS = 2000L
        const val DOWN_DWELL_MILLIS = 400L
        const val MIN_STEADY = 8.3
        const val MAX_STEADY = 11.3
    }
}

internal class FlipToStopController(
    context: Context,
    private val onState: (FlipGestureRecognizer.State) -> Unit = {},
    private val onFlip: () -> Unit,
) : SensorEventListener {
    private val manager = context.getSystemService(SensorManager::class.java)
    private val sensor = manager.getDefaultSensor(Sensor.TYPE_GRAVITY, true)
        ?: manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER, true)
        ?: manager.getDefaultSensor(Sensor.TYPE_GRAVITY)
        ?: manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val recognizer = FlipGestureRecognizer()
    private val gravity = DoubleArray(3)
    private var first = true
    private var listening = false
    fun start(): Boolean {
        val source = sensor ?: return false
        listening = manager.registerListener(this, source, 66_667, Handler(Looper.getMainLooper()))
        return listening
    }
    fun close() { if (listening) manager.unregisterListener(this); listening = false }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
    override fun onSensorChanged(event: SensorEvent) {
        for (i in 0..2) gravity[i] = if (event.sensor.type == Sensor.TYPE_GRAVITY || first) event.values[i].toDouble()
            else 0.8 * gravity[i] + 0.2 * event.values[i]
        first = false
        val before = recognizer.state
        val flipped = recognizer.sample(gravity[0], gravity[1], gravity[2], event.timestamp / 1_000_000)
        if (recognizer.state != before) onState(recognizer.state)
        if (flipped) onFlip()
    }
    val available get() = sensor != null
}
