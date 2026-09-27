import 'dart:async';
import 'package:huda/data/models/ayah_audio_range.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/surah_model.dart';

mixin AudioManagerMixin<T extends StatefulWidget> on State<T> {
  final AudioPlayer audioPlayer = getIt<AudioPlayer>();
  final AudioCoordinator _audioCoordinator = getIt<AudioCoordinator>();
  int? playingAyahIndex;
  bool autoplayEnabled = true;
  bool loopEnabled = false;
  AyahAudioRange? audioRange;
  bool _handlingCompletion = false;
  audio.SurahAudioModel? currentSurahAudio;
  bool isLoadingAudio = false;
  String? selectedReaderId;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isUserSeeking = false;
  bool isAudioPlaying = false;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  static final Uri _notificationArtUri = Uri.parse(
    'https://images.pexels.com/photos/318451/pexels-photo-318451.jpeg?auto=compress&cs=tinysrgb&w=600',
  );

  SurahModel get surah;
  int get surahNumber;
  bool get isBottomSheetOpen;
  StateSetter? get modalStateSetter;
  bool get isOfflineMode;

  void safeModalSetState();

  void setupAudioListeners() {
    _audioCoordinator.register(AudioCoordinator.surahAyah, () {
      if (mounted) {
        setState(() {
          isAudioPlaying = false;
          playingAyahIndex = null;
          audioRange = null;
          currentPosition = Duration.zero;
          totalDuration = Duration.zero;
        });
        safeModalSetState();
      }
    });

    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (!_audioCoordinator.isOwner(AudioCoordinator.surahAyah)) return;
      if (mounted) {
        setState(() => isAudioPlaying = state.playing);
        safeModalSetState();
      }
      if (state.playing &&
          state.processingState == ProcessingState.completed &&
          !_handlingCompletion) {
        playNextAyah();
      }
    });

    _positionSubscription = audioPlayer.positionStream.listen((position) {
      if (!_audioCoordinator.isOwner(AudioCoordinator.surahAyah)) return;
      if (!isUserSeeking && mounted) {
        setState(() {
          currentPosition = position;
        });

        safeModalSetState();
      }
    });

    _durationSubscription = audioPlayer.durationStream.listen((duration) {
      if (!_audioCoordinator.isOwner(AudioCoordinator.surahAyah)) return;
      if (duration != null && mounted) {
        setState(() {
          totalDuration = duration;
        });

        safeModalSetState();
      }
    });
  }

  Future<void> configureAudioRange(AyahAudioRange? range) async {
    if (range != null && range.endIndex >= (surah.ayahs?.length ?? 0)) return;
    await audioPlayer.pause();
    if (!mounted) return;
    setState(() {
      audioRange = range;
      if (range != null) {
        loopEnabled = false;
        autoplayEnabled = false;
      }
      playingAyahIndex = null;
      isAudioPlaying = false;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });
    safeModalSetState();
  }

  Future<void> playPauseAudio(int index) async {
    final isPlaying = isAudioPlaying && playingAyahIndex == index;

    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      if (playingAyahIndex == index && !isAudioPlaying) {
        audioPlayer.play();
      } else {
        await playAyahAudio(index);
      }
    }

    safeModalSetState();
  }

  Future<void> playAyahAudio(int index) async {
    final readerId = selectedReaderId;
    final ayahs = surah.ayahs;
    if (readerId == null ||
        ayahs == null ||
        index < 0 ||
        index >= ayahs.length) {
      return;
    }
    if (audioRange != null && !audioRange!.contains(index)) {
      setState(() => audioRange = null);
    }
    final ayah = ayahs[index];
    final cubit = context.read<AudioCubit>();
    String? remoteUrl;
    for (final audioSurah
        in currentSurahAudio?.data?.surahs ?? <audio.Surahs>[]) {
      if (audioSurah.number != surah.number) continue;
      for (final audioAyah in audioSurah.ayahs ?? <audio.Ayahs>[]) {
        if (audioAyah.numberInSurah == ayah.numberInSurah) {
          remoteUrl = audioAyah.audio;
        }
      }
    }
    final uri = await cubit.resolveAyahAudioUri(
      readerId: readerId,
      surahNumber: surah.number!,
      ayahNumber: ayah.numberInSurah!,
      globalAyahNumber: ayah.number,
      remoteUrl: remoteUrl,
    );
    if (uri == null || !mounted || selectedReaderId != readerId) return;
    setState(() {
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
      isUserSeeking = false;
    });
    final mediaItem = MediaItem(
      id: 'surah_${surah.number}_ayah_${ayah.numberInSurah}',
      title: '${surah.name ?? 'Surah'} - Ayah ${ayah.numberInSurah}',
      album: surah.name,
      artist: _reciterNameForId(cubit, readerId),
      artUri: _notificationArtUri,
    );
    await audioServiceReady;
    if (!mounted || selectedReaderId != readerId) return;
    _audioCoordinator.requestAudio(AudioCoordinator.surahAyah);
    await audioPlayer.setAudioSource(AudioSource.uri(uri, tag: mediaItem));
    if (mounted) setState(() => playingAyahIndex = index);
    audioPlayer.play();
  }

  String? _reciterNameForId(AudioCubit cubit, String readerId) {
    for (final reader in cubit.getReadersByLanguage(null)) {
      if (reader.identifier == readerId) {
        return reader.englishName ?? reader.name;
      }
    }
    return null;
  }

  Future<void> playNextAyah() async {
    if (playingAyahIndex == null || _handlingCompletion) return;
    _handlingCompletion = true;
    try {
      final range = audioRange;
      if (range != null) {
        final next = range.nextIndex(playingAyahIndex!);
        if (next != null) {
          await playAyahAudio(next);
        } else {
          await audioPlayer.pause();
          if (mounted) {
            setState(() {
              playingAyahIndex = null;
              isAudioPlaying = false;
            });
          }
        }
        safeModalSetState();
        return;
      }

      if (loopEnabled) {
        await playAyahAudio(playingAyahIndex!);
        return;
      }

      if (autoplayEnabled) {
        final nextIndex = playingAyahIndex! + 1;
        if (nextIndex < surah.ayahs!.length) {
          final wasBottomSheetOpen = isBottomSheetOpen;

          if (isBottomSheetOpen && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          await playAyahAudio(nextIndex);

          if (wasBottomSheetOpen) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                onAyahTap(nextIndex);
              }
            });
          }
        } else {
          if (mounted) {
            setState(() => playingAyahIndex = null);
          }
        }
      } else {
        if (mounted) {
          setState(() => playingAyahIndex = null);
        }
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> seekToPosition(double value) async {
    final position = Duration(
      milliseconds: (value * totalDuration.inMilliseconds).round(),
    );
    await audioPlayer.seek(position);
    if (mounted) {
      setState(() {
        currentPosition = position;
        isUserSeeking = false;
      });
    }
  }

  void switchReader(String newReaderId, StateSetter? setModalState) {
    if (isAudioPlaying) {
      audioPlayer.stop();
    }

    if (mounted) {
      setState(() {
        audioRange = null;
        selectedReaderId = newReaderId;
        isLoadingAudio = true;
        currentSurahAudio = null;
        playingAyahIndex = null;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        isUserSeeking = false;
      });
    }

    setModalState?.call(() {});
    context.read<AudioCubit>().fetchSurahAudio(newReaderId, surah);
  }

  void onAyahTap(int index);

  @override
  void dispose() {
    _audioCoordinator.unregister(AudioCoordinator.surahAyah);
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}
