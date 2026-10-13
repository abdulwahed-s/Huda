import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'prayer_api.g.dart';

/// The event stream is advisory. Receipts, policy and history are durable.
class HudaPrayerNotifications {
  HudaPrayerNotifications({PrayerHostApi? host}) : host = host ?? PrayerHostApi();

  static const contractVersion = 1;
  static const namespace = 'com.aw.huda/prayer_notifications';
  final PrayerHostApi host;
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  Stream<Map<String, Object?>> get events => const EventChannel(
    '$namespace/events',
  ).receiveBroadcastStream().map((event) => Map<String, Object?>.from(event as Map));

  Future<RuntimeSnapshot> initialize() async {
    if (!isSupported) {
      throw PlatformException(code: 'unsupportedPlatform', message: 'Android is required.');
    }
    final snapshot = await host.initialize(contractVersion);
    if (snapshot.contractVersion != contractVersion) {
      throw PlatformException(code: 'unsupportedContract');
    }
    return snapshot;
  }
}
