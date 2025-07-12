import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:meta/meta.dart';

part 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit() : super(QuranInitial());

  List<QuranModel> surahs = [];

  Future<void> loadQuran() async {
    emit(QuranLoading());
    try {
      final String response =
          await rootBundle.loadString('assets/json/quran_data.json');
      final List data = json.decode(response);
      surahs = data.map((json) => QuranModel.fromJson(json)).toList();
      emit(QuranLoaded(surahs));
    } catch (e) {
      emit(QuranError("Failed to load Quran data: $e"));
    }
  }
}
