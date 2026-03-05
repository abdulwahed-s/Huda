import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_audio_player.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_details_app_bar.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_share_handler.dart';
import 'package:huda/presentation/widgets/athkar%20details/error_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loaded_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loading_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/offline_state.dart';

class AthkarDetails extends StatefulWidget {
  final String athkarId;
  final String title;
  final String titleEn;

  const AthkarDetails({
    super.key,
    required this.athkarId,
    required this.title,
    required this.titleEn,
  });

  @override
  State<AthkarDetails> createState() => _AthkarDetailsState();
}

class _AthkarDetailsState extends State<AthkarDetails>
    with TickerProviderStateMixin {
  List<int>? _repeatCounters;
  List<int>? _originalRepeatCounters;
  final Map<int, GlobalKey> _athkarCardKeys = {};
  late final AthkarAudioPlayer _audioPlayer;
  late final AthkarShareHandler _shareHandler;

  @override
  void initState() {
    context.read<AthkarDetailsCubit>().loadAthkarDetail(widget.athkarId);
    _audioPlayer = AthkarAudioPlayer(
      context: context,
      onStateChanged: () => setState(() {}),
    );
    _shareHandler = AthkarShareHandler(
      context: context,
      athkarCardKeys: _athkarCardKeys,
      onGeneratingStateChanged: (isGenerating) => setState(() {}),
      title: widget.title,
    );
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0A1A) : const Color(0xFFFFFDF7),
      appBar: AthkarDetailsAppBar(
        title: widget.title,
        colorScheme: colorScheme,
      ),
      body: BlocBuilder<AthkarDetailsCubit, AthkarDetailsState>(
        builder: (context, state) {
          if (state is AthkarDetailsLoading) {
            return LoadingState(colorScheme: colorScheme);
          } else if (state is AthkarDetailsLoaded) {
            _initializeCounters(state);

            return LoadedState(
              athkarCategory: state.athkarCategory,
              repeatCounters: _repeatCounters!,
              originalRepeatCounters: _originalRepeatCounters!,
              athkarCardKeys: _athkarCardKeys,
              isGeneratingImage: _shareHandler.isGeneratingImage,
              playingIndex: _audioPlayer.playingIndex,
              isPlaying: _audioPlayer.isPlaying,
              audioDuration: _audioPlayer.audioDuration,
              audioPosition: _audioPlayer.audioPosition,
              colorScheme: colorScheme,
              isDark: isDark,
              title: widget.title,
              onCounterTap: _handleCounterTap,
              onResetCounter: _handleResetCounter,
              onShare: _shareHandler.showShareOptions,
              onPlayAudio: _audioPlayer.playAudio,
              onSeek: _audioPlayer.seekAudio,
            );
          } else if (state is AthkarDetailsOffline) {
            return OfflineState(
              colorScheme: colorScheme,
              onRetry: () => _retryLoading(),
            );
          } else if (state is AthkarDetailsError) {
            return ErrorState(
              message: state.message,
              colorScheme: colorScheme,
              onRetry: () => _retryLoading(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _initializeCounters(AthkarDetailsLoaded state) {
    _repeatCounters ??= List<int>.from(
      state.athkarCategory.details.map((e) => e.repeat ?? 0),
    );
    _originalRepeatCounters ??= List<int>.from(
      state.athkarCategory.details.map((e) => e.repeat ?? 0),
    );
  }

  void _handleCounterTap(int index) {
    if (_repeatCounters![index] > 0 && mounted) {
      setState(() {
        _repeatCounters![index]--;
      });
    }
  }

  void _handleResetCounter(int index) {
    if (mounted) {
      setState(() {
        _repeatCounters![index] = _originalRepeatCounters![index];
      });
    }
  }

  void _retryLoading() {
    context.read<AthkarDetailsCubit>().loadAthkarDetail(widget.athkarId);
  }
}
