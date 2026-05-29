import 'package:flutter/foundation.dart';

class AudioCoordinator {
  static const String quranPlayer = 'quranPlayer';
  static const String quranRadio = 'quranRadio';
  static const String surahAyah = 'surahAyah';
  static const String athkar = 'athkar';

  String? _currentOwner;
  final Map<String, VoidCallback> _preemptCallbacks = {};

  String? get currentOwner => _currentOwner;

  bool isOwner(String id) => _currentOwner == id;

  void register(String ownerId, VoidCallback onPreempted) {
    _preemptCallbacks[ownerId] = onPreempted;
  }

  void unregister(String ownerId) {
    _preemptCallbacks.remove(ownerId);
    if (_currentOwner == ownerId) _currentOwner = null;
  }

  void requestAudio(String ownerId) {
    if (_currentOwner == ownerId) return;
    final previous = _currentOwner;
    _currentOwner = ownerId;
    if (previous != null) _preemptCallbacks[previous]?.call();
  }

  void release(String ownerId) {
    if (_currentOwner == ownerId) _currentOwner = null;
  }
}
