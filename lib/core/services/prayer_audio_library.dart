import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/android_prayer_audio_repository.dart';
import 'package:huda/core/services/android_prayer_experience_service.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/ios_prayer_audio_repository.dart';
import 'package:huda/core/services/linux_prayer_audio_repository.dart';
import 'package:huda/core/services/mac_prayer_audio_repository.dart';
import 'package:huda/core/services/prayer_audio_repository.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/windows_prayer_audio_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

export 'package:huda/core/services/prayer_audio_catalog.dart';
export 'package:huda/core/services/prayer_audio_repository.dart'
    show PrayerAudioDownloadFailure;

enum PrayerSoundState { builtIn, ready, notDownloaded, downloading, failed }

@immutable
class PrayerSoundStatus {
  const PrayerSoundStatus(this.state, {this.progress, this.failure});

  final PrayerSoundState state;

  /// 0–1 while downloading; null before the first bytes arrive.
  final double? progress;
  final PrayerAudioDownloadFailure? failure;

  bool get available =>
      state == PrayerSoundState.builtIn || state == PrayerSoundState.ready;
}

/// The adhan recordings on this device: which are ready offline, downloads
/// with progress and cancel, removal, and previews. One instance outlives
/// the settings sheet, so a download keeps going after it closes.
class PrayerAudioLibrary extends ChangeNotifier {
  PrayerAudioLibrary({
    required Future<PrayerAudioRepository> Function() repository,
    AudioPlayer? player,
    AudioCoordinator? coordinator,
  }) : _createRepository = repository,
       _player = player,
       _coordinator = coordinator;

  static PrayerAudioLibrary? _shared;
  static PrayerAudioLibrary get shared =>
      _shared ??= PrayerAudioLibrary(repository: platformRepository);

  @visibleForTesting
  static set shared(PrayerAudioLibrary value) => _shared = value;

  static Future<PrayerAudioRepository> platformRepository() async {
    if (Platform.isAndroid) {
      return AndroidPrayerAudioRepository.create(
        getIt<AndroidPrayerExperienceService>().api,
      );
    }
    if (Platform.isIOS) return IOSPrayerAudioRepository.create();
    if (Platform.isMacOS) return MacPrayerAudioRepository.create();
    if (Platform.isWindows) return WindowsPrayerAudioRepository.create();
    return LinuxPrayerAudioRepository.create();
  }

  final Future<PrayerAudioRepository> Function() _createRepository;
  final AudioPlayer? _player;
  final AudioCoordinator? _coordinator;
  Future<PrayerAudioRepository>? _repository;
  final _status = <String, PrayerSoundStatus>{};
  final _tokens = <String, PrayerAudioDownloadToken>{};
  final _downloads = <String, Future<bool>>{};
  StreamSubscription<PlayerState>? _playerState;
  bool _disposed = false;

  PrayerAudioCatalog? catalog;
  bool loading = false;
  bool catalogFailed = false;

  /// The saved list is shown because the latest one couldn't be fetched.
  bool get catalogOutdated => _catalogOutdated;
  bool _catalogOutdated = false;

  /// The reciter being previewed, and whether it is the whole adhan.
  String? previewing;
  bool previewFull = false;

  Future<PrayerAudioRepository> get repository =>
      _repository ??= _createRepository();

  List<PrayerAudioReciter> get reciters => catalog?.reciters ?? const [];

  PrayerAudioReciter? reciter(String id) {
    for (final reciter in reciters) {
      if (reciter.id == id) return reciter;
    }
    return null;
  }

  /// The audio version a selection of this reciter saves.
  String versionFor(PrayerAudioReciter reciter) =>
      reciter.isBundled ? 'v1' : catalog!.version;

  PrayerSoundStatus status(String id) =>
      _status[id] ?? const PrayerSoundStatus(PrayerSoundState.notDownloaded);

