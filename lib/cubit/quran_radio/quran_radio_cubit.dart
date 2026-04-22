import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/data/repository/radio_repository.dart';
import 'package:meta/meta.dart';

part 'quran_radio_state.dart';

class QuranRadioCubit extends Cubit<QuranRadioState> {
  final RadioRepository radioRepository;
  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  static const String _radioCachePrefix = 'quran_radio_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const int _cacheExpirationHours = 24;

  static const Map<String, String> _appToApiLangMap = {
    'en': 'eng',
    'ar': 'ar',
    'tr': 'tr',
    'fr': 'fr',
    'es': 'es',
    'de': 'de',
    'ru': 'ru',
    'ur': 'ur',
    'ms': 'eng',
    'bn': 'bn',
  };

  static String mapLanguage(String appLangCode) {
    return _appToApiLangMap[appLangCode] ?? 'eng';
  }

  QuranRadioCubit(this.radioRepository) : super(QuranRadioInitial());

  Future<void> fetchRadios(String appLangCode) async {
    emit(QuranRadioLoading());
    final apiLang = mapLanguage(appLangCode);
    final cacheKey = '$_radioCachePrefix$apiLang';

    try {
      final cachedData = _cacheHelper.getDataString(key: cacheKey);

      if (cachedData != null && !_isCacheExpired(cacheKey)) {
        final Map<String, dynamic> jsonData = jsonDecode(cachedData);
        final radioModel = RadioStationModel.fromJson(jsonData);

        emit(QuranRadioLoaded(radios: radioModel.radios ?? []));

        if (await NetworkInfo.checkInternetConnectivity()) {
          _updateCache(apiLang);
        }
      } else {
        if (await NetworkInfo.checkInternetConnectivity()) {
          final radioModel = await radioRepository.getRadios(apiLang);

          await _saveCacheWithTimestamp(
            cacheKey,
            jsonEncode(radioModel.toJson()),
          );

          emit(QuranRadioLoaded(radios: radioModel.radios ?? []));
        } else {
          if (cachedData != null) {
            final Map<String, dynamic> jsonData = jsonDecode(cachedData);
            final radioModel = RadioStationModel.fromJson(jsonData);
            emit(QuranRadioLoaded(radios: radioModel.radios ?? []));
          } else {
            emit(QuranRadioError('No internet connection'));
          }
        }
      }
    } catch (e) {
      emit(QuranRadioError(e.toString()));
    }
  }

  Future<void> _updateCache(String apiLang) async {
    try {
      final radioModel = await radioRepository.getRadios(apiLang);
      final cacheKey = '$_radioCachePrefix$apiLang';
      await _saveCacheWithTimestamp(
        cacheKey,
        jsonEncode(radioModel.toJson()),
      );
    } catch (e) {
      // Silent update failure
    }
  }

  void setCurrentlyPlaying(RadioStation? station) {
    if (state is QuranRadioLoaded) {
      final currentState = state as QuranRadioLoaded;
      if (station == null) {
        emit(currentState.copyWith(clearPlaying: true));
      } else {
        emit(currentState.copyWith(currentlyPlaying: station));
      }
    }
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
}
