import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart' show PlayerState;
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audio_detail/audio_detail_cubit.dart';
import 'package:huda/cubit/audiobook_download/audiobook_download_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_chapters_header.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_download_button.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_expandable_description.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_glass_button.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_hero_header.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_play_button.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_progress_banner.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_skeleton_loader.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_track_list.dart';
import 'package:huda/presentation/widgets/audio/audiobook_player_bar.dart';
import 'package:huda/presentation/widgets/books/error_state_widget.dart';

class AudioDetailScreen extends StatefulWidget {
  final int audioId;
  final String language;
  final String title;

  const AudioDetailScreen({
    super.key,
    required this.audioId,
    required this.language,
    required this.title,
  });

  @override
  State<AudioDetailScreen> createState() => _AudioDetailScreenState();
}

class _AudioDetailScreenState extends State<AudioDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    context.read<AudioDetailCubit>().fetchAudioDetail(
          widget.audioId,
          widget.language,
        );
    context.read<AudiobookDownloadCubit>().checkStatus(widget.audioId);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _triggerEntrance() {
    if (!_entranceCtrl.isCompleted) _entranceCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? context.darkGradientStart : Colors.grey[50],
      body: Stack(
        children: [
          BlocConsumer<AudioDetailCubit, AudioDetailState>(
            listener: (context, state) {
              if (state is AudioDetailLoaded ||
                  state is AudioDetailOfflineLoaded) {
                _triggerEntrance();
              }
            },
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildStateBody(context, isDark, state),
              );
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: AudiobookPlayerBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateBody(
      BuildContext context, bool isDark, AudioDetailState state) {
    if (state is AudioDetailLoading || state is AudioDetailInitial) {
      return AudioDetailSkeletonLoader(
          key: const ValueKey('skeleton'), isDark: isDark);
    }
    if (state is AudioDetailLoaded) {
      return _buildContent(
        context,
        isDark,
        key: const ValueKey('loaded'),
        title: state.audioDetail.title ?? widget.title,
        description: state.audioDetail.description ?? '',
        fullDescription: state.audioDetail.fullDescription,
        author: _authorOf(state.audioDetail),
        tracks: state.audioDetail.attachments ?? [],
        detail: state.audioDetail,
        artUrl: state.audioDetail.image,
      );
    }
    if (state is AudioDetailOfflineLoaded) {
      return _buildContent(
        context,
        isDark,
        key: const ValueKey('offline_loaded'),
        title: state.offlineAudio.title,
        description: state.offlineAudio.description,
        fullDescription: null,
        author: state.offlineAudio.preparedBy.isNotEmpty
            ? (state.offlineAudio.preparedBy.first.title ?? '')
            : '',
        tracks: _offlineToTracks(state.offlineAudio),
        detail: null,
        artUrl: state.offlineAudio.imageUrl,
      );
    }
    if (state is AudioDetailOffline) {
      return _wrapWithAppBar(
        context,
        isDark,
        key: const ValueKey('offline'),
        child: ErrorStateWidget(
          icon: Icons.cloud_off_rounded,
          title: AppLocalizations.of(context)!.noInternetConnection,
          message: AppLocalizations.of(context)!.pleaseCheckConnection,
          isDark: isDark,
          buttonText: AppLocalizations.of(context)!.tryAgain,
          onButtonPressed: () => context
              .read<AudioDetailCubit>()
              .fetchAudioDetail(widget.audioId, widget.language),
        ),
      );
    }
    if (state is AudioDetailError) {
      return _wrapWithAppBar(
        context,
        isDark,
        key: const ValueKey('error'),
        child: ErrorStateWidget(
          icon: Icons.error_outline_rounded,
          title: AppLocalizations.of(context)!.somethingWentWrong,
          message: state.error,
          isDark: isDark,
          buttonText: AppLocalizations.of(context)!.tryAgain,
          onButtonPressed: () => context
              .read<AudioDetailCubit>()
              .fetchAudioDetail(widget.audioId, widget.language),
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _wrapWithAppBar(BuildContext context, bool isDark,
      {required Key key, required Widget child}) {
    return Scaffold(
      key: key,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(),
        ),
      ),
      body: child,
    );
  }

  String _authorOf(AudioDetailModel d) {
    if (d.preparedBy != null && d.preparedBy!.isNotEmpty) {
      return d.preparedBy!.first.title ?? '';
    }
    return '';
  }

  List<AudioTrack> _offlineToTracks(OfflineAudiobookModel offline) {
    return offline.tracks
        .map((t) => AudioTrack(
              order: t.order,
              size: t.size,
              extensionType: t.extensionType,
              description: t.description,
              url: t.originalUrl,
            ))
        .toList();
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark, {
    required Key key,
    required String title,
    required String description,
    required String? fullDescription,
    required String author,
    required List<AudioTrack> tracks,
    required AudioDetailModel? detail,
    required String? artUrl,
  }) {
    final progress = getIt<AudioProgressService>().getProgress(widget.audioId);

    return FadeTransition(
      key: key,
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(
                context, isDark, title, author, artUrl, tracks.length),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 24.h),
                    _buildActionRow(context, isDark, tracks, title, author,
                        artUrl, detail, progress),
                    if (progress != null) ...[
                      SizedBox(height: 16.h),
                      AudioDetailProgressBanner(
                          progress: progress, isDark: isDark),
                    ],
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      AudioDetailExpandableDescription(
                        text: fullDescription?.isNotEmpty == true
                            ? fullDescription!
                            : description,
                        isDark: isDark,
                      ),
                    ],
                    SizedBox(height: 28.h),
                    AudioDetailChaptersHeader(
                        count: tracks.length, isDark: isDark),
                    SizedBox(height: 12.h),
                    _buildTrackList(
                        context, isDark, tracks, title, author, artUrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, String title,
      String author, String? artUrl, int chapterCount) {
    return SliverAppBar(
      expandedHeight: 340.h,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? context.darkGradientStart : Colors.grey[50],
      elevation: 0,
      leading: AudioDetailGlassButton(
        icon: Icons.arrow_back_ios_new_rounded,
        isDark: isDark,
        onTap: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground
        ],
        background: AudioDetailHeroHeader(
          artUrl: artUrl,
          title: title,
          author: author,
          chapterCount: chapterCount,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    bool isDark,
    List<AudioTrack> tracks,
    String title,
    String author,
    String? artUrl,
    AudioDetailModel? detail,
    AudiobookProgress? progress,
  ) {
    return BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
      builder: (context, playerState) {
        final playing = playerState is AudiobookPlayerPlaying &&
            playerState.audiobookId == widget.audioId;

        if (playing) {
          return StreamBuilder<PlayerState>(
            stream: playerState.audioPlayer.playerStateStream,
            builder: (context, snap) {
              final isPlaying = snap.data?.playing ?? false;
              return _actionRowContent(
                context,
                isDark,
                tracks,
                title,
                author,
                artUrl,
                detail,
                progress,
                isThisAudioActive: true,
                isCurrentlyPlaying: isPlaying,
                onPause: () => context.read<AudiobookPlayerCubit>().pause(),
                onResume: () => context.read<AudiobookPlayerCubit>().resume(),
              );
            },
          );
        }

        return _actionRowContent(
          context,
          isDark,
          tracks,
          title,
          author,
          artUrl,
          detail,
          progress,
          isThisAudioActive: false,
          isCurrentlyPlaying: false,
          onPause: null,
          onResume: null,
        );
      },
    );
  }

  Widget _actionRowContent(
    BuildContext context,
    bool isDark,
    List<AudioTrack> tracks,
    String title,
    String author,
    String? artUrl,
    AudioDetailModel? detail,
    AudiobookProgress? progress, {
    required bool isThisAudioActive,
    required bool isCurrentlyPlaying,
    required VoidCallback? onPause,
    required VoidCallback? onResume,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasProgress = progress != null;

    return Row(
      children: [
        Expanded(
          child: AudioDetailPlayButton(
            hasProgress: hasProgress,
            trackIndex: hasProgress ? progress.trackIndex : 0,
            enabled: tracks.isNotEmpty,
            isThisAudioActive: isThisAudioActive,
            isCurrentlyPlaying: isCurrentlyPlaying,
            label: isThisAudioActive && isCurrentlyPlaying
                ? l10n.pause
                : hasProgress
                    ? l10n.resumeChapter(progress.trackIndex + 1)
                    : l10n.play,
            onPressed: tracks.isEmpty
                ? null
                : isThisAudioActive && isCurrentlyPlaying
                    ? onPause
                    : isThisAudioActive && !isCurrentlyPlaying
                        ? onResume
                        : () => _play(
                              context,
                              tracks,
                              title,
                              author,
                              artUrl,
                              initialIndex:
                                  hasProgress ? progress.trackIndex : 0,
                              initialPosition:
                                  hasProgress ? progress.position : null,
                            ),
          ),
        ),
        SizedBox(width: 12.w),
        AudioDetailDownloadButton(
          audioId: widget.audioId,
          detail: detail,
          language: widget.language,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTrackList(BuildContext context, bool isDark,
      List<AudioTrack> tracks, String title, String author, String? artUrl) {
    return BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
      builder: (context, playerState) {
        final activePlayer = playerState is AudiobookPlayerPlaying &&
                playerState.audiobookId == widget.audioId
            ? playerState
            : null;

        if (activePlayer != null) {
          return StreamBuilder<int?>(
            stream: activePlayer.audioPlayer.currentIndexStream,
            builder: (context, idxSnap) {
              return StreamBuilder<PlayerState>(
                stream: activePlayer.audioPlayer.playerStateStream,
                builder: (context, psSnap) {
                  final currentIdx = idxSnap.data ?? 0;
                  final isPlaying = psSnap.data?.playing ?? false;
                  return AudioDetailTrackList(
                    tracks: tracks,
                    isDark: isDark,
                    currentIndex: currentIdx,
                    isPlaying: isPlaying,
                    onTrackTap: (idx) => _onTrackTap(context, idx, currentIdx,
                        isPlaying, tracks, title, author, artUrl),
                  );
                },
              );
            },
          );
        }

        return AudioDetailTrackList(
          tracks: tracks,
          isDark: isDark,
          currentIndex: -1,
          isPlaying: false,
          onTrackTap: (idx) => _onTrackTap(
              context, idx, -1, false, tracks, title, author, artUrl),
        );
      },
    );
  }

  void _onTrackTap(
    BuildContext context,
    int idx,
    int currentIdx,
    bool isPlaying,
    List<AudioTrack> tracks,
    String title,
    String author,
    String? artUrl,
  ) {
    final playerCubit = context.read<AudiobookPlayerCubit>();
    if (idx == currentIdx) {
      isPlaying ? playerCubit.pause() : playerCubit.resume();
    } else {
      _play(context, tracks, title, author, artUrl, initialIndex: idx);
    }
  }

  void _play(
    BuildContext context,
    List<AudioTrack> tracks,
    String title,
    String author,
    String? artUrl, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) {
    context.read<AudiobookPlayerCubit>().startPlaying(
          audiobookId: widget.audioId,
          tracks: tracks,
          title: title,
          author: author,
          artUrl: artUrl,
          initialIndex: initialIndex,
          initialPosition: initialPosition,
          isOffline: false,
        );
    context.read<AudiobookBarCubit>().show();
  }
}
