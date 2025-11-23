import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/download_service.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/prayer_countdown_service.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:upgrader/upgrader.dart';
import 'package:huda/core/services/speech_service.dart';

final getIt = GetIt.instance;
void setupServiceLocator() {
  getIt.registerSingleton<CacheHelper>(CacheHelper());
  getIt.registerSingleton<Dio>(Dio());
  getIt.registerSingleton<DownloadService>(DownloadService());
  getIt.registerSingleton<ReadingPositionService>(ReadingPositionService());
  getIt.registerSingleton<BookmarkService>(
      BookmarkService(cacheHelper: getIt<CacheHelper>()));
  getIt.registerSingleton<PrayerCountdownService>(PrayerCountdownService());
  getIt.registerSingleton<PersistentPrayerCountdownService>(
      PersistentPrayerCountdownService());
  getIt.registerSingleton<Upgrader>(Upgrader(
    languageCode: PlatformDispatcher.instance.locale.languageCode,
    durationUntilAlertAgain: const Duration(hours: 12),
  ));

  // Register SpeechService
  getIt.registerSingleton<SpeechService>(SpeechService());
}
