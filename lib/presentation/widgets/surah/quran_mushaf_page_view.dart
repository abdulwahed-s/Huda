import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/quran/mushaf_page_content.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/core/services/service_locator.dart';

enum QuranReadingMode {
  scrollList,
  horizontalPages,
  tajweed;

  String get label {
    switch (this) {
      case QuranReadingMode.scrollList:
        return 'Scroll List';
      case QuranReadingMode.horizontalPages:
        return 'Mushaf layout';
      case QuranReadingMode.tajweed:
        return 'Mushaf Al-Tajweed layout';
    }
  }

  String localizedLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (this) {
      case QuranReadingMode.scrollList:
        return l.readingModeScrollList;
      case QuranReadingMode.horizontalPages:
        return l.readingModeMushaf;
      case QuranReadingMode.tajweed:
        return l.readingModeTajweed;
    }
  }

  IconData get icon {
    switch (this) {
      case QuranReadingMode.scrollList:
        return Icons.view_agenda_outlined;
      case QuranReadingMode.horizontalPages:
        return Icons.auto_stories_outlined;
      case QuranReadingMode.tajweed:
        return Icons.color_lens_outlined;
    }
  }

  bool get isMushaf =>
      this == QuranReadingMode.horizontalPages ||
      this == QuranReadingMode.tajweed;

  static const _storageKey = 'quran_reading_mode';

  String get storageValue => name;

  static QuranReadingMode fromStorageValue(String? value) {
    if (value == 'verticalFlip') return QuranReadingMode.horizontalPages;
    return QuranReadingMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuranReadingMode.scrollList,
    );
  }

  static String get key => _storageKey;
}

enum MushafFlipDirection {
  horizontal,
  vertical;

  String get label {
    switch (this) {
      case MushafFlipDirection.horizontal:
        return 'Horizontal Flip';
      case MushafFlipDirection.vertical:
        return 'Vertical Flip';
    }
  }

  String localizedLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (this) {
      case MushafFlipDirection.horizontal:
        return l.mushafFlipHorizontal;
      case MushafFlipDirection.vertical:
        return l.mushafFlipVertical;
    }
  }

  IconData get icon {
    switch (this) {
      case MushafFlipDirection.horizontal:
        return Icons.swipe_right_outlined;
      case MushafFlipDirection.vertical:
        return Icons.swipe_up_outlined;
    }
  }

  static const _storageKey = 'mushaf_flip_direction';
  String get storageValue => name;

  static MushafFlipDirection fromStorageValue(String? value) {
    return MushafFlipDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MushafFlipDirection.horizontal,
    );
  }

  static String get key => _storageKey;
}

enum HorizontalPageDisplayMode {
  normal,
  doublePage,
  zoomed;

  String get label {
    switch (this) {
      case HorizontalPageDisplayMode.normal:
        return 'Single Page';
      case HorizontalPageDisplayMode.doublePage:
        return 'Double Page';
      case HorizontalPageDisplayMode.zoomed:
        return 'Zoomed';
    }
  }

  String localizedLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (this) {
      case HorizontalPageDisplayMode.normal:
        return l.mushafDisplaySingle;
      case HorizontalPageDisplayMode.doublePage:
        return l.mushafDisplayDouble;
      case HorizontalPageDisplayMode.zoomed:
        return l.mushafDisplayZoomed;
    }
  }

  IconData get icon {
    switch (this) {
      case HorizontalPageDisplayMode.normal:
        return Icons.crop_portrait_outlined;
      case HorizontalPageDisplayMode.doublePage:
        return Icons.menu_book_outlined;
      case HorizontalPageDisplayMode.zoomed:
        return Icons.zoom_in_outlined;
    }
  }

  static const _storageKey = 'horizontal_page_display_mode';
  String get storageValue => name;

  static HorizontalPageDisplayMode fromStorageValue(String? value) {
    return HorizontalPageDisplayMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HorizontalPageDisplayMode.normal,
    );
  }

  static String get key => _storageKey;
}

class QuranMushafPageView extends StatefulWidget {
  final int initialPageNumber;

  final QuranReadingMode mode;

  final int? playingSurahNumber;

  final int? playingAyahNumber;

  final bool isMemorizationMode;

  final Set<int> hiddenAyahIndices;

