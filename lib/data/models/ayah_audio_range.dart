class AyahAudioRange {
  final int startIndex;
  final int endIndex;
  final bool repeat;

  AyahAudioRange({
    required this.startIndex,
    required this.endIndex,
    this.repeat = false,
  }) {
    if (startIndex < 0 || endIndex < startIndex) {
      throw ArgumentError('Invalid ayah range');
    }
  }

  bool contains(int index) => index >= startIndex && index <= endIndex;

  int? nextIndex(int currentIndex) {
    if (!contains(currentIndex)) return null;
    if (currentIndex < endIndex) return currentIndex + 1;
    return repeat ? startIndex : null;
  }
}
