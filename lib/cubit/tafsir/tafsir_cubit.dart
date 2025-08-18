import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:meta/meta.dart';

part 'tafsir_state.dart';

class TafsirCubit extends Cubit<TafsirState> {
  final TafsirRepository tafsirRepository;
  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  static const String _tafsirListCacheKey = 'tafsir_list';
  static const String _surahTafsirCachePrefix = 'surah_tafsir_';

  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const int _cacheExpirationHours = 24;

  bool? _cachedConnectivityResult;
  DateTime? _lastConnectivityCheck;
  static const int _connectivityCacheSeconds = 10;

  TafsirCubit(this.tafsirRepository) : super(TafsirInitial());

  Future<bool> isOffline() async {
    if (_cachedConnectivityResult != null &&
        _lastConnectivityCheck != null &&
        DateTime.now().difference(_lastConnectivityCheck!).inSeconds <
            _connectivityCacheSeconds) {
      return _cachedConnectivityResult!;
    }

    final isConnected = await NetworkInfo.checkInternetConnectivity();

    _cachedConnectivityResult = !isConnected;
    _lastConnectivityCheck = DateTime.now();

    return !isConnected;
  }

  void invalidateConnectivityCache() {
    _cachedConnectivityResult = null;
    _lastConnectivityCheck = null;
  }

  bool get hasConnectivityCache {
    return _cachedConnectivityResult != null &&
        _lastConnectivityCheck != null &&
        DateTime.now().difference(_lastConnectivityCheck!).inSeconds <
            _connectivityCacheSeconds;
  }

