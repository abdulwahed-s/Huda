import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';

mixin ReadingPositionTracker<T extends StatefulWidget> on State<T> {
  final ReadingPositionService _readingPositionService =
      getIt<ReadingPositionService>();
  Timer? _savePositionTimer;
  Timer? _updateThrottleTimer;

  int get currentSurahNumber;
  int get currentAyahNumber;
  double get currentScrollPosition;

  @override
  void initState() {
    super.initState();
    _startPositionTracking();
  }

  @override
  void dispose() {
    _savePositionTimer?.cancel();
    _updateThrottleTimer?.cancel();

    super.dispose();
  }

  void _startPositionTracking() {
    _savePositionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _saveCurrentPosition(),
    );
  }

  void _saveCurrentPosition() {
    try {
      _readingPositionService.saveReadingPosition(
        surahNumber: currentSurahNumber,
        ayahNumber: currentAyahNumber,
        position: currentScrollPosition,
      );
    } catch (e) {
      debugPrint('Error saving reading position: $e');
    }
  }

  void updateReadingPosition({
    required int ayahNumber,
    required double position,
  }) {
    _updateThrottleTimer?.cancel();
    _updateThrottleTimer = Timer(const Duration(milliseconds: 500), () {
      try {
        debugPrint(
            '🔄 Mixin saving: ayah $ayahNumber, position: $position, surah: $currentSurahNumber');

        _readingPositionService.updatePositionForSurah(
          surahNumber: currentSurahNumber,
          ayahNumber: ayahNumber,
          position: position,
        );
      } catch (e) {
        debugPrint('Error updating reading position: $e');
      }
    });
  }

  void saveReadingPositionManually() {
    _saveCurrentPosition();
  }
}
