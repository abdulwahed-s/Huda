import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/cache/quran_content_store.dart';
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
  final QuranContentStore _contentStore = getIt<QuranContentStore>();

  List<edition.Data> _lastKnownSources = [];
  List<edition.Data> get lastKnownSources => _lastKnownSources;

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
          _lastKnownSources = tafsirReaders.data ?? [];
          emit(TafsirLoaded(tafsirReaders));

          _updateTafsirCache();
        } else {
          _lastKnownSources = tafsirReaders.data ?? [];
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
          _lastKnownSources = tafsirReaders.data ?? [];
          emit(TafsirLoaded(tafsirReaders));
        } else {
          if (cachedData != null) {
            final Map<String, dynamic> decodedData = jsonDecode(cachedData);
            final tafsirReaders = edition.EditionModel.fromJson(decodedData);
            _lastKnownSources = tafsirReaders.data ?? [];
            emit(TafsirOffline(tafsirReaders));
          } else {
            emit(TafsirOfflineNoContent());
          }
        }
      }
    } catch (e) {
      final cachedData = _cacheHelper.getDataString(key: _tafsirListCacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedData);
        final tafsirReaders = edition.EditionModel.fromJson(decodedData);
        _lastKnownSources = tafsirReaders.data ?? [];
        emit(TafsirLoaded(tafsirReaders));
      } else if (await isOffline()) {
        emit(TafsirOfflineNoContent());
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
    } catch (e) {
      // print the error if needed
    }
  }

  Future<void> fetchSurahTafsir(String identifier, int surahNumber) async {
    emit(SurahTafsirLoading());
    try {
      final cachedContent = await getCachedSurahTafsir(identifier, surahNumber);
      if (cachedContent != null) {
        emit(SurahTafsirLoaded(cachedContent));
        return;
      }

      final isConnected = await NetworkInfo.checkInternetConnectivity();

      if (!isConnected) {
        emit(
          TafsirError('No internet connection and no cached tafsir available'),
        );
        return;
      }

      final surahTafsir = await tafsirRepository.getSurahTafsir(
        identifier,
        surahNumber,
      );
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

      final surahTafsir = await tafsirRepository.getSurahTafsir(
        identifier,
        surahNumber,
      );

      await _contentStore.saveSurah(
        QuranContentKind.tafsir,
        identifier,
        surahNumber,
        surahTafsir.toJson(),
      );

      emit(TafsirDownloadCompleted());
    } catch (e) {
      emit(TafsirError('Failed to download tafsir: ${e.toString()}'));
    }
  }

  Future<bool> isSurahTafsirDownloaded(
    String identifier,
    int surahNumber,
  ) async {
    return _contentStore.hasSurah(
      QuranContentKind.tafsir,
      identifier,
      surahNumber,
    );
  }

  Future<void> deleteSurahTafsir(String identifier, int surahNumber) async {
    try {
      await _contentStore.deleteSurah(
        QuranContentKind.tafsir,
        identifier,
        surahNumber,
      );
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

      final fullQuranTafsir = await tafsirRepository.getFullQuranTafsir(
        identifier,
      );

      await _contentStore.saveFullEdition(
        QuranContentKind.tafsir,
        identifier,
        fullQuranTafsir.toJson(),
      );

      emit(TafsirDownloadCompleted());
    } catch (e) {
      emit(
        TafsirError('Failed to download full Quran tafsir: ${e.toString()}'),
      );
    }
  }

  Future<bool> isFullQuranTafsirDownloaded(String identifier) async {
    return _contentStore.hasFullEdition(QuranContentKind.tafsir, identifier);
  }

  Future<void> deleteFullQuranTafsir(String identifier) async {
    try {
      await _contentStore.deleteFullEdition(
        QuranContentKind.tafsir,
        identifier,
      );

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
    String identifier,
    int surahNumber,
  ) async {
    final content = await _contentStore.readSurah(
      QuranContentKind.tafsir,
      identifier,
      surahNumber,
    );
    return content == null
        ? null
        : tafsir.TafsirModel.fromJson(content.response);
  }

  Future<void> fetchSurahTafsirWithCacheCheck(
    String identifier,
    int surahNumber,
  ) async {
    final cachedTafsir = await getCachedSurahTafsir(identifier, surahNumber);

    if (cachedTafsir != null) {
      emit(SurahTafsirLoaded(cachedTafsir));
      return;
    }

    await fetchSurahTafsir(identifier, surahNumber);
  }
}
