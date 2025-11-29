import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:huda/core/config/service_initializer.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/firebase_options.dart';
import 'package:huda/presentation/screens/error.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize critical services and Firebase in parallel
  await Future.wait([
    initializeCriticalServices(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ]);

  initializeNonCriticalServicesAsync();

  setCustomErrorWidget();

  runApp(const App());
}
