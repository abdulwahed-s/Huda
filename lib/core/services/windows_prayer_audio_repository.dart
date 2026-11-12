import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';

export 'prayer_audio_catalog.dart';

/// Windows keeps its existing paths, bundled MP3 and selection contract.
class WindowsPrayerAudioRepository extends PrayerAudioRepository {
  WindowsPrayerAudioRepository({
    required super.cacheDirectory,
    required super.bundledDirectory,
    super.client,
    super.bundledCatalogLoader,
  });

  static final catalogUrl = PrayerAudioRepository.catalogUrl;

  static Future<WindowsPrayerAudioRepository> create() async {
    const channel = MethodChannel('com.aw.huda/windows_prayer_taskbar');
    final paths = await channel.invokeMapMethod<String, dynamic>('audioPaths');
    return WindowsPrayerAudioRepository(
      cacheDirectory: Directory(paths!['cache'] as String),
      bundledDirectory: Directory(paths['bundled'] as String),
    );
  }

  Future<bool> isSelectionReady(WindowsPrayerExperience settings) =>
      isSelectionReadyFields(settings.reciterId, settings.audioVersion);
}
