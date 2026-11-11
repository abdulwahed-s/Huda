import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_audio_catalog.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

/// Why a download stopped, in terms the user can act on.
enum PrayerAudioDownloadFailure {
  network,
  server,
  integrity,
  storage,
  canceled,
}

class PrayerAudioDownloadException implements Exception {
  const PrayerAudioDownloadException(this.kind, [this.cause]);

  final PrayerAudioDownloadFailure kind;
  final Object? cause;

  static PrayerAudioDownloadException from(Object error) => switch (error) {
    PrayerAudioDownloadException() => error,
    SocketException() ||
    TimeoutException() ||
    HandshakeException() ||
    http.ClientException() => PrayerAudioDownloadException(
      PrayerAudioDownloadFailure.network,
      error,
    ),
    HttpException() => PrayerAudioDownloadException(
      PrayerAudioDownloadFailure.server,
      error,
    ),
    FormatException() => PrayerAudioDownloadException(
      PrayerAudioDownloadFailure.integrity,
      error,
    ),
    FileSystemException() => PrayerAudioDownloadException(
      PrayerAudioDownloadFailure.storage,
      error,
    ),
    _ => PrayerAudioDownloadException(
      PrayerAudioDownloadFailure.network,
      error,
    ),
  };

  @override
  String toString() => 'PrayerAudioDownloadException($kind, $cause)';
}

/// Cancels one download without affecting the others.
class PrayerAudioDownloadToken {
  final _canceled = Completer<void>();

  bool get canceled => _canceled.isCompleted;
  Future<void> get whenCanceled => _canceled.future;

  void cancel() {
    if (!_canceled.isCompleted) _canceled.complete();
  }
}

/// Downloads complete pairs before making a reciter selectable for offline use.
class PrayerAudioRepository {
  PrayerAudioRepository({
    required this.cacheDirectory,
    required this.bundledDirectory,
    http.Client? client,
    Future<String> Function()? bundledCatalogLoader,
  }) : _client = client ?? http.Client(),
       _bundledCatalogLoader =
           bundledCatalogLoader ??
           (() => rootBundle.loadString('assets/json/athan_catalog.json'));

  static final catalogUrl = Uri.parse(
    'https://aiheljvapaxaztcehufr.supabase.co/storage/v1/object/public/athan/catalog.json',
  );
  final Directory cacheDirectory, bundledDirectory;
  final http.Client _client;
  final Future<String> Function() _bundledCatalogLoader;
  final _lock = Lock();
  PrayerAudioCatalog? _catalog;
  PrayerAudioCatalog? _bundledCatalog;
  bool _closed = false;

  /// The last [loadCatalog] refresh failed, so the list may be out of date.
  bool catalogRefreshFailed = false;

