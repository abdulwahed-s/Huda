import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';

export 'prayer_audio_catalog.dart';

/// Linux uses stable Snap common/XDG storage and the shared verified catalog.
class LinuxPrayerAudioRepository extends PrayerAudioRepository {
  LinuxPrayerAudioRepository({
    required super.cacheDirectory,
    required super.bundledDirectory,
    super.client,
    super.bundledCatalogLoader,
  });

  static final catalogUrl = PrayerAudioRepository.catalogUrl;

  static Future<LinuxPrayerAudioRepository> create() async {
    const channel = MethodChannel('com.aw.huda/linux_prayer_tray');
    final paths = await channel.invokeMapMethod<String, dynamic>('audioPaths');
    return LinuxPrayerAudioRepository(
      cacheDirectory: Directory(paths!['cache'] as String),
      bundledDirectory: Directory(paths['bundled'] as String),
    );
  }

  Future<bool> isSelectionReady(LinuxPrayerExperience settings) =>
      isSelectionReadyFields(settings.reciterId, settings.audioVersion);
}
