import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/bismillah_widget.dart';
import 'package:huda/presentation/widgets/surah/ayah_bottom_sheet_modal_tabbed.dart';
import 'package:huda/presentation/widgets/surah/ayah_number_or_bookmark_widget.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/presentation/widgets/surah/animated_listening_waves.dart';
import 'package:huda/presentation/widgets/surah/memorization_completed_dialog.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/quran/quran.dart' as quran;

import '../../../core/mixins/surah/audio_manager_mixin.dart';
import '../../../core/mixins/surah/download_manager_mixin.dart';
import '../../../core/mixins/surah/offline_cache_manager_mixin.dart';
import '../../../core/mixins/surah/switch_handlers_mixin.dart';
import '../../../core/mixins/surah/modal_manager_mixin.dart';
import '../../../core/mixins/surah/state_validators_mixin.dart';
import '../../../core/mixins/surah/reading_position_tracker_mixin.dart';

import 'package:huda/core/utils/ui_performance_utils.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class QuranPageView extends StatefulWidget {
  final SurahModel surah;
  final int surahNumber;
  final int? scrollToAyah;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;
  final Color? customBgColor;
  final Color? customTextColor;

  const QuranPageView({
    super.key,
    required this.surah,
    required this.surahNumber,
    this.scrollToAyah,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
    this.customBgColor,
    this.customTextColor,
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
  @override
  int? playingAyahIndex;
  @override
  Duration currentPosition = Duration.zero;
  @override
  Duration totalDuration = Duration.zero;
  @override
  bool isUserSeeking = false;

  @override
  String? selectedReaderId;
  @override
  String? selectedLanguage;
  List<edition.Data> _availableReaders = [];
  @override
  bool isLoadingAudio = false;
  @override
  audio.SurahAudioModel? currentSurahAudio;

  @override
  bool loopEnabled = false;
  @override
  bool autoplayEnabled = true;

  @override
  bool isOfflineMode = false;

  @override
  bool isDownloadingSingleAyah = false;
  @override
  bool isDownloadingAllAyahs = false;
  @override
  String downloadProgressText = '';

  @override
  bool isBottomSheetOpen = false;
  @override
  StateSetter? modalStateSetter;

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

  @override
  int get currentSurahNumber => widget.surahNumber;

  @override
  int get currentAyahNumber =>
      playingAyahIndex != null ? (playingAyahIndex! + 1) : _currentVisibleAyah;

  @override
  double get currentScrollPosition {
    final visibleItems = _itemPositionsListener.itemPositions.value;
    if (visibleItems.isEmpty) return 0.0;

    final firstVisible = visibleItems
        .where((position) => position.itemLeadingEdge < 1.0)
        .reduce((a, b) => a.index < b.index ? a : b);

    return firstVisible.index.toDouble();
  }

  int? _previousPlayingAyahIndex;

  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  int _currentVisibleAyah = 1;

  @override
  void setState(VoidCallback fn) {
    _previousPlayingAyahIndex = playingAyahIndex;
    super.setState(fn);

    if (!widget.isBookmarkVisit &&
        _previousPlayingAyahIndex != playingAyahIndex &&
        playingAyahIndex != null) {
      updateReadingPosition(
        ayahNumber: playingAyahIndex! + 1,
        position: 0.0,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    setupAudioListeners();
    checkOfflineStatus();
    _syncSourcesFromCubits();

    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _setupScrollTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToAyah != null) {
        _scrollToBookmarkedAyah();
      } else if (widget.shouldRestorePosition) {
        debugPrint(
            '📍 Auto-restoring reading position (Continue Reading flow)');
        _restoreScrollPosition();
      } else {
        debugPrint('🚫 Skipping auto-restore (fresh start from Surah list)');
      }

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

  void _syncSourcesFromCubits() {
    final tafsirSources = context.read<TafsirCubit>().lastKnownSources;
    final translationSources =
        context.read<TranslationCubit>().lastKnownSources;
    final audioReaders = context.read<AudioCubit>().lastKnownReaders;

    if (_availableTafsirSources.isEmpty && tafsirSources.isNotEmpty) {
      _availableTafsirSources = tafsirSources;
    }
    if (_availableTranslationSources.isEmpty && translationSources.isNotEmpty) {
      _availableTranslationSources = translationSources;
    }
    if (_availableReaders.isEmpty && audioReaders.isNotEmpty) {
      _availableReaders = audioReaders;
    }
  }

  @override
  void dispose() {
    _saveFinalPosition();

    super.dispose();
  }

  void _saveFinalPosition() {
    if (widget.isBookmarkVisit) {
      debugPrint('🔖 Bookmark visit ending - not saving position');
      return;
    }

    debugPrint('💾 Screen dispose - relying on mixin\'s throttled saves');

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
    final readingService = getIt<ReadingPositionService>();
    final lastRead = readingService.getLastReadSummary();

    debugPrint('🔄 Restoring scroll position for surah ${widget.surahNumber}');
    debugPrint('📖 Last read data: $lastRead');

    if (lastRead != null &&
        lastRead['surahNumber'] == widget.surahNumber &&
        lastRead['ayahNumber'] != null) {
      final savedAyah = lastRead['ayahNumber'] as int? ?? 1;

      debugPrint('📍 Scrolling to saved ayah: $savedAyah');

      final bool showBismillah =
          widget.surah.number != 1 && widget.surah.number != 9;
      final int bismillahOffset = showBismillah ? 1 : 0;
      final int targetIndex = (savedAyah - 1) + bismillahOffset;

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );

          _currentVisibleAyah = savedAyah;
          debugPrint('👁️ Current visible ayah set to: $_currentVisibleAyah');
        }
      });
    } else {
      debugPrint('ℹ️ No saved position found for this surah');
    }
  }

  void _onScroll() {
    if (widget.isBookmarkVisit) {
      return;
    }

    final visibleAyah = _findCurrentVisibleAyah();
    if (visibleAyah != _currentVisibleAyah) {
      final oldAyah = _currentVisibleAyah;
      _currentVisibleAyah = visibleAyah;

      debugPrint('📜 Scroll detected: ayah $oldAyah → $visibleAyah');

      updateReadingPosition(
        ayahNumber: _currentVisibleAyah,
        position: visibleAyah.toDouble(),
      );
    }
  }

  int _findCurrentVisibleAyah() {
    final visibleItems = _itemPositionsListener.itemPositions.value;
    if (visibleItems.isEmpty) return 1;

    final visibleItem = visibleItems
        .where((position) => position.itemLeadingEdge < 1.0)
        .reduce((a, b) => a.index < b.index ? a : b);

    return visibleItem.index + 1;
  }

  String _getAyahText(Ayahs ayah) {
    String ayahText = ayah.text ?? '';
    final isFirstAyah = ayah.numberInSurah == 1;
    final shouldShowBismillah =
        isFirstAyah && widget.surah.number != 1 && widget.surah.number != 9;

    if (shouldShowBismillah) {
      const bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      if (ayahText.trim().startsWith(bismillahText)) {
        ayahText = ayahText.trim().replaceFirst(bismillahText, '').trim();
      }
    }
    return ayahText;
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
        BlocListener<MemorizationCubit, MemorizationState>(
          listener: (context, state) {
            if (state is MemorizationCompleted) {
              showDialog(
                context: context,
                builder: (context) => const MemorizationCompletedDialog(),
              );
            }
          },
        ),
      ],
      child: Container(
        decoration: widget.customBgColor != null
            ? BoxDecoration(color: widget.customBgColor)
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF0A0A0A),
                          const Color(0xFF1A1A1A),
                          context.darkGradientStart,
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
            PageView.builder(
              itemCount: 1,
              itemBuilder: (context, pageIndex) {
                final bool showBismillah =
                    widget.surah.number != 1 && widget.surah.number != 9;
                final int bismillahOffset = showBismillah ? 1 : 0;
                final int totalItems =
                    (widget.surah.ayahs?.length ?? 0) + bismillahOffset;

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: totalItems + 1,
                  padding: EdgeInsets.fromLTRB(
                    12.w,
                    8.h,
                    12.w,
                    (playingAyahIndex != null ? 120.h : 24.h) +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  itemBuilder: (context, index) {
                    if (index == totalItems) {
                      return _buildBottomNavigationRow(context);
                    }

                    if (showBismillah && index == 0) {
                      return Container(
                        margin: EdgeInsets.fromLTRB(0, 8.h, 0, 8.h),
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        decoration: BoxDecoration(
                          color: widget.customBgColor != null
                              ? (widget.customBgColor!.computeLuminance() > 0.5
                                  ? Color.lerp(
                                      widget.customBgColor, Colors.black, 0.04)!
                                  : Color.lerp(widget.customBgColor,
                                      Colors.white, 0.08)!)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).cardColor
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16.r),
                          border: widget.customTextColor != null
                              ? Border.all(
                                  color: widget.customTextColor!
                                      .withValues(alpha: 0.1),
                                  width: 1,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: widget.customBgColor != null
                                  ? Colors.black.withValues(alpha: 0.08)
                                  : context.primaryColor.withValues(
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
                        child: BismillahWidget(
                          customTextColor: widget.customTextColor,
                        ),
                      );
                    }

                    final ayahIndex = index - bismillahOffset;
                    final ayah = widget.surah.ayahs![ayahIndex];

                    return BlocBuilder<MemorizationCubit, MemorizationState>(
                      builder: (context, memState) {
                        final isMemorizationMode =
                            memState is MemorizationModeUpdated &&
                                memState.isMemorizationMode;
                        final isHidden = isMemorizationMode &&
                            memState.hiddenAyahIndices.contains(ayahIndex);
                        final isListening =
                            isMemorizationMode && memState.isListening;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(bottom: 10.h),
                          decoration: BoxDecoration(
                            color: playingAyahIndex == ayahIndex
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2A1B3D)
                                        .withValues(alpha: 0.6)
                                    : const Color(0xFFE8F5E8))
                                : (widget.customBgColor != null
                                    ? (widget.customBgColor!
                                                .computeLuminance() >
                                            0.5
                                        ? Color.lerp(widget.customBgColor,
                                            Colors.black, 0.04)!
                                        : Color.lerp(widget.customBgColor,
                                            Colors.white, 0.08)!)
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white)),
                            borderRadius: BorderRadius.circular(10.r),
                            border: playingAyahIndex == ayahIndex
                                ? Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? context.accentColor
                                        : context.primaryColor,
                                    width: 2,
                                  )
                                : Border.all(
                                    color: widget.customTextColor != null
                                        ? widget.customTextColor!
                                            .withValues(alpha: 0.1)
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.transparent),
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: playingAyahIndex == ayahIndex
                                    ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? context.accentColor
                                            .withValues(alpha: 0.3)
                                        : context.primaryColor
                                            .withValues(alpha: 0.15))
                                    : (widget.customBgColor != null
                                        ? Colors.black.withValues(alpha: 0.08)
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF0A0A0A)
                                                .withValues(alpha: 0.5)
                                            : Colors.black
                                                .withValues(alpha: 0.05))),
                                blurRadius:
                                    playingAyahIndex == ayahIndex ? 14.r : 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (isHidden) {
                                  context
                                      .read<MemorizationCubit>()
                                      .startListening();
                                } else {
                                  onAyahTap(ayahIndex);
                                }
                              },
                              borderRadius: BorderRadius.circular(10.r),
                              child: Padding(
                                padding: EdgeInsets.all(14.r),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? context.accentColor
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
                                    Row(
                                      children: [
                                        Container(
                                          width: 36.w,
                                          height: 36.h,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF2A2A2A)
                                                    : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? context.accentColor
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
                                                    ? context.accentColor
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
                                              Center(
                                                child: Container(
                                                  width: 30.w,
                                                  height: 30.h,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        context.primaryColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                        context
                                                            .primaryVariantColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                              AyahNumberOrBookmarkWidget(
                                                surahNumber: widget.surahNumber,
                                                ayahNumber:
                                                    ayah.numberInSurah ??
                                                        (index + 1),
                                                size: 14.sp,
                                                textColor: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? context.accentColor
                                                    : context.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Amiri',
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
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
                                    if (isHidden)
                                      AnimatedListeningWaves(
                                        isListening: isListening,
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text(
                                            _getAyahText(ayah),
                                            textAlign: TextAlign.right,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              fontFamily: getQuranFonts(),
                                              fontSize: 20.sp,
                                              color: playingAyahIndex ==
                                                      ayahIndex
                                                  ? (Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF2E7D32))
                                                  : (widget.customTextColor ??
                                                      (Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? const Color(
                                                              0xFFF8FAFC)
                                                          : const Color(
                                                              0xFF2C3E50))),
                                              height: 2.0,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (selectedTranslationId != null &&
                                        currentTranslation != null)
                                      Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(top: 12.h),
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF1E293B)
                                                  .withValues(alpha: 0.8)
                                              : const Color(0xFFF8F9FA),
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF4C1D95)
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
                                                          : context
                                                              .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              _getTranslationTextForAyah(index),
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFFE2E8F0)
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
                );
              },
            ),
            if (playingAyahIndex != null && currentSurahAudio != null)
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 16.h,
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
                        Row(
                          children: [
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
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: IconButton(
                                onPressed: () => _togglePlayPause(),
                                icon: Icon(
                                  isAudioPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: colors.primary,
                                  size: 20.sp,
                                ),
                              ),
                            ),
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

  String _getTranslationSourceName() {
    if (selectedTranslationId == null) return '';

    final source = _availableTranslationSources.firstWhere(
      (source) => source.identifier == selectedTranslationId,
      orElse: () => edition.Data(),
    );

    return source.name ?? source.englishName ?? 'Translation';
  }

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

  void _togglePlayPause() {
    if (isAudioPlaying) {
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
    if (isAudioPlaying) {
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

  void _handleAudioStateChanges(BuildContext context, AudioState state) {
    UIPerformanceUtils.debounce('audio_state_change', () {
      _processAudioStateChange(state);
    }, const Duration(milliseconds: 100));
  }

  void _processAudioStateChange(AudioState state) {
    if (state is AudioLoaded) {
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];

        if (state.currentSurahAudio != null) {
          currentSurahAudio = state.currentSurahAudio;
          isLoadingAudio = false;
        } else if (selectedReaderId != null) {
          currentSurahAudio = null;
          isLoadingAudio = true;
        } else {
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

      if (!offlineCacheLoaded) {
        preloadOfflineCache();
      }
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];
      });
      checkOfflineStatus();

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

      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TafsirOfflineNoContent) {
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
      HudaSnackBar.success(
        context,
        message: AppLocalizations.of(context)!.tafsirDownloadSuccess,
      );

      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TafsirError) {
      setState(() {
        isLoadingTafsir = false;
      });
      safeModalSetState();
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.tafsirError(state.message),
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

      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TranslationOfflineNoContent) {
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
      HudaSnackBar.success(
        context,
        message: AppLocalizations.of(context)!.translationDownloadSuccess,
      );

      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TranslationError) {
      setState(() {
        isLoadingTranslation = false;
      });
      safeModalSetState();
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.translationError(state.message),
      );
    }
  }

  void _showAyahBottomSheet(int index) async {
    final ayah = widget.surah.ayahs![index];
    final audioCubit = context.read<AudioCubit>();
    final memorizationCubit = context.read<MemorizationCubit>();
    final surahCubit = context.read<SurahCubit>();
    isBottomSheetOpen = true;

    if (isOfflineMode && !offlineCacheLoaded && !isCacheLoading) {
      await preloadOfflineCache();
    }

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
                bloc: audioCubit,
                builder: (blocContext, audioState) {
                  List<edition.Data> allAvailableReaders = [];
                  bool modalIsOfflineMode = isOfflineMode;
                  String? offlineMessage;

                  if (audioState is AudioLoaded) {
                    allAvailableReaders = audioState.surahAudioModel.data ?? [];
                    modalIsOfflineMode = false;
                    offlineMessage = null;
                  } else if (audioState is AudioOfflineWithDownloads) {
                    allAvailableReaders = audioState.surahAudioModel.data ?? [];
                    modalIsOfflineMode = true;

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
                          AppLocalizations.of(context)!.offlineAudioUnavailable;
                    }

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

                      List<edition.Data> availableReadersForModal;
                      List<edition.Data> availableTafsirForModal;
                      List<edition.Data> availableTranslationForModal;

                      if (modalIsOfflineMode) {
                        if (isCacheLoading) {
                          availableReadersForModal = _availableReaders;
                          availableTafsirForModal = _availableTafsirSources;
                          availableTranslationForModal =
                              _availableTranslationSources;

                          if (offlineMessage?.contains('Loading') != true) {
                            offlineMessage = 'Loading offline content...';
                          }
                        } else if (offlineCacheLoaded) {
                          availableReadersForModal = cachedDownloadedReaders;
                          availableTafsirForModal =
                              cachedDownloadedTafsirSources;
                          availableTranslationForModal =
                              cachedDownloadedTranslationSources;

                          if (offlineMessage?.contains('Loading') == true) {
                            offlineMessage = null;
                          }
                        } else {
                          preloadOfflineCache();
                          availableReadersForModal = _availableReaders;
                          availableTafsirForModal = _availableTafsirSources;
                          availableTranslationForModal =
                              _availableTranslationSources;
                          offlineMessage = 'Loading offline content...';
                        }
                      } else {
                        availableReadersForModal = allAvailableReaders;
                        availableTafsirForModal = _availableTafsirSources;
                        availableTranslationForModal =
                            _availableTranslationSources;
                      }

                      return MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: memorizationCubit),
                          BlocProvider.value(value: surahCubit),
                        ],
                        child: AyahBottomSheetModalTabbed(
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
                              switchTranslationLanguage(
                                  language, setModalState),
                          onDownloadTafsir: downloadSurahTafsir,
                          onDownloadFullTafsir: downloadFullQuranTafsir,
                          onDownloadTranslation: downloadSurahTranslation,
                          onDownloadFullTranslation:
                              downloadFullQuranTranslation,
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
                        ),
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

          _currentVisibleAyah = targetAyah;
          debugPrint('✅ Scrolled to bookmarked ayah $targetAyah');
        }
      });
    });
  }

  Widget _buildBottomNavigationRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final int currentSurahNumber = widget.surahNumber;
    final int nextSurahNumber = currentSurahNumber + 1;
    final int previousSurahNumber = currentSurahNumber - 1;

    final String nextSurahName =
        nextSurahNumber <= 114 ? quran.getSurahNameArabic(nextSurahNumber) : '';
    final String previousSurahName = previousSurahNumber >= 1
        ? quran.getSurahNameArabic(previousSurahNumber)
        : '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color buttonBgColor = widget.customBgColor != null
        ? (widget.customBgColor!.computeLuminance() > 0.5
            ? Color.lerp(widget.customBgColor, Colors.black, 0.04)!
            : Color.lerp(widget.customBgColor, Colors.white, 0.08)!)
        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));

    Color textColor =
        widget.customTextColor ?? (isDark ? Colors.white : Colors.black87);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: nextSurahNumber <= 114
                  ? _buildNavigationButton(
                      context,
                      title: nextSurahName,
                      subtitle: l10n.nextSurah,
                      icon: Icons.arrow_back_ios_new_rounded,
                      isLeftButton: false,
                      onTap: () {
                        final nextSurah = QuranModel(
                          number: nextSurahNumber,
                          name: nextSurahName,
                          englishName: quran.getSurahName(nextSurahNumber),
                        );
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoute.surahScreen,
                          arguments: {
                            'surahInfo': nextSurah,
                            'scrollToAyah': null,
                            'shouldRestorePosition': false,
                          },
                        );
                      },
                      bgColor: buttonBgColor,
                      textColor: textColor,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 3,
              child: _buildNavigationButton(
                context,
                title: '',
                subtitle: l10n.scrollToTop,
                icon: Icons.keyboard_arrow_up_rounded,
                isCenter: true,
                onTap: () {
                  _itemScrollController.scrollTo(
                    index: 0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                bgColor: buttonBgColor,
                textColor: textColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 5,
              child: previousSurahNumber >= 1
                  ? _buildNavigationButton(
                      context,
                      title: previousSurahName,
                      subtitle: l10n.previousSurah,
                      icon: Icons.arrow_forward_ios_rounded,
                      isLeftButton: true,
                      onTap: () {
                        final prevSurah = QuranModel(
                          number: previousSurahNumber,
                          name: previousSurahName,
                          englishName: quran.getSurahName(previousSurahNumber),
                        );
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoute.surahScreen,
                          arguments: {
                            'surahInfo': prevSurah,
                            'scrollToAyah': null,
                            'shouldRestorePosition': false,
                          },
                        );
                      },
                      bgColor: buttonBgColor,
                      textColor: textColor,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
    bool isCenter = false,
    bool isLeftButton = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        splashColor: textColor.withValues(alpha: 0.13),
        highlightColor: textColor.withValues(alpha: 0.07),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCenter) ...[
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: textColor.withValues(alpha: 0.65),
                    size: 22.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textColor.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: isLeftButton
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isLeftButton)
                      Icon(icon,
                          color: textColor.withValues(alpha: 0.4), size: 11.sp),
                    if (!isLeftButton) SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textColor.withValues(alpha: 0.5),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign:
                            isLeftButton ? TextAlign.end : TextAlign.start,
                      ),
                    ),
                    if (isLeftButton) SizedBox(width: 4.w),
                    if (isLeftButton)
                      Icon(icon,
                          color: textColor.withValues(alpha: 0.4), size: 11.sp),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
