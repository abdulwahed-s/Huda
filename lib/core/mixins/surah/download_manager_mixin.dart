import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/surah_model.dart';

mixin DownloadManagerMixin<T extends StatefulWidget> on State<T> {
  bool isDownloadingSingleAyah = false;
  bool isDownloadingAllAyahs = false;
  String downloadProgressText = '';

  bool isDownloadingSurahTafsir = false;
  bool isDownloadingAllTafsir = false;

  bool isDownloadingSurahTranslation = false;
  bool isDownloadingAllTranslation = false;

  SurahModel get surah;
  int get surahNumber;
  String? get selectedReaderId;
  audio.SurahAudioModel? get currentSurahAudio;
  String? get selectedTafsirId;
  String? get selectedTranslationId;
  TafsirCubit get tafsirCubit;
  TranslationCubit get translationCubit;
  List<edition.Data> get availableReaders;

  void safeModalSetState();

  Future<void> downloadSingleAyah(
      int index, Ayahs ayah, StateSetter setModalState) async {
    if (selectedReaderId == null || currentSurahAudio == null) return;

    setState(() => isDownloadingSingleAyah = true);
    setModalState(() {});

    try {
      final targetSurah = currentSurahAudio!.data!.surahs!.firstWhere(
        (surah) => surah.number == this.surah.number,
        orElse: () => currentSurahAudio!.data!.surahs!.first,
      );

      final targetAyah = targetSurah.ayahs?.firstWhere(
        (audioAyah) => audioAyah.numberInSurah == ayah.numberInSurah,
        orElse: () => targetSurah.ayahs!.first,
      );

      if (targetAyah?.audio != null) {
        await context.read<AudioCubit>().downloadAyahAudio(
              ayahAudioUrl: targetAyah!.audio!,
              surahNumber: surah.number.toString(),
              ayahNumber: ayah.numberInSurah.toString(),
              readerId: selectedReaderId!,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading ayah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isDownloadingSingleAyah = false);
    setModalState(() {});
  }

  Future<void> downloadAllSurahAyahs(StateSetter setModalState) async {
    if (selectedReaderId == null || currentSurahAudio == null) return;

    setState(() => isDownloadingAllAyahs = true);
    setModalState(() {});

    try {
      await context.read<AudioCubit>().downloadAllSurahAyahs(
            surahAudioModel: currentSurahAudio!,
            surahNumber: surah.number.toString(),
            readerId: selectedReaderId!,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading surah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isDownloadingAllAyahs = false);
    setModalState(() {});
  }

  Future<void> downloadSurahTafsir() async {
    if (selectedTafsirId == null) return;
    setState(() {
      isDownloadingSurahTafsir = true;
    });
    safeModalSetState();
    await tafsirCubit.downloadSurahTafsir(selectedTafsirId!, surahNumber);
  }

  Future<void> downloadFullQuranTafsir() async {
    if (selectedTafsirId == null) return;
    setState(() {
      isDownloadingAllTafsir = true;
    });
    safeModalSetState();
    await tafsirCubit.downloadFullQuranTafsir(selectedTafsirId!);
  }

  Future<void> downloadSurahTranslation() async {
    if (selectedTranslationId == null) return;
    setState(() {
      isDownloadingSurahTranslation = true;
    });
    safeModalSetState();
    await translationCubit.downloadSurahTranslation(
        selectedTranslationId!, surahNumber);
  }

  Future<void> downloadFullQuranTranslation() async {
    if (selectedTranslationId == null) return;
    setState(() {
      isDownloadingAllTranslation = true;
    });
    safeModalSetState();
    await translationCubit.downloadFullQuranTranslation(selectedTranslationId!);
  }

  Future<List<edition.Data>> getDownloadedReaders() async {
    final List<edition.Data> downloadedReaders = [];

    for (final reader in availableReaders) {
      bool hasAnyDownloadedAyah = false;

      for (int i = 1; i <= min(surah.ayahs?.length ?? 0, 3); i++) {
        final isDownloaded = await context.read<AudioCubit>().isAyahDownloaded(
              surahNumber: surah.number.toString(),
              ayahNumber: i.toString(),
              readerId: reader.identifier!,
            );
        if (isDownloaded) {
          hasAnyDownloadedAyah = true;
          break;
        }
      }

      if (hasAnyDownloadedAyah) {
        downloadedReaders.add(reader);
      }
    }

    return downloadedReaders;
  }
}
