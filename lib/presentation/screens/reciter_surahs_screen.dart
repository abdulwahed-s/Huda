import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/quran/quran.dart' as quran;

import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/reciter_surahs/reciter_sliver_app_bar.dart';
import 'package:huda/presentation/widgets/reciter_surahs/reciter_search_bar_delegate.dart';
import 'package:huda/presentation/widgets/reciter_surahs/surah_empty_state.dart';
import 'package:huda/presentation/widgets/reciter_surahs/surah_card.dart';

class ReciterSurahsScreen extends StatefulWidget {
  final Reciter reciter;
  final Moshaf moshaf;
  final List jsonData;
  final int? initialSurahIndex;
  final int initialPositionMs;

  const ReciterSurahsScreen({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.jsonData,
    this.initialSurahIndex,
    this.initialPositionMs = 0,
  });

  @override
  State<ReciterSurahsScreen> createState() => _ReciterSurahsScreenState();
}

class _ReciterSurahsScreenState extends State<ReciterSurahsScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> surahs;
  List<Map<String, dynamic>> filteredSurahs = [];
  String searchQuery = '';
  String? _downloadDirPath;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _listAnimController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _buildSurahList();
    _loadDownloadDir();
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _scrollController.addListener(_onScroll);
    _autoPlayIfNeeded();
  }

  void _onScroll() {
    final collapsed = _scrollController.hasClients &&
        _scrollController.offset > (190.h - kToolbarHeight);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadDir() async {
    final path = await context.read<QuranPlayerCubit>().getDownloadDirPath();
    if (mounted) setState(() => _downloadDirPath = path);
  }

  void _autoPlayIfNeeded() {
    final index = widget.initialSurahIndex;
    if (index == null || index < 0) return;

    final numbers = widget.moshaf.surahList.toString().split(',');
    if (index >= numbers.length) return;

    final surahNumber = int.parse(numbers[index]);
    context.read<QuranPlayerCubit>().startPlaying(
          moshaf: widget.moshaf,
          reciter: widget.reciter,
          suraNumber: surahNumber,
          initialIndex: index,
          jsonData: widget.jsonData,
          initialPositionMs: widget.initialPositionMs,
        );
    context.read<PlayerBarCubit>().show();
  }

  void _buildSurahList() {
    final numbers = widget.moshaf.surahList.toString().split(',');
    surahs = numbers.map((e) {
      final match = widget.jsonData
          .where((el) => el['id'].toString() == e.toString())
          .toList();
      return {
        'surahNumber': e,
        'suraName': match.isNotEmpty ? match.first['name'] : 'Surah $e',
      };
    }).toList();
    filteredSurahs = List.from(surahs);
  }

  void _filterSurahs(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredSurahs = List.from(surahs);
      } else {
        final normalizedQuery = quran.normalise(query);
        final lowerQuery = query.toLowerCase();
        filteredSurahs = surahs.where((s) {
          final surahNumber = int.tryParse(s['surahNumber'].toString()) ?? 0;
          final arabicName = quran.normalise(s['suraName'].toString());
          final englishName = surahNumber > 0
              ? quran.getSurahNameEnglish(surahNumber).toLowerCase()
              : '';
          return arabicName.contains(normalizedQuery) ||
              englishName.contains(lowerQuery) ||
              s['surahNumber'].toString().contains(query);
        }).toList();
      }
    });
  }

  bool _isDownloaded(String surahNumber) {
    if (_downloadDirPath == null) return false;
    return context.read<QuranPlayerCubit>().isDownloaded(
          widget.reciter,
          widget.moshaf,
          surahNumber,
          _downloadDirPath!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              ReciterSliverAppBar(
                reciter: widget.reciter,
                moshaf: widget.moshaf,
                surahCount: surahs.length,
                theme: theme,
                isCollapsed: _isCollapsed,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: ReciterSearchBarDelegate(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  onClear: () {
                    _searchController.clear();
                    _filterSurahs('');
                  },
                  query: searchQuery,
                  isDark: isDark,
                  theme: theme,
                  l10n: l10n,
                ),
              ),
              _buildSurahSliver(l10n, theme, isDark, isArabic),
              SliverToBoxAdapter(child: SizedBox(height: 90.h)),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlayerBarWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahSliver(
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
    bool isArabic,
  ) {
    return BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
      builder: (context, dlState) {
        if (filteredSurahs.isEmpty) {
          return SurahEmptyState(theme: theme, l10n: l10n);
        }

        return BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
          builder: (context, playerState) {
            if (playerState is QuranPlayerLoading &&
                playerState.reciterId == widget.reciter.id &&
                playerState.moshafId == widget.moshaf.id) {
              return _buildSliverList(l10n, theme, isDark, isArabic, dlState,
                  -1, playerState.initialIndex ?? -1);
            }

            if (playerState is! QuranPlayerPlaying ||
                playerState.reciter.id != widget.reciter.id ||
                playerState.moshaf.id != widget.moshaf.id) {
              return _buildSliverList(
                  l10n, theme, isDark, isArabic, dlState, -1, -1);
            }

            return StreamBuilder<int?>(
              stream: playerState.audioPlayer.currentIndexStream,
              builder: (context, indexSnapshot) {
                final currentIndex = indexSnapshot.data ?? -1;
                return StreamBuilder<PlayerState>(
                  stream: playerState.audioPlayer.playerStateStream,
                  builder: (context, psSnapshot) {
                    final ps = psSnapshot.data?.processingState;
                    final isBuffering = ps == ProcessingState.loading ||
                        ps == ProcessingState.buffering;
                    final loadingIndex =
                        isBuffering && currentIndex >= 0 ? currentIndex : -1;
                    return _buildSliverList(l10n, theme, isDark, isArabic,
                        dlState, currentIndex, loadingIndex);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  SliverList _buildSliverList(
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
    bool isArabic,
    DownloadProgressState dlState,
    int currentPlayingIndex,
    int loadingIndex,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final surah = filteredSurahs[index];
          final surahNum = surah['surahNumber'].toString();
          final intNum = int.parse(surahNum);
          final downloaded = _isDownloaded(surahNum);
          final progress = dlState.getSurahProgress(
              widget.reciter.id, widget.moshaf.id, surahNum);
          final isDownloading = progress != null && progress < 1.0;
          final surahIndex = surahs.indexOf(surah);
          final isPlaying =
              currentPlayingIndex >= 0 && currentPlayingIndex == surahIndex;

          return SurahCard(
            surahNum: surahNum,
            intNum: intNum,
            surahName: surah['suraName'].toString(),
            downloaded: downloaded,
            progress: progress,
            isDownloading: isDownloading,
            isPlaying: isPlaying,
            isLoading: loadingIndex == surahIndex,
            theme: theme,
            isArabic: isArabic,
            l10n: l10n,
            listAnimController: _listAnimController,
            itemIndex: index,
            onPlay: () {
              context.read<QuranPlayerCubit>().startPlaying(
                    moshaf: widget.moshaf,
                    reciter: widget.reciter,
                    suraNumber: intNum,
                    initialIndex: surahIndex,
                    jsonData: widget.jsonData,
                  );
              context.read<PlayerBarCubit>().show();
            },
            onDownload: () {
              context.read<QuranPlayerCubit>().downloadSurah(
                    reciter: widget.reciter,
                    moshaf: widget.moshaf,
                    suraNumber: surahNum,
                    url:
                        '${widget.moshaf.server}/${surahNum.padLeft(3, "0")}.mp3',
                  );
            },
          );
        },
        childCount: filteredSurahs.length,
      ),
    );
  }
}
