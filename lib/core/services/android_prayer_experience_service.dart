import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda_notifications/huda_notifications.dart';

class AndroidPrayerExperienceService extends ChangeNotifier {
  AndroidPrayerExperienceService({
    required this.cache,
    required this.api,
    this.onEligibilityChanged,
  });
  final CacheHelper cache;
  final PrayerHostApi api;
  final Future<void> Function()? onEligibilityChanged;
  AndroidPrayerExperience? policy;
  Future<void> refresh() async {
    policy = AndroidPrayerExperience.fromPolicy(await api.getPolicy());
    notifyListeners();
  }

  Future<AndroidPrayerExperience> update(
    Map<String, Object?> changes, {
    String? prayer,
  }) async {
    var current =
        policy ?? AndroidPrayerExperience.fromPolicy(await api.getPolicy());
    for (var attempt = 0; ; attempt++) {
      final desired = current.edit(changes, prayer: prayer);
      try {
        final acknowledged = AndroidPrayerExperience.fromPolicy(
          await api.setPolicy(desired.toPolicy(), current.policyRevision),
        );
        policy = acknowledged;
        notifyListeners();
        try {
          final saved = await cache.saveData(
            key: AndroidPrayerExperience.preferenceKey,
            value: jsonEncode({
              'schemaVersion': 1,
              'policyRevision': acknowledged.policyRevision,
              ...acknowledged.values,
            }),
          );
          if (!saved) {
            throw StateError(
              'Android prayer preference projection could not be saved.',
            );
          }
        } finally {
          // Reminders before prayers change how many prayers native can hold.
          if (current.eligibilitySignature !=
                  acknowledged.eligibilitySignature ||
              current.advanceActive != acknowledged.advanceActive) {
            await onEligibilityChanged?.call();
          }
        }
        return acknowledged;
      } on PlatformException catch (error) {
        if (error.code != 'stalePolicy' || attempt != 0) rethrow;
        current = AndroidPrayerExperience.fromPolicy(await api.getPolicy());
      }
    }
  }

  Future<void> resetOverride(String prayer) => update({
    for (final key in AndroidPrayerExperience.overrideKeys) key: null,
  }, prayer: prayer);
}
