import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';
import 'package:huda/core/services/prayer_audio_catalog.dart';
import 'package:path/path.dart' as p;
export 'prayer_audio_catalog.dart';

class IOSPrayerAudioRepository extends PrayerAudioRepository {
  IOSPrayerAudioRepository({
    required super.cacheDirectory,
    required super.bundledDirectory,
    super.bundledCatalogLoader,
    super.client,
  });
  static Future<IOSPrayerAudioRepository> create() async {
    final paths = await IOSPrayerBridge.channel
        .invokeMapMethod<String, dynamic>('audioPaths', {'schemaVersion': 1});
    if (paths == null) throw StateError('iOS Adhan resources unavailable.');
    return IOSPrayerAudioRepository(
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

  Future<void> prepare(
    PrayerAudioReciter reciter,
    String version, {
    void Function(double)? onProgress,
    PrayerAudioDownloadToken? token,
  }) async {
    await ensureDownloaded(
      reciter,
      version,
      onProgress: onProgress,
      token: token,
    );
    // The bundled clip already lives in the bundle. Downloaded clips must be
    // verified and installed in Library/Sounds before becoming selectable.
    if (!reciter.isBundled) {
      await IOSPrayerBridge.channel.invokeMethod<Object?>('installAudio', {
        'schemaVersion': 1,
        'reciterId': reciter.id,
        'audioVersion': version,
        'path': p.join(
          directoryFor(version, reciter.id).path,
          reciter.short.filename,
        ),
        'bytes': reciter.short.bytes,
        'sha256': reciter.short.sha256Hex,
        'durationMs': reciter.short.durationMs,
      });
    }
  }

  String previewPath(
    PrayerAudioReciter reciter,
    String version, {
    required bool full,
  }) => p.join(
    directoryFor(reciter.isBundled ? 'v1' : version, reciter.id).path,
    full ? reciter.full.filename : reciter.short.filename,
  );
}
