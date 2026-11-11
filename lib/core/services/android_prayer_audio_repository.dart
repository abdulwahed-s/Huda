import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_audio_catalog.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';
import 'package:huda_notifications/huda_notifications.dart';
import 'package:path/path.dart' as p;

/// Downloads share the catalog workflow; the host verifies and pins immutable DP files.
class AndroidPrayerAudioRepository extends PrayerAudioRepository {
  AndroidPrayerAudioRepository._(this.api, this.storage)
    : super(
        cacheDirectory: Directory(storage.stagingRoot),
        bundledDirectory: Directory(storage.stagingRoot),
        bundledCatalogLoader: () async {
          final raw =
              jsonDecode(
                    await rootBundle.loadString(
                      'assets/json/athan_catalog.json',
                    ),
                  )
                  as Map<String, dynamic>;
          final asset = storage.bundled;
          final descriptor = {
            'bytes': asset.bytes,
            'sha256': asset.sha256,
            'duration_ms': asset.durationMillis,
          };
          raw['reciters'] = [
            {
              'id': 'huda-default',
              'source': 'bundled',
              'name_en': 'Huda default',
              'name_ar': 'أذان هدى الافتراضي',
              'full': descriptor,
              'notification': {...descriptor, 'duration_ms': 30000},
            },
            ...(raw['reciters'] as List).where(
              (reciter) => (reciter as Map)['source'] != 'bundled',
            ),
          ];
          return jsonEncode(raw);
        },
      );
  final PrayerHostApi api;
  final AudioStorageData storage;
  static Future<AndroidPrayerAudioRepository> create(PrayerHostApi api) async =>
      AndroidPrayerAudioRepository._(api, await api.getAudioStorage());
  @override
  Future<bool> isReady(PrayerAudioReciter reciter, String version) =>
      reciter.isBundled
      ? Future.value(version == 'v1')
      : super.isReady(reciter, version);
  @override
  Future<bool> isSelectionReadyFields(String reciterId, String audioVersion) =>
      api.isAudioReady(reciterId, audioVersion);

  /// The native store keeps it while a prayer or a session still uses it.
  @override
  Future<void> delete(PrayerAudioReciter reciter, String version) async {
    if (reciter.isBundled) return;
    await api.removeAudio(reciter.id, version);
    await super.delete(reciter, version);
  }
  @override
  Future<void> ensureDownloaded(
    PrayerAudioReciter reciter,
    String version, {
    void Function(double)? onProgress,
    PrayerAudioDownloadToken? token,
  }) async {
    if (reciter.isBundled) {
      onProgress?.call(1);
      return;
    }
    await super.ensureDownloaded(
      reciter,
      version,
      onProgress: onProgress,
      token: token,
    );
    final directory = directoryFor(version, reciter.id);
    await api.registerVerifiedAudio([
      for (final variant in [reciter.full, reciter.short])
        AudioAssetData(
          reciterId: reciter.id,
          version: version,
          variant: identical(variant, reciter.full) ? 'full' : 'short',
          path: p.join(directory.path, variant.filename),
          bytes: variant.bytes,
          sha256: variant.sha256Hex,
          durationMillis: variant.durationMs,
          nameEnglish: reciter.name('en'),
          nameArabic: reciter.name('ar'),
        ),
    ]);
  }
}
