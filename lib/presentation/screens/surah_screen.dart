import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/surah_screen_settings_service.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/api/audio_services.dart';
import 'package:huda/data/api/tafsir_services.dart';
import 'package:huda/data/api/translation_services.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/repository/audio_repository.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/khatma_page.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/surah/mushaf_interactive_wrapper.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/presentation/widgets/surah/quran_page_view.dart';
import 'package:huda/presentation/widgets/surah/quran_reader_menus.dart';

class SurahScreen extends StatefulWidget {
  final QuranModel surahInfo;
  final int? scrollToAyah;

  final bool flashAyah;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;

  const SurahScreen({
    super.key,
    required this.surahInfo,
    this.scrollToAyah,
    this.flashAyah = false,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
  });

  static Widget route({
    required QuranModel surahInfo,
    int? scrollToAyah,
    bool flashAyah = false,
    bool shouldRestorePosition = false,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider<AudioCubit>(create: (_) => createAudioCubit()),
      BlocProvider<TafsirCubit>(create: (_) => createTafsirCubit()),
      BlocProvider<TranslationCubit>(create: (_) => createTranslationCubit()),
    ],
    child: SurahScreen(
      surahInfo: surahInfo,
      scrollToAyah: scrollToAyah,
      flashAyah: flashAyah,
      shouldRestorePosition: shouldRestorePosition,
    ),
  );

