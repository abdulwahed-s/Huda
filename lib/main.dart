import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/presentation/screens/bootstrapper.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      CrashReporter.report(details.exception, details.stack, source: 'flutter');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught platform error: $error');
      CrashReporter.report(error, stack, source: 'platform');
      return true;
    };

    runApp(const Bootstrapper());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
    CrashReporter.report(error, stack, source: 'zone');
  });
}
