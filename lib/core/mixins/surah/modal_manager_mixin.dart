import 'package:flutter/material.dart';

mixin ModalManagerMixin<T extends StatefulWidget> on State<T> {
  StateSetter? modalStateSetter;
  bool isBottomSheetOpen = false;

  void safeModalSetState() {
    if (isBottomSheetOpen && modalStateSetter != null) {
      modalStateSetter!(() {});
    }
  }

  void skipToPreviousAyah(int currentIndex) {
    if (currentIndex > 0) {
      stopAudioIfPlaying();

      modalStateSetter = null;
      isBottomSheetOpen = false;
      Navigator.pop(context);

      resetAudioState();

      Future.delayed(const Duration(milliseconds: 100), () {
        onAyahTap(currentIndex - 1);
      });
    }
  }

  void skipToNextAyah(int currentIndex, int totalAyahs) {
    if (currentIndex + 1 < totalAyahs) {
      stopAudioIfPlaying();

      modalStateSetter = null;
      isBottomSheetOpen = false;
      Navigator.pop(context);

      resetAudioState();

      Future.delayed(const Duration(milliseconds: 100), () {
        onAyahTap(currentIndex + 1);
      });
    }
  }

  void onBottomSheetClosed() {
    modalStateSetter = null;
    isBottomSheetOpen = false;
  }

  void onAyahTap(int index);
  void stopAudioIfPlaying();
  void resetAudioState();
}