  @visibleForTesting
  static AudioCubit Function() createAudioCubit = () =>
      AudioCubit(AudioRepository(audioServices: AudioServices()));
  @visibleForTesting
  static TafsirCubit Function() createTafsirCubit = () =>
      TafsirCubit(TafsirRepository(tafsirServices: TafsirServices()));
  @visibleForTesting
  static TranslationCubit Function() createTranslationCubit = () =>
      TranslationCubit(
        TranslationRepository(translationServices: TranslationServices()),
      );

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> with WidgetsBindingObserver {
  QuranReadingMode _readingMode = QuranReadingMode.scrollList;
  MushafLayout _mushafLayout = const MushafLayout();
  MushafFlipDirection _mushafFlipDirection = MushafFlipDirection.horizontal;

  Color? _customBgColor;
  Color? _customTextColor;
  String _quranFont = 'Amiri';
  late final SurahScreenSettingsService _settingsService;

  int _currentMushafPage = 1;

  late int _surahNumber = widget.surahInfo.number ?? 1;
  int? _pendingAyahSheet;

  bool get _isOpeningSurah => _surahNumber == widget.surahInfo.number;

  late bool _flashPending = widget.flashAyah && widget.scrollToAyah != null;

  (int, int)? get _mushafFlash => _flashPending && _isOpeningSurah
      ? (_surahNumber, widget.scrollToAyah!)
      : null;

  void _flashShown() => _flashPending = false;

  static const Map<String, String> _fonts = {
    'Amiri': 'Amiri',
    'IndoPak': 'IndoPak',
  };

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

    context.read<AudioCubit>().fetchAudioInfo(_surahNumber.toString());
    context.read<TafsirCubit>().fetchTafsirInfo();
    context.read<TranslationCubit>().fetchTranslationInfo();

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  int _initialMushafPage() {
    final surahNumber = widget.surahInfo.number ?? 1;
    try {
      if (widget.shouldRestorePosition) {
        final lastRead = getIt<ReadingPositionService>().getLastReadSummary();
        if (lastRead != null &&
            lastRead['surahNumber'] == surahNumber &&
            lastRead['ayahNumber'] != null) {
          final savedAyah = lastRead['ayahNumber'] as int;
          return _readingMode.pagination.pageOf(surahNumber, savedAyah);
        }
      }
      final ayah = widget.scrollToAyah ?? 1;
      return _readingMode.pagination.pageOf(surahNumber, ayah);
    } catch (_) {
      return 1;
    }
  }

  void _onMushafPageChanged(int page) {
    _currentMushafPage = page;
    if (widget.isBookmarkVisit) return;
    try {
      final pageData = _readingMode.pagination.sectionsOf(page);
      if (pageData.isNotEmpty) {
        getIt<ReadingPositionService>().updatePositionForSurah(
          surahNumber: pageData[0]['surah'] as int,
          ayahNumber: pageData[0]['start'] as int,
          position: 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error saving Mushaf page position: $e');
    }
  }

  void _loadSavedMode() {
    final cache = getIt<CacheHelper>();
    _readingMode = QuranReadingMode.fromStorageValue(
      cache.getData(key: QuranReadingMode.key) as String?,
    );
    _mushafLayout = MushafLayout.read(cache);
    _mushafFlipDirection = MushafFlipDirection.fromStorageValue(
      cache.getData(key: MushafFlipDirection.key) as String?,
    );
  }

  void _loadCustomisation() {
    _customBgColor = _settingsService.getBackgroundColor();
    _customTextColor = _settingsService.getTextColor();
    _quranFont = getQuranFonts();
  }

  void _switchSurah(BuildContext context, int surahNumber, int verseNumber) {
    setState(() {
      _surahNumber = surahNumber;
      _pendingAyahSheet = verseNumber;
    });
    context.read<SurahCubit>().loadSurah(surahNumber);
    context.read<AudioCubit>().fetchAudioInfo(surahNumber.toString());
  }

  void _openSurah(BuildContext context, int number) {
    if (number == _surahNumber) return;
    getIt<ReadingPositionService>().saveReadingPosition(
      surahNumber: number,
      ayahNumber: 1,
      position: 0.0,
    );
    setState(() {
      _surahNumber = number;
      _pendingAyahSheet = null;
      try {
        _currentMushafPage = _readingMode.pagination.pageOf(number, 1);
      } catch (_) {}
    });
    context.read<SurahCubit>().loadSurah(number);
    context.read<AudioCubit>().fetchAudioInfo(number.toString());
  }

  void _setMode(QuranReadingMode mode) {
    setState(() {
      try {
        _currentMushafPage = _readingMode.pagination.convertPage(
          _currentMushafPage,
          mode.pagination,
        );
      } catch (_) {
        _currentMushafPage = 1;
      }
      _readingMode = mode;
    });
    getIt<CacheHelper>().saveData(
      key: QuranReadingMode.key,
      value: mode.storageValue,
    );
  }

  void _setMushafLayout(MushafLayout layout) {
    setState(() => _mushafLayout = layout);
    layout.write(getIt<CacheHelper>());
  }

  void _setMushafFlipDirection(MushafFlipDirection direction) {
    setState(() => _mushafFlipDirection = direction);
    getIt<CacheHelper>().saveData(
      key: MushafFlipDirection.key,
      value: direction.storageValue,
    );
  }

  MushafPackService? _packFor(QuranReadingMode mode) {
    final pack = mode.pack;
    if (pack == null) return null;
    try {
      return getIt<MushafPackService>(instanceName: pack.name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectReadingMode(
    QuranReadingMode mode,
    BuildContext sheetContext,
  ) async {
    final pack = _packFor(mode);
    if (!mode.isMushaf || (pack?.isReady ?? true)) {
      Navigator.pop(sheetContext);
      _setMode(mode);
      return;
    }
    try {
      await pack!.init();
      if (!mounted || !sheetContext.mounted) return;
      if (!pack.isReady) await pack.downloadAndInstall();
      if (!mounted || !pack.isReady) return;
      if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
        Navigator.pop(sheetContext);
      }
      _setMode(mode);
    } catch (error) {
      debugPrint('Unable to prepare Quran reading mode: $error');
    }
  }

  int _visibleSurah() {
    if (!_readingMode.isMushaf) return _surahNumber;
    try {
      final sections = _readingMode.pagination.sectionsOf(_currentMushafPage);
      if (sections.isNotEmpty) return sections.first['surah'] as int;
    } catch (_) {}
    return _surahNumber;
  }

  void _showIndex(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showHudaSheet<void>(
      context: context,
      title: l10n.surahsLabel,
      sideSheet: true,
      builder: (sheetContext) => QuranIndexList(
        current: _visibleSurah(),
        onSelect: (number) {
          Navigator.pop(sheetContext);
          _openSurah(context, number);
        },
      ),
    );
  }

  void _showDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showHudaSheet<void>(
      context: context,
      title: l10n.quranDisplay,
      sideSheet: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          MediaQuery.sizeOf(sheetContext);
          final size = MediaQuery.sizeOf(context);
          final fold = FoldInfo.of(context);
          final twoPages = QuranMushafPageView.showsSpread(
            size,
            fold,
            twoPages: _mushafLayout.twoPages,
          );
          return QuranDisplaySettings(
            readingMode: _readingMode,
            twoPages: twoPages,
            twoPagesAvailable: QuranMushafPageView.allowsSpread(size, fold),
            zoomed: _mushafLayout.zoomed,
            pageFillsWidth: !twoPages && size.width < size.height,
            flipDirection: _mushafFlipDirection,
            font: _quranFont,
            fonts: _fonts,
            packFor: _packFor,
            onReadingMode: (mode) => _selectReadingMode(mode, sheetContext),
            onTwoPages: (two) {
              _setMushafLayout(_mushafLayout.copyWith(twoPages: two));
              setSheetState(() {});
            },
            onZoomed: (zoomed) {
              _setMushafLayout(_mushafLayout.copyWith(zoomed: zoomed));
              setSheetState(() {});
            },
            onFlipDirection: (direction) {
              _setMushafFlipDirection(direction);
              setSheetState(() {});
            },
            onFont: (family) {
              setState(() => _quranFont = family);
              setQuranFonts(family);
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  void _showMemorize(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memorization = context.read<MemorizationCubit>();
    showHudaSheet<void>(
      context: context,
      title: l10n.memorizationMode,
      builder: (sheetContext) => BlocProvider.value(
        value: memorization,
        child: QuranMemorizePanel(
          onStart: () {
            _startMemorization(memorization);
            Navigator.pop(sheetContext);
          },
          onStop: () => memorization.toggleMemorizationMode([], 0),
        ),
      ),
    );
  }

  void _showKhatma(BuildContext context) => showKhatmaSheet(context);

  void _startMemorization(MemorizationCubit memorization) {
    final surah = _visibleSurah();
    final verseCount = quran.getVerseCount(surah);
    final ayahTexts = List.generate(
      verseCount,
      (i) => quran.getVerse(surah, i + 1),
    );
    memorization.toggleMemorizationMode(ayahTexts, surah);
  }

  List<Widget> _actions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        key: const ValueKey('quran-index-button'),
        tooltip: l10n.surahsLabel,
        onPressed: () => _showIndex(context),
        icon: const Icon(Icons.format_list_bulleted_rounded),
      ),
      IconButton(
        key: const ValueKey('quran-display-button'),
        tooltip: l10n.quranDisplay,
        onPressed: () => _showDisplay(context),
        icon: const Icon(Icons.tune_rounded),
      ),
      PopupMenuButton<String>(
        key: const ValueKey('quran-more-button'),
        tooltip: l10n.quranMore,
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (item) => switch (item) {
          'memorize' => _showMemorize(context),
          _ => _showKhatma(context),
        },
        itemBuilder: (_) => [
          if (!PlatformUtils.isLinux)
            PopupMenuItem(
              value: 'memorize',
              child: ListTile(
                leading: const Icon(Icons.psychology_rounded),
                title: Text(l10n.tabMemorization),
              ),
            ),
          PopupMenuItem(
            value: 'khatma',
            child: ListTile(
              leading: const Icon(Icons.auto_stories_rounded),
              title: Text(l10n.khatmaLegendKhatma),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SurahCubit()..loadSurah(widget.surahInfo.number!),
        ),
        BlocProvider(
          create: (_) =>
              BookmarksCubit(bookmarkService: getIt<BookmarkService>()),
        ),
        BlocProvider(create: (_) => MemorizationCubit()),
      ],
      child: Builder(
        builder: (inner) => _readingMode.isMushaf
            ? _buildMushaf(inner)
            : _buildScrolling(inner),
      ),
    );
  }

  Widget _buildScrolling(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final ref = QuranSurahRef.number(_surahNumber, language);
    final reader = _scrollBody(context);
    return HudaScaffold(
      title: ref.title,
      actions: _actions(context),
      floatingActionButton: BlocBuilder<MemorizationCubit, MemorizationState>(
        builder: (context, state) {
          final active =
              state is MemorizationModeUpdated && state.isMemorizationMode;
          if (!active) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            key: const ValueKey('quran-memorize-fab'),
            onPressed: () =>
                context.read<MemorizationCubit>().toggleMemorizationMode([], 0),
            icon: const Icon(Icons.stop_rounded),
            label: Text(l10n.stopMemorization),
          );
        },
      ),
      body: reader,
    );
  }

  Widget _scrollBody(BuildContext context, {bool showHeader = true}) {
    final l10n = AppLocalizations.of(context)!;
    final screen = context;
    return BlocBuilder<SurahCubit, SurahState>(
      builder: (context, state) {
        if (state is SurahLoaded) {
          return QuranPageView(
            key: ValueKey('quran-surah-$_surahNumber'),
            surah: state.surah,
            surahNumber: _surahNumber,
            scrollToAyah: _isOpeningSurah ? widget.scrollToAyah : null,
            flashAyah: _isOpeningSurah && _flashPending,
            onFlashShown: _flashShown,
            ayahPosition: _isOpeningSurah ? widget.ayahPosition : null,
            shouldRestorePosition:
                _isOpeningSurah && widget.shouldRestorePosition,
            isBookmarkVisit: _isOpeningSurah && widget.isBookmarkVisit,
            customBgColor: _customBgColor,
            customTextColor: _customTextColor,
            onOpenSurah: (number) => _openSurah(context, number),
            overlayContext: screen,
            showHeader: showHeader,
          );
        }
        if (state is SurahError) {
          return HudaErrorState(
            identity: quranIdentity,
            message: l10n.quranSurahLoadError,
            onRetry: () => context.read<SurahCubit>().loadSurah(_surahNumber),
          );
        }
        return const _ReaderSkeleton();
      },
    );
  }

  Widget _buildMushaf(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final page = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: page, bottom: page),
      child: HudaChromeFrame(
        actions: _actions(context),
        child: Scaffold(
          backgroundColor: QuranMushafPageView.paperOf(context, _customBgColor),
          body: BlocBuilder<SurahCubit, SurahState>(
            builder: (context, state) {
              if (state is SurahLoaded && state.surah.number == _surahNumber) {
                final pendingAyahSheet = _pendingAyahSheet;
                if (pendingAyahSheet != null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _pendingAyahSheet = null,
                  );
                }
                return MushafInteractiveWrapper(
                  key: ValueKey(
                    '${_readingMode}_${_mushafLayout}_${_mushafFlipDirection}_$_surahNumber',
                  ),
                  surah: state.surah,
                  surahNumber: _surahNumber,
                  title: QuranSurahRef.number(_visibleSurah(), language).title,
                  initialAyahSheet: pendingAyahSheet,
                  flashAyah: _mushafFlash,
                  onFlashShown: _flashShown,
                  onOtherSurahAyah: (surahNumber, verseNumber) =>
                      _switchSurah(context, surahNumber, verseNumber),
                  initialPageNumber: _currentMushafPage,
                  mode: _readingMode,
                  layout: _mushafLayout,
                  flipDirection: _mushafFlipDirection,
                  onPageChanged: _onMushafPageChanged,
                  actions: _actions(context),
                  customBgColor: _customBgColor,
                  customTextColor: _customTextColor,
                );
              }
              return QuranMushafPageView(
                key: ValueKey(
                  '${_readingMode}_${_mushafLayout}_$_mushafFlipDirection',
                ),
                flashAyah: _mushafFlash,
                onFlashShown: _flashShown,
                initialPageNumber: _currentMushafPage,
                mode: _readingMode,
                layout: _mushafLayout,
                flipDirection: _mushafFlipDirection,
                onPageChanged: _onMushafPageChanged,
                customBgColor: _customBgColor,
                customTextColor: _customTextColor,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: QuranPageView.measure),
        child: Padding(
          padding: EdgeInsets.all(
            space.gutter(MediaQuery.sizeOf(context).width),
          ),
          child: HudaSkeleton(
            announce: true,
            child: Column(
              children: [
                const HudaSkeletonBlock(height: 80),
                SizedBox(height: space.xl),
                for (var i = 0; i < 4; i++) ...[
                  HudaSkeletonLines(lines: 2, style: context.type.ayah),
                  SizedBox(height: space.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