  final int memorizedSurahNumber;

  final ValueChanged<int>? onPageChanged;

  final void Function(int surahNumber, int verseNumber)? onAyahTap;

  final void Function(int surahNumber, int verseNumber)? onAyahLongPress;

  final Color? customBgColor;

  final Color? customTextColor;

  final HorizontalPageDisplayMode displayMode;
  final MushafFlipDirection flipDirection;

  const QuranMushafPageView({
    super.key,
    required this.initialPageNumber,
    required this.mode,
    this.playingSurahNumber,
    this.playingAyahNumber,
    this.isMemorizationMode = false,
    this.hiddenAyahIndices = const {},
    this.memorizedSurahNumber = 0,
    this.onPageChanged,
    this.onAyahTap,
    this.onAyahLongPress,
    this.customBgColor,
    this.customTextColor,
    this.displayMode = HorizontalPageDisplayMode.normal,
    this.flipDirection = MushafFlipDirection.horizontal,
  });

  @override
  State<QuranMushafPageView> createState() => _QuranMushafPageViewState();
}

class _QuranMushafPageViewState extends State<QuranMushafPageView>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentPage;
  bool _currentIsDoubleMode = false;
  DateTime _lastScrollTime = DateTime.now();
  final _contentCache = MushafPageContentCache();
  QcfFontService? _activeFontService;

  void _handlePointerScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final now = DateTime.now();
      if (now.difference(_lastScrollTime).inMilliseconds < 250) return;

      if (event.scrollDelta.dy > 0 || event.scrollDelta.dx > 0) {
        _lastScrollTime = now;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.scrollDelta.dy < 0 || event.scrollDelta.dx < 0) {
        _lastScrollTime = now;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _calculateIsDoubleMode(BuildContext context) {
    if (widget.displayMode != HorizontalPageDisplayMode.doublePage ||
        !widget.mode.isMushaf) {
      return false;
    }

    bool isDesktop = false;
    try {
      if (kIsWeb) {
        isDesktop = true;
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        isDesktop = true;
      }
    } catch (_) {}

    if (isDesktop) return true;

    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool get _useTajweedFonts => widget.mode == QuranReadingMode.tajweed;

  int _toControllerPage(int quranPage, bool isDouble) =>
      isDouble ? (quranPage - 1) ~/ 2 : quranPage - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.initialPageNumber.clamp(1, quran.totalPagesCount);

    _currentIsDoubleMode =
        widget.displayMode == HorizontalPageDisplayMode.doublePage &&
        widget.mode.isMushaf;
    _pageController = PageController(
      initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode),
    );
    unawaited(_requestFontsForPage(_currentPage));
  }

  QcfFontService? _getFontService() {
    if (!widget.mode.isMushaf) return null;
    try {
      final instanceName = _useTajweedFonts ? 'tajweed' : 'qcf4';
      return getIt<QcfFontService>(instanceName: instanceName);
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestFontsForPage(int pageNumber) async {
    final fontService = _getFontService();
    if (_activeFontService != fontService) {
      _activeFontService?.clearPreloadWindow();
      _activeFontService = fontService;
    }
    if (fontService == null) return;
    try {
      await fontService.loadPageWindow(
        pageNumber,
        doublePage: _currentIsDoubleMode,
      );
    } on QcfFontRequestCancelled {
      // A subsequent navigation or memory-pressure event superseded this work.
    } catch (error) {
      debugPrint('Unable to load Quran page fonts: $error');
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _activeFontService?.setReaderScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _activeFontService?.setReaderScrolling(false);
    }
    final metrics = notification.metrics;
    if (metrics is PageMetrics && metrics.page != null) {
      final position = metrics.page!;
      final first = (position + 0.001).floor();
      final last = (position - 0.001).ceil();
      _activeFontService?.updateVisiblePages([
        for (var index = first; index <= last; index++)
          if (_currentIsDoubleMode) ...[
            index * 2 + 1,
            index * 2 + 2,
          ] else
            index + 1,
      ]);
    }
    return false;
  }

  @override
  void didHaveMemoryPressure() {
    _contentCache.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldBeDouble = _calculateIsDoubleMode(context);
    if (_currentIsDoubleMode != shouldBeDouble) {
      _activeFontService?.setReaderScrolling(false);
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode),
      );
      unawaited(_requestFontsForPage(_currentPage));
    }
  }

  @override
  void didUpdateWidget(QuranMushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldBeDouble = _calculateIsDoubleMode(context);
    if (oldWidget.mode != widget.mode ||
        oldWidget.initialPageNumber != widget.initialPageNumber ||
        oldWidget.displayMode != widget.displayMode ||
        oldWidget.flipDirection != widget.flipDirection ||
        _currentIsDoubleMode != shouldBeDouble) {
      final savedPage = oldWidget.initialPageNumber != widget.initialPageNumber
          ? widget.initialPageNumber.clamp(1, quran.totalPagesCount)
          : _currentPage;
      _activeFontService?.setReaderScrolling(false);
      _currentPage = savedPage;
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: _toControllerPage(savedPage, _currentIsDoubleMode),
      );
      unawaited(_requestFontsForPage(savedPage));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeFontService?.clearPreloadWindow();
    _contentCache.clear();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: _buildPageView(context),
      );

  Widget _buildPageView(BuildContext context) {
    if (_currentIsDoubleMode) {
      final spreadCount = (quran.totalPagesCount / 2).ceil();
      return Listener(
        onPointerSignal: _handlePointerScroll,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            allowImplicitScrolling: true,
            key: ObjectKey(_pageController),
            scrollDirection: Axis.horizontal,
            scrollBehavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            controller: _pageController,
            itemCount: spreadCount,
            onPageChanged: (spreadIndex) {
              final rightPage = (spreadIndex * 2 + 1).clamp(
                1,
                quran.totalPagesCount,
              );
              setState(() => _currentPage = rightPage);
              widget.onPageChanged?.call(rightPage);
              unawaited(_requestFontsForPage(rightPage));
            },
            itemBuilder: (context, spreadIndex) {
              final rightPage = spreadIndex * 2 + 1;
              final leftPage = spreadIndex * 2 + 2;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Row(
                children: [
                  Expanded(
                    child: _QuranMushafPage(
                      contentCache: _contentCache,
                      requiredFontPages: [rightPage, leftPage, 1],
                      fontPriority:
                          spreadIndex == _toControllerPage(_currentPage, true)
                          ? QcfFontPriority.visible
                          : QcfFontPriority.prepared,
                      pageNumber: rightPage.clamp(1, quran.totalPagesCount),
                      playingSurahNumber: widget.playingSurahNumber,
                      playingAyahNumber: widget.playingAyahNumber,
                      isMemorizationMode: widget.isMemorizationMode,
                      hiddenAyahIndices: widget.hiddenAyahIndices,
                      memorizedSurahNumber: widget.memorizedSurahNumber,
                      onAyahTap: widget.onAyahTap,
                      onAyahLongPress: widget.onAyahLongPress,
                      customBgColor: widget.customBgColor,
                      customTextColor: widget.customTextColor,
                      displayMode: widget.displayMode,
                      useTajweedFonts: _useTajweedFonts,
                    ),
                  ),
                  Container(
                    width: 1.0,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  if (leftPage <= quran.totalPagesCount)
                    Expanded(
                      child: _QuranMushafPage(
                        contentCache: _contentCache,
                        requiredFontPages: [rightPage, leftPage, 1],
                        fontPriority:
                            spreadIndex == _toControllerPage(_currentPage, true)
                            ? QcfFontPriority.visible
                            : QcfFontPriority.prepared,
                        pageNumber: leftPage,
                        playingSurahNumber: widget.playingSurahNumber,
                        playingAyahNumber: widget.playingAyahNumber,
                        isMemorizationMode: widget.isMemorizationMode,
                        hiddenAyahIndices: widget.hiddenAyahIndices,
                        memorizedSurahNumber: widget.memorizedSurahNumber,
                        onAyahTap: widget.onAyahTap,
                        onAyahLongPress: widget.onAyahLongPress,
                        customBgColor: widget.customBgColor,
                        customTextColor: widget.customTextColor,
                        displayMode: widget.displayMode,
                        useTajweedFonts: _useTajweedFonts,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              );
            },
          ),
        ),
      );
    }

    return Listener(
      onPointerSignal: _handlePointerScroll,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          allowImplicitScrolling: true,
          key: ObjectKey(_pageController),
          scrollDirection: widget.flipDirection == MushafFlipDirection.vertical
              ? Axis.vertical
              : Axis.horizontal,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          controller: _pageController,
          itemCount: quran.totalPagesCount,
          onPageChanged: (index) {
            setState(() => _currentPage = index + 1);
            widget.onPageChanged?.call(index + 1);
            unawaited(_requestFontsForPage(index + 1));
          },
          itemBuilder: (context, index) {
            return _QuranMushafPage(
              contentCache: _contentCache,
              requiredFontPages: [index + 1, 1],
              fontPriority: index + 1 == _currentPage
                  ? QcfFontPriority.visible
                  : QcfFontPriority.prepared,
              pageNumber: index + 1,
              playingSurahNumber: widget.playingSurahNumber,
              playingAyahNumber: widget.playingAyahNumber,
              isMemorizationMode: widget.isMemorizationMode,
              hiddenAyahIndices: widget.hiddenAyahIndices,
              memorizedSurahNumber: widget.memorizedSurahNumber,
              onAyahTap: widget.onAyahTap,
              onAyahLongPress: widget.onAyahLongPress,
              customBgColor: widget.customBgColor,
              customTextColor: widget.customTextColor,
              displayMode: widget.displayMode,
              useTajweedFonts: _useTajweedFonts,
            );
          },
        ),
      ),
    );
  }
}

