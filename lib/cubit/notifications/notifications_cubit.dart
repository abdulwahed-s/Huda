import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({NotificationOrchestrator? reminders})
      : _reminders = reminders,
        super(NotificationsInitial());

  final CacheHelper cacheHelper = getIt<CacheHelper>();
  final NotificationPageHelper _notificationHelper = NotificationPageHelper();
  final NotificationOrchestrator? _reminders;

  NotificationOrchestrator get _orchestrator =>
      _reminders ?? NotificationOrchestrator.shared;

  /// From the latest sync that planned random Athkar.
  int? _athkarScheduledFrequency;

  void _remember(ReminderSyncResult result, {required bool athkarPlanned}) {
    if (athkarPlanned) _athkarScheduledFrequency = result.athkarMinutes;
  }

  /// Reminder IDs each settings switch controls.
  static const Map<String, List<int>> _reminderIds = {
    'kahfFriday': [NotificationIds.kahfFriday],
    'sabahMasaa': [NotificationIds.morningAthkar, NotificationIds.eveningAthkar],
    'quranReminder': [NotificationIds.quranReminder],
    'checklistReminder': [NotificationIds.checklistReminder],
  };

  /// Asks the orchestrator to apply saved settings. Throws when switching
  /// [key] on left its notifications unscheduled.
  Future<void> _syncReminders(String key, {required bool enabled}) async {
    final athkar = key == 'randomAthkar';
    final result = await _orchestrator.requestSync(
      'setting:$key',
      categories: {
        athkar ? ReminderCategory.randomAthkar : ReminderCategory.reminder,
      },
    );
    _remember(result, athkarPlanned: athkar);
    if (!enabled) return;
    final ids = _reminderIds[key] ?? const <int>[];
    final rejected = !result.supported ||
        (athkar
            ? result.athkarIncomplete
            : ids.any(result.reminderFailed));
    if (rejected) throw NotificationNotScheduledException(ids.firstOrNull ?? 0);
  }

  NotificationPageHelper get notificationHelper => _notificationHelper;

  /// Same answer as every other page: [NotificationPermissions.areEnabled].
  Future<bool> getIsNotificationEnabled() async {
    if (kIsWeb) return true;
    if (PlatformUtils.isWindows) await _notificationHelper.init();
    return NotificationPermissions.areEnabled();
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
      randomAthkarScheduledFrequency: _athkarScheduledFrequency,
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

    try {
      if (key == 'sahurAlarmEnabled') {
        if (value) {
          await SahurAlarmHelper.updateSahurAlarmSchedule();
        } else {
          await SahurAlarmHelper.stopAlarm();
        }
      } else {
        await _syncReminders(key, enabled: value);
      }
    } on NotificationNotScheduledException {
      // Keep the switch honest and remove anything partly scheduled.
      await cacheHelper.saveData(key: key, value: false);
      unawaited(_orchestrator.requestSync('setting-rejected:$key'));
      rethrow;
    } finally {
      final latest = state;
      final remaining = <String>{
        if (latest is NotificationPreferencesLoaded) ...latest.loadingKeys,
      }..remove(key);
      emit(_buildLoadedState(loadingKeys: remaining));
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

  Future<void> setQuranReminderTime(String time) =>
      _setReminderSetting('quranReminderTime', time, 'quranReminder');

  Future<void> setChecklistReminderTime(String time) =>
      _setReminderSetting('checklistReminderTime', time, 'checklistReminder');

  Future<void> setRandomAthkarFrequency(int minutes) =>
      _setReminderSetting('randomAthkarFrequency', minutes, 'randomAthkar');

  Future<void> setKahfFridayTime(String time) =>
      _setReminderSetting('kahfFridayTime', time, 'kahfFriday');

  Future<void> setMorningAthkarTime(String time) =>
      _setReminderSetting('morningAthkarTime', time, 'sabahMasaa');

  Future<void> setEveningAthkarTime(String time) =>
      _setReminderSetting('eveningAthkarTime', time, 'sabahMasaa');

  Future<void> _setReminderSetting(
      String key, Object value, String enabledKey) async {
    await cacheHelper.saveData(key: key, value: value);
    await loadPreferences();
    if (cacheHelper.getData(key: enabledKey) != true) return;
    try {
      await _syncReminders(enabledKey, enabled: true);
    } finally {
      await loadPreferences();
    }
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
    if (await getIsNotificationEnabled()) {
      final result =
          await _orchestrator.requestSync('notifications-page-opened');
      _remember(result, athkarPlanned: true);
      await loadPreferences();
    }
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
