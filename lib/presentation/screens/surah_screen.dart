import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/surah_screen_settings_service.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/mushaf_interactive_wrapper.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/presentation/widgets/surah/quran_page_view.dart';
import 'package:huda/presentation/widgets/surah/surah_loading_state_widget.dart';
import 'package:huda/presentation/widgets/surah/khatma_tab_content.dart';
import 'package:huda/presentation/widgets/surah/memorization_stop_fab.dart';
import 'package:huda/presentation/widgets/surah/memorization_tab_content.dart';
import 'package:huda/presentation/widgets/surah/settings_tab.dart';
import 'package:huda/presentation/widgets/surah/sheet_drag_handle.dart';
import 'package:huda/presentation/widgets/surah/sheet_tab_bar.dart';
import 'package:huda/presentation/widgets/surah/surah_index_tab.dart';
import 'package:huda/presentation/widgets/surah/surah_screen_app_bar.dart';

class SurahScreen extends StatefulWidget {
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
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> with WidgetsBindingObserver {
  QuranReadingMode _readingMode = QuranReadingMode.scrollList;
  HorizontalPageDisplayMode _horizontalDisplayMode =
      HorizontalPageDisplayMode.normal;
  MushafFlipDirection _mushafFlipDirection = MushafFlipDirection.horizontal;

  Color? _customBgColor;
  Color? _customTextColor;
  String _quranFont = 'Amiri';
  late final SurahScreenSettingsService _settingsService;

  int _currentMushafPage = 1;

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<SurahScreenSettingsService>();
    _loadSavedMode();
    _loadCustomisation();
    _currentMushafPage = _initialMushafPage();

    if (!widget.isBookmarkVisit && !widget.shouldRestorePosition) {
      getIt<ReadingPositionService>().saveReadingPosition(
        surahNumber: widget.surahInfo.number ?? 1,
        ayahNumber: widget.scrollToAyah ?? 1,
        position: 0.0,
      );
    }

    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    WakelockPlus.disable();
    super.dispose();
  }

  int _initialMushafPage() {
    final surahNumber = widget.surahInfo.number ?? 1;
    try {
      if (widget.shouldRestorePosition) {
        final readingService = getIt<ReadingPositionService>();
        final lastRead = readingService.getLastReadSummary();
        if (lastRead != null &&
            lastRead['surahNumber'] == surahNumber &&
            lastRead['ayahNumber'] != null) {
          final savedAyah = lastRead['ayahNumber'] as int;
          return quran.getPageNumber(surahNumber, savedAyah);
        }
      }
      final ayah = widget.scrollToAyah ?? 1;
      return quran.getPageNumber(surahNumber, ayah);
    } catch (_) {
      return 1;
    }
  }

