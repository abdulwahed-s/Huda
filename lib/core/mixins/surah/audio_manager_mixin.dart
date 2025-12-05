import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/surah_model.dart';

mixin AudioManagerMixin<T extends StatefulWidget> on State<T> {
  final AudioPlayer audioPlayer = AudioPlayer();
  int? playingAyahIndex;
  bool autoplayEnabled = true;
  bool loopEnabled = false;
  audio.SurahAudioModel? currentSurahAudio;
  bool isLoadingAudio = false;
  String? selectedReaderId;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isUserSeeking = false;

  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  SurahModel get surah;
  int get surahNumber;
  bool get isBottomSheetOpen;
  StateSetter? get modalStateSetter;
  bool get isOfflineMode;

  void safeModalSetState();

  void setupAudioListeners() {
    _playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((event) {
      playNextAyah();
    });

    _positionSubscription = audioPlayer.onPositionChanged.listen((position) {
      if (!isUserSeeking && mounted) {
        setState(() {
          currentPosition = position;
        });

        safeModalSetState();
      }
    });

    _durationSubscription = audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });

        safeModalSetState();
      }
    });
  }

  Future<void> playPauseAudio(int index) async {
    final isPlaying =
        audioPlayer.state == PlayerState.playing && playingAyahIndex == index;

    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      if (currentSurahAudio != null) {
        if (playingAyahIndex == index &&
            audioPlayer.state == PlayerState.paused) {
          await audioPlayer.resume();
        } else {
          await playAyahAudio(index);
        }
        if (mounted) {
          setState(() => playingAyahIndex = index);
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
        await audioPlayer.stop();
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

        if (downloadedPath != null) {
          await audioPlayer.play(DeviceFileSource(downloadedPath));
        } else {
          if (kIsWeb) {
            final proxyUrl =
                'https://corsproxy.io/?${Uri.encodeComponent(targetAyah!.audio!)}';
            await audioPlayer.play(
              UrlSource(
                proxyUrl,
                mimeType: 'audio/mpeg',
              ),
            );
          } else {
            await audioPlayer.play(UrlSource(targetAyah!.audio!));
          }
        }

        if (mounted) {
          setState(() => playingAyahIndex = index);
        }
      }
    }
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
        if (mounted) {
          setState(() => playingAyahIndex = nextIndex);
        }

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
    if (audioPlayer.state == PlayerState.playing) {
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
    _playerCompleteSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();

    audioPlayer.dispose();
    super.dispose();
  }
}
