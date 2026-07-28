import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class AthkarAudioPlayer {
  final BuildContext context;
  final VoidCallback onStateChanged;

  final AudioPlayer _audioPlayer = getIt<AudioPlayer>();
  final AudioCoordinator _coordinator = getIt<AudioCoordinator>();

  int? playingIndex;
  bool isPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  AthkarAudioPlayer({
    required this.context,
    required this.onStateChanged,
  }) {
    _coordinator.register(AudioCoordinator.athkar, () {
      playingIndex = null;
      isPlaying = false;
      audioPosition = Duration.zero;
      onStateChanged();
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (state.processingState == ProcessingState.completed) {
        _playNextAudio();
      }
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        audioPosition = Duration.zero;
      }
      onStateChanged();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (duration != null) {
        audioDuration = duration;
        onStateChanged();
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      audioPosition = position;
      onStateChanged();
    });
  }

  void _playNextAudio() {
    if (playingIndex == null) return;

    final cubit = context.read<AthkarDetailsCubit>();
    final state = cubit.state;
    if (state is! AthkarDetailsLoaded) return;

    final nextIndex = playingIndex! + 1;
    if (nextIndex < state.athkarCategory.details.length) {
      final nextAudio = state.athkarCategory.details[nextIndex].audio;
      if (nextAudio != null && nextAudio.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          playAudio(nextAudio, nextIndex);
        });
      }
    } else {
      playingIndex = null;
      isPlaying = false;
      audioPosition = Duration.zero;
      onStateChanged();
    }
  }

  Future<void> playAudio(String? audioUrl, int index) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      _showAudioErrorSnackbar('رابط الصوت غير متوفر');
      return;
    }

    if (audioUrl.startsWith('http://')) {
      audioUrl = audioUrl.replaceFirst('http://', 'https://');
    }

    try {
      if (_coordinator.isOwner(AudioCoordinator.athkar) &&
          playingIndex == index) {
        if (isPlaying) {
          await _audioPlayer.pause();
        } else {
          _audioPlayer.play();
        }
      } else {
        _coordinator.requestAudio(AudioCoordinator.athkar);
        await audioServiceReady;
        await _audioPlayer.setAudioSource(AudioSource.uri(
          Uri.parse(audioUrl),
          tag: MediaItem(id: audioUrl, title: 'Athkar'),
        ));
        playingIndex = index;
        onStateChanged();
        _audioPlayer.play();
      }
    } catch (e) {
      _showAudioErrorSnackbar('فشل في تشغيل الصوت: ${e.toString()}');
    }
  }

  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _showAudioErrorSnackbar(String message) {
    HudaSnackBar.error(context, message: message);
  }

  void dispose() {
    _coordinator.unregister(AudioCoordinator.athkar);
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
  }
}
