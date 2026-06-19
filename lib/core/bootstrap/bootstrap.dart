import 'dart:async';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/core/config/service_initializer.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/core/services/quick_actions_service.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';
import 'package:huda/core/services/service_locator.dart';

String? _findLinuxLibmpv() {
  final snap = Platform.environment['SNAP'];
  if (snap != null) {
    for (final path in [
      '$snap/usr/lib/x86_64-linux-gnu/libmpv.so.2',
      '$snap/usr/lib/aarch64-linux-gnu/libmpv.so.2',
    ]) {
      if (File(path).existsSync()) return path;
    }
    final arch = Platform.environment['SNAP_ARCH'] ?? 'amd64';
    return arch == 'arm64'
        ? '/usr/lib/aarch64-linux-gnu/libmpv.so.2'
        : '/usr/lib/x86_64-linux-gnu/libmpv.so.2';
  }

  for (final path in [
    '/usr/lib/x86_64-linux-gnu/libmpv.so.2',
    '/usr/lib/x86_64-linux-gnu/libmpv.so',
    '/usr/lib/aarch64-linux-gnu/libmpv.so.2',
    '/usr/lib/aarch64-linux-gnu/libmpv.so',
    '/usr/lib/libmpv.so.2',
    '/usr/lib/libmpv.so',
    '/usr/local/lib/libmpv.so.2',
    '/usr/local/lib/libmpv.so',
  ]) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

bool _locatorReady = false;

void _ensureLocator() {
  if (_locatorReady) return;
  setupServiceLocator();
  _locatorReady = true;
}

Future<String> initCriticalAndGetRoute() async {
  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: true,
    macOS: false,
    iOS: false,
    android: false,
    libmpv: Platform.isLinux ? _findLinuxLibmpv() : null,
  );

  _ensureLocator();
  await initializeCriticalServices().timeout(const Duration(seconds: 8));

  _startBackgroundInit();

  await getIt.allReady(timeout: const Duration(seconds: 8));

  final onboardingCompleted =
      getIt<CacheHelper>().getData(key: 'onboarding_completed') as bool?;
  return (onboardingCompleted == true) ? AppRoute.home : AppRoute.onboarding;
}

bool _backgroundInitStarted = false;

void _startBackgroundInit() {
  unawaited(_runBackgroundInit());
}

Future<void> _runBackgroundInit() async {
  if (_backgroundInitStarted) return;
  _backgroundInitStarted = true;

  audioServiceReady = _guard(
    'JustAudioBackground',
    () => JustAudioBackground.init(
      androidNotificationChannelId: 'com.huda.audio',
      androidNotificationChannelName: 'Quran Player',
      androidNotificationOngoing: true,
    ),
    const Duration(seconds: 10),
  );

  await Future.wait([
    _guard('Alarm', () async {
      await Alarm.init();
      SahurAlarmHelper.initListeners();
    }, const Duration(seconds: 8)),
    _guard('Supabase', _initializeSupabase, const Duration(seconds: 10)),
    _guard('Notifications', initializeNotifications,
        const Duration(seconds: 8)),
    _guard('PrayerWidget', PrayerWidgetService.initialize,
        const Duration(seconds: 8)),
  ]);

  await initializeNonCriticalServicesAsync();

  getIt<QcfFontService>(instanceName: 'qcf4').init();
  getIt<QcfFontService>(instanceName: 'tajweed').init();

  QuickActionsService.initialize();
}

Future<void> _guard(
  String name,
  Future<void> Function() op,
  Duration timeout,
) async {
  try {
    await op().timeout(timeout);
  } catch (e) {
    debugPrint('⚠️ bootstrap step "$name" failed/timed out: $e');
  }
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  unawaited(CrashReporter.flushPending());
}
