import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_location_monitor.dart';
import 'package:huda/core/services/prayer_location_time_zone_service.dart';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/prayer_notification_background_scheduler.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_location_coordinator.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:workmanager/workmanager.dart';

const String dailyTaskKey =
    PrayerNotificationBackgroundScheduler.legacyTaskName;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      switch (task) {
        case PrayerNotificationBackgroundScheduler.taskName:
        case PrayerNotificationBackgroundScheduler.legacyTaskName:
        case PrayerNotificationBackgroundScheduler.iosIdentifier:
          return _reconcilePrayerNotifications();
        case 'reconcilePrayerLocationCandidate':
          return _reconcilePrayerLocationCandidate(inputData);
        case 'renewAthkarNotifications':
        case 'retryAthkarScheduling':
          return _renewAthkar();
        default:
          debugPrint('Unknown Workmanager task: $task');
          return true;
      }
    } catch (error, stackTrace) {
      debugPrint('Workmanager task $task failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  });
}

Future<bool> _reconcilePrayerLocationCandidate(
  Map<String, dynamic>? inputData,
) async {
  final cache = CacheHelper();
  await cache.init();
  const key = 'prayer_location_native_candidate_v1';
  final raw = cache.getDataString(key: key);
  final repository = PrayerLocationRepository(cacheHelper: cache);
  final scheduler = PrayerNotificationScheduler(
    cacheHelper: cache,
    locationRepository: repository,
  );
  if (raw == null || raw.isEmpty) {
    final result = await scheduler.reconcile(
      reason: inputData?['reason']?.toString() ?? 'native-system-change',
      force: true,
    );
    return result.isSuccess ||
        result.status == PrayerScheduleStatus.locationUnavailable;
  }

  if (cache.getData(key: 'prayer_background_travel_enabled') != true) {
    await PrayerLocationMonitor.consumeNativeCandidate(raw);
    return true;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['schemaVersion'] != 1) {
      await repository.updateIssues(add: {PrayerWorkflowIssue.nativeCandidate});
      await PrayerLocationMonitor.consumeNativeCandidate(raw);
      return true;
    }
    double? number(String field) {
      final value = decoded[field];
      if (value is! num) return null;
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }

    final latitude = number('latitude');
    final longitude = number('longitude');
    final accuracy = number('accuracyMeters');
    final capturedAt = DateTime.tryParse(
      decoded['capturedAtUtc']?.toString() ?? '',
    );
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        capturedAt == null ||
        !capturedAt.isUtc) {
      await repository.updateIssues(add: {PrayerWorkflowIssue.nativeCandidate});
      await PrayerLocationMonitor.consumeNativeCandidate(raw);
      return true;
    }
    final metadata = PrayerLocationMetadata(
      countryCode: decoded['countryCode']?.toString(),
    );
    final source =
        decoded['source']?.toString() ==
            PrayerLocationSource.iosSignificantChange.name
        ? PrayerLocationSource.iosSignificantChange
        : PrayerLocationSource.androidBackground;
    final coordinator = PrayerLocationCoordinator(
      cacheHelper: cache,
      repository: repository,
      activator: scheduler,
      timeZoneResolver: PrayerLocationTimeZoneService.resolveExact,
      metadataResolver: (_, _) async => metadata,
    );
    final result = await coordinator.submit(
      fix: PrayerLocationFix(
        latitude: latitude,
        longitude: longitude,
        capturedAtUtc: capturedAt,
        accuracyMeters: accuracy,
      ),
      mode: PrayerLocationMode.automatic,
      source: source,
      reason:
          inputData?['reason']?.toString() ?? '${source.name}-queued-candidate',
      suppliedMetadata: metadata,
    );
    if (result.activated ||
        result.status == PrayerLocationUpdateStatus.ignoredInsignificant) {
      await cache.saveData(
        key: 'prayer_location_last_validation_ms',
        value: DateTime.now().millisecondsSinceEpoch,
      );
    }
    await cache.reload();
    final latest = cache.getDataString(key: key);
    final retryable = _retryableLocationStatus(result.status);
    if (latest == raw && !retryable) {
      if (await PrayerLocationMonitor.consumeNativeCandidate(raw)) {
        await repository.updateIssues(
          remove: {PrayerWorkflowIssue.nativeCandidate},
        );
      }
    } else if (retryable) {
      await repository.updateIssues(add: {PrayerWorkflowIssue.nativeCandidate});
    }
    return !retryable;
  } catch (error) {
    try {
      await repository.updateIssues(add: {PrayerWorkflowIssue.nativeCandidate});
    } catch (_) {}
    debugPrint('Native prayer candidate recovery failed: $error');
    return false;
  }
}

Future<bool> _reconcilePrayerNotifications() async {
  final cache = CacheHelper();
  await cache.init();
  const candidateKey = 'prayer_location_native_candidate_v1';
  if ((cache.getDataString(key: candidateKey) ?? '').isNotEmpty) {
    return _reconcilePrayerLocationCandidate(const {
      'reason': 'background-refresh-candidate-recovery',
    });
  }
  final result = await PrayerNotificationScheduler(
    cacheHelper: cache,
  ).reconcile(reason: 'background-refresh');
  return result.isSuccess ||
      result.status == PrayerScheduleStatus.locationUnavailable ||
      result.status == PrayerScheduleStatus.permissionDenied ||
      result.message == PrayerNotificationScheduler.verificationPendingMessage;
}

bool _retryableLocationStatus(PrayerLocationUpdateStatus status) =>
    status == PrayerLocationUpdateStatus.timeZoneUnavailable ||
    status == PrayerLocationUpdateStatus.deferredCountry ||
    status == PrayerLocationUpdateStatus.degraded ||
    status == PrayerLocationUpdateStatus.failed;

Future<bool> _renewAthkar() async {
  final cache = CacheHelper();
  await cache.init();
  if (cache.getData(key: 'randomAthkar') != true) return true;

  final configured = cache.getData(key: 'randomAthkarFrequency');
  final frequency = configured is int ? configured : 60;
  final helper = NotificationPageHelper();
  await helper.init();
  await helper.scheduleRandomAthkar(true, frequency, fromBackground: true);
  return true;
}
