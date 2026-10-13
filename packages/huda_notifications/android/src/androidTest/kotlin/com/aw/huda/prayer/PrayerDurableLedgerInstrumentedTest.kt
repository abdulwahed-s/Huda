package com.aw.huda.prayer

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.*

/** Verifies SQLite locking and reopen using device-protected storage. */
@RunWith(AndroidJUnit4::class)
class PrayerDurableLedgerInstrumentedTest {
    @Test fun twoDatabaseClientsShareOneOccurrenceClaimAcrossReopen() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext.createDeviceProtectedStorageContext()
        val name = "instrumented-prayer-claims.db"
        context.deleteDatabase(name)
        fun open() = Room.databaseBuilder(context, PrayerAlarmDatabase::class.java, name).build()
        var first = open()
        val second = open()
        val pool = Executors.newFixedThreadPool(8)
        try {
            assertTrue(context.isDeviceProtectedStorage)
            val start = CountDownLatch(1)
            val claims = (0 until 32).map { index -> pool.submit(Callable {
                start.await()
                val store = PrayerStore(if (index % 2 == 0) first else second)
                store.transaction {
                    if (store.dao.claim(326100091) != null) false else {
                        store.dao.insertClaim(ClaimRow(326100091, store.nextCursor(), 1, 1, 1, 1,
                            "native", "attempted", "instrumented", "session-$index")) != -1L
                    }
                }
            }) }
            start.countDown()
            assertEquals(1, claims.count { it.get(30, TimeUnit.SECONDS) })
            first.close()
            first = open()
            assertEquals(1, first.dao().history(0, 1000).size)
            assertNotNull(first.dao().claim(326100091))
            assertEquals(context.getDatabasePath(name).absolutePath, first.openHelper.writableDatabase.path)
        } finally {
            pool.shutdownNow(); first.close(); second.close(); context.deleteDatabase(name)
        }
    }
}
