import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:huda/core/config/service_initializer.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/quick_actions_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/presentation/screens/error.dart';
import 'package:alarm/alarm.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';

String? _findLinuxLibmpv() {
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

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: true,
    macOS: false,
    iOS: false,
    android: false,
    libmpv: Platform.isLinux ? _findLinuxLibmpv() : null,
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.huda.audio',
    androidNotificationChannelName: 'Quran Player',
    androidNotificationOngoing: true,
  );

  await Alarm.init();
  SahurAlarmHelper.initListeners();

  await Future.wait([
    initializeCriticalServices(),
    _initializeSupabase(),
  ]);

  initializeNonCriticalServicesAsync();

  await getIt.allReady();

  getIt<QcfFontService>(instanceName: 'qcf4').init();
  getIt<QcfFontService>(instanceName: 'tajweed').init();

  setCustomErrorWidget();

  await PrayerWidgetService.initialize();

  runApp(const App());

  QuickActionsService.initialize();
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}