  Future<PrayerAudioCatalog> loadCatalog({bool refresh = false}) async {
    if (_catalog != null && !refresh) return _catalog!;
    final cached = File(p.join(cacheDirectory.path, 'catalog.json'));
    if (refresh) {
      try {
        final response = await _client
            .send(http.Request('GET', catalogUrl))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200 ||
            (response.contentLength ?? 0) > 262144) {
          throw const FormatException('Invalid catalog response.');
        }
        final bytes = <int>[];
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 12),
        )) {
          if (_closed || bytes.length + chunk.length > 262144) {
            throw const FormatException('Invalid catalog response.');
          }
          bytes.addAll(chunk);
        }
        final raw = utf8.decode(bytes);
        final catalog = PrayerAudioCatalog(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (catalog.reciters.any(
          (reciter) =>
              reciter.isBundled ||
              reciter.id == PrayerAudioCatalogRules.bundledReciterId,
        )) {
          throw const FormatException(
            'The public catalog cannot replace built-in audio.',
          );
        }
        await cacheDirectory.create(recursive: true);
        final temporary = File('${cached.path}.tmp');
        await temporary.writeAsString(raw, flush: true);
        await temporary.rename(cached.path);
        catalogRefreshFailed = false;
        return _catalog = await _withBuiltIn(catalog);
      } catch (_) {
        /* Offline retains the last validated manifest. */
        catalogRefreshFailed = true;
      }
    }
    try {
      return _catalog = await _withBuiltIn(
        PrayerAudioCatalog(
          jsonDecode(await cached.readAsString()) as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      return _catalog = _bundledCatalog ??= PrayerAudioCatalog(
        jsonDecode(await _bundledCatalogLoader()) as Map<String, dynamic>,
      );
    }
  }

  Future<PrayerAudioCatalog> _withBuiltIn(PrayerAudioCatalog catalog) async {
    final local = _bundledCatalog ??= PrayerAudioCatalog(
      jsonDecode(await _bundledCatalogLoader()) as Map<String, dynamic>,
    );
    final bundled = local.reciters.where((reciter) => reciter.isBundled);
    return bundled.isEmpty ? catalog : catalog.withBuiltIn(bundled.single);
  }

  Directory directoryFor(String version, String id) {
    if (!PrayerAudioCatalogRules.versionPattern.hasMatch(version) ||
        !PrayerAudioCatalogRules.idPattern.hasMatch(id)) {
      throw const FormatException('Invalid audio identity.');
    }
    return id == PrayerAudioCatalogRules.bundledReciterId && version == 'v1'
        ? Directory(p.join(bundledDirectory.path, version, id))
        : Directory(p.join(cacheDirectory.path, version, id));
  }

  Future<bool> isReady(PrayerAudioReciter reciter, String version) async {
    final directory = directoryFor(
      reciter.isBundled ? 'v1' : version,
      reciter.id,
    );
    return await _valid(
          File(p.join(directory.path, reciter.full.filename)),
          reciter.full,
        ) &&
        await _valid(
          File(p.join(directory.path, reciter.short.filename)),
          reciter.short,
        );
  }

  Future<bool> _valid(File file, PrayerAudioVariant variant) async {
    return _validMetadata(file, variant.bytes, variant.sha256Hex);
  }

  Future<bool> _validMetadata(File file, int bytes, String digest) async {
    try {
      return bytes > 0 &&
          bytes <= 8388608 &&
          RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) &&
          await file.length() == bytes &&
          (await sha256.bind(file.openRead()).first).toString() == digest;
    } catch (_) {
      return false;
    }
  }

  /// A saved version stays usable even after the public catalog moves forward.
  Future<bool> isSelectionReadyFields(
    String reciterId,
    String audioVersion,
  ) async {
    try {
      if (reciterId == PrayerAudioCatalogRules.bundledReciterId &&
          audioVersion == 'v1') {
        final bundled = _bundledCatalog ??= PrayerAudioCatalog(
          jsonDecode(await _bundledCatalogLoader()) as Map<String, dynamic>,
        );
        return isReady(
          bundled.reciters.firstWhere((r) => r.id == reciterId),
          'v1',
        );
      }
      final directory = directoryFor(audioVersion, reciterId);
      final manifest =
          jsonDecode(
                await File(
                  p.join(directory.path, 'manifest.json'),
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final reciter = manifest['reciter'] as Map<String, dynamic>;
      if (manifest['audio_version'] != audioVersion ||
          reciter['id'] != reciterId) {
        return false;
      }
      for (final variant in {
        'full': 'full.mp3',
        'notification': 'notification.wav',
      }.entries) {
        final metadata = reciter[variant.key] as Map<String, dynamic>;
        if (!await _validMetadata(
          File(p.join(directory.path, variant.value)),
          metadata['bytes'] as int,
          metadata['sha256'] as String,
        )) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeManifest(
    PrayerAudioReciter reciter,
    String version,
  ) async {
    if (reciter.id == PrayerAudioCatalogRules.bundledReciterId &&
        version == 'v1') {
      return;
    }
    final manifest = File(
      p.join(directoryFor(version, reciter.id).path, 'manifest.json'),
    );
    final temporary = File('${manifest.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'audio_version': version,
        'reciter': {
          'id': reciter.id,
          'full': {
            'bytes': reciter.full.bytes,
            'sha256': reciter.full.sha256Hex,
          },
          'notification': {
            'bytes': reciter.short.bytes,
            'sha256': reciter.short.sha256Hex,
          },
        },
      }),
      flush: true,
    );
    await temporary.rename(manifest.path);
  }

  /// Removes a downloaded recording. The built-in one stays.
  Future<void> delete(PrayerAudioReciter reciter, String version) =>
      _lock.synchronized(() async {
        if (reciter.isBundled) return;
        final directory = directoryFor(version, reciter.id);
        if (await directory.exists()) await directory.delete(recursive: true);
      });

  /// Throws [PrayerAudioDownloadException]; [token] cancels this download only.
  Future<void> ensureDownloaded(
    PrayerAudioReciter reciter,
    String version, {
    void Function(double progress)? onProgress,
    PrayerAudioDownloadToken? token,
  }) async {
    try {
      await _download(reciter, version, onProgress, token);
    } catch (error) {
      if (token?.canceled == true || _closed) {
        throw const PrayerAudioDownloadException(
          PrayerAudioDownloadFailure.canceled,
        );
      }
      throw PrayerAudioDownloadException.from(error);
    }
  }

  Future<void> _download(
    PrayerAudioReciter reciter,
    String version,
    void Function(double progress)? onProgress,
    PrayerAudioDownloadToken? token,
  ) => _lock.synchronized(() async {
    if (_closed || token?.canceled == true) {
      throw StateError('Audio downloads were canceled.');
    }
    if (await isReady(reciter, version)) {
      await _writeManifest(reciter, version);
      onProgress?.call(1);
      return;
    }
    if (reciter.id == PrayerAudioCatalogRules.bundledReciterId &&
        version == 'v1') {
      throw const FileSystemException(
        'The bundled Adhan recording is unavailable.',
      );
    }
    final directory = directoryFor(version, reciter.id);
    await directory.create(recursive: true);
    final total = reciter.full.bytes + reciter.short.bytes;
    var completed = 0;
    final temporaryFiles = <File>[];
    try {
      for (final variant in [reciter.full, reciter.short]) {
        final target = File(p.join(directory.path, variant.filename));
        final temporary = File('${target.path}.download');
        temporaryFiles.add(temporary);
        final response = await Future.any([
          _client
              .send(http.Request('GET', variant.url!))
              .timeout(const Duration(seconds: 20)),
          if (token != null)
            token.whenCanceled.then<http.StreamedResponse>(
              (_) => throw StateError('Audio downloads were canceled.'),
            ),
        ]);
        if (response.statusCode != 200) {
          throw HttpException(
            'Adhan download failed (${response.statusCode}).',
          );
        }
        final sink = temporary.openWrite();
        var received = 0;
        try {
          await for (final chunk in response.stream.timeout(
            const Duration(seconds: 30),
          )) {
            if (_closed || token?.canceled == true) {
              throw StateError('Audio downloads were canceled.');
            }
            received += chunk.length;
            if (received > variant.bytes) {
              throw const FormatException(
                'Adhan download exceeds manifest size.',
              );
            }
            sink.add(chunk);
            onProgress?.call((completed + received) / total);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (!await _valid(temporary, variant)) {
          throw const FormatException(
            'Adhan download failed integrity verification.',
          );
        }
        completed += received;
      }
      // Settings are committed only after both verified files have been promoted.
      for (final temporary in temporaryFiles) {
        await temporary.rename(
          temporary.path.substring(
            0,
            temporary.path.length - '.download'.length,
          ),
        );
      }
      await _writeManifest(reciter, version);
      onProgress?.call(1);
    } finally {
      for (final temporary in temporaryFiles) {
        if (await temporary.exists()) await temporary.delete();
      }
    }
  });

  void close() {
    _closed = true;
    _client.close();
  }
}
