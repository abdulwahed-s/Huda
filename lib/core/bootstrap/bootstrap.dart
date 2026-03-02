import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:huda/core/config/service_initializer.dart';
import 'package:huda/core/services/quick_actions_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/firebase_options.dart';
import 'package:huda/presentation/screens/error.dart';
import 'package:alarm/alarm.dart';
import 'package:huda/core/services/sahur_alarm_helper.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();
  SahurAlarmHelper.initListeners();

  // Initialize critical services and Firebase in parallel
  await Future.wait([
    initializeCriticalServices(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ]);

  initializeNonCriticalServicesAsync();

  await getIt.allReady();

  setCustomErrorWidget();

  runApp(const App());

  QuickActionsService.initialize();
}
