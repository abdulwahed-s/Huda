import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/data/repository/radio_repository.dart';
import 'package:meta/meta.dart';

part 'quran_radio_state.dart';

class QuranRadioCubit extends Cubit<QuranRadioState> {
  final RadioRepository radioRepository;
  final CacheHelper _cacheHelper = getIt<CacheHelper>();
  final AudioPlayer _audioPlayer = getIt<AudioPlayer>();
  final AudioCoordinator _coordinator = getIt<AudioCoordinator>();

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

  QuranRadioCubit(this.radioRepository) : super(QuranRadioInitial()) {
    _coordinator.register(AudioCoordinator.quranRadio, () {
      if (state is QuranRadioLoaded) {
        emit((state as QuranRadioLoaded).copyWith(
          clearPlaying: true,
          isPlaying: false,
          isBuffering: false,
        ));
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (!_coordinator.isOwner(AudioCoordinator.quranRadio)) return;
      if (state is QuranRadioLoaded) {
        final current = state as QuranRadioLoaded;
        final isBuffering =
            playerState.processingState == ProcessingState.buffering ||
                playerState.processingState == ProcessingState.loading;
        emit(current.copyWith(
          isPlaying: playerState.playing,
          isBuffering: isBuffering,
        ));
      }
    });
  }

  Future<void> fetchRadios(String appLangCode) async {
    final previousStation =
        state is QuranRadioLoaded ? (state as QuranRadioLoaded).currentlyPlaying : null;
    final wasPlaying =
        state is QuranRadioLoaded ? (state as QuranRadioLoaded).isPlaying : false;
    final wasBuffering =
        state is QuranRadioLoaded ? (state as QuranRadioLoaded).isBuffering : false;

    emit(QuranRadioLoading());
    final apiLang = mapLanguage(appLangCode);
    final cacheKey = '$_radioCachePrefix$apiLang';

    try {
      final cachedData = _cacheHelper.getDataString(key: cacheKey);

      if (cachedData != null && !_isCacheExpired(cacheKey)) {
        final Map<String, dynamic> jsonData = jsonDecode(cachedData);
        final radioModel = RadioStationModel.fromJson(jsonData);

        emit(QuranRadioLoaded(
          radios: radioModel.radios ?? [],
          currentlyPlaying: previousStation,
          isPlaying: wasPlaying,
          isBuffering: wasBuffering,
        ));

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

          emit(QuranRadioLoaded(
            radios: radioModel.radios ?? [],
            currentlyPlaying: previousStation,
            isPlaying: wasPlaying,
            isBuffering: wasBuffering,
          ));
        } else {
          if (cachedData != null) {
            final Map<String, dynamic> jsonData = jsonDecode(cachedData);
            final radioModel = RadioStationModel.fromJson(jsonData);
            emit(QuranRadioLoaded(
              radios: radioModel.radios ?? [],
              currentlyPlaying: previousStation,
              isPlaying: wasPlaying,
              isBuffering: wasBuffering,
            ));
          } else {
            emit(QuranRadioError('No internet connection'));
          }
        }
      }
    } catch (e) {
      emit(QuranRadioError(e.toString()));
    }
  }

  Future<void> playStation(RadioStation station) async {
    if (state is! QuranRadioLoaded) return;
    final current = state as QuranRadioLoaded;

    if (_coordinator.isOwner(AudioCoordinator.quranRadio) &&
        current.currentlyPlaying?.id == station.id) {
      if (current.isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    _coordinator.requestAudio(AudioCoordinator.quranRadio);

    emit(current.copyWith(
      currentlyPlaying: station,
      isBuffering: true,
      isPlaying: false,
    ));

    final audioSource = AudioSource.uri(
      Uri.parse(station.url.toString()),
      tag: MediaItem(
        id: station.id.toString(),
        title: station.name.toString(),
        artUri: Uri.parse(
            'https://images.pexels.com/photos/318451/pexels-photo-318451.jpeg?auto=compress&cs=tinysrgb&w=600'),
      ),
    );

    await _audioPlayer.setAudioSource(audioSource);
    await _audioPlayer.play();
  }

  Future<void> stopStation() async {
    await _audioPlayer.stop();
    _coordinator.release(AudioCoordinator.quranRadio);
    if (state is QuranRadioLoaded) {
      emit((state as QuranRadioLoaded).copyWith(
        clearPlaying: true,
        isPlaying: false,
        isBuffering: false,
      ));
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

  @override
  Future<void> close() {
    _coordinator.unregister(AudioCoordinator.quranRadio);
    return super.close();
  }
}
