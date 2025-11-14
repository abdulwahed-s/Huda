import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as translation;
import 'package:huda/data/repository/translation_repository.dart';
import 'package:meta/meta.dart';

part 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {
  final TranslationRepository translationRepository;
  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  static const String _translationListCacheKey = 'translation_list';
  static const String _surahTranslationCachePrefix = 'surah_translation_';

  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const int _cacheExpirationHours = 24;

  bool? _cachedConnectivityResult;
  DateTime? _lastConnectivityCheck;
  static const int _connectivityCacheSeconds = 10;

  TranslationCubit(this.translationRepository) : super(TranslationInitial());

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

  Future<void> fetchTranslationInfo() async {
    emit(TranslationLoading());
    try {
      final cachedData =
          _cacheHelper.getDataString(key: _translationListCacheKey);

      if (cachedData != null && !_isCacheExpired(_translationListCacheKey)) {
        final translationReaders =
            edition.EditionModel.fromJson(jsonDecode(cachedData));

        if (await isOffline()) {
          emit(TranslationOffline(translationReaders));
        } else {
          emit(TranslationLoaded(translationReaders));

          _updateTranslationCache();
        }
      } else {
        final translationReaders = await translationRepository.getTranslation();
        await _saveCacheWithTimestamp(
            _translationListCacheKey, jsonEncode(translationReaders.toJson()));
        emit(TranslationLoaded(translationReaders));
      }
    } catch (e) {
      final cachedData =
          _cacheHelper.getDataString(key: _translationListCacheKey);
      if (cachedData != null) {
        final translationReaders =
            edition.EditionModel.fromJson(jsonDecode(cachedData));
        emit(TranslationOffline(translationReaders));
      } else {
        emit(TranslationError(
            "Failed to load translation sources: ${e.toString()}"));
      }
    }
  }

  Future<void> _updateTranslationCache() async {
    try {
      final translationReaders = await translationRepository.getTranslation();
      await _saveCacheWithTimestamp(
          _translationListCacheKey, jsonEncode(translationReaders.toJson()));
    } catch (e) {
      // print the error if needed
    }
  }

  Future<void> fetchSurahTranslation(String identifier, int surahNumber) async {
    emit(SurahTranslationLoading());
    try {
      final cacheKey =
          '$_surahTranslationCachePrefix${identifier}_$surahNumber';
      final cachedData = _cacheHelper.getDataString(key: cacheKey);

      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        if (cachedData != null) {
          final Map<String, dynamic> decodedData = jsonDecode(cachedData);
          final surahTranslation =
              translation.TafsirModel.fromJson(decodedData);
          emit(SurahTranslationLoaded(surahTranslation));
        } else {
          emit(TranslationError(
              'No internet connection and no cached translation available'));
        }
        return;
      }

      final surahTranslation = await translationRepository.getSurahTranslation(
          identifier, surahNumber);
      emit(SurahTranslationLoaded(surahTranslation));
    } catch (e) {
      emit(TranslationError(
          "Failed to load surah translation: ${e.toString()}"));
    }
  }

  Future<void> downloadSurahTranslation(
      String identifier, int surahNumber) async {
    emit(SurahTranslationDownloadInProgress(identifier, surahNumber));
    try {
      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        emit(TranslationError('Cannot download when offline'));
        return;
      }

      final surahTranslation = await translationRepository.getSurahTranslation(
          identifier, surahNumber);
      final cacheKey =
          '$_surahTranslationCachePrefix${identifier}_$surahNumber';
      await _saveCacheWithTimestamp(
          cacheKey, jsonEncode(surahTranslation.toJson()));
      emit(TranslationDownloadCompleted());
    } catch (e) {
      emit(TranslationError(
          "Failed to download surah translation: ${e.toString()}"));
    }
  }

  Future<bool> isSurahTranslationDownloaded(
      String identifier, int surahNumber) async {
    final cacheKey = '$_surahTranslationCachePrefix${identifier}_$surahNumber';
    return _cacheHelper.getDataString(key: cacheKey) != null;
  }

  Future<void> deleteSurahTranslation(
      String identifier, int surahNumber) async {
    try {
      final cacheKey =
          '$_surahTranslationCachePrefix${identifier}_$surahNumber';
      final timestampKey = '$_cacheTimestampPrefix$cacheKey';

      await _cacheHelper.removeData(key: cacheKey);
      await _cacheHelper.removeData(key: timestampKey);

      emit(TranslationDownloadDeleted());
    } catch (e) {
      emit(TranslationError(
          "Failed to delete surah translation: ${e.toString()}"));
    }
  }

  Future<void> downloadFullQuranTranslation(String identifier) async {
    emit(FullQuranTranslationDownloadInProgress(identifier));
    try {
      final fullQuranTranslation =
          await translationRepository.getFullQuranTranslation(identifier);
      final cacheKey = 'full_quran_translation_$identifier';
      await _saveCacheWithTimestamp(
          cacheKey, jsonEncode(fullQuranTranslation.toJson()));
      emit(TranslationDownloadCompleted());
    } catch (e) {
      emit(TranslationError(
          "Failed to download full Quran translation: ${e.toString()}"));
    }
  }

  Future<bool> isFullQuranTranslationDownloaded(String identifier) async {
    final cacheKey = 'full_quran_translation_$identifier';
    return _cacheHelper.getDataString(key: cacheKey) != null;
  }

  Future<void> deleteFullQuranTranslation(String identifier) async {
    try {
      final cacheKey = 'full_quran_translation_$identifier';
      final timestampKey = '$_cacheTimestampPrefix$cacheKey';

      await _cacheHelper.removeData(key: cacheKey);
      await _cacheHelper.removeData(key: timestampKey);

      emit(TranslationDownloadDeleted());
    } catch (e) {
      emit(TranslationError(
          "Failed to delete full Quran translation: ${e.toString()}"));
    }
  }

  Future<void> clearTranslationCache() async {
    try {
      final keysToRemove = <String>[];

      keysToRemove.add(_translationListCacheKey);
      keysToRemove.add('$_cacheTimestampPrefix$_translationListCacheKey');

      for (final key in keysToRemove) {
        await _cacheHelper.removeData(key: key);
      }

      emit(TranslationCacheCleared());
    } catch (e) {
      emit(TranslationError(
          "Failed to clear translation cache: ${e.toString()}"));
    }
  }

  bool get hasTranslationCache {
    return _cacheHelper.getDataString(key: _translationListCacheKey) != null;
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
        key: timestampKey, value: DateTime.now().millisecondsSinceEpoch);
  }

  Future<translation.TafsirModel?> getCachedSurahTranslation(
      String identifier, int surahNumber) async {
    final surahCacheKey =
        '$_surahTranslationCachePrefix${identifier}_$surahNumber';
    final cachedSurahData = _cacheHelper.getDataString(key: surahCacheKey);

    if (cachedSurahData != null) {
      return translation.TafsirModel.fromJson(jsonDecode(cachedSurahData));
    }

    final fullQuranCacheKey = 'full_quran_translation_$identifier';
    final cachedFullQuranData =
        _cacheHelper.getDataString(key: fullQuranCacheKey);

    if (cachedFullQuranData != null) {
      final fullQuranTranslation =
          translation.TafsirModel.fromJson(jsonDecode(cachedFullQuranData));

      if (fullQuranTranslation.data?.surahs != null) {
        final targetSurah = fullQuranTranslation.data!.surahs!
            .firstWhere((surah) => surah.number == surahNumber);

        final singleSurahTranslation = translation.TafsirModel(
          code: fullQuranTranslation.code,
          status: fullQuranTranslation.status,
          data: translation.Data(
            surahs: [targetSurah],
            edition: fullQuranTranslation.data!.edition,
          ),
        );

        return singleSurahTranslation;
      }
    }

    return null;
  }

  Future<void> fetchSurahTranslationWithCacheCheck(
      String identifier, int surahNumber) async {
    final cachedTranslation =
        await getCachedSurahTranslation(identifier, surahNumber);

    if (cachedTranslation != null) {
      emit(SurahTranslationLoaded(cachedTranslation));
      return;
    }

    await fetchSurahTranslation(identifier, surahNumber);
  }
}
