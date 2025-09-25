import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/edition_model.dart' as edition;

mixin OfflineCacheManagerMixin<T extends StatefulWidget> on State<T> {
  bool isOfflineMode = false;

  List<edition.Data> cachedDownloadedReaders = [];
  List<edition.Data> cachedDownloadedTafsirSources = [];
  List<edition.Data> cachedDownloadedTranslationSources = [];
  bool offlineCacheLoaded = false;
  bool isCacheLoading = false;

  List<edition.Data> get availableTafsirSources;
  List<edition.Data> get availableTranslationSources;
  int get surahNumber;
  TafsirCubit get tafsirCubit;
  TranslationCubit get translationCubit;

  void safeModalSetState();

  Future<List<edition.Data>> getDownloadedReaders();

  Future<void> checkOfflineStatus() async {
    try {
      final audioCubit = context.read<AudioCubit>();
      final currentState = audioCubit.state;

      setState(() {
        isOfflineMode = currentState is AudioOfflineWithDownloads ||
            currentState is ReaderOffline;
      });

      if (isOfflineMode && !offlineCacheLoaded) {
        await preloadOfflineCache();
      }
    } catch (e) {
      setState(() {
        isOfflineMode = true;
      });

      if (!offlineCacheLoaded) {
        await preloadOfflineCache();
      }
    }
  }

  Future<void> preloadOfflineCache() async {
    if (isCacheLoading) return;

    setState(() {
      isCacheLoading = true;
    });

    safeModalSetState();

    try {
      final results = await Future.wait([
        getDownloadedReaders(),
        getDownloadedTafsirSources(),
        getDownloadedTranslationSources(),
      ]);

      setState(() {
        cachedDownloadedReaders = results[0];
        cachedDownloadedTafsirSources = results[1];
        cachedDownloadedTranslationSources = results[2];
        offlineCacheLoaded = true;
        isCacheLoading = false;
      });

      safeModalSetState();
    } catch (e) {
      setState(() {
        cachedDownloadedReaders = [];
        cachedDownloadedTafsirSources = [];
        cachedDownloadedTranslationSources = [];
        offlineCacheLoaded = true;
        isCacheLoading = false;
      });

      safeModalSetState();
    }
  }

  Future<List<edition.Data>> getDownloadedTafsirSources() async {
    final List<edition.Data> downloadedSources = [];

    for (final source in availableTafsirSources) {
      final hasSurahDownloaded = await tafsirCubit.isSurahTafsirDownloaded(
        source.identifier!,
        surahNumber,
      );
      final hasFullQuranDownloaded =
          await tafsirCubit.isFullQuranTafsirDownloaded(
        source.identifier!,
      );

      if (hasSurahDownloaded || hasFullQuranDownloaded) {
        downloadedSources.add(source);
      }
    }

    return downloadedSources;
  }

  Future<List<edition.Data>> getDownloadedTranslationSources() async {
    final List<edition.Data> downloadedSources = [];

    for (final source in availableTranslationSources) {
      final hasSurahDownloaded =
          await translationCubit.isSurahTranslationDownloaded(
        source.identifier!,
        surahNumber,
      );
      final hasFullQuranDownloaded =
          await translationCubit.isFullQuranTranslationDownloaded(
        source.identifier!,
      );

      if (hasSurahDownloaded || hasFullQuranDownloaded) {
        downloadedSources.add(source);
      }
    }

    return downloadedSources;
  }

  Future<bool> isCurrentAyahPlayable(int ayahIndex) async {
    if (!isOfflineMode) return true;

    return false;
  }
}
