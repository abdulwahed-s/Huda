import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/service_locator.dart';

/// Plays a chapter's dhikr audio on the app's shared player, through the
/// [AudioCoordinator] (owner `athkar`). When one dhikr's audio finishes,
/// the next one's plays; a dhikr without audio ends the run.
class AthkarAudio extends ChangeNotifier {
  AthkarAudio({required this.audioAt, required this.onError}) {
    _coordinator.register(AudioCoordinator.athkar, () {
      playingIndex = null;
      isPlaying = false;
      position = Duration.zero;
      notifyListeners();
    });

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        position = Duration.zero;
      }
      notifyListeners();
    });

    _durationSubscription = _player.durationStream.listen((value) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (value != null) {
        duration = value;
        notifyListeners();
      }
    });

    _positionSubscription = _player.positionStream.listen((value) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      position = value;
      notifyListeners();
    });
  }

  /// The audio URL of the dhikr at an index, or null past the end.
  final String? Function(int index) audioAt;

  /// Audio couldn't play (no URL, or the player failed).
  final VoidCallback onError;

  final AudioPlayer _player = getIt<AudioPlayer>();
  final AudioCoordinator _coordinator = getIt<AudioCoordinator>();

  int? playingIndex;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool _disposed = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  void _playNext() {
    final current = playingIndex;
    if (current == null) return;
    final next = audioAt(current + 1);
    if (next != null && next.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_disposed) play(current + 1);
      });
    } else {
      playingIndex = null;
      isPlaying = false;
      position = Duration.zero;
      notifyListeners();
    }
  }

  /// Plays the dhikr at [index], or pauses and resumes it if it's the one
  /// already loaded.
  Future<void> play(int index) async {
    var url = audioAt(index);
    if (url == null || url.isEmpty) {
      onError();
      return;
    }
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    try {
      if (_coordinator.isOwner(AudioCoordinator.athkar) &&
          playingIndex == index) {
        if (isPlaying) {
          await _player.pause();
        } else {
          _player.play();
        }
      } else {
        _coordinator.requestAudio(AudioCoordinator.athkar);
        await audioServiceReady;
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(id: url, title: 'Athkar'),
          ),
        );
        if (_disposed) return;
        playingIndex = index;
        notifyListeners();
        _player.play();
      }
    } catch (_) {
      if (!_disposed) onError();
    }
  }

  Future<void> seek(Duration value) => _player.seek(value);

  @override
  void dispose() {
    _disposed = true;
    _coordinator.unregister(AudioCoordinator.athkar);
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
