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
      // The built-in `full.mp3` is the only bundled file; native code makes
      // its notification clip and alarm file in Library/Sounds.
      bundledDirectory: Directory(paths['bundled'] as String),
    );
  }

  /// Also makes the alarm file for reciters downloaded before it existed.
  @override
  Future<bool> isReady(PrayerAudioReciter reciter, String version) async {
    if (!await super.isReady(reciter, version)) return false;
    final status = IOSPrayerBridge.status.value;
    if (!reciter.isBundled &&
        status.customAlarmSound &&
        !status.fullAlarmReciters.contains(reciter.id)) {
      try {
        await _install(reciter, version);
      } catch (_) {
        /* Full adhan alarms use the default recording until it's made. */
      }
    }
    return true;
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
    // Downloaded clips must be verified and installed in Library/Sounds
    // before becoming selectable, with the alarm file made from `full.mp3`.
    if (!reciter.isBundled) await _install(reciter, version);
  }

  Future<void> _install(PrayerAudioReciter reciter, String version) async {
    final directory = directoryFor(version, reciter.id).path;
    // The native service refuses while it is updating the schedule.
    for (var attempt = 1; ; attempt++) {
      try {
        return await _installOnce(reciter, version, directory);
      } on PlatformException catch (error) {
        if (error.code != 'busy' || attempt == 5) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  Future<void> _installOnce(
    PrayerAudioReciter reciter,
    String version,
    String directory,
  ) async {
    await IOSPrayerBridge.installAudio({
      'reciterId': reciter.id,
      'audioVersion': version,
      'path': p.join(directory, reciter.short.filename),
      'bytes': reciter.short.bytes,
      'sha256': reciter.short.sha256Hex,
      'durationMs': reciter.short.durationMs,
      'fullPath': p.join(directory, reciter.full.filename),
      'fullBytes': reciter.full.bytes,
      'fullSha256': reciter.full.sha256Hex,
    });
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
