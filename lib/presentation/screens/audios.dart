import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/audios/audios_cubit.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/audio/audio_language_selection_fab.dart';
import 'package:huda/presentation/widgets/audio/audios_app_bar.dart';
import 'package:huda/presentation/widgets/audio/audios_error_widget.dart';
import 'package:huda/presentation/widgets/audio/audios_loaded_widget.dart';
import 'package:huda/presentation/widgets/audio/audios_loading_widget.dart';
import 'package:huda/presentation/widgets/audio/audios_offline_widget.dart';
import 'package:huda/presentation/widgets/audio/audiobook_player_bar.dart';
import 'package:huda/presentation/widgets/audio/offline_audio_empty_state_widget.dart';
import 'package:huda/presentation/widgets/books/offline_state_widget.dart';

class AudiosScreen extends StatefulWidget {
  const AudiosScreen({super.key});

  @override
  State<AudiosScreen> createState() => _AudiosScreenState();
}

class _AudiosScreenState extends State<AudiosScreen>
    with TickerProviderStateMixin {
  String? selectedLanguage;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupAnimations();
  }

  void _loadInitialData() {
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    selectedLanguage = languageCode;
    context.read<AudiosCubit>().fetchAudios(languageCode, 1, languageCode);
    context.read<AudioLanguagesCubit>().fetchLanguages(languageCode);
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Stack(
        children: [
          BlocConsumer<AudiosCubit, AudiosState>(
            listener: (context, state) {
              if (state is AudiosLoaded &&
                  state.audiosResponse.data.isEmpty &&
                  selectedLanguage != null) {
                final languageCode =
                    context.read<LocalizationCubit>().state.locale.languageCode;
                setState(() => selectedLanguage = null);
                context
                    .read<AudiosCubit>()
                    .fetchAudios('showall', 1, languageCode);
              }
            },
            builder: (context, state) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  AudiosAppBar(isDark: isDark),
                  ..._buildContentForState(context, state, isDark),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 152.h),
                  ),
                ],
              );
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: AudiobookPlayerBar(),
          ),
          BlocBuilder<AudiosCubit, AudiosState>(
            builder: (context, audioState) {
              final isOffline = audioState is AudiosOfflineLoaded ||
                  audioState is AudiosOfflineEmpty ||
                  audioState is AudiosOffline;

              if (isOffline) return const SizedBox.shrink();

              return BlocBuilder<AudiobookBarCubit, AudiobookBarVisibility>(
                builder: (context, barState) {
                  return BlocBuilder<AudiobookPlayerCubit,
                      AudiobookPlayerState>(
                    builder: (context, playerState) {
                      final playerVisible =
                          barState == AudiobookBarVisibility.visible &&
                              playerState is AudiobookPlayerPlaying;

                      return AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: AlignmentDirectional.bottomEnd,
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsetsDirectional.only(
                            end: 16.w,
                            bottom: (playerVisible ? 84.h : 16.h) +
                                MediaQuery.of(context).viewPadding.bottom,
                          ),
                          child: AudioLanguageSelectionFab(
                            animation: _fabAnimation,
                            selectedLanguage: selectedLanguage,
                            onLanguageSelected: _handleLanguageChange,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentForState(
      BuildContext context, AudiosState state, bool isDark) {
    if (state is AudiosLoading || state is AudiosOfflineLoading) {
      return [AudiosLoadingWidget(isDark: isDark)];
    } else if (state is AudiosLoaded) {
      return [
        AudiosLoadedWidget(
          state: state,
          isDark: isDark,
          selectedLanguage: selectedLanguage,
          onLanguageChanged: _handleLanguageChange,
        )
      ];
    } else if (state is AudiosOfflineLoaded) {
      return [
        AudiosOfflineWidget(state: state, isDark: isDark),
      ];
    } else if (state is AudiosOfflineEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: OfflineAudioEmptyStateWidget(
              isDark: isDark, onRetry: _retryLoading),
        )
      ];
    } else if (state is AudiosOffline) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: OfflineStateWidget(isDark: isDark, onRetry: _retryLoading),
        )
      ];
    } else if (state is AudiosError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AudiosErrorWidget(
            message: state.message,
            isDark: isDark,
            onRetry: _retryLoading,
          ),
        )
      ];
    }
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  void _handleLanguageChange(String? language) {
    setState(() {
      selectedLanguage = language;
    });
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    context
        .read<AudiosCubit>()
        .fetchAudios(language ?? 'showall', 1, languageCode);
  }

  void _retryLoading() {
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    context
        .read<AudiosCubit>()
        .fetchAudios(selectedLanguage ?? 'showall', 1, languageCode);
    context.read<AudioLanguagesCubit>().fetchLanguages(languageCode);
  }
}
