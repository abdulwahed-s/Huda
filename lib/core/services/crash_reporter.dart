import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrashReporter {
  CrashReporter._();

  static const String _queueKey = 'crash_reporter_pending';

  static final Set<String> _seen = <String>{};

  static const int _maxReportsPerSession = 50;
  static int _reportCount = 0;

  static const int _maxQueued = 50;

  static bool _flushing = false;

  static Map<String, String>? _deviceInfo;

  static Future<void> report(
    Object error,
    StackTrace? stack, {
    String source = 'dart',
  }) async {
    try {
      if (_reportCount >= _maxReportsPerSession) return;

      final message = error.toString();

      final signature = '$source::${message.split('\n').first}'.trim();
      if (!_seen.add(signature)) return;
      _reportCount++;

      final entry = <String, dynamic>{
        'error': _compose(source, message, stack),
        'device': await _getDeviceInfo(),
        'ts': DateTime.now().toUtc().toIso8601String(),
      };

      if (await _tryInsert(entry)) {
        unawaited(flushPending());
      } else {
        await _enqueue(entry);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashReporter failed to report: $e');
      }
    }
  }

  static Future<void> flushPending() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = prefs.getStringList(_queueKey);
      if (queued == null || queued.isEmpty) return;

      final remaining = <String>[];
      for (final raw in queued) {
        Map<String, dynamic> entry;
        try {
          entry = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        if (!await _tryInsert(entry)) {
          remaining.add(raw);
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        await prefs.setStringList(_queueKey, remaining);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashReporter failed to flush: $e');
      }
    } finally {
      _flushing = false;
    }
  }

  static Future<bool> _tryInsert(Map<String, dynamic> entry) async {
    try {
      final client = Supabase.instance.client;
      await client.from('error_reports').insert({
        'error': entry['error'],
        'user_message': '',
        'device': entry['device'],
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _enqueue(Map<String, dynamic> entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? <String>[];
      list.add(jsonEncode(entry));

      while (list.length > _maxQueued) {
        list.removeAt(0);
      }
      await prefs.setStringList(_queueKey, list);
    } catch (_) {}
  }

  static String _compose(String source, String message, StackTrace? stack) {
    final buffer = StringBuffer()..writeln('[$source] $message');
    if (stack != null) {
      buffer
        ..writeln()
        ..write(stack.toString());
    }
    return buffer.toString();
  }

  static Future<Map<String, String>> _getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;

    var model = 'Unknown';
    var version = 'Unknown';
    var manufacturer = 'Unknown';
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      model = androidInfo.model;
      version = androidInfo.version.release;
      manufacturer = androidInfo.manufacturer;
    } catch (_) {}

    return _deviceInfo = {
      'model': model,
      'version': version,
      'manufacturer': manufacturer,
    };
  }
}
