package com.aw.huda.miqaat

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar


class MiqaatLockAccessibilityService : AccessibilityService() {

    companion object {
        const val PREFS_NAME = "miqaat_lock_prefs"
        const val KEY_IS_ENABLED = "is_enabled"
        const val KEY_LOCKED_APPS = "locked_apps"
        const val KEY_TIME_SLOTS = "time_slots"
        const val KEY_GOAL_DURATION = "goal_duration"
        const val KEY_COMPLETED_SLOTS = "completed_slots"
        const val KEY_COMPLETED_SLOTS_DATE = "completed_slots_date"

        var instance: MiqaatLockAccessibilityService? = null
            private set
    }

    private lateinit var prefs: SharedPreferences
    private var lockedApps: Set<String> = emptySet()
    private var timeSlots: List<TimeSlotData> = emptyList()
    private var isEnabled: Boolean = false
    private var goalDurationMinutes: Int = 10

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        loadSettings()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        if (!isEnabled) return

        val packageName = event.packageName?.toString() ?: return


        if (packageName == "com.aw.huda" ||
            packageName == "com.android.systemui" ||
            packageName.startsWith("com.android.launcher")
        ) {
            return
        }


        if (!lockedApps.contains(packageName)) return


        val activeSlot = getActiveTimeSlot()
        if (activeSlot == null) return


        if (isTimeSlotCompleted(activeSlot.id)) return


        showLockOverlay(packageName)
    }

    override fun onInterrupt() {

    }

    private fun loadSettings() {
        isEnabled = prefs.getBoolean(KEY_IS_ENABLED, false)
        goalDurationMinutes = prefs.getInt(KEY_GOAL_DURATION, 10)


        val appsJson = prefs.getString(KEY_LOCKED_APPS, "[]") ?: "[]"
        lockedApps = try {
            val array = JSONArray(appsJson)
            (0 until array.length()).map { array.getString(it) }.toSet()
        } catch (e: Exception) {
            emptySet()
        }


        val slotsJson = prefs.getString(KEY_TIME_SLOTS, "[]") ?: "[]"
        timeSlots = try {
            val array = JSONArray(slotsJson)
            (0 until array.length()).map { index ->
                val slot = array.getJSONObject(index)
                TimeSlotData(
                    id = slot.optString("id", "slot_$index"),
                    startHour = slot.getInt("startHour"),
                    startMinute = slot.getInt("startMinute"),
                    endHour = slot.getInt("endHour"),
                    endMinute = slot.getInt("endMinute"),
                    weekdays = slot.optJSONArray("weekdays")?.let { arr ->
                        (0 until arr.length()).map { arr.getInt(it) }
                    } ?: emptyList()
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun updateSettings(
        enabled: Boolean,
        apps: List<String>,
        slots: List<Map<String, Any>>,
        goalDuration: Int
    ) {
        isEnabled = enabled
        lockedApps = apps.toSet()
        goalDurationMinutes = goalDuration

        timeSlots = slots.map { slot ->
            TimeSlotData(
                id = (slot["id"] as? String) ?: "",
                startHour = (slot["startHour"] as? Number)?.toInt() ?: 0,
                startMinute = (slot["startMinute"] as? Number)?.toInt() ?: 0,
                endHour = (slot["endHour"] as? Number)?.toInt() ?: 0,
                endMinute = (slot["endMinute"] as? Number)?.toInt() ?: 0,
                weekdays = (slot["weekdays"] as? List<*>)?.mapNotNull { (it as? Number)?.toInt() }
                    ?: emptyList()
            )
        }


        prefs.edit().apply {
            putBoolean(KEY_IS_ENABLED, enabled)
            putInt(KEY_GOAL_DURATION, goalDuration)
            putString(KEY_LOCKED_APPS, JSONArray(apps).toString())
            putString(KEY_TIME_SLOTS, JSONArray(slots.map { JSONObject(it) }).toString())
            apply()
        }
    }


    private fun getActiveTimeSlot(): TimeSlotData? {
        if (timeSlots.isEmpty()) return null

        val calendar = Calendar.getInstance()
        val currentMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        val isoDayOfWeek = if (dayOfWeek == 1) 7 else dayOfWeek - 1

        return timeSlots.firstOrNull { slot ->

            if (slot.weekdays.isNotEmpty() && !slot.weekdays.contains(isoDayOfWeek)) {
                return@firstOrNull false
            }

            val startMinutes = slot.startHour * 60 + slot.startMinute
            val endMinutes = slot.endHour * 60 + slot.endMinute


            if (endMinutes < startMinutes) {
                currentMinutes >= startMinutes || currentMinutes < endMinutes
            } else {
                currentMinutes >= startMinutes && currentMinutes < endMinutes
            }
        }
    }


    private fun isTimeSlotCompleted(slotId: String): Boolean {

        val today = android.icu.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            .format(java.util.Date())
        val storedDate = prefs.getString(KEY_COMPLETED_SLOTS_DATE, null)

        if (storedDate != today) {

            prefs.edit().apply {
                remove(KEY_COMPLETED_SLOTS)
                putString(KEY_COMPLETED_SLOTS_DATE, today)
                apply()
            }
            return false
        }

        val completedSlots = prefs.getStringSet(KEY_COMPLETED_SLOTS, emptySet()) ?: emptySet()
        return completedSlots.contains(slotId)
    }


    fun completeTimeSlot(timeSlotId: String) {
        val today = android.icu.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            .format(java.util.Date())

        val completedSlots =
            (prefs.getStringSet(KEY_COMPLETED_SLOTS, emptySet()) ?: emptySet()).toMutableSet()
        completedSlots.add(timeSlotId)

        prefs.edit().apply {
            putStringSet(KEY_COMPLETED_SLOTS, completedSlots)
            putString(KEY_COMPLETED_SLOTS_DATE, today)
            apply()
        }
    }

    private fun showLockOverlay(packageName: String) {
        val intent = Intent(this, MiqaatLockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("package_name", packageName)
            putExtra("goal_duration", goalDurationMinutes)
        }
        startActivity(intent)
    }

    data class TimeSlotData(
        val id: String,
        val startHour: Int,
        val startMinute: Int,
        val endHour: Int,
        val endMinute: Int,
        val weekdays: List<Int>
    )
}
