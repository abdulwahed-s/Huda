import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
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
      'https://images.pexels.com/photos/318451/pexels-photo-318451.jpeg?auto=compress&cs=tinysrgb&w=600');

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
      if (state.processingState == ProcessingState.completed) {
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

  Future<void> playPauseAudio(int index) async {
    final isPlaying = isAudioPlaying && playingAyahIndex == index;

    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      if (currentSurahAudio != null) {
        if (playingAyahIndex == index && !isAudioPlaying) {
          audioPlayer.play();
        } else {
          await playAyahAudio(index);
        }
      }
    }

    safeModalSetState();
  }

  Future<void> playAyahAudio(int index) async {
    if (currentSurahAudio?.data?.surahs?.isNotEmpty == true) {
      final targetSurah = currentSurahAudio!.data!.surahs!.firstWhere(
        (surah) => surah.number == this.surah.number,
        orElse: () => currentSurahAudio!.data!.surahs!.first,
      );

      final AudioCubit cubit = context.read<AudioCubit>();

      final ayahFromCurrentScreen = surah.ayahs![index];
      final targetAyah = targetSurah.ayahs?.firstWhere(
        (ayah) => ayah.numberInSurah == ayahFromCurrentScreen.numberInSurah,
        orElse: () => targetSurah.ayahs!.first,
      );

      if (targetAyah?.audio != null && selectedReaderId != null) {
        if (mounted) {
          setState(() {
            currentPosition = Duration.zero;
            totalDuration = Duration.zero;
            isUserSeeking = false;
          });
        }

        final downloadedPath = await cubit.getDownloadedAyahPath(
          surahNumber: surah.number.toString(),
          ayahNumber: ayahFromCurrentScreen.numberInSurah.toString(),
          readerId: selectedReaderId!,
        );

        final mediaId =
            'surah_${surah.number}_ayah_${ayahFromCurrentScreen.numberInSurah}';
        final mediaTitle =
            '${surah.name ?? 'Surah'} - Ayah ${ayahFromCurrentScreen.numberInSurah}';
        final mediaItem = MediaItem(
          id: mediaId,
          title: mediaTitle,
          album: surah.name,
          artist: _reciterNameForId(cubit, selectedReaderId!),
          artUri: _notificationArtUri,
        );

        await audioServiceReady;
        _audioCoordinator.requestAudio(AudioCoordinator.surahAyah);

        if (downloadedPath != null) {
          await audioPlayer.setAudioSource(AudioSource.uri(
            Uri.file(downloadedPath),
            tag: mediaItem,
          ));
        } else {
          if (kIsWeb) {
            final proxyUrl =
                'https://corsproxy.io/?${Uri.encodeComponent(targetAyah!.audio!)}';
            await audioPlayer.setAudioSource(AudioSource.uri(
              Uri.parse(proxyUrl),
              tag: mediaItem,
            ));
          } else {
            await audioPlayer.setAudioSource(AudioSource.uri(
              Uri.parse(targetAyah!.audio!),
              tag: mediaItem,
            ));
          }
        }

        if (mounted) {
          setState(() => playingAyahIndex = index);
        }
        audioPlayer.play();
      }
    }
  }

  String? _reciterNameForId(AudioCubit cubit, String readerId) {
    for (final reader in cubit.getReadersByLanguage(null)) {
      if (reader.identifier == readerId) {
        return reader.englishName ?? reader.name;
      }
    }
    return null;
  }

  void playNextAyah() async {
    if (playingAyahIndex == null) return;

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
  }

  Future<void> seekToPosition(double value) async {
    final position =
        Duration(milliseconds: (value * totalDuration.inMilliseconds).round());
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
    context.read<AudioCubit>().fetchSurahAudio(newReaderId);
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