  /// Bytes used by downloaded recordings (the built-in one is not counted).
  int get downloadedBytes => reciters
      .where((reciter) => status(reciter.id).state == PrayerSoundState.ready)
      .fold(
        0,
        (sum, reciter) => sum + reciter.full.bytes + reciter.short.bytes,
      );

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    loading = true;
    catalogFailed = false;
    _notify();
    try {
      final repo = await repository;
      catalog = await repo.loadCatalog(refresh: refresh);
      _catalogOutdated = refresh && repo.catalogRefreshFailed;
      for (final reciter in reciters) {
        if (status(reciter.id).state == PrayerSoundState.downloading) continue;
        _status[reciter.id] = reciter.isBundled
            ? const PrayerSoundStatus(PrayerSoundState.builtIn)
            : await repo.isReady(reciter, versionFor(reciter))
            ? const PrayerSoundStatus(PrayerSoundState.ready)
            : const PrayerSoundStatus(PrayerSoundState.notDownloaded);
      }
    } catch (error) {
      debugPrint('Adhan sounds unavailable: $error');
      catalogFailed = true;
    } finally {
      loading = false;
      _notify();
    }
  }

  /// Downloads and verifies [id]; true once it is ready offline. A second
  /// call while downloading waits for the same download.
  Future<bool> download(String id) {
    if (status(id).available) return Future.value(true);
    return _downloads[id] ??= _download(
      id,
    ).whenComplete(() => _downloads.remove(id));
  }

  Future<bool> _download(String id) async {
    final reciter = this.reciter(id);
    if (reciter == null) return false;
    final token = _tokens[id] = PrayerAudioDownloadToken();
    _status[id] = const PrayerSoundStatus(PrayerSoundState.downloading);
    _notify();
    try {
      final repo = await repository;
      void progress(double value) {
        if (token.canceled) return;
        _status[id] = PrayerSoundStatus(
          PrayerSoundState.downloading,
          progress: value.clamp(0, 1).toDouble(),
        );
        _notify();
      }

      if (repo is IOSPrayerAudioRepository) {
        await repo.prepare(
          reciter,
          versionFor(reciter),
          onProgress: progress,
          token: token,
        );
      } else {
        await repo.ensureDownloaded(
          reciter,
          versionFor(reciter),
          onProgress: progress,
          token: token,
        );
      }
      _status[id] = const PrayerSoundStatus(PrayerSoundState.ready);
      return true;
    } on PrayerAudioDownloadException catch (error) {
      _status[id] = error.kind == PrayerAudioDownloadFailure.canceled
          ? const PrayerSoundStatus(PrayerSoundState.notDownloaded)
          : PrayerSoundStatus(PrayerSoundState.failed, failure: error.kind);
      return false;
    } catch (error) {
      debugPrint('Adhan download failed: $error');
      _status[id] = const PrayerSoundStatus(
        PrayerSoundState.failed,
        failure: PrayerAudioDownloadFailure.storage,
      );
      return false;
    } finally {
      _tokens.remove(id);
      _notify();
    }
  }

  void cancel(String id) => _tokens[id]?.cancel();

  /// Removes a downloaded recording. The caller makes sure no prayer uses it.
  Future<void> remove(String id) async {
    final reciter = this.reciter(id);
    if (reciter == null || reciter.isBundled) return;
    if (previewing == id) await stopPreview();
    await (await repository).delete(reciter, versionFor(reciter));
    _status[id] = const PrayerSoundStatus(PrayerSoundState.notDownloaded);
    _notify();
  }

  AudioPlayer get _audio => _player ?? getIt<AudioPlayer>();
  AudioCoordinator get _owner => _coordinator ?? getIt<AudioCoordinator>();

  /// Plays a sample: the short recording, or the whole adhan when [full].
  /// Recordings that aren't downloaded stream from the catalog.
  Future<void> preview(String id, {bool full = false, double? volume}) async {
    final reciter = this.reciter(id);
    if (reciter == null) return;
    final source = await _source(reciter, full: full);
    if (source == null) return;
    _owner.register(AudioCoordinator.adhanPreview, () {
      previewing = null;
      _notify();
    });
    _owner.requestAudio(AudioCoordinator.adhanPreview);
    previewing = id;
    previewFull = full;
    _notify();
    try {
      await audioServiceReady;
      await _audio.setAudioSource(source);
      if (volume != null) await _audio.setVolume(volume);
      _playerState ??= _audio.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed &&
            _owner.isOwner(AudioCoordinator.adhanPreview)) {
          unawaited(stopPreview());
        }
      });
      unawaited(_audio.play());
    } catch (error) {
      debugPrint('Adhan preview failed: $error');
      await stopPreview();
      rethrow;
    }
  }

  Future<void> setPreviewVolume(double volume) async {
    if (previewing != null) await _audio.setVolume(volume);
  }

  Future<void> stopPreview() async {
    if (previewing == null) return;
    previewing = null;
    _notify();
    if (_owner.isOwner(AudioCoordinator.adhanPreview)) {
      try {
        await _audio.stop();
        await _audio.setVolume(1);
      } catch (_) {}
      _owner.release(AudioCoordinator.adhanPreview);
    }
  }

  Future<AudioSource?> _source(
    PrayerAudioReciter reciter, {
    required bool full,
  }) async {
    final tag = MediaItem(
      id: 'adhan-preview-${reciter.id}',
      title: reciter.nameEn,
    );
    final variant = full ? reciter.full : reciter.short;
    if (status(reciter.id).available) {
      final repo = await repository;
      if (Platform.isAndroid && reciter.isBundled) {
        final package = (await PackageInfo.fromPlatform()).packageName;
        return AudioSource.uri(
          Uri.parse('android.resource://$package/raw/azan_sound'),
          tag: tag,
        );
      }
      final file = File(
        p.join(
          repo.directoryFor(versionFor(reciter), reciter.id).path,
          variant.filename,
        ),
      );
      if (await file.exists()) return AudioSource.file(file.path, tag: tag);
    }
    final url = variant.url;
    return url == null ? null : AudioSource.uri(url, tag: tag);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _tokens.values) {
      token.cancel();
    }
    unawaited(_playerState?.cancel());
    super.dispose();
  }
}
