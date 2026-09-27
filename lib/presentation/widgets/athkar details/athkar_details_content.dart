import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/athkar%20details/error_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loaded_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loading_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/offline_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_share_card.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_options_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class AthkarDetailsContent extends StatefulWidget {
  final String athkarId;
  final String title;
  final String titleEn;

  const AthkarDetailsContent({
    super.key,
    required this.athkarId,
    required this.title,
    required this.titleEn,
  });

  @override
  State<AthkarDetailsContent> createState() => _AthkarDetailsContentState();
}

class _AthkarDetailsContentState extends State<AthkarDetailsContent>
    with TickerProviderStateMixin {
  List<int>? _repeatCounters;
  List<int>? _originalRepeatCounters;
  bool _isGeneratingImage = false;
  final Map<int, GlobalKey> _athkarCardKeys = {};

  late final AudioPlayer _audioPlayer;
  late final AudioCoordinator _coordinator;
  int? _playingIndex;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    _initAudioPlayer();
    super.initState();
  }

  void _initAudioPlayer() {
    _audioPlayer = getIt<AudioPlayer>();
    _coordinator = getIt<AudioCoordinator>();

    _coordinator.register(AudioCoordinator.athkar, () {
      if (mounted) {
        setState(() {
          _playingIndex = null;
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (state.processingState == ProcessingState.completed) {
        _playNextAudio();
      }
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed ||
              state.processingState == ProcessingState.idle) {
            _audioPosition = Duration.zero;
          }
        });
      }
    });
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (duration != null && mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!_coordinator.isOwner(AudioCoordinator.athkar)) return;
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });
  }

  void _playNextAudio() {
    if (_playingIndex == null) return;

    final state = context.read<AthkarDetailsCubit>().state;
    if (state is! AthkarDetailsLoaded) return;

    final nextIndex = _playingIndex! + 1;
    if (nextIndex < state.athkarCategory.details.length) {
      final nextAudio = state.athkarCategory.details[nextIndex].audio;
      if (nextAudio != null && nextAudio.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _playAudio(nextAudio, nextIndex);
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _playingIndex = null;
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _coordinator.unregister(AudioCoordinator.athkar);
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0A1A)
          : const Color(0xFFFFFDF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
      body: BlocBuilder<AthkarDetailsCubit, AthkarDetailsState>(
        builder: (context, state) {
          if (state is AthkarDetailsLoading) {
            return LoadingState(colorScheme: colorScheme);
          } else if (state is AthkarDetailsLoaded) {
            _repeatCounters ??= List<int>.from(
              state.athkarCategory.details.map((e) => e.repeat ?? 0),
            );
            _originalRepeatCounters ??= List<int>.from(
              state.athkarCategory.details.map((e) => e.repeat ?? 0),
            );

            return LoadedState(
              athkarCategory: state.athkarCategory,
              repeatCounters: _repeatCounters!,
              originalRepeatCounters: _originalRepeatCounters!,
              athkarCardKeys: _athkarCardKeys,
              isGeneratingImage: _isGeneratingImage,
              playingIndex: _playingIndex,
              isPlaying: _isPlaying,
              audioDuration: _audioDuration,
              audioPosition: _audioPosition,
              colorScheme: colorScheme,
              isDark: isDark,
              title: widget.title,
              onCounterTap: (index) {
                if (_repeatCounters![index] > 0 && mounted) {
                  setState(() {
                    _repeatCounters![index]--;
                  });
                }
              },
              onResetCounter: (index) {
                if (mounted) {
                  setState(() {
                    _repeatCounters![index] = _originalRepeatCounters![index];
                  });
                }
              },
              onShare: _showShareOptions,
              onPlayAudio: _playAudio,
              onSeek: _seekAudio,
            );
          } else if (state is AthkarDetailsOffline) {
            return OfflineState(
              colorScheme: colorScheme,
              onRetry: () => context
                  .read<AthkarDetailsCubit>()
                  .loadAthkarDetail(widget.athkarId),
            );
          } else if (state is AthkarDetailsError) {
            return ErrorState(
              message: state.message,
              colorScheme: colorScheme,
              onRetry: () => context
                  .read<AthkarDetailsCubit>()
                  .loadAthkarDetail(widget.athkarId),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _playAudio(String? audioUrl, int index) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.unableToLoadAudio,
      );
      return;
    }

    if (audioUrl.startsWith('http://')) {
      audioUrl = audioUrl.replaceFirst('http://', 'https://');
    }

    try {
      if (_coordinator.isOwner(AudioCoordinator.athkar) &&
          _playingIndex == index) {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          _audioPlayer.play();
        }
      } else {
        _coordinator.requestAudio(AudioCoordinator.athkar);
        await audioServiceReady;
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: MediaItem(id: audioUrl, title: 'Athkar'),
          ),
        );
        if (mounted) {
          setState(() {
            _playingIndex = index;
          });
        }
        _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.unableToLoadAudio,
        );
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _showShareOptions(int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShareOptionsBottomSheet(
          isGeneratingImage: _isGeneratingImage,
          onShareText: () {
            Navigator.pop(context);
            _shareAsText(index);
          },
          onShareImage: () {
            Navigator.pop(context);
            _shareAsImage(index);
          },
        );
      },
    );
  }

  Future<void> _shareAsText(int index) async {
    final state = context.read<AthkarDetailsCubit>().state;
    if (state is! AthkarDetailsLoaded) return;

    final athkar = state.athkarCategory.details[index];
    final localizations = AppLocalizations.of(context)!;
    final shareText =
        """
${athkar.arabicText ?? ''}

${athkar.languageArabicTranslatedText ?? ''}

${localizations.athkarShareRepeatCount(athkar.repeat ?? 0)}

${localizations.sharedViaHuda}
""";

    final screenSize = MediaQuery.of(context).size;
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _shareAsImage(int index) async {
    if (mounted) {
      setState(() {
        _isGeneratingImage = true;
      });
    }

    try {
      final state = context.read<AthkarDetailsCubit>().state;
      if (state is! AthkarDetailsLoaded) return;

      final athkar = state.athkarCategory.details[index];
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final title = isArabic || widget.titleEn.trim().isEmpty
          ? widget.title
          : widget.titleEn;
      await ShareImageCapture.share(
        context: context,
        card: AthkarShareCard(
          title: title,
          arabicText: athkar.arabicText ?? '',
          translatedText: athkar.translatedText,
          repeatCount: athkar.repeat ?? 1,
        ),
        fileName: 'athkar_${widget.athkarId}_$index.png',
        text: '$title\n\n${AppLocalizations.of(context)!.sharedViaHuda}',
      );
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.failedToShareImage,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }
}
