import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/core/services/crash_reporting_consent.dart';
import 'package:huda/core/services/home_preferences_service.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Builds the controller that reads and requests notification access.
typedef OnboardingAccessFactory =
    NotificationAccessController Function(
      NotificationsCubit cubit,
      Future<void> Function() onAccessGained,
    );

/// What the wizard reaches outside its cubits: storage, the flavor, the
/// app version, connectivity, the Mushaf packs, crash consent and
/// notification access. [OnboardingEnvironment.live] wires the app's own
/// services; tests and the device matrix pass fakes, so nothing calls a
/// platform channel or the network.
@immutable
class OnboardingEnvironment {
  const OnboardingEnvironment({
    required this.cache,
    required this.homePreferences,
    required this.appVersion,
    required this.onWifi,
    required this.downloadMushaf,
    required this.setCrashConsent,
    required this.createAccess,
    this.isFoss = false,
    this.isAndroid = false,
    this.canOpenSettings = true,
    this.alerts,
  });

  factory OnboardingEnvironment.live() => OnboardingEnvironment(
    cache: getIt<CacheHelper>(),
    homePreferences: getIt<HomePreferencesService>(),
    isFoss: CrashReportingConsent.requiresExplicitConsent,
    isAndroid: PlatformUtils.isAndroid,
    // Linux has no settings page to open for these permissions.
    canOpenSettings: !PlatformUtils.isLinux,
    appVersion: () async => (await PackageInfo.fromPlatform()).version,
    onWifi: () async {
      final links = await Connectivity().checkConnectivity();
      return links.contains(ConnectivityResult.wifi) ||
          links.contains(ConnectivityResult.ethernet);
    },
    downloadMushaf: (pack) {
      final service = getIt<MushafPackService>(instanceName: _instance(pack));
      // Keeps going after onboarding; the reader shows its progress.
      unawaited(
        service.downloadAndInstall().catchError(
          (Object error) => debugPrint('Mushaf download failed: $error'),
        ),
      );
    },
    setCrashConsent: CrashReporter.setFossConsent,
    createAccess: (cubit, onAccessGained) => NotificationAccessController(
      cubit: cubit,
      onAccessGained: onAccessGained,
    ),
    alerts: () => PrayerAlerts.shared,
  );

  static String _instance(MushafPack pack) => switch (pack) {
    MushafPack.hafs => 'hafs',
    MushafPack.tajweed => 'tajweed',
    MushafPack.indopak => 'indopak',
  };

  final CacheHelper cache;
  final HomePreferencesService homePreferences;

  /// The FOSS flavor asks for crash-report consent (the privacy step).
  final bool isFoss;

  /// Android records the reliability answer for the Prayer screen.
  final bool isAndroid;

  /// Whether "Open settings" can open the system's page.
  final bool canOpenSettings;

  final Future<String> Function() appVersion;

  /// Whether the device is on Wi-Fi (or a wired link), for the Mushaf
  /// download's default.
  final Future<bool> Function() onWifi;

  /// Starts a pack's download in the background.
  final void Function(MushafPack pack) downloadMushaf;

  final Future<void> Function(bool allowed) setCrashConsent;
  final OnboardingAccessFactory createAccess;

  /// The prayer alert settings the adhan step's style choice edits (the
  /// same controller as Prayer's alert sheet). Null hides the choice.
  final PrayerAlertController<Object?> Function()? alerts;

  /// Whether a pack is already on the device (the key its service writes).
  bool mushafInstalled(MushafPack pack) =>
      cache.getData(key: pack.cacheKey) == true;
}