class _QuranMushafPage extends StatefulWidget {
  final MushafPageContentCache contentCache;
  final List<int> requiredFontPages;
  final QcfFontPriority fontPriority;
  final int pageNumber;
  final int? playingSurahNumber;
  final int? playingAyahNumber;
  final bool isMemorizationMode;
  final Set<int> hiddenAyahIndices;
  final int memorizedSurahNumber;
  final void Function(int surahNumber, int verseNumber)? onAyahTap;
  final void Function(int surahNumber, int verseNumber)? onAyahLongPress;
  final Color? customBgColor;
  final Color? customTextColor;
  final HorizontalPageDisplayMode displayMode;
  final bool useTajweedFonts;

  const _QuranMushafPage({
    required this.contentCache,
    required this.requiredFontPages,
    required this.fontPriority,
    required this.pageNumber,
    this.playingSurahNumber,
    this.playingAyahNumber,
    this.isMemorizationMode = false,
    this.hiddenAyahIndices = const {},
    this.memorizedSurahNumber = 0,
    this.onAyahTap,
    this.onAyahLongPress,
    this.customBgColor,
    this.customTextColor,
    this.displayMode = HorizontalPageDisplayMode.normal,
    this.useTajweedFonts = false,
  });

  @override
  State<_QuranMushafPage> createState() => _QuranMushafPageState();
}

