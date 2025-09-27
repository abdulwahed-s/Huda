import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:huda/data/models/surah_model.dart';
import 'dart:convert';

import 'package:meta/meta.dart';

part 'surah_state.dart';

class SurahCubit extends Cubit<SurahState> {
  static List<dynamic>? _cachedSurahData;

  SurahCubit() : super(SurahInitial());

  Future<void> loadSurah(int surahNumber) async {
    // If we already have the specific surah data cached, emit it immediately
    if (_cachedSurahData != null) {
      try {
        final surahJson =
            _cachedSurahData!.firstWhere((s) => s['number'] == surahNumber);
        final surah = SurahModel.fromJson(surahJson);
        emit(SurahLoaded(surah));
        return;
      } catch (e) {
        // If surah not found in cache, proceed with loading
      }
    }

    // Only emit loading if we don't have cached data
    emit(SurahLoading());
    try {
      // Load and cache the data if not already cached
      if (_cachedSurahData == null) {
        final String response =
            await rootBundle.loadString('assets/json/surah_data_new.json');
        _cachedSurahData = json.decode(response);
      }

      final surahJson =
          _cachedSurahData!.firstWhere((s) => s['number'] == surahNumber);
      final surah = SurahModel.fromJson(surahJson);
      emit(SurahLoaded(surah));
    } catch (e) {
      emit(SurahError("Failed to load surah: $e"));
    }
  }

  // Method to preload all surah data
  static Future<void> preloadSurahData() async {
    if (_cachedSurahData == null) {
      try {
        final String response =
            await rootBundle.loadString('assets/json/surah_data_new.json');
        _cachedSurahData = json.decode(response);
      } catch (e) {
        //  Add error handling here if needed
      }
    }
  }

  // Method to check if data is preloaded
  static bool get isDataPreloaded => _cachedSurahData != null;
}
