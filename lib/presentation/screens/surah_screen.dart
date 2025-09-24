import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/bismillah_widget.dart';
import 'package:huda/presentation/widgets/surah/surah_loading_state_widget.dart';
import 'package:huda/presentation/widgets/surah/ayah_bottom_sheet_modal_tabbed.dart';
import 'package:huda/presentation/widgets/surah/ayah_number_or_bookmark_widget.dart';

// Import mixins
import 'surah/mixins/audio_manager_mixin.dart';
import 'surah/mixins/download_manager_mixin.dart';
import 'surah/mixins/offline_cache_manager_mixin.dart';
import 'surah/mixins/switch_handlers_mixin.dart';
import 'surah/mixins/modal_manager_mixin.dart';
import 'surah/mixins/state_validators_mixin.dart';
import 'surah/mixins/reading_position_tracker_mixin.dart';

import 'package:huda/core/utils/ui_performance_utils.dart';

class SurahScreen extends StatelessWidget {
  final QuranModel surahInfo;
  final int? scrollToAyah;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;

  const SurahScreen({
    super.key,
    required this.surahInfo,
    this.scrollToAyah,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // This will trigger the dispose method which saves the position
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SurahCubit()..loadSurah(surahInfo.number!),
          ),
          BlocProvider(
            create: (_) => context.read<AudioCubit>()
              ..fetchAudioInfo(surahInfo.number.toString()),
          ),
          BlocProvider(
            create: (_) => TafsirCubit(context.read<TafsirRepository>())
              ..fetchTafsirInfo(),
          ),
          BlocProvider(
            create: (_) =>
                TranslationCubit(context.read<TranslationRepository>())
                  ..fetchTranslationInfo(),
          ),
          BlocProvider(
            create: (_) => BookmarksCubit(
              bookmarkService: getIt<BookmarkService>(),
            ),
          ),
        ],
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(90.h),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          context.darkGradientStart,
                          context.darkGradientMid,
                          context.darkGradientEnd,
                        ]
                      : [
                          context.primaryColor,
                          context.primaryVariantColor,
                          context.primaryLightColor,
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Surah info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              surahInfo.name ?? '',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1.h),
                                    blurRadius: 2.r,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Surah ${surahInfo.number}',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                if (surahInfo.englishName != null)
                                  Flexible(
                                    child: Text(
                                      surahInfo.englishName!,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: BlocBuilder<SurahCubit, SurahState>(
            builder: (context, state) {
              if (state is SurahLoading) {
                return const SurahLoadingStateWidget();
              } else if (state is SurahLoaded) {
                return QuranPageView(
                  surah: state.surah,
                  surahNumber: surahInfo.number!,
                  scrollToAyah: scrollToAyah,
                  ayahPosition: ayahPosition,
                  shouldRestorePosition: shouldRestorePosition,
                  isBookmarkVisit: isBookmarkVisit,
                );
              } else if (state is SurahError) {
                return Center(
                  child: Text(AppLocalizations.of(context)!
                      .unknownError(state.message)),
                );
              } else {
                return Center(
                  child: Text(AppLocalizations.of(context)!.unknownState),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class QuranPageView extends StatefulWidget {
  final SurahModel surah;
  final int surahNumber;
  final int? scrollToAyah;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;

  const QuranPageView({
    super.key,
    required this.surah,
    required this.surahNumber,
    this.scrollToAyah,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
  });

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView>
    with
        AudioManagerMixin,
        DownloadManagerMixin,
        OfflineCacheManagerMixin,
        SwitchHandlersMixin,
        ModalManagerMixin,
        StateValidatorsMixin,
        ReadingPositionTracker {
  // Core audio variables - audioPlayer is provided by AudioManagerMixin
  @override
  int? playingAyahIndex;
  @override
  Duration currentPosition = Duration.zero;
  @override
  Duration totalDuration = Duration.zero;
  @override
  bool isUserSeeking = false;

  // Reader and language selection
  @override
  String? selectedReaderId;
  @override
  String? selectedLanguage;
  List<edition.Data> _availableReaders = [];
  @override
  bool isLoadingAudio = false;
  @override
  audio.SurahAudioModel? currentSurahAudio;

  // Audio controls
  @override
  bool loopEnabled = false;
  @override
  bool autoplayEnabled = true;

  // Connection and offline mode
  @override
  bool isOfflineMode = false;

  // Download states
  @override
  bool isDownloadingSingleAyah = false;
  @override
  bool isDownloadingAllAyahs = false;
  @override
  String downloadProgressText = '';

  // Modal state
  @override
  bool isBottomSheetOpen = false;
  @override
  StateSetter? modalStateSetter;

  // Tafsir variables
  List<edition.Data> _availableTafsirSources = [];
  @override
  String? selectedTafsirId;
  @override
  tafsir.TafsirModel? currentTafsir;
  @override
  bool isLoadingTafsir = false;
  @override
  bool isDownloadingSurahTafsir = false;
  @override
  bool isDownloadingAllTafsir = false;

  // Translation variables
  List<edition.Data> _availableTranslationSources = [];
  @override
  String? selectedTranslationId;
  @override
  String? selectedTranslationLanguage;
  @override
  tafsir.TafsirModel? currentTranslation;
  @override
  bool isLoadingTranslation = false;
  @override
  bool isDownloadingSurahTranslation = false;
  @override
  bool isDownloadingAllTranslation = false;

  // Getter implementations for mixins
  @override
  List<edition.Data> get availableReaders => _availableReaders;

  @override
  SurahModel get surah => widget.surah;

  @override
  List<edition.Data> get availableTafsirSources => _availableTafsirSources;

  @override
  List<edition.Data> get availableTranslationSources =>
      _availableTranslationSources;

  @override
  int get surahNumber => widget.surahNumber;

  @override
  TafsirCubit get tafsirCubit => context.read<TafsirCubit>();

  @override
  TranslationCubit get translationCubit => context.read<TranslationCubit>();

  // Reading position tracker implementations
  @override
  int get currentSurahNumber => widget.surahNumber;

  @override
  int get currentAyahNumber => playingAyahIndex != null
      ? (playingAyahIndex! + 1) // If audio is playing, use that
      : _currentVisibleAyah; // Otherwise use scroll-tracked ayah

  @override
  double get currentScrollPosition {
    // For ScrollablePositionedList, we can estimate position based on visible items
    final visibleItems = _itemPositionsListener.itemPositions.value;
    if (visibleItems.isEmpty) return 0.0;

    // Use the first visible item to estimate scroll position
    final firstVisible = visibleItems
        .where((position) => position.itemLeadingEdge < 1.0)
        .reduce((a, b) => a.index < b.index ? a : b);

    return firstVisible.index.toDouble();
  }

  int? _previousPlayingAyahIndex;

  // Scroll tracking variables
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  int _currentVisibleAyah = 1;

  @override
  void setState(VoidCallback fn) {
    _previousPlayingAyahIndex = playingAyahIndex;
    super.setState(fn);

    // Track reading position when ayah changes, but skip if this is a bookmark visit
    if (!widget.isBookmarkVisit &&
        _previousPlayingAyahIndex != playingAyahIndex &&
        playingAyahIndex != null) {
      updateReadingPosition(
        ayahNumber: playingAyahIndex! + 1, // Convert to 1-based index
        position: 0.0,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    setupAudioListeners();
    checkOfflineStatus();

    // Initialize scroll controller and set up scroll tracking
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _setupScrollTracking();

    // Save initial reading position when user opens a surah
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we need to scroll to a specific ayah from bookmark
      if (widget.scrollToAyah != null) {
        _scrollToBookmarkedAyah();
      } else if (widget.shouldRestorePosition) {
        // Only restore position if explicitly requested (e.g., from "Continue Reading")
        debugPrint(
            '📍 Auto-restoring reading position (Continue Reading flow)');
        _restoreScrollPosition();
      } else {
        debugPrint('🚫 Skipping auto-restore (fresh start from Surah list)');
      }

      // Only set initial position if no saved position exists and not a bookmark visit
      final readingService = getIt<ReadingPositionService>();
      final lastRead = readingService.getLastReadSummary();

      if (!widget.isBookmarkVisit &&
          (lastRead == null || lastRead['surahNumber'] != widget.surahNumber)) {
        debugPrint('🆕 Setting initial reading position for new surah');
        updateReadingPosition(
          ayahNumber: 1,
          position: 0.0,
        );
      } else if (widget.isBookmarkVisit) {
        debugPrint('🔖 Bookmark visit - skipping reading position updates');
      } else {
        debugPrint(
            '🔄 Skipping initial position - will restore saved position');
      }
    });
  }

  @override
  void dispose() {
    // Save final position before disposing
    _saveFinalPosition();
    // ItemScrollController and ItemPositionsListener don't need explicit disposal
    // Don't dispose audioPlayer directly - let AudioManagerMixin handle it
    super.dispose();
  }

  void _saveFinalPosition() {
    // Skip saving position for bookmark visits
    if (widget.isBookmarkVisit) {
      debugPrint('🔖 Bookmark visit ending - not saving position');
      return;
    }

    // The mixin's throttled saves should have already saved the position
    // Just log for verification - don't try to save again as ScrollController may be disposed
    debugPrint('💾 Screen dispose - relying on mixin\'s throttled saves');

    // Verify what was last saved
    Future.delayed(const Duration(milliseconds: 100), () {
      final readingService = getIt<ReadingPositionService>();
      final saved = readingService.getLastReadSummary();
      debugPrint('✅ Verification - Final saved data: $saved');
    });
  }

  void _setupScrollTracking() {
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _restoreScrollPosition() {
    // Check if this surah was previously read and restore position
    final readingService = getIt<ReadingPositionService>();
    final lastRead = readingService.getLastReadSummary();

    debugPrint('🔄 Restoring scroll position for surah ${widget.surahNumber}');
    debugPrint('📖 Last read data: $lastRead');

    if (lastRead != null &&
        lastRead['surahNumber'] == widget.surahNumber &&
        lastRead['ayahNumber'] != null) {
      final savedAyah = lastRead['ayahNumber'] as int? ?? 1;

      debugPrint('📍 Scrolling to saved ayah: $savedAyah');

      // Calculate if we need to account for Bismillah
      final bool showBismillah =
          widget.surah.number != 1 && widget.surah.number != 9;
      final int bismillahOffset = showBismillah ? 1 : 0;
      final int targetIndex = (savedAyah - 1) + bismillahOffset;

      // Wait for the layout to complete, then scroll to saved ayah
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );

          // Update current visible ayah
          _currentVisibleAyah = savedAyah;
          debugPrint('👁️ Current visible ayah set to: $_currentVisibleAyah');
        }
      });
    } else {
      debugPrint('ℹ️ No saved position found for this surah');
    }
  }

  void _onScroll() {
    // Skip scroll tracking for bookmark visits to avoid updating reading position
    if (widget.isBookmarkVisit) {
      return;
    }

    // Throttle scroll events to avoid too frequent updates
    final visibleAyah = _findCurrentVisibleAyah();
    if (visibleAyah != _currentVisibleAyah) {
      final oldAyah = _currentVisibleAyah;
      _currentVisibleAyah = visibleAyah;

      debugPrint('📜 Scroll detected: ayah $oldAyah → $visibleAyah');

      // Update reading position for the visible ayah
      updateReadingPosition(
        ayahNumber: _currentVisibleAyah,
        position: visibleAyah.toDouble(), // Use ayah index as position
      );
    }
  }

  int _findCurrentVisibleAyah() {
    final visibleItems = _itemPositionsListener.itemPositions.value;
    if (visibleItems.isEmpty) return 1;

    // Find the first fully or partially visible item
    final visibleItem = visibleItems
        .where((position) => position.itemLeadingEdge < 1.0)
        .reduce((a, b) => a.index < b.index ? a : b);

    // Add 1 because our list is 0-based but ayah numbers are 1-based
    return visibleItem.index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MultiBlocListener(
      listeners: [
        BlocListener<AudioCubit, AudioState>(
          listener: _handleAudioStateChanges,
        ),
        BlocListener<TafsirCubit, TafsirState>(
          listener: _handleTafsirStateChanges,
        ),
        BlocListener<TranslationCubit, TranslationState>(
          listener: _handleTranslationStateChanges,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF0A0A0A), // Pure black at top
                    const Color(0xFF1A1A1A), // Dark gray-black
                    context.darkGradientStart, // Theme-aware dark gradient
                  ]
                : [
                    const Color(0xFFFFFDF7),
                    const Color(0xFFFFF9E6),
                    const Color(0xFFFFF5D6),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            PageView.builder(
              itemCount: 1,
              itemBuilder: (context, pageIndex) {
                // Calculate if we need Bismillah as first item
                final bool showBismillah =
                    widget.surah.number != 1 && widget.surah.number != 9;
                final int bismillahOffset = showBismillah ? 1 : 0;
                final int totalItems =
                    (widget.surah.ayahs?.length ?? 0) + bismillahOffset;

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: totalItems,
                  padding: EdgeInsets.fromLTRB(
                      12.w,
                      8.h,
                      12.w,
                      // Add extra padding when audio is playing to prevent blocking
                      playingAyahIndex != null ? 120.h : 24.h),
                  itemBuilder: (context, index) {
                    // First item is Bismillah if needed
                    if (showBismillah && index == 0) {
                      return Container(
                        margin: EdgeInsets.fromLTRB(0, 8.h, 0, 8.h),
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).cardColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryColor.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.2
                                    : 0.1,
                              ),
                              blurRadius: 16.r,
                              offset: Offset(0, 6.h),
                            ),
                          ],
                        ),
                        child: const BismillahWidget(),
                      );
                    }

                    // Adjust index for ayahs (subtract bismillah offset)
                    final ayahIndex = index - bismillahOffset;
                    final ayah = widget.surah.ayahs![ayahIndex];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: playingAyahIndex == ayahIndex
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(
                                        0xFF2A1B3D) // Deep purple for playing card
                                    .withValues(alpha: 0.6)
                                : const Color(0xFFE8F5E8))
                            : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(
                                    0xFF1A1A1A) // Dark gray card background
                                : Colors.white),
                        borderRadius: BorderRadius.circular(10.r),
                        border: playingAyahIndex == ayahIndex
                            ? Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? context.accentColor // Theme-aware accent
                                    : context.primaryColor,
                                width: 2,
                              )
                            : Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(
                                        0xFF2A2A2A) // Subtle border for dark cards
                                    : Colors.transparent,
                                width: 1,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: playingAyahIndex == ayahIndex
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? context.accentColor // Theme-aware glow
                                        .withValues(alpha: 0.3)
                                    : context.primaryColor
                                        .withValues(alpha: 0.15))
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF0A0A0A)
                                        .withValues(alpha: 0.5) // Dark shadow
                                    : Colors.black.withValues(alpha: 0.05)),
                            blurRadius:
                                playingAyahIndex == ayahIndex ? 14.r : 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onAyahTap(ayahIndex),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Padding(
                            padding: EdgeInsets.all(14.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Playing indicator (if playing)
                                if (playingAyahIndex == ayahIndex)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? context
                                                .accentColor // Theme-aware accent
                                            : context.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.volume_up,
                                            color: Colors.white,
                                            size: 12.sp,
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            'Playing',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Header with ayah number
                                Row(
                                  children: [
                                    // Decorative Islamic pattern ayah number
                                    Container(
                                      width: 36.w,
                                      height: 36.h,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFF2A2A2A) // Dark gray circle
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? context
                                                  .accentColor // Theme-aware border
                                                  .withValues(alpha: 0.6)
                                              : context.primaryColor
                                                  .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? context
                                                    .accentColor // Theme-aware glow
                                                    .withValues(alpha: 0.2)
                                                : context.primaryColor
                                                    .withValues(alpha: 0.1),
                                            blurRadius: 4.r,
                                            offset: Offset(0, 1.h),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Decorative Islamic pattern background
                                          Center(
                                            child: Container(
                                              width: 30.w,
                                              height: 30.h,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    context.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    context.primaryVariantColor
                                                        .withValues(alpha: 0.1),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          // Ayah number or bookmark icon
                                          AyahNumberOrBookmarkWidget(
                                            surahNumber: widget.surahNumber,
                                            ayahNumber: ayah.numberInSurah ??
                                                (index + 1),
                                            size: 14.sp,
                                            textColor: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? context
                                                    .accentColor // Theme-aware number
                                                : context.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Amiri',
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(width: 10.w),

                                    // Decorative divider
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              context.primaryColor
                                                  .withValues(alpha: 0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16.h),

                                // Ayah text with proper RTL layout
                                SizedBox(
                                  width: double.infinity,
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      (() {
                                        String ayahText = ayah.text ?? '';
                                        final isFirstAyah =
                                            ayah.numberInSurah == 1;
                                        final shouldShowBismillah =
                                            isFirstAyah &&
                                                widget.surah.number != 1 &&
                                                widget.surah.number != 9;

                                        // Remove Bismillah if it exists in the text and we're showing it separately
                                        if (shouldShowBismillah) {
                                          const bismillahText =
                                              'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';
                                          if (ayahText
                                              .trim()
                                              .startsWith(bismillahText)) {
                                            ayahText = ayahText
                                                .trim()
                                                .replaceFirst(bismillahText, '')
                                                .trim();
                                          }
                                        }
                                        return ayahText;
                                      })(),
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontFamily: getQuranFonts(),
                                        fontSize: 20.sp,
                                        color: playingAyahIndex == ayahIndex
                                            ? (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(
                                                    0xFF10B981) // Bright green for playing
                                                : const Color(0xFF2E7D32))
                                            : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(
                                                    0xFFF8FAFC) // Pure white for text
                                                : const Color(0xFF2C3E50)),
                                        height: 2.0,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),

                                // Translation text (if selected)
                                if (selectedTranslationId != null &&
                                    currentTranslation != null)
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(top: 12.h),
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                                  0xFF1E293B) // Dark slate background
                                              .withValues(alpha: 0.8)
                                          : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                    0xFF4C1D95) // Purple border
                                                .withValues(alpha: 0.3)
                                            : const Color(0xFF674B5D)
                                                .withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Translation source label
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.translate,
                                              size: 12.sp,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? context.accentColor
                                                  : context.primaryColor,
                                            ),
                                            SizedBox(width: 3.w),
                                            Expanded(
                                              child: Text(
                                                _getTranslationSourceName(),
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? context.accentColor
                                                      : context.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5.h),
                                        // Translation text
                                        Text(
                                          _getTranslationTextForAyah(index),
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? const Color(
                                                        0xFFE2E8F0) // Light gray text
                                                    .withValues(alpha: 0.9)
                                                : const Color(0xFF2C3E50),
                                            height: 1.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Floating audio controls bar
            if (playingAyahIndex != null && currentSurahAudio != null)
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 16.h, // Slightly higher from bottom
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: playingAyahIndex != null
                      ? Offset.zero
                      : const Offset(0, 1),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                colors.primaryDark,
                                colors.primary,
                              ]
                            : [
                                colors.primary,
                                colors.primaryVariant,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Currently playing info
                        Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Ayah ${playingAyahIndex! + 1} of ${widget.surah.ayahs!.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showAyahBottomSheet(playingAyahIndex!),
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.expand_less,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        // Quick audio controls
                        Row(
                          children: [
                            // Previous
                            IconButton(
                              onPressed: playingAyahIndex! > 0
                                  ? () => _previousAyah()
                                  : null,
                              icon: Icon(
                                Icons.skip_previous,
                                color: playingAyahIndex! > 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                size: 20.sp,
                              ),
                            ),

                            // Play/Pause
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: IconButton(
                                onPressed: () => _togglePlayPause(),
                                icon: Icon(
                                  audioPlayer.state == PlayerState.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: colors.primary,
                                  size: 20.sp,
                                ),
                              ),
                            ),

                            // Next
                            IconButton(
                              onPressed: playingAyahIndex! <
                                      widget.surah.ayahs!.length - 1
                                  ? () => _nextAyah()
                                  : null,
                              icon: Icon(
                                Icons.skip_next,
                                color: playingAyahIndex! <
                                        widget.surah.ayahs!.length - 1
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                size: 20.sp,
                              ),
                            ),

                            const Spacer(),

                            // Progress indicator
                            if (totalDuration.inMilliseconds > 0)
                              Text(
                                '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get translation source name
  String _getTranslationSourceName() {
    if (selectedTranslationId == null) return '';

    final source = _availableTranslationSources.firstWhere(
      (source) => source.identifier == selectedTranslationId,
      orElse: () => edition.Data(),
    );

    return source.name ?? source.englishName ?? 'Translation';
  }

  // Helper method to get translation text for a specific ayah
  String _getTranslationTextForAyah(int ayahIndex) {
    if (currentTranslation == null ||
        currentTranslation!.data == null ||
        currentTranslation!.data!.surahs == null ||
        currentTranslation!.data!.surahs!.isEmpty) {
      return 'Translation not available';
    }

    final surah = currentTranslation!.data!.surahs!.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => tafsir.Surahs(),
    );

    if (surah.ayahs == null || surah.ayahs!.length <= ayahIndex) {
      return 'Translation not available';
    }

    return surah.ayahs![ayahIndex].text ?? 'Translation not available';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Audio control methods for floating audio bar
  void _togglePlayPause() {
    if (audioPlayer.state == PlayerState.playing) {
      audioPlayer.pause();
    } else if (playingAyahIndex != null) {
      playAyahAudio(playingAyahIndex!);
    }
  }

  void _previousAyah() {
    if (playingAyahIndex != null && playingAyahIndex! > 0) {
      final previousIndex = playingAyahIndex! - 1;
      playAyahAudio(previousIndex);
    }
  }

  void _nextAyah() {
    if (playingAyahIndex != null &&
        playingAyahIndex! < widget.surah.ayahs!.length - 1) {
      final nextIndex = playingAyahIndex! + 1;
      playAyahAudio(nextIndex);
    }
  }

  // Implement required methods from mixins
  @override
  void onAyahTap(int index) {
    _showAyahBottomSheet(index);
  }

  @override
  void onReaderInvalidated() {
    selectedReaderId = null;
  }

  @override
  void stopAudioIfPlaying() {
    if (audioPlayer.state == PlayerState.playing) {
      audioPlayer.stop();
    }
  }

  @override
  void resetAudioState() {
    setState(() {
      playingAyahIndex = null;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });
  }

  @override
  Future<List<edition.Data>> getDownloadedReaders() async {
    return await super.getDownloadedReaders();
  }

  // Event handlers for BlocListeners
  void _handleAudioStateChanges(BuildContext context, AudioState state) {
    // Use debouncing to prevent excessive state updates
    UIPerformanceUtils.debounce('audio_state_change', () {
      _processAudioStateChange(state);
    }, const Duration(milliseconds: 100));
  }

  void _processAudioStateChange(AudioState state) {
    if (state is AudioLoaded) {
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];

        // Update audio state when AudioLoaded changes
        if (state.currentSurahAudio != null) {
          currentSurahAudio = state.currentSurahAudio;
          isLoadingAudio = false;
        } else if (selectedReaderId != null) {
          // Reader is selected but no audio yet - keep loading
          currentSurahAudio = null;
          isLoadingAudio = true;
        } else {
          // No reader selected
          currentSurahAudio = null;
          isLoadingAudio = false;
        }
      });
      safeModalSetState();
      checkOfflineStatus();
    } else if (state is AudioOfflineWithDownloads) {
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];
      });
      checkOfflineStatus();
      // Refresh offline cache when offline state changes
      if (!offlineCacheLoaded) {
        preloadOfflineCache();
      }
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];
      });
      checkOfflineStatus();
      // Refresh offline cache when offline state changes
      if (!offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is ReaderOffline) {
      setState(() {
        isLoadingAudio = false;
      });
      checkOfflineStatus();
    } else if (state is SurahAudioLoaded) {
      setState(() {
        currentSurahAudio = state.audioModel;
        isLoadingAudio = false;
      });
      safeModalSetState();
    } else if (state is SurahAudioLoading) {
      setState(() {
        isLoadingAudio = true;
      });
      safeModalSetState();
    } else if (state is DownloadInProgress) {
      setState(() {
        downloadProgressText = '${(state.progress * 100).toInt()}%';
      });
      safeModalSetState();
    } else if (state is DownloadCompleted || state is SurahDownloadCompleted) {
      setState(() {
        downloadProgressText = '';
        isDownloadingSingleAyah = false;
        isDownloadingAllAyahs = false;
      });
      safeModalSetState();
      // Refresh offline cache when new downloads complete
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    }
  }

  void _handleTafsirStateChanges(BuildContext context, TafsirState state) {
    if (state is TafsirLoaded) {
      setState(() {
        _availableTafsirSources = state.tafsirModel.data ?? [];
      });
    } else if (state is TafsirOffline) {
      setState(() {
        _availableTafsirSources = state.tafsirModel.data ?? [];
      });
      // Refresh offline cache when tafsir state changes
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is SurahTafsirLoaded) {
      setState(() {
        currentTafsir = state.tafsirModel;
        isLoadingTafsir = false;
      });
      safeModalSetState();
    } else if (state is SurahTafsirLoading) {
      setState(() {
        isLoadingTafsir = true;
      });
      safeModalSetState();
    } else if (state is TafsirDownloadInProgress) {
      setState(() {
        isDownloadingSurahTafsir = true;
      });
      safeModalSetState();
    } else if (state is TafsirDownloadCompleted) {
      setState(() {
        isDownloadingSurahTafsir = false;
        isDownloadingAllTafsir = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tafsirDownloadSuccess),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh offline cache when new downloads complete
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TafsirError) {
      setState(() {
        isLoadingTafsir = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.tafsirError(state.message)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleTranslationStateChanges(
      BuildContext context, TranslationState state) {
    if (state is TranslationLoaded) {
      setState(() {
        _availableTranslationSources = state.translationModel.data ?? [];
      });
    } else if (state is TranslationOffline) {
      setState(() {
        _availableTranslationSources = state.translationModel.data ?? [];
      });
      // Refresh offline cache when translation state changes
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is SurahTranslationLoaded) {
      setState(() {
        currentTranslation = state.translationModel;
        isLoadingTranslation = false;
      });
      safeModalSetState();
    } else if (state is SurahTranslationLoading) {
      setState(() {
        isLoadingTranslation = true;
      });
      safeModalSetState();
    } else if (state is TranslationDownloadInProgress) {
      setState(() {
        isDownloadingSurahTranslation = true;
      });
      safeModalSetState();
    } else if (state is TranslationDownloadCompleted) {
      setState(() {
        isDownloadingSurahTranslation = false;
        isDownloadingAllTranslation = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.translationDownloadSuccess),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh offline cache when new downloads complete
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TranslationError) {
      setState(() {
        isLoadingTranslation = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translationError(state.message)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAyahBottomSheet(int index) async {
    final ayah = widget.surah.ayahs![index];
    final audioCubit = context.read<AudioCubit>();
    isBottomSheetOpen = true;

    // If in offline mode and cache not loaded, preload it first
    if (isOfflineMode && !offlineCacheLoaded && !isCacheLoading) {
      await preloadOfflineCache();
    }

    // Store the cubit reference before entering the modal context
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        enableDrag: true,
        builder: (modalContext) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (draggableContext, scrollController) {
              return BlocBuilder<AudioCubit, AudioState>(
                bloc: audioCubit, // Use the stored cubit reference
                builder: (blocContext, audioState) {
                  List<edition.Data> allAvailableReaders = [];
                  bool modalIsOfflineMode =
                      isOfflineMode; // Use stored offline mode state
                  String? offlineMessage;

                  if (audioState is AudioLoaded) {
                    allAvailableReaders = audioState.surahAudioModel.data ?? [];
                    modalIsOfflineMode =
                        false; // Online mode when we have AudioLoaded
                    offlineMessage = null; // Clear any offline message
                  } else if (audioState is AudioOfflineWithDownloads) {
                    allAvailableReaders = audioState.surahAudioModel.data ?? [];
                    modalIsOfflineMode = true;
                    // Update stored offline mode
                    if (!isOfflineMode) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            isOfflineMode = true;
                          });
                        }
                      });
                    }
                  } else if (audioState is ReaderOffline) {
                    modalIsOfflineMode = true;
                    if (isCacheLoading) {
                      offlineMessage = 'Loading offline content...';
                    } else if (!offlineCacheLoaded) {
                      offlineMessage = 'Loading offline content...';
                    } else if (cachedDownloadedReaders.isEmpty &&
                        cachedDownloadedTafsirSources.isEmpty &&
                        cachedDownloadedTranslationSources.isEmpty) {
                      offlineMessage =
                          'No internet connection. No offline content available.';
                    }
                    // Update stored offline mode
                    if (!isOfflineMode) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            isOfflineMode = true;
                          });
                        }
                      });
                    }
                  }

                  if (allAvailableReaders.isEmpty && !modalIsOfflineMode) {
                    allAvailableReaders = _availableReaders;
                  }

                  return StatefulBuilder(
                    builder: (modalContext, setModalState) {
                      modalStateSetter = setModalState;

                      // Handle offline mode data loading
                      List<edition.Data> availableReadersForModal;
                      List<edition.Data> availableTafsirForModal;
                      List<edition.Data> availableTranslationForModal;

                      if (modalIsOfflineMode) {
                        if (isCacheLoading) {
                          // Show loading state - use current available data as fallback
                          availableReadersForModal = _availableReaders;
                          availableTafsirForModal = _availableTafsirSources;
                          availableTranslationForModal =
                              _availableTranslationSources;
                          // Ensure loading message is shown
                          if (offlineMessage?.contains('Loading') != true) {
                            offlineMessage = 'Loading offline content...';
                          }
                        } else if (offlineCacheLoaded) {
                          // Use cached data
                          availableReadersForModal = cachedDownloadedReaders;
                          availableTafsirForModal =
                              cachedDownloadedTafsirSources;
                          availableTranslationForModal =
                              cachedDownloadedTranslationSources;
                          // Clear loading message when cache is loaded
                          if (offlineMessage?.contains('Loading') == true) {
                            offlineMessage = null;
                          }
                        } else {
                          // Cache not loaded yet, trigger loading and show fallback
                          preloadOfflineCache();
                          availableReadersForModal = _availableReaders;
                          availableTafsirForModal = _availableTafsirSources;
                          availableTranslationForModal =
                              _availableTranslationSources;
                          offlineMessage = 'Loading offline content...';
                        }
                      } else {
                        // Online mode - use live data
                        availableReadersForModal = allAvailableReaders;
                        availableTafsirForModal = _availableTafsirSources;
                        availableTranslationForModal =
                            _availableTranslationSources;
                      }

                      return AyahBottomSheetModalTabbed(
                        ayah: ayah,
                        index: index,
                        surahNumber: widget.surahNumber,
                        totalAyahs: widget.surah.ayahs?.length ?? 0,
                        surahName: widget.surah.name,
                        surahEnglishName: widget.surah.englishName,
                        audioPlayer: audioPlayer,
                        playingAyahIndex: playingAyahIndex,
                        currentPosition: currentPosition,
                        totalDuration: totalDuration,
                        isUserSeeking: isUserSeeking,
                        selectedReaderId: selectedReaderId,
                        selectedLanguage: selectedLanguage,
                        availableReaders: availableReadersForModal,
                        isLoadingAudio: isLoadingAudio,
                        currentSurahAudio: currentSurahAudio,
                        loopEnabled: loopEnabled,
                        autoplayEnabled: autoplayEnabled,
                        isOfflineMode: modalIsOfflineMode,
                        offlineMessage: offlineMessage,
                        isDownloadingSingle: isDownloadingSingleAyah,
                        isDownloadingAll: isDownloadingAllAyahs,
                        downloadProgressText: downloadProgressText,
                        availableTafsirSources: availableTafsirForModal,
                        selectedTafsirId: selectedTafsirId,
                        currentTafsir: currentTafsir,
                        isLoadingTafsir: isLoadingTafsir,
                        availableTranslationSources:
                            availableTranslationForModal,
                        selectedTranslationId: selectedTranslationId,
                        selectedTranslationLanguage:
                            selectedTranslationLanguage,
                        currentTranslation: currentTranslation,
                        isLoadingTranslation: isLoadingTranslation,
                        onPlayPause: playPauseAudio,
                        onPrevious: (currentIndex) =>
                            skipToPreviousAyah(currentIndex),
                        onNext: (currentIndex) => skipToNextAyah(
                            currentIndex, widget.surah.ayahs?.length ?? 0),
                        onSeek: seekToPosition,
                        onUserSeekingChanged: (seeking) =>
                            setState(() => isUserSeeking = seeking),
                        onReaderSelected: (readerId) =>
                            switchReader(readerId, setModalState),
                        onLanguageSelected: (language) =>
                            switchLanguage(language, setModalState),
                        onLoopChanged: (value) =>
                            setModalState(() => loopEnabled = value ?? false),
                        onAutoplayChanged: (value) => setModalState(
                            () => autoplayEnabled = value ?? true),
                        onDownloadSingle: () =>
                            downloadSingleAyah(index, ayah, setModalState),
                        onDownloadAll: () =>
                            downloadAllSurahAyahs(setModalState),
                        checkAllDownloaded: areAllAyahsDownloaded,
                        checkSingleDownloaded: () =>
                            isSingleAyahDownloaded(index),
                        onTafsirSelected: (tafsirId) =>
                            switchTafsir(tafsirId, setModalState),
                        onTranslationSelected: (translationId) =>
                            switchTranslation(translationId, setModalState),
                        onTranslationLanguageSelected: (language) =>
                            switchTranslationLanguage(language, setModalState),
                        onDownloadTafsir: downloadSurahTafsir,
                        onDownloadFullTafsir: downloadFullQuranTafsir,
                        onDownloadTranslation: downloadSurahTranslation,
                        onDownloadFullTranslation: downloadFullQuranTranslation,
                        isDownloadingSurahTafsir: isDownloadingSurahTafsir,
                        isDownloadingAllTafsir: isDownloadingAllTafsir,
                        isDownloadingSurahTranslation:
                            isDownloadingSurahTranslation,
                        isDownloadingAllTranslation:
                            isDownloadingAllTranslation,
                        checkSurahTafsirDownloaded: isSurahTafsirDownloaded,
                        checkAllTafsirDownloaded: isAllTafsirDownloaded,
                        checkSurahTranslationDownloaded:
                            isSurahTranslationDownloaded,
                        checkAllTranslationDownloaded:
                            isAllTranslationDownloaded,
                        checkCurrentAyahPlayable: () =>
                            isCurrentAyahPlayable(index),
                        getCurrentScrollPosition: () => currentScrollPosition,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ).then((_) => onBottomSheetClosed());
    }
  }

  void _scrollToBookmarkedAyah() {
    final targetAyah = widget.scrollToAyah!;

    debugPrint('🔖 Scrolling to bookmarked ayah $targetAyah');

    // Calculate if we need to account for Bismillah
    final bool showBismillah =
        widget.surah.number != 1 && widget.surah.number != 9;
    final int bismillahOffset = showBismillah ? 1 : 0;
    final int targetIndex = (targetAyah - 1) + bismillahOffset;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );

          // Update current visible ayah
          _currentVisibleAyah = targetAyah;
          debugPrint('✅ Scrolled to bookmarked ayah $targetAyah');
        }
      });
    });
  }
}
