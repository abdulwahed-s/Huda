import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/cache/quran_content_store.dart';
import 'package:huda/core/services/quran_audio_catalog.dart';
import 'package:huda/data/models/surah_model.dart' as quran;
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/download_service.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart';
import 'package:huda/data/repository/audio_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  final AudioRepository audioRepository;
  final CacheHelper _cacheHelper = getIt<CacheHelper>();
  final DownloadService _downloadService = getIt<DownloadService>();

  static const String _readersListCacheKey = 'audio_readers_list';
  final QuranContentStore _contentStore = getIt<QuranContentStore>();
  final Future<bool> Function() _isConnected;
  int _audioRequest = 0;

  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const int _cacheExpirationHours = 24;

  // Persists the reader list across state transitions (e.g. AudioLoaded →
  // SurahAudioLoaded) so widgets can always retrieve it regardless of the
  // current state.
  List<edition.Data> _lastKnownReaders = [];
  List<edition.Data> get lastKnownReaders => _lastKnownReaders;

  Future<bool> isOffline() async {
    return !(await _isConnected());
  }

  AudioCubit(this.audioRepository, {Future<bool> Function()? isConnected})
    : _isConnected = isConnected ?? NetworkInfo.checkInternetConnectivity,
      super(AudioInitial());

  Future<void> fetchAudioInfo([String? surahNumber]) async {
    emit(ReaderLoading());
    try {
      edition.EditionModel? readers;
      final cachedData = _cacheHelper.getDataString(key: _readersListCacheKey);
      if (cachedData != null) {
        try {
          readers = edition.EditionModel.fromJson(jsonDecode(cachedData));
        } catch (_) {
        }
      }
      final online = await _isConnected();
      if (online &&
          (readers == null || _isCacheExpired(_readersListCacheKey))) {
        try {
          readers = await audioRepository.getAudio();
          await _saveCacheWithTimestamp(
            _readersListCacheKey,
            jsonEncode(readers.toJson()),
          );
        } catch (_) {
          if (readers == null) rethrow;
        }
      }
      if (isClosed) return;
      if (!online && surahNumber != null) {
        final ids = await getDownloadedReadersForSurah(surahNumber);
        if (isClosed) return;
        if (ids.isEmpty) {
          emit(ReaderOffline());
          return;
        }
        final entries = [...?readers?.data];
        for (final id in ids) {
          if (!entries.any((reader) => reader.identifier == id)) {
            entries.add(
              edition.Data(
                identifier: id,
                name: id,
                englishName: id,
                language: id.split('.').first,
                format: 'audio',
              ),
            );
          }
        }
        readers = edition.EditionModel(data: entries);
        _lastKnownReaders = entries;
        emit(
          AudioOfflineWithDownloads(
            surahAudioModel: readers,
            downloadedReaderIds: ids,
            surahNumber: surahNumber,
          ),
        );
      } else if (readers != null) {
        _lastKnownReaders = readers.data ?? [];
        emit(AudioLoaded(surahAudioModel: readers));
      } else {
        emit(ReaderOffline());
      }
    } catch (e) {
      if (!isClosed) emit(ReaderError(e.toString()));
    }
  }

  Future<void> fetchSurahAudio(
    String identifier,
    quran.SurahModel surah,
  ) async {
    final request = ++_audioRequest;
    bool isCurrent() => !isClosed && request == _audioRequest;
    SurahAudioModel? cachedAudio;
    emit(SurahAudioLoading());
    try {
      final generated = QuranAudioCatalog.forSurah(identifier, surah);
      if (generated != null) {
        emit(SurahAudioLoaded(audioModel: generated));
        return;
      }

      final cached = await _contentStore.readSurah(
        QuranContentKind.audio,
        identifier,
        surah.number!,
      );
      if (!isCurrent()) return;
      if (cached != null) {
        cachedAudio = SurahAudioModel.fromJson(cached.response);
        emit(SurahAudioLoaded(audioModel: cachedAudio));
        if (!cached.isExpired) return;
      }
      final online = await _isConnected();
      if (!isCurrent()) return;
      if (!online) {
        if (cachedAudio == null) emit(AudioOffline());
        return;
      }
      final audio = await audioRepository.getSurahAudio(
        identifier,
        surah.number!,
      );
      await _contentStore.saveSurah(
        QuranContentKind.audio,
        identifier,
        surah.number!,
        audio.toJson(),
      );
      if (isCurrent()) emit(SurahAudioLoaded(audioModel: audio));
    } catch (e) {
      if (isCurrent() && cachedAudio == null) emit(AudioError(e.toString()));
    }
  }

  Future<Uri?> resolveAyahAudioUri({
    required String readerId,
    required int surahNumber,
    required int ayahNumber,
    int? globalAyahNumber,
    String? remoteUrl,
  }) async {
    final downloadedPath = await getDownloadedAyahPath(
      surahNumber: surahNumber.toString(),
      ayahNumber: ayahNumber.toString(),
      readerId: readerId,
    );
    if (downloadedPath != null) return Uri.file(downloadedPath);
    final url =
        remoteUrl ?? QuranAudioCatalog.ayahUrl(readerId, globalAyahNumber);
    if (url == null) return null;
    return Uri.parse(
      kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(url)}' : url,
    );
  }

  Future<void> clearAudioCache() async {
    await _contentStore.clearAudio();
    await _cacheHelper.removeData(key: _readersListCacheKey);
    await _cacheHelper.removeData(
      key: '$_cacheTimestampPrefix$_readersListCacheKey',
    );
  }

  Future<void> clearReaderCache(String identifier) =>
      _contentStore.clearAudio(identifier);

  bool get hasReadersCache =>
      _cacheHelper.getDataString(key: _readersListCacheKey) != null;

  bool _isCacheExpired(String key) {
    final timestampKey = '$_cacheTimestampPrefix$key';
    final timestamp = _cacheHelper.getData(key: timestampKey);

    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inHours;

    return difference >= _cacheExpirationHours;
  }

  Future<void> _saveCacheWithTimestamp(String key, String value) async {
    await _cacheHelper.saveData(key: key, value: value);
    final timestampKey = '$_cacheTimestampPrefix$key';
    await _cacheHelper.saveData(
      key: timestampKey,
      value: DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<String> getAvailableLanguages() {
    List<edition.Data> allReaders = _lastKnownReaders;

    if (state is AudioLoaded) {
      final audioState = state as AudioLoaded;
      allReaders = audioState.surahAudioModel.data ?? [];
    } else if (state is AudioOfflineWithDownloads) {
      final audioState = state as AudioOfflineWithDownloads;
      allReaders = audioState.surahAudioModel.data ?? [];
    }

    final languages = allReaders
        .map((reader) => reader.language)
        .where((language) => language != null && language.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    languages.sort();
    return languages;
  }

  List<edition.Data> getReadersByLanguage(String? selectedLanguage) {
    List<edition.Data> allReaders = _lastKnownReaders;

    if (state is AudioLoaded) {
      final audioState = state as AudioLoaded;
      allReaders = audioState.surahAudioModel.data ?? [];
    } else if (state is AudioOfflineWithDownloads) {
      final audioState = state as AudioOfflineWithDownloads;
      allReaders = audioState.surahAudioModel.data ?? [];
    }

    if (selectedLanguage == null || selectedLanguage.isEmpty) {
      return allReaders;
    }

    return allReaders
        .where((reader) => reader.language == selectedLanguage)
        .toList();
  }

  Future<void> downloadAyahAudio({
    required String ayahAudioUrl,
    required String surahNumber,
    required String ayahNumber,
    required String readerId,
  }) async {
    try {
      final fileName = 'ayah_${ayahNumber}_$readerId.mp3';
      final ayahId = '${surahNumber}_${ayahNumber}_$readerId';

      final isDownloaded = await _downloadService.isFileDownloaded(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        fileName: fileName,
      );

      if (isDownloaded) {
        final localPath = await _downloadService.getLocalFilePath(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          fileName: fileName,
        );
        emit(
          DownloadCompleted(
            ayahId: ayahId,
            filePath: localPath!,
            fileName: fileName,
          ),
        );
        return;
      }

      final filePath = await _downloadService.downloadAudioFile(
        url: ayahAudioUrl,
        fileName: fileName,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        onProgress: (progress) {
          emit(
            DownloadInProgress(
              ayahId: ayahId,
              progress: progress,
              fileName: fileName,
            ),
          );
        },
      );

      if (filePath != null) {
        emit(
          DownloadCompleted(
            ayahId: ayahId,
            filePath: filePath,
            fileName: fileName,
          ),
        );
      } else {
        emit(
          DownloadError(ayahId: ayahId, error: 'Failed to download audio file'),
        );
      }
    } catch (e) {
      final ayahId = '${surahNumber}_${ayahNumber}_$readerId';
      emit(DownloadError(ayahId: ayahId, error: e.toString()));
    }
  }

  Future<void> downloadAllSurahAyahs({
    required SurahAudioModel surahAudioModel,
    required String surahNumber,
    required String readerId,
  }) async {
    try {
      final targetSurah = surahAudioModel.data?.surahs?.firstWhere(
        (surah) => surah.number.toString() == surahNumber,
        orElse: () => surahAudioModel.data!.surahs!.first,
      );

      if (targetSurah?.ayahs == null || targetSurah!.ayahs!.isEmpty) {
        emit(
          DownloadError(
            ayahId: 'surah_$surahNumber',
            error: 'No ayahs found in surah',
          ),
        );
        return;
      }

      final totalAyahs = targetSurah.ayahs!.length;
      int downloadedCount = 0;

      for (int i = 0; i < targetSurah.ayahs!.length; i++) {
        final ayah = targetSurah.ayahs![i];
        if (ayah.audio == null) continue;

        final fileName = 'ayah_${ayah.numberInSurah}_$readerId.mp3';

        final isDownloaded = await _downloadService.isFileDownloaded(
          surahNumber: surahNumber,
          ayahNumber: ayah.numberInSurah.toString(),
          fileName: fileName,
        );

        if (!isDownloaded) {
          emit(
            SurahDownloadInProgress(
              totalAyahs: totalAyahs,
              downloadedAyahs: downloadedCount,
              overallProgress: downloadedCount / totalAyahs,
              currentAyahFileName: fileName,
            ),
          );

          final filePath = await _downloadService.downloadAudioFile(
            url: ayah.audio!,
            fileName: fileName,
            surahNumber: surahNumber,
            ayahNumber: ayah.numberInSurah.toString(),
          );

          if (filePath == null) {
            emit(
              DownloadError(
                ayahId: 'surah_$surahNumber',
                error: 'Failed to download ayah ${ayah.numberInSurah}',
              ),
            );
            return;
          }
        }

        downloadedCount++;

        emit(
          SurahDownloadInProgress(
            totalAyahs: totalAyahs,
            downloadedAyahs: downloadedCount,
            overallProgress: downloadedCount / totalAyahs,
            currentAyahFileName: fileName,
          ),
        );
      }

      emit(
        SurahDownloadCompleted(
          totalAyahs: totalAyahs,
          surahNumber: surahNumber,
        ),
      );
    } catch (e) {
      emit(DownloadError(ayahId: 'surah_$surahNumber', error: e.toString()));
    }
  }

  Future<bool> isAyahDownloaded({
    required String surahNumber,
    required String ayahNumber,
    required String readerId,
  }) async {
    final fileName = 'ayah_${ayahNumber}_$readerId.mp3';
    return await _downloadService.isFileDownloaded(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      fileName: fileName,
    );
  }

  Future<String?> getDownloadedAyahPath({
    required String surahNumber,
    required String ayahNumber,
    required String readerId,
  }) async {
    final fileName = 'ayah_${ayahNumber}_$readerId.mp3';
    return await _downloadService.getLocalFilePath(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      fileName: fileName,
    );
  }

  Future<bool> deleteDownloadedAyah({
    required String surahNumber,
    required String ayahNumber,
    required String readerId,
  }) async {
    final fileName = 'ayah_${ayahNumber}_$readerId.mp3';
    return await _downloadService.deleteDownloadedFile(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      fileName: fileName,
    );
  }

  Future<List<String>> getDownloadedReadersForSurah(String surahNumber) async {
    if (kIsWeb) return [];
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(
        path.join(appDocDir.path, 'quran_audio', 'surah_$surahNumber'),
      );
      if (!await audioDir.exists()) return [];
      final readers = <String>{};
      final filePattern = RegExp(r'^ayah_\d+_(.+)\.mp3$');
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          final match = filePattern.firstMatch(path.basename(entity.path));
          if (match != null) readers.add(match[1]!);
        }
      }
      return readers.toList()..sort();
    } catch (_) {
      return [];
    }
  }
}
