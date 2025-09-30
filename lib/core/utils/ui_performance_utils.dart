import 'dart:async';
import 'package:flutter/scheduler.dart';

class UIPerformanceUtils {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, Timer> _timers = {};

  static T? getCached<T>(String key) {
    return _cache[key] as T?;
  }

  static void setCached<T>(String key, T value, [Duration? expiry]) {
    _cache[key] = value;

    if (expiry != null) {
      _timers[key]?.cancel();
      _timers[key] = Timer(expiry, () {
        _cache.remove(key);
        _timers.remove(key);
      });
    }
  }

  static final Map<String, Timer> _debouncers = {};

  static void debounce(String key, VoidCallback callback, Duration delay) {
    _debouncers[key]?.cancel();
    _debouncers[key] = Timer(delay, callback);
  }

  static final Map<String, DateTime> _lastCalls = {};

  static void throttle(String key, VoidCallback callback, Duration interval) {
    final now = DateTime.now();
    final lastCall = _lastCalls[key];

    if (lastCall == null || now.difference(lastCall) >= interval) {
      _lastCalls[key] = now;
      callback();
    }
  }

  static void schedulePostFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  static Future<void> processInBatches<T>(
    List<T> items,
    void Function(T item) processor, {
    int batchSize = 10,
    Duration batchDelay = const Duration(milliseconds: 1),
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      for (final item in batch) {
        processor(item);
      }

      if (end < items.length) {
        await Future.delayed(batchDelay);
      }
    }
  }

  static void clearAll() {
    _cache.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();

    _lastCalls.clear();
  }
}
