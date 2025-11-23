import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/speech_service.dart';

part 'memorization_state.dart';

class MemorizationCubit extends Cubit<MemorizationState> {
  final SpeechService _speechService = getIt<SpeechService>();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _errorSubscription;

  final String _id =
      DateTime.now().millisecondsSinceEpoch.toString().substring(8);

  MemorizationCubit() : super(MemorizationInitial()) {
    _setupSpeechListeners();
  }

  void _setupSpeechListeners() {
    _statusSubscription = _speechService.statusStream.listen(_onStatus);
    _errorSubscription = _speechService.errorStream.listen(_onError);
  }

  List<String> _ayahTexts = [];
  int _surahNumber = 0;

  Future<void> toggleMemorizationMode(
      List<String> ayahTexts, int surahNumber) async {
    if (state is MemorizationModeUpdated &&
        (state as MemorizationModeUpdated).isMemorizationMode) {
      emit(const MemorizationModeUpdated(
        isMemorizationMode: false,
        hiddenAyahIndices: {},
      ));
      await stopListening();
    } else {
      _ayahTexts = ayahTexts;
      _surahNumber = surahNumber;

      final hiddenIndices =
          Set<int>.from(List.generate(ayahTexts.length, (i) => i));
      emit(MemorizationModeUpdated(
        isMemorizationMode: true,
        hiddenAyahIndices: hiddenIndices,
      ));

      await startListening();
    }
  }

  Future<void> startListening() async {
    if (isClosed) {
      return;
    }

    final isInitialized = await _speechService.initialize();
    if (!isInitialized) {
      debugPrint('❌ [$_id] Failed to initialize speech service');
      emit(const MemorizationError("Failed to initialize speech recognition"));
      return;
    }

    if (_speechService.isListening) {
      debugPrint('⚠️ [$_id] Service already listening, stopping first...');
      await _speechService.stop();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final currentState = state as MemorizationModeUpdated;

    if (!currentState.isListening) {
      emit(currentState.copyWith(
        isListening: true,
        isMatch: false,
      ));
    }

    try {
      await _speechService.listen(
        onResult: (result) {
          if (isClosed) return;

          if (result == null) return;
          final recognizedWords = result.recognizedWords;
          debugPrint('🗣️ STT Recognized: "$recognizedWords"');

          if (state is! MemorizationModeUpdated) return;
          final currentMemState = state as MemorizationModeUpdated;

          bool matchFound = false;
          int? matchedIndex;

          final sortedHiddenIndices = currentMemState.hiddenAyahIndices.toList()
            ..sort();

          for (final index in sortedHiddenIndices) {
            final expectedText = _getExpectedText(index);
            final isMatch = verifyRecitation(recognizedWords, expectedText);

            if (isMatch) {
              matchFound = true;
              matchedIndex = index;
              break;
            }
          }

          if (matchFound && matchedIndex != null) {
            debugPrint('🎉 Match found! Revealing ayah $matchedIndex');
            _handleMatch(matchedIndex);
          } else {
            emit(currentMemState.copyWith(
              recognizedText: recognizedWords,
              isMatch: false,
            ));
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting listening: $e');
      if (e.toString().contains('error_busy')) {
        _retryListening();
      }
    }
  }

  void _onError(dynamic val) {
    debugPrint('❌ [$_id] STT Error: $val');
  }

  void _retryListening() {
    if (isClosed) return;
    if (state is MemorizationModeUpdated &&
        (state as MemorizationModeUpdated).isMemorizationMode) {
      Future.delayed(const Duration(seconds: 1), () {
        if (isClosed) return;
        if (state is MemorizationModeUpdated &&
            (state as MemorizationModeUpdated).isMemorizationMode) {
          debugPrint('🔄 [$_id] Retrying listening...');
          startListening();
        }
      });
    }
  }

  void _onStatus(String status) {
    if (isClosed) return;
    debugPrint('📶 [$_id] STT Status: $status');
    if (status == 'notListening' || status == 'done') {
      if (state is MemorizationModeUpdated) {
        final currentState = state as MemorizationModeUpdated;
        if (currentState.isMemorizationMode) {
          debugPrint('🔄 [$_id] Restarting listening for continuous mode...');

          Future.delayed(const Duration(milliseconds: 1000), () async {
            if (isClosed) return;

            if (state is MemorizationModeUpdated &&
                (state as MemorizationModeUpdated).isMemorizationMode) {
              if (_speechService.isListening) {
                debugPrint('✅ [$_id] Already listening, skipping restart');
                return;
              }

              startListening();
            }
          });
        } else {
          emit(currentState.copyWith(isListening: false));
        }
      }
    } else if (status == 'listening') {
      if (state is MemorizationModeUpdated) {
        emit((state as MemorizationModeUpdated).copyWith(isListening: true));
      }
    }
  }

  String _getExpectedText(int index) {
    if (index < 0 || index >= _ayahTexts.length) return '';

    String expectedText = _ayahTexts[index];
    final isFirstAyah = index == 0;
    final shouldShowBismillah =
        isFirstAyah && _surahNumber != 1 && _surahNumber != 9;

    if (shouldShowBismillah) {
      const bismillahText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';
      if (expectedText.trim().startsWith(bismillahText)) {
        expectedText =
            expectedText.trim().replaceFirst(bismillahText, '').trim();
      }
    }
    return expectedText;
  }

  Future<void> stopListening() async {
    await _speechService.stop();
    if (state is MemorizationModeUpdated) {
      final currentState = state as MemorizationModeUpdated;
      emit(currentState.copyWith(isListening: false, listeningAyahIndex: null));
    }
  }

  void _handleMatch(int ayahIndex) {
    if (state is MemorizationModeUpdated) {
      final currentState = state as MemorizationModeUpdated;
      final newHiddenIndices = Set<int>.from(currentState.hiddenAyahIndices);
      newHiddenIndices.remove(ayahIndex);

      if (newHiddenIndices.isEmpty) {
        debugPrint('🎉 Surah memorization completed!');
        stopListening();
        emit(const MemorizationCompleted());
      } else {
        emit(currentState.copyWith(
          hiddenAyahIndices: newHiddenIndices,
          isListening: true,
          listeningAyahIndex: null,
          isMatch: true,
          recognizedText: '',
        ));
      }
    }
  }

  bool verifyRecitation(String spoken, String expected) {
    final normalizedSpoken =
        TextUtils.removeDiacriticsAndNormalize(spoken).trim();
    final normalizedExpected =
        TextUtils.removeDiacriticsAndNormalize(expected).trim();

    if (normalizedSpoken == normalizedExpected) return true;
    if (normalizedSpoken.contains(normalizedExpected)) {
      return true;
    }

    final spokenWords =
        normalizedSpoken.split(' ').where((w) => w.isNotEmpty).toList();
    final expectedWords =
        normalizedExpected.split(' ').where((w) => w.isNotEmpty).toList();

    if (expectedWords.isEmpty) return false;

    int matchCount = 0;
    for (var word in expectedWords) {
      if (spokenWords.any((s) {
        if (s == word || s.contains(word) || word.contains(s)) return true;

        final distance = TextUtils.getLevenshteinDistance(s, word);
        final allowedDistance = word.length > 4 ? 2 : 1;
        return distance <= allowedDistance;
      })) {
        matchCount++;
      }
    }

    final matchPercentage = matchCount / expectedWords.length;
    return matchPercentage >= 0.7;
  }

  @override
  Future<void> close() async {
    await stopListening();
    await _statusSubscription?.cancel();
    await _errorSubscription?.cancel();
    return super.close();
  }
}
