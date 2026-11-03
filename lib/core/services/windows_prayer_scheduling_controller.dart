import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/windows_prayer_notification_gateway.dart';
import 'package:huda/core/services/windows_prayer_scheduling_worker.dart';
import 'package:huda/core/services/windows_prayer_worker_cache.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:path_provider/path_provider.dart';

class WindowsPrayerSchedulingController {
  WindowsPrayerSchedulingController({
    required this.cache,
    required this.initializeNotifications,
    required this.resolveDeviceTimeZone,
    required this.publishWidget,
    WindowsPrayerSchedulingWorker? worker,
    this.storageDirectory,
    this.appId = WindowsPrayerNotificationGateway.defaultAppId,
    this.fixedNow,
  }) : worker = worker ?? WindowsPrayerSchedulingWorker.shared;

  final CacheHelper cache;
  final Future<void> Function() initializeNotifications;
  final Future<String> Function() resolveDeviceTimeZone;
  final PrayerWidgetPublisher publishWidget;
  final WindowsPrayerSchedulingWorker worker;
  final Directory? storageDirectory;
  final String appId;
  final DateTime? fixedNow;
  Map<String, int> lastDiagnostics = const {};

  Future<PrayerScheduleResult> reconcile({
    String reason = 'unspecified',
    bool force = false,
  }) => _run(reason: reason, force: force);

  Future<PrayerScheduleResult> activateCandidate({
    required PrayerLocationGeneration candidate,
    required String reason,
  }) => _run(reason: reason, force: false, candidate: candidate);

  Future<PrayerScheduleResult> _run({
    required String reason,
    required bool force,
    PrayerLocationGeneration? candidate,
  }) async {
    try {
      // The original root plugin continues to own registration/activation.
      await initializeNotifications();
      final directory =
          storageDirectory ?? await getApplicationSupportDirectory();
      final zone = await resolveDeviceTimeZone();
      final outcome = await worker.run(
        directory: directory.path,
        appId: appId,
        zone: zone,
        reason: reason,
        force: force,
        candidate: candidate,
        fixedNow: fixedNow,
        rpc: (operation, arguments) async {
          switch (operation) {
            case 'read':
              return WindowsPrayerWorkerPreferences.read(cache);
            case 'write':
              return WindowsPrayerWorkerPreferences.write(cache, arguments);
            case 'publish':
              await publishWidget(
                generation:
                    arguments['generation']! as PrayerLocationGeneration,
                scheduleRevision: arguments['scheduleRevision']! as int,
                publicationRevision: arguments['publicationRevision']! as int,
                configurationSignature:
                    arguments['configurationSignature']! as String,
              );
              if (appId == WindowsPrayerNotificationGateway.defaultAppId) {
                await WindowsPrayerTaskbarBridge.publishNotificationContract(
                  locationRevision:
                      (arguments['generation']! as PrayerLocationGeneration)
                          .revision,
                  scheduleRevision: arguments['scheduleRevision']! as int,
                  configurationSignature:
                      arguments['configurationSignature']! as String,
                );
              }
              return null;
            default:
              throw StateError('Unknown worker request $operation');
          }
        },
      );
      lastDiagnostics = outcome.diagnostics;
      return outcome.result;
    } catch (error, stack) {
      debugPrint('Windows prayer scheduling unavailable: $error\n$stack');
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.failed,
        message: PrayerScheduleResult.localFailureMessage,
      );
    }
  }
}
