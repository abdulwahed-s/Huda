package com.aw.huda.prayer

import android.content.Context
import androidx.room.*
import com.google.gson.Gson

@Entity(tableName = "state")
internal data class StateRow(@PrimaryKey val key: String, val value: String)

/** Contains no coordinates, raw configuration signature or schema-3 payload. */
@Entity(tableName = "events", indices = [Index(value = ["token"], unique = true)])
internal data class AlarmRow(
    @PrimaryKey val key: String,
    val id: Long,
    val prayer: String,
    val utcMillis: Long,
    val timeZone: String,
    val localDate: String,
    val title: String,
    val body: String,
    val epoch: String,
    val generation: Long,
    val locationRevision: Long,
    val scheduleRevision: Long,
    val configurationDigest: String,
    val token: String,
    val precision: String = "unknown",
    val registration: String = "staged",
    val purpose: String = "prayer",
) {
    fun event() = EventData(id, prayer, utcMillis, timeZone, localDate, title, body, null)
    fun receipt() = RegistrationData(event(), token, precision, registration)
}

@Entity(tableName = "owners")
internal data class OwnerRow(@PrimaryKey val id: Long, val backend: String, val generation: Long)

@Entity(tableName = "aliases")
internal data class AliasRow(@PrimaryKey val legacyId: Long, val id: Long, val utcMillis: Long)

@Entity(tableName = "claims", indices = [Index(value = ["cursor"], unique = true)])
internal data class ClaimRow(
    @PrimaryKey val id: Long,
    val cursor: Long,
    val utcMillis: Long,
    val receivedMillis: Long,
    val locationRevision: Long,
    val scheduleRevision: Long,
    val backend: String,
    val outcome: String,
    val reason: String,
    val sessionId: String? = null,
) {
    fun data() = DeliveryData(cursor, id, utcMillis, receivedMillis, locationRevision,
        scheduleRevision, backend, outcome, reason, sessionId)
}

@Dao
internal interface PrayerDao {
    @Query("SELECT * FROM state WHERE `key` = :key") fun state(key: String): StateRow?
    @Insert(onConflict = OnConflictStrategy.REPLACE) fun put(row: StateRow)
    @Query("DELETE FROM state WHERE `key` = :key") fun deleteState(key: String)
    @Query("SELECT * FROM state WHERE `key` LIKE :prefix") fun states(prefix: String): List<StateRow>
    @Insert(onConflict = OnConflictStrategy.REPLACE) fun putEvent(row: AlarmRow)
    @Query("SELECT * FROM events WHERE `key` = :key") fun event(key: String): AlarmRow?
    @Query("SELECT * FROM events WHERE token = :token") fun eventByToken(token: String): AlarmRow?
    @Query("SELECT * FROM events ORDER BY utcMillis, id") fun events(): List<AlarmRow>
    @Query("DELETE FROM events WHERE `key` = :key") fun deleteEvent(key: String)
    @Query("SELECT * FROM owners WHERE id = :id") fun owner(id: Long): OwnerRow?
    @Insert(onConflict = OnConflictStrategy.REPLACE) fun putOwner(row: OwnerRow)
    @Insert(onConflict = OnConflictStrategy.REPLACE) fun putAlias(row: AliasRow)
    @Query("SELECT * FROM aliases WHERE legacyId = :id") fun alias(id: Long): AliasRow?
    @Query("SELECT * FROM claims WHERE id = :id") fun claim(id: Long): ClaimRow?
    @Insert(onConflict = OnConflictStrategy.IGNORE) fun insertClaim(row: ClaimRow): Long
    @Update fun updateClaim(row: ClaimRow)
    @Query("SELECT * FROM claims WHERE cursor > :cursor ORDER BY cursor LIMIT :limit")
    fun history(cursor: Long, limit: Int): List<ClaimRow>
    @Query("SELECT * FROM claims ORDER BY cursor DESC LIMIT :limit") fun latest(limit: Int): List<ClaimRow>
    @Query("DELETE FROM claims WHERE utcMillis < :boundary") fun pruneClaims(boundary: Long)
    @Query("DELETE FROM claims") fun clearClaims()
}

@Database(entities = [StateRow::class, AlarmRow::class, OwnerRow::class, AliasRow::class, ClaimRow::class],
    version = 1, exportSchema = true)
internal abstract class PrayerAlarmDatabase : RoomDatabase() {
    abstract fun dao(): PrayerDao
    companion object {
        fun open(context: Context) = Room.databaseBuilder(
            context.createDeviceProtectedStorageContext(), PrayerAlarmDatabase::class.java,
            "huda_prayer_execution.db",
        ).build() // No destructive migration or main-thread queries.
    }
}

internal class PrayerStore(val database: PrayerAlarmDatabase) {
    val dao = database.dao()
    val gson = Gson()
    fun <T> read(key: String, type: Class<T>): T? = dao.state(key)?.let { gson.fromJson(it.value, type) }
    fun write(key: String, value: Any) = dao.put(StateRow(key, gson.toJson(value)))
    fun text(key: String, default: String = "") = dao.state(key)?.value ?: default
    fun putText(key: String, value: String) = dao.put(StateRow(key, value))
    fun nextCursor(): Long {
        val cursor = text("historyCursor", "0").toLong() + 1
        putText("historyCursor", cursor.toString())
        return cursor
    }
    fun <T> transaction(action: () -> T): T = database.runInTransaction(java.util.concurrent.Callable { action() })
}
