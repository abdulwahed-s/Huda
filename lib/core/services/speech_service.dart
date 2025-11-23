import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  // Broadcast streams for status and errors
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  final _errorController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get errorStream => _errorController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    debugPrint('🎤 [SpeechService] Initializing...');
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('❌ [SpeechService] Error: $val');
          _errorController.add(val);
        },
        onStatus: (val) {
          debugPrint('📶 [SpeechService] Status: $val');
          _statusController.add(val);
        },
      );
      debugPrint('🎤 [SpeechService] Initialized result: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('❌ [SpeechService] Initialization Exception: $e');
      _errorController.add(e);
      return false;
    }
  }

  Future<void> listen({
    required Function(dynamic) onResult,
    String localeId = 'ar-SA',
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        throw Exception('Failed to initialize speech recognition');
      }
    }

    if (_speech.isListening) {
      debugPrint('⚠️ [SpeechService] Already listening, stopping first...');
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('🎤 [SpeechService] Starting listen...');
    try {
      await _speech.listen(
        onResult: onResult,
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        pauseFor: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('❌ [SpeechService] Listen Exception: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      debugPrint('🛑 [SpeechService] Stopping...');
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      debugPrint('🛑 [SpeechService] Canceling...');
      await _speech.cancel();
    }
  }

  /// Forcefully resets the speech service if it gets stuck
  Future<void> reset() async {
    debugPrint('🔄 [SpeechService] Resetting...');
    await cancel();
  }
}
