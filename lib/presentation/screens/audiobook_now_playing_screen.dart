import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/presentation/widgets/audio/audiobook_background.dart';
import 'package:huda/presentation/widgets/audio/audiobook_error_state.dart';
import 'package:huda/presentation/widgets/audio/audiobook_initial_state.dart';
import 'package:huda/presentation/widgets/audio/audiobook_loading_skeleton.dart';
import 'package:huda/presentation/widgets/audio/audiobook_player_content.dart';

class AudiobookNowPlayingScreen extends StatelessWidget {
  const AudiobookNowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? context.darkGradientStart : context.lightSurface,
      body: BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
        builder: (context, state) {
          final artUrl = state is AudiobookPlayerPlaying ? state.artUrl : null;

          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AudiobookBackground(artUrl: artUrl, isDark: isDark),
                ),
              ),
              if (state is AudiobookPlayerInitial)
                AudiobookInitialState(isDark: isDark),
              if (state is AudiobookPlayerLoading)
                AudiobookLoadingSkeleton(isDark: isDark),
              if (state is AudiobookPlayerError)
                AudiobookErrorState(message: state.message, isDark: isDark),
              if (state is AudiobookPlayerPlaying)
                AudiobookPlayerContent(state: state, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}
