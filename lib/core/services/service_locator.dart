import 'package:just_audio/just_audio.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/download_service.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';
import 'package:huda/data/services/audiobook_download_service.dart';
import 'package:huda/core/services/prayer_countdown_service.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/data/repository/miqaat_lock_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:huda/core/services/speech_service.dart';
import 'package:huda/core/services/surah_screen_settings_service.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/islamic_event_service.dart';
import 'package:huda/core/services/qcf_font_service.dart';

final getIt = GetIt.instance;
void setupServiceLocator() {
  getIt.registerSingleton<AudioPlayer>(AudioPlayer());
  getIt.registerSingleton<AudioCoordinator>(AudioCoordinator());
  getIt.registerSingleton<CacheHelper>(CacheHelper());
  getIt.registerSingleton<Dio>(Dio());
  getIt.registerSingleton<DownloadService>(DownloadService());
  getIt.registerSingleton<ReadingPositionService>(ReadingPositionService());
  getIt.registerSingleton<AudioProgressService>(AudioProgressService());
  getIt.registerSingleton<BookProgressService>(BookProgressService());
  getIt.registerSingleton<QuranAudioProgressService>(QuranAudioProgressService());
  getIt.registerSingleton<QuranRadioProgressService>(QuranRadioProgressService());
  getIt.registerSingleton<OfflineAudiobooksService>(OfflineAudiobooksService());
  getIt.registerSingleton<AudiobookDownloadService>(AudiobookDownloadService());
  getIt.registerSingleton<BookmarkService>(
      BookmarkService(cacheHelper: getIt<CacheHelper>()));
  getIt.registerSingleton<PrayerCountdownService>(PrayerCountdownService());
  getIt.registerSingleton<PersistentPrayerCountdownService>(
      PersistentPrayerCountdownService());

  getIt.registerSingleton<SpeechService>(SpeechService());

  getIt.registerSingleton<SurahScreenSettingsService>(
      SurahScreenSettingsService());

  getIt.registerSingleton<KhatmaService>(
      KhatmaService(cache: getIt<CacheHelper>()));

  getIt.registerSingleton<IslamicEventService>(
      IslamicEventService(cacheHelper: getIt<CacheHelper>()));

  getIt.registerLazySingleton<QcfFontService>(
      () => QcfFontService(
          cache: getIt<CacheHelper>(), packType: FontPackType.qcf4),
      instanceName: 'qcf4');

  getIt.registerLazySingleton<QcfFontService>(
      () => QcfFontService(
          cache: getIt<CacheHelper>(), packType: FontPackType.tajweed),
      instanceName: 'tajweed');

  getIt.registerSingletonAsync<MiqaatLockRepository>(
    () => MiqaatLockRepository.create(),
  );
  getIt.registerSingletonWithDependencies<MiqaatLockCubit>(
    () => MiqaatLockCubit(getIt<MiqaatLockRepository>())..loadSettings(),
    dependsOn: [MiqaatLockRepository],
  );
}
