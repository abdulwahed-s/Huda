import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/surah_audio_model.dart' as audio;

mixin StateValidatorsMixin<T extends StatefulWidget> on State<T> {
  SurahModel get surah;
  int get surahNumber;
  String? get selectedReaderId;
  String? get selectedTafsirId;
  String? get selectedTranslationId;
  bool get isOfflineMode;
  audio.SurahAudioModel? get currentSurahAudio;
  TafsirCubit get tafsirCubit;
  TranslationCubit get translationCubit;

  Future<bool> isCurrentAyahPlayable(int ayahIndex) async {
    if (!isOfflineMode) return true;

    if (selectedReaderId == null || currentSurahAudio == null) return false;

    final ayah = surah.ayahs![ayahIndex];
    return await context.read<AudioCubit>().isAyahDownloaded(
          surahNumber: surah.number.toString(),
          ayahNumber: ayah.numberInSurah.toString(),
          readerId: selectedReaderId!,
        );
  }

  Future<bool> areAllAyahsDownloaded() async {
    if (selectedReaderId == null || surah.ayahs == null) return false;

    for (final ayah in surah.ayahs!) {
      final isDownloaded = await context.read<AudioCubit>().isAyahDownloaded(
            surahNumber: surah.number.toString(),
            ayahNumber: ayah.numberInSurah.toString(),
            readerId: selectedReaderId!,
          );
      if (!isDownloaded) return false;
    }
    return true;
  }

  Future<bool> isSingleAyahDownloaded(int ayahIndex) async {
    if (selectedReaderId == null || surah.ayahs == null) return false;
    final ayah = surah.ayahs![ayahIndex];

    return await context.read<AudioCubit>().isAyahDownloaded(
          surahNumber: surah.number.toString(),
          ayahNumber: ayah.numberInSurah.toString(),
          readerId: selectedReaderId!,
        );
  }

  Future<bool> isSurahTafsirDownloaded() async {
    if (selectedTafsirId == null) return false;
    return await tafsirCubit.isSurahTafsirDownloaded(
        selectedTafsirId!, surahNumber);
  }

  Future<bool> isAllTafsirDownloaded() async {
    if (selectedTafsirId == null) return false;
    return await tafsirCubit.isFullQuranTafsirDownloaded(selectedTafsirId!);
  }

  Future<bool> isSurahTranslationDownloaded() async {
    if (selectedTranslationId == null) return false;
    return await translationCubit.isSurahTranslationDownloaded(
        selectedTranslationId!, surahNumber);
  }

  Future<bool> isAllTranslationDownloaded() async {
    if (selectedTranslationId == null) return false;
    return await translationCubit
        .isFullQuranTranslationDownloaded(selectedTranslationId!);
  }

  bool hasAvailableContent() {
    return selectedReaderId != null ||
        selectedTafsirId != null ||
        selectedTranslationId != null;
  }

  bool canDownloadContent() {
    return !isOfflineMode && hasAvailableContent();
  }

  bool isReaderValid(String readerId) {
    return readerId.isNotEmpty;
  }

  bool isTafsirValid(String tafsirId) {
    return tafsirId.isNotEmpty;
  }

  bool isTranslationValid(String translationId) {
    return translationId.isNotEmpty;
  }

  bool hasValidSelections() {
    return (selectedReaderId?.isNotEmpty ?? false) ||
        (selectedTafsirId?.isNotEmpty ?? false) ||
        (selectedTranslationId?.isNotEmpty ?? false);
  }

  bool isSurahComplete() {
    return surah.ayahs != null && surah.ayahs!.isNotEmpty;
  }

  bool isValidAyahIndex(int index) {
    if (surah.ayahs == null) return false;
    return index >= 0 && index < surah.ayahs!.length;
  }
}
