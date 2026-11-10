import 'dart:convert';

import 'package:huda/core/cache/cache_helper.dart';

/// The reminder rules a companion process holds (Linux delivers them,
/// Windows renews their toasts). Kept in app storage so the prayer-tray and
/// taskbar bridges republish them with every configuration, including after
/// Huda restarts.
abstract final class ReminderRuleStore {
  static const key = 'notification_reminder_rules_v1';

  static List<Map<String, Object?>> read(CacheHelper cache) {
    try {
      final decoded = jsonDecode(cache.getDataString(key: key) ?? '[]');
      return [
        for (final rule in decoded as List)
          Map<String, Object?>.from(rule as Map),
      ];
    } on Object {
      return const [];
    }
  }

  static Future<void> write(
    CacheHelper cache,
    Iterable<Map<String, Object?>> rules,
  ) => cache.saveData(
    key: key,
    value: jsonEncode([
      ...rules.toList()..sort((a, b) => (a['id']! as int) - (b['id']! as int)),
    ]),
  );
}
