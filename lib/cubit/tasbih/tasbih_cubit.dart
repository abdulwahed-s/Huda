import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:vibration/vibration.dart';

part 'tasbih_state.dart';

class TasbihNote {
  final String text;
  final int count;

  const TasbihNote({required this.text, this.count = 0});

  TasbihNote copyWith({String? text, int? count}) {
    return TasbihNote(
      text: text ?? this.text,
      count: count ?? this.count,
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'count': count};

  factory TasbihNote.fromJson(Map<String, dynamic> json) {
    return TasbihNote(
      text: json['text'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TasbihCubit extends Cubit<TasbihState> {
  TasbihCubit() : super(TasbihInitial());

  final CacheHelper cacheHelper = getIt<CacheHelper>();

  List<TasbihNote> _notes = [];
  int _selectedNoteIndex = 0;
  bool _mode = true;

  void increment() {
    if (_notes.isEmpty) return;

    final index = _selectedIndexClamped();
    final note = _notes[index];
    _notes[index] = note.copyWith(count: note.count + 1);

    if ((note.count + 1) % 5 == 0) {
      saveTasbih();
    }

    if (_mode) {
      Future.microtask(() async {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 50);
        }
      });
    }

    _emitLoaded();
  }

  void decrement() {
    if (_notes.isEmpty) return;

    final index = _selectedIndexClamped();
    final note = _notes[index];
    if (note.count <= 0) return;

    _notes[index] = note.copyWith(count: note.count - 1);
    saveTasbih();
    _emitLoaded();
  }

  @override
  Future<void> close() {
    saveTasbih();
    return super.close();
  }

  void reset() {
    if (_notes.isEmpty) return;

    final index = _selectedIndexClamped();
    _notes[index] = _notes[index].copyWith(count: 0);
    saveTasbih();
    _emitLoaded();
  }

  void changeMode(bool newMode) {
    _mode = newMode;
    saveTasbih();
    _emitLoaded();
  }

  void selectNote(int index) {
    if (_notes.isEmpty) return;
    _selectedNoteIndex = index.clamp(0, _notes.length - 1);
    saveTasbih();
    _emitLoaded();
  }

  void addNote(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _notes = [..._notes, TasbihNote(text: trimmed)];
    _selectedNoteIndex = _notes.length - 1;
    saveTasbih();
    _emitLoaded();
  }

  void removeNote(int index) {
    if (index < 0 || index >= _notes.length) return;

    _notes = List<TasbihNote>.from(_notes)..removeAt(index);
    if (_notes.isEmpty) {
      _selectedNoteIndex = 0;
    } else if (_selectedNoteIndex >= _notes.length) {
      _selectedNoteIndex = _notes.length - 1;
    } else if (index < _selectedNoteIndex) {
      _selectedNoteIndex -= 1;
    }
    saveTasbih();
    _emitLoaded();
  }

  void loadTasbih() {
    emit(TasbihLoading());
    try {
      _mode = cacheHelper.getData(key: 'tasbih_mode') ?? true;

      final notesJson = cacheHelper.getDataString(key: 'tasbih_notes');
      if (notesJson != null && notesJson.isNotEmpty) {
        final decoded = jsonDecode(notesJson) as List<dynamic>;
        _notes = decoded
            .map(
                (e) => TasbihNote.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((n) => n.text.isNotEmpty)
            .toList();
        _selectedNoteIndex =
            cacheHelper.getData(key: 'tasbih_selected_index') ?? 0;
      } else {
        _notes = _migrateLegacyNotes();
        if (_notes.isEmpty) {
          _notes = _defaultNotes();
        }
        _selectedNoteIndex = 0;
        saveTasbih();
      }

      if (_notes.isNotEmpty) {
        _selectedNoteIndex = _selectedNoteIndex.clamp(0, _notes.length - 1);
      } else {
        _selectedNoteIndex = 0;
      }

      _emitLoaded();
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  void saveTasbih() {
    cacheHelper.saveData(key: 'tasbih_mode', value: _mode);
    cacheHelper.saveData(
      key: 'tasbih_notes',
      value: jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
    cacheHelper.saveData(
        key: 'tasbih_selected_index', value: _selectedNoteIndex);
  }

  List<TasbihNote> _defaultNotes() => [
        const TasbihNote(text: 'سُبْحَانَ اللّٰه'),
        const TasbihNote(text: 'الْحَمْدُ لِلّٰه'),
        const TasbihNote(text: 'اللّٰهُ أَكْبَر'),
        const TasbihNote(text: 'لَا إِلٰهَ إِلَّا اللّٰه'),
        const TasbihNote(text: 'أَسْتَغْفِرُ اللّٰه'),
        const TasbihNote(text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰه'),
        const TasbihNote(text: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ'),
        const TasbihNote(text: 'اللّٰهُمَّ صَلِّ عَلَى مُحَمَّد'),
      ];

  List<TasbihNote> _migrateLegacyNotes() {
    final legacyCount = cacheHelper.getData(key: 'tasbih_count') as int? ?? 0;
    final legacyNote = cacheHelper.getData(key: 'tasbih_note') as String?;

    if (legacyNote != null && legacyNote.trim().isNotEmpty) {
      return [TasbihNote(text: legacyNote.trim(), count: legacyCount)];
    }
    if (legacyCount > 0) {
      return [TasbihNote(text: '', count: legacyCount)];
    }
    return [];
  }

  int _selectedIndexClamped() =>
      _notes.isEmpty ? 0 : _selectedNoteIndex.clamp(0, _notes.length - 1);

  void _emitLoaded() {
    emit(
      TasbihLoaded(
        notes: List.unmodifiable(_notes),
        selectedNoteIndex: _selectedIndexClamped(),
        mode: _mode,
      ),
    );
  }
}
