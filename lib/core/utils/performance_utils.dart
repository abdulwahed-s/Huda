import 'package:flutter/foundation.dart';

class PerformanceUtils {
  static final Map<String, DateTime> _startTimes = {};

  static void startTimer(String operation) {
    if (kDebugMode) {
      _startTimes[operation] = DateTime.now();
    }
  }

  static void endTimer(String operation) {
    if (kDebugMode && _startTimes.containsKey(operation)) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTimes[operation]!);
      debugPrint('⏱️ $operation took: ${duration.inMilliseconds}ms');
      _startTimes.remove(operation);
    }
  }

  static Future<T> timeAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }

  static T timeOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      final result = operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }
}
