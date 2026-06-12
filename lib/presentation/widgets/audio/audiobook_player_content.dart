import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/presentation/widgets/audio/audiobook_action_bar.dart';
import 'package:huda/presentation/widgets/audio/audiobook_artwork.dart';
import 'package:huda/presentation/widgets/audio/audiobook_chapter_list.dart';
import 'package:huda/presentation/widgets/audio/audiobook_controls.dart';
import 'package:huda/presentation/widgets/audio/audiobook_scrubber.dart';
import 'package:huda/presentation/widgets/audio/audiobook_title.dart';
import 'package:huda/presentation/widgets/audio/audiobook_top_bar.dart';

class AudiobookPlayerContent extends StatefulWidget {
  final AudiobookPlayerPlaying state;
  final bool isDark;

  const AudiobookPlayerContent({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  State<AudiobookPlayerContent> createState() => _AudiobookPlayerContentState();
}

class _AudiobookPlayerContentState extends State<AudiobookPlayerContent> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AudiobookPlayerCubit>();
    final state = widget.state;
    final player = state.audioPlayer;
    final isDark = widget.isDark;

    return SafeArea(
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: AudiobookTopBar(isDark: isDark, isScrolled: _isScrolled),
          ),
          SliverToBoxAdapter(
            child: AudiobookArtwork(
              player: player,
              artUrl: state.artUrl,
              isOffline: state.isOffline,
            ),
          ),
          SliverToBoxAdapter(
            child: AudiobookTitle(
              player: player,
              title: state.title,
              author: state.author,
              tracks: state.tracks,
              isDark: isDark,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: AudiobookScrubber(player: player, onSeek: cubit.seek),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: AudiobookControls(player: player, cubit: cubit),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: AudiobookActionBar(player: player, cubit: cubit),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              indent: 24.w,
              endIndent: 24.w,
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.10),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: AudiobookChapterList(
                tracks: state.tracks,
                player: player,
                cubit: cubit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
