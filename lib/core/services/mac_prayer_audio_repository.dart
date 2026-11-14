import 'dart:io';

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
      // The default's notification clip is signed into the app bundle,
      // cut from this `full.mp3`.
      bundledDirectory: Directory(paths['bundled'] as String),
    );
  }

  Future<bool> isSelectionReady(MacPrayerExperience settings) =>
      isSelectionReadyFields(settings.reciterId, settings.audioVersion);
}