  void _onMushafPageChanged(int page) {
    _currentMushafPage = page;

    if (widget.isBookmarkVisit) return;

    try {
      final pageData = quran.getPageData(page);
      if (pageData.isNotEmpty) {
        final surahNum = pageData[0]['surah'] as int;
        final startAyah = pageData[0]['start'] as int;

        getIt<ReadingPositionService>().updatePositionForSurah(
          surahNumber: surahNum,
          ayahNumber: startAyah,
          position: 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error saving Mushaf page position: $e');
    }
  }

  void _loadSavedMode() {
    final cache = getIt<CacheHelper>();
    final saved = cache.getData(key: QuranReadingMode.key) as String?;
    final mode = QuranReadingMode.fromStorageValue(saved);
    final savedDisplay =
        cache.getData(key: HorizontalPageDisplayMode.key) as String?;
    final displayMode =
        HorizontalPageDisplayMode.fromStorageValue(savedDisplay);
    final savedFlip = cache.getData(key: MushafFlipDirection.key) as String?;
    final flipMode = MushafFlipDirection.fromStorageValue(savedFlip);
    setState(() {
      _readingMode = mode;
      _horizontalDisplayMode = displayMode;
      _mushafFlipDirection = flipMode;
    });
  }

  void _loadCustomisation() {
    _customBgColor = _settingsService.getBackgroundColor();
    _customTextColor = _settingsService.getTextColor();
    _quranFont = getQuranFonts();
  }

  void _setMode(QuranReadingMode mode) {
    setState(() => _readingMode = mode);
    getIt<CacheHelper>().saveData(
      key: QuranReadingMode.key,
      value: mode.storageValue,
    );
  }

  void _setHorizontalDisplayMode(HorizontalPageDisplayMode displayMode) {
    setState(() => _horizontalDisplayMode = displayMode);
    getIt<CacheHelper>().saveData(
      key: HorizontalPageDisplayMode.key,
      value: displayMode.storageValue,
    );
  }

  void _setMushafFlipDirection(MushafFlipDirection direction) {
    setState(() => _mushafFlipDirection = direction);
    getIt<CacheHelper>().saveData(
      key: MushafFlipDirection.key,
      value: direction.storageValue,
    );
  }

  void _showTabsSheet(BuildContext context, {int initialTab = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? context.primaryLightColor : context.primaryColor;
    final memorizationCubit = context.read<MemorizationCubit>();
    final l = AppLocalizations.of(context)!;

    final visibleSurahs = _getVisibleSurahs(context);
    final selectedSurah = visibleSurahs.isNotEmpty
        ? visibleSurahs.first
        : (widget.surahInfo.number ?? 1);
    final rowIndex = (selectedSurah - 1) ~/ 3;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32.w - 24.w) / 3;
    final itemHeight = itemWidth / 2.2;
    final rowHeight = itemHeight + 12.h;
    double initialOffset = rowIndex * rowHeight - rowHeight * 1.5;
    if (initialOffset < 0) initialOffset = 0;

    final gridScrollController =
        ScrollController(initialScrollOffset: initialOffset);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return BlocProvider.value(
          value: memorizationCubit,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DefaultTabController(
              length: 4,
              initialIndex: initialTab,
              child: StatefulBuilder(
                builder: (sheetCtx, setSheetState) {
                  return Container(
                    height: MediaQuery.of(sheetCtx).size.height * 0.92,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141414)
                          : const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        SheetDragHandle(isDark: isDark),
                        SizedBox(height: 10.h),
                        Expanded(
                          child: TabBarView(
                            children: [
                              SurahIndexTab(
                                isDark: isDark,
                                accent: accent,
                                visibleSurahs: visibleSurahs,
                                scrollController: gridScrollController,
                                onSurahSelected: (surahNumber) =>
                                    _navigateToSurah(surahNumber, sheetCtx),
                                onCurrentSurahTapped: () =>
                                    Navigator.pop(sheetCtx),
                              ),
                              KhatmaTabContent(
                                isDark: isDark,
                                title: l.khatmaLegendKhatma,
                              ),
                              SettingsTab(
                                isDark: isDark,
                                accent: accent,
                                readingMode: _readingMode,
                                horizontalDisplayMode: _horizontalDisplayMode,
                                mushafFlipDirection: _mushafFlipDirection,
                                quranFont: _quranFont,
                                fontOptions: _fontOptions,
                                qcf4FontService:
                                    getIt<QcfFontService>(instanceName: 'qcf4'),
                                tajweedFontService: getIt<QcfFontService>(
                                    instanceName: 'tajweed'),
                                onReadingModeTap:
                                    (mode, fontService, requiresFonts) =>
                                        _handleReadingModeSelection(
                                  mode: mode,
                                  fontService: fontService,
                                  requiresFonts: requiresFonts,
                                  sheetCtx: sheetCtx,
                                  setSheetState: setSheetState,
                                ),
                                onHorizontalDisplayModeSelected: (dm) {
                                  setSheetState(() {});
                                  _setHorizontalDisplayMode(dm);
                                },
                                onMushafFlipDirectionSelected: (fd) {
                                  setSheetState(() {});
                                  _setMushafFlipDirection(fd);
                                },
                                onFontSelected: (family) {
                                  setSheetState(() {});
                                  setState(() => _quranFont = family);
                                  setQuranFonts(family);
                                },
                              ),
                              MemorizationTabContent(
                                isDark: isDark,
                                accent: accent,
                                onStart: () => _startMemorization(sheetCtx),
                                onStop: () => _stopMemorization(sheetCtx),
                              ),
                            ],
                          ),
                        ),
                        SurahSheetTabBar(
                          isDark: isDark,
                          accent: accent,
                          surahsLabel: l.surahsLabel,
                          khatmaLabel: l.khatmaLegendKhatma,
                          settingsLabel: l.settings,
                          memorizationLabel: l.tabMemorization,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToSurah(int surahNumber, BuildContext sheetCtx) {
    getIt<ReadingPositionService>().saveReadingPosition(
      surahNumber: surahNumber,
      ayahNumber: 1,
      position: 0.0,
    );
    Navigator.pop(sheetCtx);
    Navigator.pushReplacementNamed(
      context,
      AppRoute.surahScreen,
      arguments: {
        'surahInfo': QuranModel(
          number: surahNumber,
          name: quran.getSurahNameArabic(surahNumber),
          englishName: quran.getSurahNameEnglish(surahNumber),
        ),
        'shouldRestorePosition': false,
        'scrollToAyah': 1,
      },
    );
  }

  void _handleReadingModeSelection({
    required QuranReadingMode mode,
    required QcfFontService? fontService,
    required bool requiresFonts,
    required BuildContext sheetCtx,
    required StateSetter setSheetState,
  }) {
    final fontsReady = fontService?.areFontsReady ?? true;
    final previouslyDownloaded = fontService?.wasPreviouslyDownloaded ?? false;
    final currentStatus = fontService?.currentState.status;
    final fontsBeingProcessed = currentStatus == QcfFontStatus.downloading ||
        currentStatus == QcfFontStatus.extracting ||
        currentStatus == QcfFontStatus.loading;

    if (!requiresFonts || fontsReady) {
      Navigator.pop(sheetCtx);
      _setMode(mode);
    } else if (previouslyDownloaded) {
      fontService!.stateStream
          .firstWhere((s) => s.status == QcfFontStatus.ready)
          .then((_) {
        if (Navigator.of(sheetCtx).canPop()) Navigator.pop(sheetCtx);
        _setMode(mode);
      });
    } else if (!fontsBeingProcessed) {
      setSheetState(() {});
      fontService!.downloadAndInstall().then((_) {
        if (fontService.areFontsReady) {
          if (Navigator.of(sheetCtx).canPop()) {
            Navigator.pop(sheetCtx);
          }
          _setMode(mode);
        }
      });
    }
  }

  void _startMemorization(BuildContext sheetCtx) {
    int activeSurahNumber = widget.surahInfo.number ?? 1;
    if (_readingMode.isMushaf) {
      try {
        final pageData = quran.getPageData(_currentMushafPage);
        if (pageData.isNotEmpty) {
          activeSurahNumber = pageData.first['surah'] as int;
        }
      } catch (_) {}
    }

    final verseCount = quran.getVerseCount(activeSurahNumber);
    final ayahTexts = List.generate(
      verseCount,
      (i) => quran.getVerse(activeSurahNumber, i + 1),
    );
    sheetCtx
        .read<MemorizationCubit>()
        .toggleMemorizationMode(ayahTexts, activeSurahNumber);
    Navigator.pop(sheetCtx);
  }

  void _stopMemorization(BuildContext sheetCtx) {
    sheetCtx.read<MemorizationCubit>().toggleMemorizationMode([], 0);
  }

  List<int> _getVisibleSurahs(BuildContext context) {
    if (!_readingMode.isMushaf) {
      return [widget.surahInfo.number ?? 1];
    }

    final surahs = <int>{};
    try {
      final pageData = quran.getPageData(_currentMushafPage);
      for (final s in pageData) {
        surahs.add(s['surah'] as int);
      }

      bool isDoubleMode = false;
      if (_horizontalDisplayMode == HorizontalPageDisplayMode.doublePage) {
        bool isDesktop = false;
        try {
          if (kIsWeb) {
            isDesktop = true;
          } else if (Platform.isMacOS ||
              Platform.isWindows ||
              Platform.isLinux) {
            isDesktop = true;
          }
        } catch (_) {}
        if (isDesktop ||
            MediaQuery.orientationOf(context) == Orientation.landscape) {
          isDoubleMode = true;
        }
      }

      if (isDoubleMode) {
        final leftPage = _currentMushafPage + 1;
        if (leftPage <= quran.totalPagesCount) {
          final leftPageData = quran.getPageData(leftPage);
          for (final s in leftPageData) {
            surahs.add(s['surah'] as int);
          }
        }
      }
    } catch (_) {}
    return surahs.toList();
  }

  static const List<Map<String, String>> _fontOptions = [
    {'family': 'Amiri', 'label': 'Amiri'},
    {'family': 'IndoPak', 'label': 'IndoPak'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMushafMode = _readingMode.isMushaf;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {},
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SurahCubit()..loadSurah(widget.surahInfo.number!),
          ),
          BlocProvider(
            create: (_) => context.read<AudioCubit>()
              ..fetchAudioInfo(widget.surahInfo.number.toString()),
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
          BlocProvider(
            create: (_) => MemorizationCubit(),
          ),
        ],
        child: Builder(
          builder: (innerContext) => Scaffold(
            backgroundColor: isMushafMode
                ? (_customBgColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F0F0F)
                        : const Color(0xFFFFF9E8)))
                : null,
            appBar: isMushafMode
                ? null
                : SurahScreenAppBar(
                    surahName: widget.surahInfo.name ?? '',
                    surahNumber: widget.surahInfo.number ?? 0,
                    englishName: widget.surahInfo.englishName,
                    onBack: () => Navigator.pop(context),
                    onMenu: () => _showTabsSheet(innerContext),
                  ),
            body: Stack(
              children: [
                if (isMushafMode)
                  _buildMushafBody(innerContext)
                else
                  _buildScrollBody(innerContext),
              ],
            ),
            floatingActionButton: isMushafMode
                ? null
                : BlocBuilder<MemorizationCubit, MemorizationState>(
                    builder: (context, state) {
                      final isMemorizationMode =
                          state is MemorizationModeUpdated &&
                              state.isMemorizationMode;

                      if (!isMemorizationMode) return const SizedBox.shrink();

                      return MemorizationStopFab(
                        onPressed: () => context
                            .read<MemorizationCubit>()
                            .toggleMemorizationMode([], 0),
                        label: AppLocalizations.of(context)!.stopMemorization,
                      );
                    },
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollBody(BuildContext context) {
    return BlocBuilder<SurahCubit, SurahState>(
      builder: (context, state) {
        if (state is SurahLoading) {
          return const SurahLoadingStateWidget();
        } else if (state is SurahLoaded) {
          return QuranPageView(
            surah: state.surah,
            surahNumber: widget.surahInfo.number!,
            scrollToAyah: widget.scrollToAyah,
            ayahPosition: widget.ayahPosition,
            shouldRestorePosition: widget.shouldRestorePosition,
            isBookmarkVisit: widget.isBookmarkVisit,
            customBgColor: _customBgColor,
            customTextColor: _customTextColor,
          );
        } else if (state is SurahError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.unknownError(state.message),
            ),
          );
        } else {
          return Center(
            child: Text(AppLocalizations.of(context)!.unknownState),
          );
        }
      },
    );
  }

  Widget _buildMushafBody(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<SurahCubit, SurahState>(
        builder: (context, state) {
          if (state is SurahLoaded) {
            return MushafInteractiveWrapper(
              key: ValueKey(
                  '${_readingMode}_${_horizontalDisplayMode}_$_mushafFlipDirection'),
              surah: state.surah,
              surahNumber: widget.surahInfo.number!,
              initialPageNumber: _currentMushafPage,
              mode: _readingMode,
              displayMode: _horizontalDisplayMode,
              flipDirection: _mushafFlipDirection,
              onPageChanged: _onMushafPageChanged,
              onMenuTapped: () => _showTabsSheet(context),
              customBgColor: _customBgColor,
              customTextColor: _customTextColor,
            );
          }

          return QuranMushafPageView(
            key: ValueKey(
                '${_readingMode}_${_horizontalDisplayMode}_$_mushafFlipDirection'),
            initialPageNumber: _currentMushafPage,
            mode: _readingMode,
            displayMode: _horizontalDisplayMode,
            flipDirection: _mushafFlipDirection,
            onPageChanged: _onMushafPageChanged,
            customBgColor: _customBgColor,
            customTextColor: _customTextColor,
          );
        },
      ),
    );
  }
}
