import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:huda/core/config/service_initializer.dart';
import 'package:huda/core/services/quick_actions_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/firebase_options.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/presentation/screens/error.dart';
import 'package:alarm/alarm.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: true,
    macOS: false,
    iOS: false,
    android: false,
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
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ]);

  initializeNonCriticalServicesAsync();

  await getIt.allReady();

  getIt<QcfFontService>(instanceName: 'qcf4').init();
  getIt<QcfFontService>(instanceName: 'tajweed').init();

  setCustomErrorWidget();

  runApp(const App());

  QuickActionsService.initialize();
}