  Future<void> fetchTafsirInfo() async {
    emit(TafsirLoading());
    try {
      final cachedData = _cacheHelper.getDataString(key: _tafsirListCacheKey);

      if (cachedData != null && !_isCacheExpired(_tafsirListCacheKey)) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedData);
        final tafsirReaders = edition.EditionModel.fromJson(decodedData);

        final isConnected = await NetworkInfo.checkInternetConnectivity();

        if (isConnected) {
          emit(TafsirLoaded(tafsirReaders));

          _updateTafsirCache();
        } else {
          emit(TafsirOffline(tafsirReaders));
        }
      } else {
        final isConnected = await NetworkInfo.checkInternetConnectivity();

        if (isConnected) {
          final tafsirReaders = await tafsirRepository.getTafsir();
          await _saveCacheWithTimestamp(
            _tafsirListCacheKey,
            jsonEncode(tafsirReaders.toJson()),
          );
          emit(TafsirLoaded(tafsirReaders));
        } else {
          if (cachedData != null) {
            final Map<String, dynamic> decodedData = jsonDecode(cachedData);
            final tafsirReaders = edition.EditionModel.fromJson(decodedData);
            emit(TafsirOffline(tafsirReaders));
          } else {
            emit(TafsirError(
                'No internet connection and no cached data available'));
          }
        }
      }
    } catch (e) {
      final cachedData = _cacheHelper.getDataString(key: _tafsirListCacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedData);
        final tafsirReaders = edition.EditionModel.fromJson(decodedData);
        emit(TafsirLoaded(tafsirReaders));
      } else {
        emit(TafsirError(e.toString()));
      }
    }
  }

  Future<void> _updateTafsirCache() async {
    try {
      final tafsirReaders = await tafsirRepository.getTafsir();
      await _saveCacheWithTimestamp(
        _tafsirListCacheKey,
        jsonEncode(tafsirReaders.toJson()),
      );
    } catch (e) {}
  }

  Future<void> fetchSurahTafsir(String identifier, int surahNumber) async {
    emit(SurahTafsirLoading());
    try {
      final cacheKey = '$_surahTafsirCachePrefix${identifier}_$surahNumber';
      final cachedData = _cacheHelper.getDataString(key: cacheKey);

      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        if (cachedData != null) {
          final Map<String, dynamic> decodedData = jsonDecode(cachedData);
          final surahTafsir = tafsir.TafsirModel.fromJson(decodedData);
          emit(SurahTafsirLoaded(surahTafsir));
        } else {
          emit(TafsirError(
              'No internet connection and no cached tafsir available'));
        }
        return;
      }

      final surahTafsir =
          await tafsirRepository.getSurahTafsir(identifier, surahNumber);
      emit(SurahTafsirLoaded(surahTafsir));
    } catch (e) {
      emit(TafsirError(e.toString()));
    }
  }

  Future<void> downloadSurahTafsir(String identifier, int surahNumber) async {
    emit(SurahTafsirDownloadInProgress(identifier, surahNumber));
    try {
      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        emit(TafsirError('Cannot download when offline'));
        return;
      }

      final surahTafsir =
          await tafsirRepository.getSurahTafsir(identifier, surahNumber);

      final cacheKey = '$_surahTafsirCachePrefix${identifier}_$surahNumber';
      await _cacheHelper.saveData(
        key: cacheKey,
        value: jsonEncode(surahTafsir.toJson()),
      );

      emit(TafsirDownloadCompleted());
    } catch (e) {
      emit(TafsirError('Failed to download tafsir: ${e.toString()}'));
    }
  }

  Future<bool> isSurahTafsirDownloaded(
      String identifier, int surahNumber) async {
    final cacheKey = '$_surahTafsirCachePrefix${identifier}_$surahNumber';
    return _cacheHelper.getDataString(key: cacheKey) != null;
  }

  Future<void> deleteSurahTafsir(String identifier, int surahNumber) async {
    try {
      final cacheKey = '$_surahTafsirCachePrefix${identifier}_$surahNumber';
      await _cacheHelper.removeData(key: cacheKey);
      emit(TafsirDownloadDeleted());
    } catch (e) {
      emit(TafsirError('Failed to delete tafsir: ${e.toString()}'));
    }
  }

  Future<void> downloadFullQuranTafsir(String identifier) async {
    emit(FullQuranTafsirDownloadInProgress(identifier));
    try {
      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        emit(TafsirError('Cannot download when offline'));
        return;
      }

      final fullQuranTafsir =
          await tafsirRepository.getFullQuranTafsir(identifier);

      final cacheKey = 'full_quran_tafsir_$identifier';
      await _cacheHelper.saveData(
        key: cacheKey,
        value: jsonEncode(fullQuranTafsir.toJson()),
      );

      emit(TafsirDownloadCompleted());
    } catch (e) {
      emit(
          TafsirError('Failed to download full Quran tafsir: ${e.toString()}'));
    }
  }

  Future<bool> isFullQuranTafsirDownloaded(String identifier) async {
    final cacheKey = 'full_quran_tafsir_$identifier';
    return _cacheHelper.getDataString(key: cacheKey) != null;
  }

  Future<void> deleteFullQuranTafsir(String identifier) async {
    try {
      final cacheKey = 'full_quran_tafsir_$identifier';
      await _cacheHelper.removeData(key: cacheKey);
      emit(TafsirDownloadDeleted());
    } catch (e) {
      emit(TafsirError('Failed to delete full Quran tafsir: ${e.toString()}'));
    }
  }

  Future<void> clearTafsirCache() async {
    try {
      await _cacheHelper.removeData(key: _tafsirListCacheKey);

      emit(TafsirCacheCleared());
    } catch (e) {
      emit(TafsirError('Failed to clear cache: ${e.toString()}'));
    }
  }

  bool get hasTafsirCache {
    return _cacheHelper.getDataString(key: _tafsirListCacheKey) != null;
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

  Future<tafsir.TafsirModel?> getCachedSurahTafsir(
      String identifier, int surahNumber) async {
    final surahCacheKey = '$_surahTafsirCachePrefix${identifier}_$surahNumber';
    final cachedSurahData = _cacheHelper.getDataString(key: surahCacheKey);

    if (cachedSurahData != null) {
      final Map<String, dynamic> decodedData = jsonDecode(cachedSurahData);
      return tafsir.TafsirModel.fromJson(decodedData);
    }

    final fullQuranCacheKey = 'full_quran_tafsir_$identifier';
    final cachedFullQuranData =
        _cacheHelper.getDataString(key: fullQuranCacheKey);

    if (cachedFullQuranData != null) {
      try {
        final Map<String, dynamic> decodedData =
            jsonDecode(cachedFullQuranData);
        final fullQuranTafsir = tafsir.TafsirModel.fromJson(decodedData);

        final targetSurah = fullQuranTafsir.data?.surahs?.firstWhere(
          (surah) => surah.number == surahNumber,
          orElse: () => throw Exception('Surah not found'),
        );

        if (targetSurah != null) {
          final extractedTafsir = tafsir.TafsirModel(
            code: fullQuranTafsir.code,
            status: fullQuranTafsir.status,
            data: tafsir.Data(
              surahs: [targetSurah],
              edition: fullQuranTafsir.data?.edition,
            ),
          );
          return extractedTafsir;
        }
      } catch (e) {}
    }

    return null;
  }

  Future<void> fetchSurahTafsirWithCacheCheck(
      String identifier, int surahNumber) async {
    final cachedTafsir = await getCachedSurahTafsir(identifier, surahNumber);

    if (cachedTafsir != null) {
      emit(SurahTafsirLoaded(cachedTafsir));
      return;
    }

    await fetchSurahTafsir(identifier, surahNumber);
  }
}
