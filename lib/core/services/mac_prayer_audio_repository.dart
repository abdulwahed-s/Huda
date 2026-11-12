import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huda/core/services/mac_prayer_bridge.dart';
import 'package:huda/core/services/mac_prayer_experience.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';

export 'prayer_audio_catalog.dart';

class MacPrayerAudioRepository extends PrayerAudioRepository {
  MacPrayerAudioRepository({
    required super.cacheDirectory,
    required super.bundledDirectory,
    super.client,
    super.bundledCatalogLoader,
  });
  static Future<MacPrayerAudioRepository> create() async {
    final paths = await MacPrayerBridge.channel
        .invokeMapMethod<String, dynamic>('audioPaths', {'schemaVersion': 1});
    if (paths == null) {
      throw StateError('macOS Adhan resources are unavailable.');
    }
    return MacPrayerAudioRepository(
      cacheDirectory: Directory(paths['cache'] as String),
      bundledDirectory: Directory(paths['bundled'] as String),
      bundledCatalogLoader: () async {
        final json =
            jsonDecode(
                  await rootBundle.loadString('assets/json/athan_catalog.json'),
                )
                as Map<String, dynamic>;
        final reciter = (json['reciters'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((r) => r['id'] == 'huda-default');
        reciter['notification'] = {
          ...Map<String, dynamic>.from(paths['notification'] as Map),
          'filename': 'notification.caf',
        };
        return jsonEncode(json);
      },
    );
  }

  Future<bool> isSelectionReady(MacPrayerExperience settings) =>
      isSelectionReadyFields(settings.reciterId, settings.audioVersion);
}
