import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsInitial());

  final CacheHelper cacheHelper = getIt<CacheHelper>();
  final NotificationPageHelper _notificationHelper = NotificationPageHelper();

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  Map<String, String> _getLocalizedContent() {
    if (_context == null) {
      return {
        'kahfTitle': '🕌 Surat Al-Kahf Reminder',
        'kahfBody':
            'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.',
        'morningTitle': '🌅 Morning Athkar',
        'morningBody':
            'Start your day with morning Athkar and remembrance of Allah.',
        'eveningTitle': '🌅 Evening Athkar',
        'eveningBody':
            'End your day with evening Athkar and gratitude to Allah.',
        'quranTitle': '📖 Quran Reading Reminder',
        'quranBody':
            'Time to read some verses from the Holy Quran and reflect on its guidance.',
        'checklistTitle': '📋 Daily Checklist Reminder',
        'checklistBody':
            'Time to fill your daily Islamic checklist and track your spiritual progress.',
        'randomTitle': '🤲 Random Athkar',
        'khatmaTitle': '📖 Khatma Daily Reminder',
        'khatmaBody':
            'Time to read your daily Quran wird and stay on track with your Khatma.',
      };
    }

    final localizations = AppLocalizations.of(_context!);
    return {
      'kahfTitle':
          localizations?.notificationKahfTitle ?? '🕌 Surat Al-Kahf Reminder',
      'kahfBody': localizations?.notificationKahfBody ??
          'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.',
      'morningTitle':
          localizations?.notificationMorningAthkarTitle ?? '🌅 Morning Athkar',
      'morningBody': localizations?.notificationMorningAthkarBody ??
          'Start your day with morning Athkar and remembrance of Allah.',
      'eveningTitle':
          localizations?.notificationEveningAthkarTitle ?? '🌅 Evening Athkar',
      'eveningBody': localizations?.notificationEveningAthkarBody ??
          'End your day with evening Athkar and gratitude to Allah.',
      'quranTitle':
          localizations?.notificationQuranTitle ?? '📖 Quran Reading Reminder',
      'quranBody': localizations?.notificationQuranBody ??
          'Time to read some verses from the Holy Quran and reflect on its guidance.',
      'checklistTitle': localizations?.notificationChecklistTitle ??
          '📋 Daily Checklist Reminder',
      'checklistBody': localizations?.notificationChecklistBody ??
          'Time to fill your daily Islamic checklist and track your spiritual progress.',
      'randomTitle':
          localizations?.notificationRandomAthkarTitle ?? '🤲 Random Athkar',
      'khatmaTitle':
          localizations?.notificationKhatmaTitle ?? '📖 Khatma Daily Reminder',
      'khatmaBody': localizations?.notificationKhatmaBody ??
          'Time to read your daily Quran wird and stay on track with your Khatma.',
    };
  }

  NotificationPageHelper get notificationHelper => _notificationHelper;

  Future<bool> getIsNotificationEnabled() async {
    if (PlatformUtils.isMacOS) {
      final macOSGranted =
          await _notificationHelper.checkMacOSPermissionStatus();
      return macOSGranted;
    }

    if (kIsWeb || PlatformUtils.isDesktop) return true;

    if (PlatformUtils.isIOS) {
      return (await Permission.notification.status).isGranted;
    }

    PermissionStatus status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    } else {
      debugPrint('📱 Android notification permission status: $status');
      return false;
    }
  }

  Future<bool> getIsBatteryOptimizationExempted() async {
    if (!PlatformUtils.isAndroid) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking battery optimization status: $e');
      return false;
    }
  }

  Future<bool> canScheduleExactNotifications() async {
    return _notificationHelper.canScheduleExactNotifications();
  }

  Future<bool> requestExactAlarmsPermission() async {
    return _notificationHelper.requestExactAlarmsPermission();
  }

  NotificationPreferencesLoaded _buildLoadedState({
    Set<String> loadingKeys = const {},
  }) {
    return NotificationPreferencesLoaded(
      kahfFriday: cacheHelper.getData(key: 'kahfFriday') ?? false,
      randomAthkar: cacheHelper.getData(key: 'randomAthkar') ?? false,
      sabahMasaa: cacheHelper.getData(key: 'sabahMasaa') ?? false,
      quranReminder: cacheHelper.getData(key: 'quranReminder') ?? false,
      checklistReminder: cacheHelper.getData(key: 'checklistReminder') ?? false,
      quranReminderTime:
          cacheHelper.getData(key: 'quranReminderTime') ?? '19:30',
      checklistReminderTime:
          cacheHelper.getData(key: 'checklistReminderTime') ?? '20:00',
      randomAthkarFrequency:
          cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60,
      kahfFridayTime: cacheHelper.getData(key: 'kahfFridayTime') ?? '09:00',
      morningAthkarTime:
          cacheHelper.getData(key: 'morningAthkarTime') ?? '07:00',
      eveningAthkarTime:
          cacheHelper.getData(key: 'eveningAthkarTime') ?? '18:00',
      sahurAlarmEnabled: cacheHelper.getData(key: 'sahurAlarmEnabled') ?? false,
      sahurAlarmType: cacheHelper.getData(key: 'sahurAlarmType') ?? 0,
      sahurExactTime: cacheHelper.getData(key: 'sahurExactTime') ?? '04:00',
      sahurMinutesBeforeFajr:
          cacheHelper.getData(key: 'sahurMinutesBeforeFajr') ?? 30,
      loadingKeys: loadingKeys,
    );
  }

  Future<void> loadPreferences() async {
    final current = state;
    emit(_buildLoadedState(
      loadingKeys: current is NotificationPreferencesLoaded
          ? current.loadingKeys
          : const {},
    ));
  }

  Future<void> togglePreference(String key, bool value) async {
    await _notificationHelper.init();
    final current = state;

    if (current is NotificationPreferencesLoaded &&
        current.loadingKeys.contains(key)) {
      return;
    }

    await cacheHelper.saveData(key: key, value: value);

    final startingKeys = <String>{
      if (current is NotificationPreferencesLoaded) ...current.loadingKeys,
      key,
    };
    emit(_buildLoadedState(loadingKeys: startingKeys));

    final localizedContent = _getLocalizedContent();

    try {
      switch (key) {
        case 'kahfFriday':
          if (value) {
            final timeStr =
                cacheHelper.getData(key: 'kahfFridayTime') ?? '09:00';
            final time = _parseTimeOfDay(timeStr);
            await _notificationHelper.scheduleKahfFriday(value, time,
                localizedContent['kahfTitle'], localizedContent['kahfBody']);
          } else {
            await _notificationHelper.scheduleKahfFriday(false, null);
          }
          break;
        case 'sabahMasaa':
          if (value) {
            final morningTimeStr =
                cacheHelper.getData(key: 'morningAthkarTime') ?? '07:00';
            final eveningTimeStr =
                cacheHelper.getData(key: 'eveningAthkarTime') ?? '18:00';
            final morningTime = _parseTimeOfDay(morningTimeStr);
            final eveningTime = _parseTimeOfDay(eveningTimeStr);
            await _notificationHelper.scheduleSabahMasaa(
                value,
                morningTime,
                eveningTime,
                localizedContent['morningTitle'],
                localizedContent['morningBody'],
                localizedContent['eveningTitle'],
                localizedContent['eveningBody']);
          } else {
            await _notificationHelper.scheduleSabahMasaa(false, null, null);
          }
          break;
        case 'randomAthkar':
          final frequency =
              cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60;
          await _notificationHelper.scheduleRandomAthkar(value, frequency);
          break;
        case 'quranReminder':
          if (value) {
            final timeStr =
                cacheHelper.getData(key: 'quranReminderTime') ?? '19:30';
            final time = _parseTimeOfDay(timeStr);
            await _notificationHelper.scheduleQuranReminder(value, time,
                localizedContent['quranTitle'], localizedContent['quranBody']);
          } else {
            await _notificationHelper.scheduleQuranReminder(false, null);
          }
          break;
        case 'checklistReminder':
          if (value) {
            final timeStr =
                cacheHelper.getData(key: 'checklistReminderTime') ?? '20:00';
            final time = _parseTimeOfDay(timeStr);
            await _notificationHelper.scheduleChecklistReminder(
                value,
                time,
                localizedContent['checklistTitle'],
                localizedContent['checklistBody']);
          } else {
            await _notificationHelper.scheduleChecklistReminder(false, null);
          }
          break;
        case 'sahurAlarmEnabled':
          if (value) {
            await SahurAlarmHelper.updateSahurAlarmSchedule();
          } else {
            await SahurAlarmHelper.stopAlarm();
          }
          break;
      }
    } finally {
      final latest = state;
      final remaining = <String>{
        if (latest is NotificationPreferencesLoaded) ...latest.loadingKeys,
      }..remove(key);
      emit(_buildLoadedState(loadingKeys: remaining));
      await _reconcilePrayerCapacity('notification-preference-changed');
    }
  }

  Future<void> setSahurAlarmType(int type) async {
    await cacheHelper.saveData(key: 'sahurAlarmType', value: type);
    await loadPreferences();
    if (cacheHelper.getData(key: 'sahurAlarmEnabled') ?? false) {
      await SahurAlarmHelper.updateSahurAlarmSchedule();
    }
  }

  Future<void> setSahurExactTime(String time) async {
    await cacheHelper.saveData(key: 'sahurExactTime', value: time);
    await loadPreferences();
    if (cacheHelper.getData(key: 'sahurAlarmEnabled') ?? false) {
      await SahurAlarmHelper.updateSahurAlarmSchedule();
    }
  }

  Future<void> setSahurMinutesBeforeFajr(int minutes) async {
    await cacheHelper.saveData(key: 'sahurMinutesBeforeFajr', value: minutes);
    await loadPreferences();
    if (cacheHelper.getData(key: 'sahurAlarmEnabled') ?? false) {
      await SahurAlarmHelper.updateSahurAlarmSchedule();
    }
  }

  Future<void> setQuranReminderTime(String time) async {
    await cacheHelper.saveData(key: 'quranReminderTime', value: time);

    final isEnabled = cacheHelper.getData(key: 'quranReminder') ?? false;
    if (isEnabled) {
      final localizedContent = _getLocalizedContent();
      final timeOfDay = _parseTimeOfDay(time);
      await _notificationHelper.scheduleQuranReminder(true, timeOfDay,
          localizedContent['quranTitle'], localizedContent['quranBody']);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('quran-reminder-time-changed');
  }

  Future<void> setChecklistReminderTime(String time) async {
    await cacheHelper.saveData(key: 'checklistReminderTime', value: time);

    final isEnabled = cacheHelper.getData(key: 'checklistReminder') ?? false;
    if (isEnabled) {
      final localizedContent = _getLocalizedContent();
      final timeOfDay = _parseTimeOfDay(time);
      await _notificationHelper.scheduleChecklistReminder(
          true,
          timeOfDay,
          localizedContent['checklistTitle'],
          localizedContent['checklistBody']);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('checklist-reminder-time-changed');
  }

  Future<void> setRandomAthkarFrequency(int minutes) async {
    await cacheHelper.saveData(key: 'randomAthkarFrequency', value: minutes);

    final isEnabled = cacheHelper.getData(key: 'randomAthkar') ?? false;
    if (isEnabled) {
      await _notificationHelper.scheduleRandomAthkar(true, minutes);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('random-athkar-frequency-changed');
  }

  Future<void> setKahfFridayTime(String time) async {
    await cacheHelper.saveData(key: 'kahfFridayTime', value: time);

    final isEnabled = cacheHelper.getData(key: 'kahfFriday') ?? false;
    if (isEnabled) {
      final localizedContent = _getLocalizedContent();
      final timeOfDay = _parseTimeOfDay(time);
      await _notificationHelper.scheduleKahfFriday(true, timeOfDay,
          localizedContent['kahfTitle'], localizedContent['kahfBody']);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('kahf-reminder-time-changed');
  }

  Future<void> setMorningAthkarTime(String time) async {
    await cacheHelper.saveData(key: 'morningAthkarTime', value: time);

    final isEnabled = cacheHelper.getData(key: 'sabahMasaa') ?? false;
    if (isEnabled) {
      final localizedContent = _getLocalizedContent();
      final morningTime = _parseTimeOfDay(time);
      final eveningTimeStr =
          cacheHelper.getData(key: 'eveningAthkarTime') ?? '18:00';
      final eveningTime = _parseTimeOfDay(eveningTimeStr);
      await _notificationHelper.scheduleSabahMasaa(
          true,
          morningTime,
          eveningTime,
          localizedContent['morningTitle'],
          localizedContent['morningBody'],
          localizedContent['eveningTitle'],
          localizedContent['eveningBody']);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('morning-athkar-time-changed');
  }

  Future<void> setEveningAthkarTime(String time) async {
    await cacheHelper.saveData(key: 'eveningAthkarTime', value: time);

    final isEnabled = cacheHelper.getData(key: 'sabahMasaa') ?? false;
    if (isEnabled) {
      final localizedContent = _getLocalizedContent();
      final eveningTime = _parseTimeOfDay(time);
      final morningTimeStr =
          cacheHelper.getData(key: 'morningAthkarTime') ?? '07:00';
      final morningTime = _parseTimeOfDay(morningTimeStr);
      await _notificationHelper.scheduleSabahMasaa(
          true,
          morningTime,
          eveningTime,
          localizedContent['morningTitle'],
          localizedContent['morningBody'],
          localizedContent['eveningTitle'],
          localizedContent['eveningBody']);
    }

    await loadPreferences();
    await _reconcilePrayerCapacity('evening-athkar-time-changed');
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    if (!PlatformUtils.isAndroid) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      debugPrint('🔋 Battery optimization status: $status');

      if (status.isGranted) {
        debugPrint('✅ Battery optimization exemption already granted');
        return true;
      }

      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('🔋 Battery optimization request result: $result');

      return result.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  Future<void> initializeNotifications() async {
    await _notificationHelper.init();
    await loadPreferences();

    final state = this.state;
    if (state is NotificationPreferencesLoaded &&
        await getIsNotificationEnabled()) {
      final localizedContent = _getLocalizedContent();
      await _notificationHelper.rescheduleAllNotifications(
        kahfFriday: state.kahfFriday,
        sabahMasaa: state.sabahMasaa,
        randomAthkar: state.randomAthkar,
        randomAthkarFrequency: state.randomAthkarFrequency,
        quranReminder: state.quranReminder,
        quranReminderTime: state.quranReminder
            ? _parseTimeOfDay(state.quranReminderTime)
            : null,
        kahfFridayTime:
            state.kahfFriday ? _parseTimeOfDay(state.kahfFridayTime) : null,
        morningAthkarTime:
            state.sabahMasaa ? _parseTimeOfDay(state.morningAthkarTime) : null,
        eveningAthkarTime:
            state.sabahMasaa ? _parseTimeOfDay(state.eveningAthkarTime) : null,
        kahfTitle: localizedContent['kahfTitle'],
        kahfBody: localizedContent['kahfBody'],
        morningTitle: localizedContent['morningTitle'],
        morningBody: localizedContent['morningBody'],
        eveningTitle: localizedContent['eveningTitle'],
        eveningBody: localizedContent['eveningBody'],
        quranTitle: localizedContent['quranTitle'],
        quranBody: localizedContent['quranBody'],
        checklistTitle: localizedContent['checklistTitle'],
        checklistBody: localizedContent['checklistBody'],
        checklistReminder: state.checklistReminder,
        checklistReminderTime: state.checklistReminder
            ? _parseTimeOfDay(state.checklistReminderTime)
            : null,
      );
      await _reconcilePrayerCapacity('notification-settings-restored');
    }
  }

  Future<void> _reconcilePrayerCapacity(String reason) async {
    if (!getIt.isRegistered<PrayerNotificationScheduler>()) return;
    final result =
        await getIt<PrayerNotificationScheduler>().reconcile(reason: reason);
    debugPrint(
      'Prayer capacity reconciliation: ${result.status.name}; '
      'coverage=${result.coverageUntil}',
    );
  }

  Future<int> getPendingNotificationsCount() async {
    final pending = await _notificationHelper.getPendingNotifications();
    return pending.length;
  }

  Future<void> debugNotifications() async {
    await _notificationHelper.comprehensiveDebug();
  }

  Future<void> scheduleTestNotification() async {
    await _notificationHelper.scheduleTestNotification();
  }

  Future<void> forceInitializeNotifications() async {
    try {
      await _notificationHelper.init();
      debugPrint('🔔 Notification helper initialized successfully');

      await loadPreferences();
      debugPrint('📋 Preferences loaded successfully');

      final state = this.state;
      if (state is NotificationPreferencesLoaded) {
        debugPrint('📊 Current preferences:');
        debugPrint('   - Kahf Friday: ${state.kahfFriday}');
        debugPrint('   - Sabah Masaa: ${state.sabahMasaa}');
        debugPrint(
            '   - Random Athkar: ${state.randomAthkar} (${state.randomAthkarFrequency}min)');
        debugPrint(
            '   - Quran Reminder: ${state.quranReminder} (${state.quranReminderTime})');
      }
    } catch (e) {
      debugPrint('❌ Error in force initialization: $e');
    }
  }
}
