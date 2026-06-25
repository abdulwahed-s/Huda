import 'package:bloc/bloc.dart';
import 'package:huda/core/quran/surah_builder.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:meta/meta.dart';

part 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit() : super(QuranInitial());

  List<QuranModel> surahs = [];

  Future<void> loadQuran() async {
    emit(QuranLoading());
    try {
      surahs = SurahBuilder.buildQuranIndex();
      emit(QuranLoaded(surahs));
    } catch (e) {
      emit(QuranError("Failed to load Quran data: $e"));
    }
  }
}