class _QuranMushafPageState extends State<_QuranMushafPage> {
  final Map<String, LongPressGestureRecognizer> _verseRecognizers = {};

  int? _pressedSurah;
  int? _pressedVerse;

  List<BookmarkModel> _bookmarks = [];
  StreamSubscription<BookmarkChange>? _bookmarkSub;
  StreamSubscription<void>? _khatmaSub;
  StreamSubscription<int>? _fontSub;
  bool _fontLoaded = false;
  bool _fontFailed = false;
  int _fontRequestGeneration = 0;

  int get pageNumber => widget.pageNumber;

  @override
  void initState() {
    super.initState();
    _checkFont();
    _loadBookmarks();
    try {
      _bookmarkSub = getIt<BookmarkService>().bookmarkChanges.listen(
        (_) => _loadBookmarks(),
      );
    } catch (_) {}
    try {
      _khatmaSub = getIt<KhatmaService>().khatmaChanges.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  void _checkFont({bool notify = false}) {
    final generation = ++_fontRequestGeneration;
    _fontSub?.cancel();
    _fontSub = null;
    final fontService = _getFontService();
    _fontFailed = false;
    _fontLoaded =
        kIsWeb ||
        (fontService != null &&
            widget.requiredFontPages.every(fontService.isPageFontLoaded));
    if (notify) setState(() {});
    if (!_fontLoaded) {
      _fontSub = fontService?.pageFontLoadedStream.listen((_) {
        if (fontService.areFontsReady &&
            widget.requiredFontPages.every(fontService.isPageFontLoaded)) {
          _markFontsReady(generation);
        }
      });
      unawaited(_awaitFonts(fontService, generation, retry: notify));
    } else {
      _reportReadableFrame(generation);
    }
  }

  Future<void> _awaitFonts(
    QcfFontService? fontService,
    int generation, {
    bool retry = false,
  }) async {
    try {
      if (fontService == null) {
        throw StateError('Quran font service unavailable');
      }
      final load = retry
          ? fontService.retryPagesLoaded
          : fontService.ensurePagesLoaded;
      await load(widget.requiredFontPages, priority: widget.fontPriority);
      _markFontsReady(generation);
    } on QcfFontRequestCancelled {
      // Prepared pages retry when they become visible.
    } catch (_) {
      if (mounted && generation == _fontRequestGeneration) {
        setState(() => _fontFailed = true);
      }
    }
  }

  void _markFontsReady(int generation) {
    if (!mounted || generation != _fontRequestGeneration || _fontLoaded) return;
    setState(() {
      _fontLoaded = true;
      _fontFailed = false;
    });
    _fontSub?.cancel();
    _fontSub = null;
    _reportReadableFrame(generation);
  }

  void _reportReadableFrame(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          generation == _fontRequestGeneration &&
          _fontLoaded &&
          widget.fontPriority == QcfFontPriority.visible) {
        Timeline.instantSync(
          'Quran page ready',
          arguments: {'page': pageNumber, 'tajweed': widget.useTajweedFonts},
        );
      }
    });
  }

  @override
  void didUpdateWidget(_QuranMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != pageNumber) {
      for (final recognizer in _verseRecognizers.values) {
        recognizer.dispose();
      }
      _verseRecognizers.clear();
      _pressedSurah = null;
      _pressedVerse = null;
    }
    if (oldWidget.pageNumber != pageNumber ||
        oldWidget.useTajweedFonts != widget.useTajweedFonts ||
        !listEquals(oldWidget.requiredFontPages, widget.requiredFontPages) ||
        oldWidget.fontPriority != widget.fontPriority) {
      _checkFont();
    }
  }

  QcfFontService? _getFontService() {
    try {
      final instanceName = widget.useTajweedFonts ? 'tajweed' : 'qcf4';
      return getIt<QcfFontService>(instanceName: instanceName);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await getIt<BookmarkService>().getAllBookmarks();
      if (mounted) setState(() => _bookmarks = bookmarks);
    } catch (_) {}
  }

  @override
  void dispose() {
    _fontRequestGeneration++;
    _fontSub?.cancel();
    _bookmarkSub?.cancel();
    _khatmaSub?.cancel();
    for (final r in _verseRecognizers.values) {
      r.dispose();
    }
    _verseRecognizers.clear();
    super.dispose();
  }

  Color _accentColor(BuildContext context, bool isDark) =>
      isDark ? context.primaryLightColor : context.primaryDarkColor;

  Color _bgColor(bool isDark) =>
      widget.customBgColor ??
      (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF9E8));

  Color _textColor(bool isDark) =>
      widget.customTextColor ??
      (isDark ? const Color(0xFFEEEAE0) : const Color(0xFF1A1A1A));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_fontLoaded) {
      if (_fontFailed) return _buildFontError(context, isDark);
      return _buildFontLoadingPlaceholder(isDark);
    }

    MushafPageContent pageContent;
    try {
      pageContent = widget.contentCache.getPage(pageNumber);
    } catch (_) {
      return _buildErrorPage(context, isDark);
    }

    if (pageContent.verses.isEmpty) {
      return _buildErrorPage(context, isDark);
    }

    final firstSurah = pageContent.firstSurah;
    final juzNumber = pageContent.juzNumber;
    final hizbText = pageContent.hizbText;

    if (widget.displayMode == HorizontalPageDisplayMode.zoomed) {
      return _buildZoomedLayout(
        context,
        pageContent,
        firstSurah,
        juzNumber,
        hizbText,
        isDark,
      );
    }

    return Container(
      color: _bgColor(isDark),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: _baselineWidth,
                    child: ColoredBox(
                      color: _bgColor(isDark),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          right: 4.0,
                          top: 40.0,
                          bottom: 50.0,
                        ),
                        child: _buildPageContent(context, pageContent, isDark),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(context, firstSurah, juzNumber, isDark),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFooter(context, hizbText, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomedLayout(
    BuildContext context,
    MushafPageContent pageContent,
    int firstSurah,
    int juzNumber,
    String? hizbText,
    bool isDark,
  ) {
    return Container(
      color: _bgColor(isDark),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: _refH(context, 44)),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: _baselineWidth,
                        child: ColoredBox(
                          color: _bgColor(isDark),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              right: 4.0,
                              bottom: 50.0,
                            ),
                            child: _buildPageContent(
                              context,
                              pageContent,
                              isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _refH(context, 44)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context, firstSurah, juzNumber, isDark),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFooter(context, hizbText, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int surahNumber,
    int juzNumber,
    bool isDark,
  ) {
    final accent = _accentColor(context, isDark);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _refW(context, 16),
        vertical: _refH(context, 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'سورة ${quran.getSurahNameArabic(surahNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: _refW(context, 16),
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'الجزء ${_getJuzNameArabic(juzNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: _refW(context, 16),
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    MushafPageContent pageContent,
    bool isDark,
  ) => Timeline.timeSync(
    'Quran page spans',
    () => _buildPageSpans(context, pageContent, isDark),
    arguments: {'page': pageNumber, 'tajweed': widget.useTajweedFonts},
  );

  Widget _buildPageSpans(
    BuildContext context,
    MushafPageContent pageContent,
    bool isDark,
  ) {
    final textColor = _textColor(isDark);
    final accent = _accentColor(context, isDark);
    final fontPrefix = widget.useTajweedFonts ? 'QCF_T' : 'QCF_P';
    final pageFontFamily =
        '$fontPrefix${pageNumber.toString().padLeft(3, '0')}';
    final fontSize = _verseFontSize(context, pageNumber);
    final lineHeight = _pageLineHeight(pageNumber);

    // Reused for every tajweed-dark span (Bismillah + verses) to avoid
    // allocating a new Paint per verse.
    final Paint tajweedAdaptivePaint = Paint()
      ..colorFilter = const ColorFilter.matrix(<double>[
        0.3,
        0,
        0,
        0,
        180,
        0,
        0.3,
        0,
        0,
        180,
        0,
        0,
        0.3,
        0,
        180,
        0,
        0,
        0,
        1,
        0,
      ]);

    final List<InlineSpan> spans = [];
    final khatmaService = getIt<KhatmaService>();
    final khatmaRange = khatmaService.enabled && !khatmaService.isCompleted
        ? khatmaService.rangeDetailsForDay(
            khatmaService.currentDayIndex,
            khatmaService.planDays,
          )
        : null;

    for (final verse in pageContent.verses) {
      final surahNum = verse.surahNumber;
      final v = verse.verseNumber;
      if (v == 1) {
        spans.add(
          WidgetSpan(
            child: _buildSurahBanner(context, surahNum, accent, textColor),
          ),
        );

        if (pageNumber != 1 && pageNumber != 187) {
          final Paint? bismillahPaint = (isDark && widget.useTajweedFonts)
              ? tajweedAdaptivePaint
              : null;
          spans.add(
            TextSpan(
              text: " ﱁ  ﱂﱃﱄ\n",
              style: TextStyle(
                fontFamily: '${fontPrefix}001',
                fontSize: 24.0,
                color: bismillahPaint == null ? textColor : null,
                foreground: bismillahPaint,
              ),
            ),
          );
        }
      }

      final String verseKey = '${surahNum}_$v';
      if (!_verseRecognizers.containsKey(verseKey)) {
        _verseRecognizers[verseKey] =
            LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 400),
              )
              ..onLongPressCancel = () {}
              ..onLongPress = () {
                setState(() {
                  _pressedSurah = surahNum;
                  _pressedVerse = v;
                });
                widget.onAyahLongPress?.call(surahNum, v);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      if (_pressedSurah == surahNum && _pressedVerse == v) {
                        _pressedSurah = null;
                        _pressedVerse = null;
                      }
                    });
                  }
                });
              };
      }

      final recognizer = _verseRecognizers[verseKey]!;

      bool hasStar = false, hasNote = false, hasBookmark = false;
      Color? bookmarkColor;

      for (final b in _bookmarks) {
        if (b.surahNumber == surahNum && b.ayahNumber == v) {
          if (b.type == BookmarkType.star) {
            hasStar = true;
          } else if (b.type == BookmarkType.note) {
            hasNote = true;
          } else if (b.type == BookmarkType.bookmark) {
            hasBookmark = true;
            bookmarkColor = b.color;
          }
        }
      }

      final isKhatmaStart =
          khatmaRange != null &&
          surahNum == khatmaRange.startSurah &&
          v == khatmaRange.startVerse;
      final isKhatmaEnd =
          khatmaRange != null &&
          surahNum == khatmaRange.endSurah &&
          v == khatmaRange.endVerse;

      Color? bookmarkBgColor;
      if (hasStar) {
        bookmarkBgColor = Colors.amber.withValues(alpha: 0.28);
      } else if (hasNote) {
        bookmarkBgColor = Colors.orange.withValues(alpha: 0.28);
      } else if (hasBookmark) {
        bookmarkBgColor = (bookmarkColor ?? accent).withValues(alpha: 0.28);
      } else if (isKhatmaStart) {
        bookmarkBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.28);
      } else if (isKhatmaEnd) {
        bookmarkBgColor = const Color(0xFFE53935).withValues(alpha: 0.28);
      }

      final bool isPressed = _pressedSurah == surahNum && _pressedVerse == v;
      final bool isPlaying =
          widget.playingSurahNumber == surahNum &&
          widget.playingAyahNumber == v;

      final Color? effectiveBgColor = (isPressed || isPlaying)
          ? accent.withValues(alpha: 0.2)
          : bookmarkBgColor;

      final int ayahIndex = v - 1;
      final bool isHidden =
          widget.isMemorizationMode &&
          surahNum == widget.memorizedSurahNumber &&
          widget.hiddenAyahIndices.contains(ayahIndex);
      final Color verseColor = isHidden
          ? textColor.withValues(alpha: 0)
          : textColor;

      final Paint? tajweedDarkPaint =
          (!isHidden && isDark && widget.useTajweedFonts)
          ? tajweedAdaptivePaint
          : null;

      spans.add(
        TextSpan(
          text: verse.text,
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: pageFontFamily,
            fontSize: fontSize,
            color: tajweedDarkPaint == null ? verseColor : null,
            foreground: tajweedDarkPaint,
            height: lineHeight,
            backgroundColor: isHidden ? null : effectiveBgColor,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: verse.numberGlyph,
          style: TextStyle(
            fontFamily: pageFontFamily,
            color: accent,
            height: 1.35,
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(children: spans),
        locale: const Locale('ar'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          height: lineHeight,
          letterSpacing: 0,
          wordSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildSurahBanner(
    BuildContext context,
    int surahNum,
    Color accent,
    Color textColor,
  ) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/images/surah_header.png',
              width: double.infinity,
              color: accent.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.color,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'surah${surahNum.toString().padLeft(3, '0')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'arsura',
                    fontSize: 40,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontLoadingPlaceholder(bool isDark) {
    return Container(
      color: _bgColor(isDark),
      alignment: Alignment.center,
      child: Text(
        _convertToArabicNumber(pageNumber.toString()),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 18,
          color: _textColor(isDark).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildFontError(BuildContext context, bool isDark) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: _bgColor(isDark),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l.mushafPageNumber(pageNumber)} · ${l.failedToLoad}',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textColor(isDark)),
          ),
          TextButton.icon(
            onPressed: () => _checkFont(notify: true),
            icon: const Icon(Icons.refresh),
            label: Text(l.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(BuildContext context, bool isDark) {
    return Container(
      color: _bgColor(isDark),
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.mushafPageNumber(pageNumber),
        style: TextStyle(
          fontSize: _refW(context, 16),
          color: _textColor(isDark),
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  double _verseFontSize(BuildContext context, int page) {
    const double userFontSize = 23.0;
    final double baseFontSize = userFontSize * _fontScale;

    final bool isFirstPages = page == 1 || page == 2;
    final double minAllPagesFontSize = (_baselineWidth * 0.045).clamp(
      18.0,
      34.0,
    );
    final double minFirstPagesFontSize = (_refDesignW * 0.075).clamp(
      26.0,
      36.0,
    );

    return isFirstPages
        ? baseFontSize.clamp(minFirstPagesFontSize, 44.0)
        : baseFontSize.clamp(minAllPagesFontSize, 44.0);
  }

  double _pageLineHeight(int page) {
    if (page == 1 || page == 2) return 2.15;
    return 2.2 * 0.96;
  }

  Widget _buildFooter(BuildContext context, String? hizbText, bool isDark) {
    final accent = _accentColor(context, isDark);
    final String pageStr = _convertToArabicNumber(pageNumber.toString());
    final String? arabicHizb = _getHizbTextArabic(hizbText);
    final bool hasHizb = arabicHizb != null;

    final bgBase = widget.customBgColor ?? _bgColor(isDark);
    final textBase = widget.customTextColor ?? accent;

    final bannerFill = bgBase.computeLuminance() > 0.5
        ? Color.lerp(bgBase, Colors.black, 0.08)!
        : Color.lerp(bgBase, Colors.white, 0.12)!;

    final bannerBorder = textBase.withValues(alpha: 0.25);

    final textStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize: _refW(context, 13),
      color: textBase.withValues(alpha: 0.85),
      fontWeight: FontWeight.bold,
    );

    final double bannerWidth = hasHizb
        ? _refW(context, 180)
        : _refW(context, 90);
    final double bannerHeight = _refH(context, 28);

    return Padding(
      padding: EdgeInsets.only(
        bottom: _refH(context, 8),
        left: _refW(context, 12),
        right: _refW(context, 12),
      ),
      child: Align(
        alignment: hasHizb ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          width: bannerWidth,
          height: bannerHeight,
          decoration: BoxDecoration(
            color: bannerFill,
            borderRadius: BorderRadius.circular(bannerHeight / 2),
            border: Border.all(color: bannerBorder, width: 1),
          ),
          child: hasHizb
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: _refW(context, 16)),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(child: Text(pageStr, style: textStyle)),
                      ),
                      Container(
                        width: 1,
                        height: bannerHeight * 0.5,
                        color: bannerBorder,
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(arabicHizb, style: textStyle),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: Text(pageStr, style: textStyle)),
        ),
      ),
    );
  }

  String _getJuzNameArabic(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) {
      return _convertToArabicNumber(juzNumber.toString());
    }
    const juzNames = [
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
      'العشرون',
      'الحادي والعشرون',
      'الثاني والعشرون',
      'الثالث والعشرون',
      'الرابع والعشرون',
      'الخامس والعشرون',
      'السادس والعشرون',
      'السابع والعشرون',
      'الثامن والعشرون',
      'التاسع والعشرون',
      'الثلاثون',
    ];
    return juzNames[juzNumber - 1];
  }

  String? _getHizbTextArabic(String? englishHizb) {
    if (englishHizb == null) return null;
    final parts = englishHizb.split('Hizb ');
    if (parts.length != 2) return englishHizb;

    final prefix = parts[0].trim();
    final numberStr = parts[1].trim();
    final arabicNum = _convertToArabicNumber(numberStr);

    if (prefix.isEmpty) return 'الحزب $arabicNum';
    if (prefix == '1/4') return 'ربع الحزب $arabicNum';
    if (prefix == '2/4') return 'نصف الحزب $arabicNum';
    if (prefix == '3/4') return 'ثلاثة أرباع الحزب $arabicNum';

    return englishHizb;
  }

  String _convertToArabicNumber(String input) {
    const Map<String, String> arabicNumbers = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return input.split('').map((char) => arabicNumbers[char] ?? char).join();
  }

  static const _refDesignW = 392.72727272727275;
  static const _refDesignH = 800.7272727272727;

  static const double _baselineWidth = 470;
  static const double _fontScale = 1.18;

  double _refScale(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final scaleW = screenW / _refDesignW;
    final scaleH = screenH / _refDesignH;
    return scaleW < scaleH ? scaleW : scaleH;
  }

  double _refW(BuildContext context, double value) =>
      value * _refScale(context);

  double _refH(BuildContext context, double value) =>
      value * _refScale(context);
}
