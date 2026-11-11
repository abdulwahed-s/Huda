import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/notifications/reminder_rule_store.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/service_locator.dart';

/// Linux has no scheduled-notification queue, so Huda's prayer companion
/// delivers reminders, random Athkar and calendar events while the session
/// runs, with Huda closed. The rules travel in the companion's configuration;
/// what this backend holds is exactly what was last published.
class LinuxReminderBackend implements ReminderBackend {
  LinuxReminderBackend({
    CacheHelper? cache,
    Future<bool> Function()? publish,
    Future<void> Function()? prepare,
  }) : _cache = cache,
       _publish = publish ?? LinuxPrayerTrayBridge.publishReminderRules,
       _prepare = prepare ?? _refreshTimeZone;

  final CacheHelper? _cache;
  final Future<bool> Function() _publish;
  final Future<void> Function() _prepare;

  CacheHelper get _store => _cache ?? getIt<CacheHelper>();

  static Future<void> _refreshTimeZone() async {
    await PrayerTimeZoneService.refreshLocalTimeZone();
  }

  @override
  ReminderBackendCapabilities get capabilities =>
      const ReminderBackendCapabilities(supported: true);

  @override
  Future<void> prepare() => _prepare();

  @override
  Future<T> session<T>(Future<T> Function() action) => action();

  @override
  Future<List<QueuedNotification>> inventory() async => [
    for (final rule in ReminderRuleStore.read(_store))
      QueuedNotification(
        id: rule['id']! as int,
        title: rule['title'] as String?,
        body: rule['body'] as String?,
        payload: rule['payload'] as String?,
      ),
  ];

  @override
  Future<String> scheduleMode() async => 'companion';

  /// Rules are saved before publishing, so a companion that is not running
  /// receives them with the next configuration it accepts.
  @override
  Future<ApplyReport> apply(ReminderChanges changes) async {
    final rules = {
      for (final rule in ReminderRuleStore.read(_store))
        rule['id']! as int: rule,
    }..removeWhere((id, _) => changes.cancel.contains(id));
    for (final notification in changes.schedule) {
      rules[notification.id] = notification.toRule();
    }
    await ReminderRuleStore.write(_store, rules.values);
    await _publish();
    return const ApplyReport();
  }
}
