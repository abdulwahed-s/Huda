import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_empty_search_results.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_error_state.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_header_background.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_now_playing_bar.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_search_bar.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_station_card.dart';

class QuranRadioScreen extends StatefulWidget {
  const QuranRadioScreen({super.key});

  @override
  State<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends State<QuranRadioScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollController.hasClients &&
        _scrollController.offset > (180.h - kToolbarHeight);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  void _fetchRadios() {
    final langCode = Localizations.localeOf(context).languageCode;
    context.read<QuranRadioCubit>().fetchRadios(langCode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<QuranRadioCubit>().state;
    if (state is QuranRadioInitial) {
      _fetchRadios();
    }
  }

  Future<void> _playStation(RadioStation station) async {
    try {
      HapticFeedback.selectionClick();
      await context.read<QuranRadioCubit>().playStation(station);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? context.darkGradientStart : context.lightSurface,
      body: BlocBuilder<QuranRadioCubit, QuranRadioState>(
        builder: (context, state) {
          final currentStation =
              state is QuranRadioLoaded ? state.currentlyPlaying : null;
          final isPlaying =
              state is QuranRadioLoaded ? state.isPlaying : false;
          final isBuffering =
              state is QuranRadioLoaded ? state.isBuffering : false;

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(theme, l10n, state),
                  SliverToBoxAdapter(
                    child: RadioSearchBar(
                      controller: _searchController,
                      hintText: l10n.searchRadio,
                      showClearButton: _searchQuery.isNotEmpty,
                      onChanged: (q) => setState(() => _searchQuery = q),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ),
                  _buildBodySliver(
                      state, theme, l10n, currentStation, isPlaying,
                      isBuffering),
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: currentStation != null ? 110.h : 24.h),
                  ),
                ],
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 24.h,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: currentStation != null
                      ? RadioNowPlayingBar(
                          key: const ValueKey('now_playing'),
                          station: currentStation,
                          isPlaying: isPlaying,
                          isBuffering: isBuffering,
                          pulseController: _pulseController,
                          nowPlayingLabel: l10n.nowPlaying,
                          onPlayPause: () => _playStation(currentStation),
                          onStop: () async {
                            await context
                                .read<QuranRadioCubit>()
                                .stopStation();
                          },
                        )
                      : const SizedBox.shrink(key: ValueKey('empty_player')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      ThemeData theme, AppLocalizations l10n, QuranRadioState state) {
    final int? stationCount =
        state is QuranRadioLoaded ? state.radios.length : null;

    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      title: _isCollapsed
          ? Text(
              l10n.quranRadio,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: RadioHeaderBackground(
          title: l10n.quranRadio,
          stationCount: stationCount,
        ),
      ),
    );
  }

  Widget _buildBodySliver(
    QuranRadioState state,
    ThemeData theme,
    AppLocalizations l10n,
    RadioStation? currentStation,
    bool isPlaying,
    bool isBuffering,
  ) {
    if (state is QuranRadioLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (state is QuranRadioError) {
      return SliverFillRemaining(
        child: RadioErrorState(
          message: state.message,
          retryLabel: l10n.checkConnection,
          onRetry: _fetchRadios,
        ),
      );
    }

    if (state is QuranRadioLoaded) {
      final radios = state.radios
          .where((r) => r.name
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();

      if (radios.isEmpty) {
        return SliverFillRemaining(
          child: RadioEmptySearchResults(message: l10n.noResultsFound),
        );
      }

      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final station = radios[index];
              return RadioStationCard(
                station: station,
                isActive: currentStation?.id == station.id,
                isPlaying: isPlaying,
                isBuffering: isBuffering,
                pulseController: _pulseController,
                onTap: () => _playStation(station),
                index: index,
              );
            },
            childCount: radios.length,
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}
