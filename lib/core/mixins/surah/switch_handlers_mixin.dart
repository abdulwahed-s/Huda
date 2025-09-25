import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;

mixin SwitchHandlersMixin<T extends StatefulWidget> on State<T> {
  String? selectedLanguage;
  String? selectedTafsirId;
  String? selectedTranslationId;
  String? selectedTranslationLanguage;

  tafsir.TafsirModel? currentTafsir;
  bool isLoadingTafsir = false;
  tafsir.TafsirModel? currentTranslation;
  bool isLoadingTranslation = false;

  List<edition.Data> get availableTranslationSources;
  int get surahNumber;
  String? get selectedReaderId;
  TafsirCubit get tafsirCubit;
  TranslationCubit get translationCubit;

  void switchLanguage(String? newLanguage, StateSetter? setModalState) {
    setState(() {
      selectedLanguage = newLanguage;
      if (selectedReaderId != null && newLanguage != null) {
        final audioCubit = context.read<AudioCubit>();
        final filteredReaders = audioCubit.getReadersByLanguage(newLanguage);
        final isCurrentReaderValid = filteredReaders
            .any((reader) => reader.identifier == selectedReaderId);
        if (!isCurrentReaderValid) {
          onReaderInvalidated();
        }
      }
    });
    setModalState?.call(() {});
  }

  void switchTafsir(String tafsirId, StateSetter? setModalState) {
    setState(() {
      selectedTafsirId = tafsirId;
      isLoadingTafsir = true;
    });
    setModalState?.call(() {});
    tafsirCubit.fetchSurahTafsirWithCacheCheck(tafsirId, surahNumber);
  }

  void switchTranslation(String translationId, StateSetter? setModalState) {
    setState(() {
      selectedTranslationId = translationId;
      isLoadingTranslation = true;
    });
    setModalState?.call(() {});
    translationCubit.fetchSurahTranslationWithCacheCheck(
        translationId, surahNumber);
  }

  void switchTranslationLanguage(
      String? newLanguage, StateSetter? setModalState) {
    setState(() {
      selectedTranslationLanguage = newLanguage;
      if (selectedTranslationId != null && newLanguage != null) {
        final isCurrentTranslationValid = availableTranslationSources
            .where((source) => source.language == newLanguage)
            .any((source) => source.identifier == selectedTranslationId);
        if (!isCurrentTranslationValid) {
          selectedTranslationId = null;
          currentTranslation = null;
        }
      }
    });
    setModalState?.call(() {});
  }

  void onReaderInvalidated();
}
