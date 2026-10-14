package com.aw.huda.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Local widget work gets a bounded broadcast lifetime, with durable work as recovery. */
internal object WidgetBroadcastDispatcher {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private const val BUDGET_MILLIS = 8_000L

    fun launch(
        context: Context,
        pending: BroadcastReceiver.PendingResult,
        tag: String,
        event: String,
        recovery: (Context) -> Unit,
        work: suspend (Context) -> Unit,
    ) {
        val appContext = context.applicationContext
        val finished = AtomicBoolean(false)
        val started = android.os.SystemClock.elapsedRealtime()
        // This separate deadline releases the broadcast even if synchronous rendering
        // does not cooperate with coroutine cancellation. The worker can recover it.
        val deadline = scope.launch {
            delay(BUDGET_MILLIS)
            if (finished.compareAndSet(false, true)) {
                try {
                    Log.w(tag, "$event exceeded broadcast budget; queueing recovery")
                    recovery(appContext)
                } finally {
                    pending.finish()
                }
            }
        }
        scope.launch {
            try {
                work(appContext)
                Log.i(tag, "$event complete elapsedMs=${android.os.SystemClock.elapsedRealtime() - started}")
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                Log.e(tag, "$event failed; queueing recovery", error)
                recovery(appContext)
            } finally {
                deadline.cancel()
                if (finished.compareAndSet(false, true)) pending.finish()
            }
        }
    }
}
