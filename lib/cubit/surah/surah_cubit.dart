import 'package:bloc/bloc.dart';
import 'package:huda/core/quran/surah_builder.dart';
import 'package:huda/data/models/surah_model.dart';

import 'package:meta/meta.dart';

part 'surah_state.dart';

class SurahCubit extends Cubit<SurahState> {
  SurahCubit() : super(SurahInitial());

  Future<void> loadSurah(int surahNumber) async {
    emit(SurahLoading());
    try {
      final surah = SurahBuilder.buildSurahModel(surahNumber);
      emit(SurahLoaded(surah));
    } catch (e) {
      emit(SurahError("Failed to load surah: $e"));
    }
  }

  static Future<void> preloadSurahData() async {
    SurahBuilder.buildAllSurahAyahs();
  }

  static bool get isDataPreloaded => SurahBuilder.isDataPreloaded;
}
