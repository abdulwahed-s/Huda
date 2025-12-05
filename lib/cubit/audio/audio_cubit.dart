import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/core/cache/cache_helper.dart';
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
  static const String _surahAudioCachePrefix = 'surah_audio_';

  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const int _cacheExpirationHours = 24;

  Future<bool> isOffline() async {
    return !(await NetworkInfo.checkInternetConnectivity());
  }

  AudioCubit(this.audioRepository) : super(AudioInitial());

  Future<void> fetchAudioInfo([String? surahNumber]) async {
    emit(ReaderLoading());
    try {
      final cachedData = _cacheHelper.getDataString(key: _readersListCacheKey);

      if (cachedData != null && !_isCacheExpired(_readersListCacheKey)) {
        final Map<String, dynamic> jsonData = jsonDecode(cachedData);
        final audiosReaders = edition.EditionModel.fromJson(jsonData);

        final isOnline = await NetworkInfo.checkInternetConnectivity();

        if (isOnline) {
          emit(AudioLoaded(surahAudioModel: audiosReaders));
          _updateReadersCache();
        } else {
          if (surahNumber != null) {
            final downloadedReaderIds =
                await getDownloadedReadersForSurah(surahNumber);

            if (downloadedReaderIds.isNotEmpty) {
              emit(AudioOfflineWithDownloads(
                surahAudioModel: audiosReaders,
                downloadedReaderIds: downloadedReaderIds,
                surahNumber: surahNumber,
              ));
            } else {
              emit(ReaderOffline());
            }
          } else {
            emit(AudioLoaded(surahAudioModel: audiosReaders));
          }
        }
      } else {
        if (await NetworkInfo.checkInternetConnectivity()) {
          final audiosReaders = await audioRepository.getAudio();

          await _saveCacheWithTimestamp(
            _readersListCacheKey,
            jsonEncode(audiosReaders.toJson()),
          );

          emit(AudioLoaded(surahAudioModel: audiosReaders));
        } else {
          if (cachedData != null) {
            final Map<String, dynamic> jsonData = jsonDecode(cachedData);
            final audiosReaders = edition.EditionModel.fromJson(jsonData);

            if (surahNumber != null) {
              final downloadedReaderIds =
                  await getDownloadedReadersForSurah(surahNumber);

              if (downloadedReaderIds.isNotEmpty) {
                emit(AudioOfflineWithDownloads(
                  surahAudioModel: audiosReaders,
                  downloadedReaderIds: downloadedReaderIds,
                  surahNumber: surahNumber,
                ));
              } else {
                emit(ReaderOffline());
              }
            } else {
              emit(AudioLoaded(surahAudioModel: audiosReaders));
            }
          } else {
            if (surahNumber != null) {
              final downloadedReaderIds =
                  await getDownloadedReadersForSurah(surahNumber);
              if (downloadedReaderIds.isNotEmpty) {
                emit(ReaderOffline());
              } else {
                emit(ReaderOffline());
              }
            } else {
              emit(ReaderOffline());
            }
          }
        }
      }
    } catch (e) {
      emit(ReaderError(e.toString()));
    }
  }

  Future<void> _updateReadersCache() async {
    try {
      final audiosReaders = await audioRepository.getAudio();
      await _saveCacheWithTimestamp(
        _readersListCacheKey,
        jsonEncode(audiosReaders.toJson()),
      );
    } catch (e) {
      // print the error if needed
    }
  }

  Future<void> fetchSurahAudio(String identifier) async {
    try {
      final cacheKey = '$_surahAudioCachePrefix$identifier';
      final cachedData = _cacheHelper.getDataString(key: cacheKey);

      final isCached = cachedData != null && !_isCacheExpired(cacheKey);

      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(clearAudio: true));
      } else {
        emit(SurahAudioLoading());
      }

      if (isCached) {
        final Map<String, dynamic> jsonData = jsonDecode(cachedData);
        final audio = SurahAudioModel.fromJson(jsonData);

        if (state is AudioLoaded) {
          final currentState = state as AudioLoaded;
          emit(currentState.copyWith(currentSurahAudio: audio));
        } else {
          emit(SurahAudioLoaded(audioModel: audio));
        }

        if (await NetworkInfo.checkInternetConnectivity()) {
          _updateSurahAudioCache(identifier);
        }
      } else {
        if (await NetworkInfo.checkInternetConnectivity()) {
          final audio = await audioRepository.getSurahAudio(identifier);

          await _saveCacheWithTimestamp(
            cacheKey,
            jsonEncode(audio.toJson()),
          );

          if (state is AudioLoaded) {
            final currentState = state as AudioLoaded;
            emit(currentState.copyWith(currentSurahAudio: audio));
          } else {
            emit(SurahAudioLoaded(audioModel: audio));
          }
        } else {
          emit(AudioOffline());
        }
      }
    } catch (e) {
      emit(AudioError(e.toString()));
    }
  }

  Future<void> _updateSurahAudioCache(String identifier) async {
    try {
      final audio = await audioRepository.getSurahAudio(identifier);
      final cacheKey = '$_surahAudioCachePrefix$identifier';
      await _saveCacheWithTimestamp(
        cacheKey,
        jsonEncode(audio.toJson()),
      );

      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentSurahAudio: audio));
      }
    } catch (e) {
      // print the error if needed
    }
  }

  Future<void> clearAudioCache() async {
    try {
      await _cacheHelper.removeData(key: _readersListCacheKey);

      final keys = CacheHelper.sharedPreferences.getKeys();
      for (final key in keys) {
        if (key.startsWith(_surahAudioCachePrefix)) {
          await _cacheHelper.removeData(key: key);
        }
      }
    } catch (e) {
      // print the error if needed
    }
  }

  Future<void> clearReaderCache(String identifier) async {
    try {
      final cacheKey = '$_surahAudioCachePrefix$identifier';
      await _cacheHelper.removeData(key: cacheKey);
    } catch (e) {
      // print the error if needed
    }
  }

  bool get hasReadersCache {
    return _cacheHelper.getDataString(key: _readersListCacheKey) != null;
  }

  bool hasReaderAudioCache(String identifier) {
    final cacheKey = '$_surahAudioCachePrefix$identifier';
    return _cacheHelper.getDataString(key: cacheKey) != null;
  }

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
    List<edition.Data> allReaders = [];

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
    List<edition.Data> allReaders = [];

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
        emit(DownloadCompleted(
          ayahId: ayahId,
          filePath: localPath!,
          fileName: fileName,
        ));
        return;
      }

      final filePath = await _downloadService.downloadAudioFile(
        url: ayahAudioUrl,
        fileName: fileName,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        onProgress: (progress) {
          emit(DownloadInProgress(
            ayahId: ayahId,
            progress: progress,
            fileName: fileName,
          ));
        },
      );

      if (filePath != null) {
        emit(DownloadCompleted(
          ayahId: ayahId,
          filePath: filePath,
          fileName: fileName,
        ));
      } else {
        emit(DownloadError(
          ayahId: ayahId,
          error: 'Failed to download audio file',
        ));
      }
    } catch (e) {
      final ayahId = '${surahNumber}_${ayahNumber}_$readerId';
      emit(DownloadError(
        ayahId: ayahId,
        error: e.toString(),
      ));
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
        emit(DownloadError(
          ayahId: 'surah_$surahNumber',
          error: 'No ayahs found in surah',
        ));
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
          emit(SurahDownloadInProgress(
            totalAyahs: totalAyahs,
            downloadedAyahs: downloadedCount,
            overallProgress: downloadedCount / totalAyahs,
            currentAyahFileName: fileName,
          ));

          final filePath = await _downloadService.downloadAudioFile(
            url: ayah.audio!,
            fileName: fileName,
            surahNumber: surahNumber,
            ayahNumber: ayah.numberInSurah.toString(),
          );

          if (filePath == null) {
            emit(DownloadError(
              ayahId: 'surah_$surahNumber',
              error: 'Failed to download ayah ${ayah.numberInSurah}',
            ));
            return;
          }
        }

        downloadedCount++;

        emit(SurahDownloadInProgress(
          totalAyahs: totalAyahs,
          downloadedAyahs: downloadedCount,
          overallProgress: downloadedCount / totalAyahs,
          currentAyahFileName: fileName,
        ));
      }

      emit(SurahDownloadCompleted(
        totalAyahs: totalAyahs,
        surahNumber: surahNumber,
      ));
    } catch (e) {
      emit(DownloadError(
        ayahId: 'surah_$surahNumber',
        error: e.toString(),
      ));
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
    final downloadedReaders = <String>[];

    final cachedData = _cacheHelper.getDataString(key: _readersListCacheKey);
    if (cachedData != null) {
      final Map<String, dynamic> jsonData = jsonDecode(cachedData);
      final audiosReaders = edition.EditionModel.fromJson(jsonData);
      final readers = audiosReaders.data ?? [];

      for (final reader in readers) {
        if (reader.identifier != null) {
          final hasDownloads = await _hasAnyDownloadedAyahsForReader(
            surahNumber: surahNumber,
            readerId: reader.identifier!,
          );
          if (hasDownloads) {
            downloadedReaders.add(reader.identifier!);
          }
        }
      }
    }

    return downloadedReaders;
  }

  Future<bool> _hasAnyDownloadedAyahsForReader({
    required String surahNumber,
    required String readerId,
  }) async {
    // Downloads not supported on web
    if (kIsWeb) return false;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(
          path.join(appDocDir.path, 'quran_audio', 'surah_$surahNumber'));

      if (!await audioDir.exists()) {
        return false;
      }

      await for (FileSystemEntity entity in audioDir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.contains('_$readerId.mp3')) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
