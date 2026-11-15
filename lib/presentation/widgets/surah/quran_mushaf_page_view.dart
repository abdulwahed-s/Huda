import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, mapEquals, setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/quran/mushaf_page_content.dart';
import 'package:huda/core/quran/mushaf_pagination.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/services/service_locator.dart';

enum QuranReadingMode {
  scrollList,
  horizontalPages,
  tajweed,
  indopak;

  String get label {
    switch (this) {
      case QuranReadingMode.scrollList:
        return 'Scroll List';
      case QuranReadingMode.horizontalPages:
        return 'Mushaf layout';
      case QuranReadingMode.tajweed:
        return 'Mushaf Al-Tajweed layout';
      case QuranReadingMode.indopak:
        return 'IndoPak Mushaf';
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
      case QuranReadingMode.indopak:
        return l.readingModeIndopak;
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
      case QuranReadingMode.indopak:
        return Icons.import_contacts_outlined;
    }
  }

  bool get isMushaf => pack != null;

  /// The page-image pack a Mushaf mode reads from.
  MushafPack? get pack {
    switch (this) {
      case QuranReadingMode.scrollList:
        return null;
      case QuranReadingMode.horizontalPages:
        return MushafPack.hafs;
      case QuranReadingMode.tajweed:
        return MushafPack.tajweed;
      case QuranReadingMode.indopak:
        return MushafPack.indopak;
    }
  }

  /// Page numbering of this mode's printed Mushaf; the scroll list keeps
  /// Madani page numbers.
  MushafPagination get pagination => this == QuranReadingMode.indopak
      ? MushafPagination.indopak
      : MushafPagination.madani;

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
  late MushafPageContentCache _contentCache = MushafPageContentCache(
    pagination: widget.mode.pagination,
  );

  int get _pageCount => widget.mode.pagination.pageCount;

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

  int _toControllerPage(int quranPage, bool isDouble) =>
      isDouble ? (quranPage - 1) ~/ 2 : quranPage - 1;

  MushafPackService? get _packService {
    final pack = widget.mode.pack;
    if (pack == null) return null;
    try {
      return getIt<MushafPackService>(instanceName: pack.name);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.initialPageNumber.clamp(1, _pageCount);

    _currentIsDoubleMode =
        widget.displayMode == HorizontalPageDisplayMode.doublePage &&
        widget.mode.isMushaf;
    _pageController = PageController(
      initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode),
    );
    unawaited(_packService?.init());
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
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode),
      );
    }
  }

  @override
  void didUpdateWidget(QuranMushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      unawaited(_packService?.init());
      if (oldWidget.mode.pagination != widget.mode.pagination) {
        _contentCache = MushafPageContentCache(
          pagination: widget.mode.pagination,
        );
      }
    }
    final shouldBeDouble = _calculateIsDoubleMode(context);
    if (oldWidget.mode != widget.mode ||
        oldWidget.initialPageNumber != widget.initialPageNumber ||
        oldWidget.displayMode != widget.displayMode ||
        oldWidget.flipDirection != widget.flipDirection ||
        _currentIsDoubleMode != shouldBeDouble) {
      final savedPage = oldWidget.initialPageNumber != widget.initialPageNumber
          ? widget.initialPageNumber.clamp(1, _pageCount)
          : _currentPage.clamp(1, _pageCount);
      _currentPage = savedPage;
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: _toControllerPage(savedPage, _currentIsDoubleMode),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentCache.clear();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _packService;
    if (service == null) return _buildPageView(context, null);
    return StreamBuilder<MushafPackState>(
      stream: service.stateStream,
      initialData: service.currentState,
      builder: (context, _) => service.isReady
          ? _buildPageView(context, service)
          : _MushafPackRequired(
              service: service,
              customBgColor: widget.customBgColor,
              customTextColor: widget.customTextColor,
            ),
    );
  }

  Widget _page(
    MushafPackService? service,
    int pageNumber, {
    bool? rightOfSpread,
  }) => _QuranMushafPage(
    key: ValueKey(pageNumber),
    contentCache: _contentCache,
    packService: service,
    pageNumber: pageNumber,
    rightOfSpread: rightOfSpread,
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
  );

  Widget _buildPageView(BuildContext context, MushafPackService? service) {
    if (_currentIsDoubleMode) {
      final spreadCount = (_pageCount / 2).ceil();
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
              final rightPage = (spreadIndex * 2 + 1).clamp(1, _pageCount);
              setState(() => _currentPage = rightPage);
              widget.onPageChanged?.call(rightPage);
            },
            itemBuilder: (context, spreadIndex) {
              final rightPage = spreadIndex * 2 + 1;
              final leftPage = spreadIndex * 2 + 2;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Row(
                children: [
                  Expanded(
                    child: _page(
                      service,
                      rightPage.clamp(1, _pageCount),
                      rightOfSpread: true,
                    ),
                  ),
                  Container(
                    width: 1.0,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  if (leftPage <= _pageCount)
                    Expanded(
                      child: _page(service, leftPage, rightOfSpread: false),
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
          itemCount: _pageCount,
          onPageChanged: (index) {
            setState(() => _currentPage = index + 1);
            widget.onPageChanged?.call(index + 1);
          },
          itemBuilder: (context, index) => _page(service, index + 1),
        ),
      ),
    );
  }
}

/// Shown in place of the pages until the selected Mushaf pack is installed,
/// including for readers whose old page fonts were removed by an update.
class _MushafPackRequired extends StatelessWidget {
  final MushafPackService service;
  final Color? customBgColor;
  final Color? customTextColor;

  const _MushafPackRequired({
    required this.service,
    this.customBgColor,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        customBgColor ??
        (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF9E8));
    final fg =
        customTextColor ??
        (isDark ? const Color(0xFFEEEAE0) : const Color(0xFF1A1A1A));
    final accent = isDark
        ? context.primaryLightColor
        : context.primaryDarkColor;
    final state = service.currentState;

    final Widget action;
    switch (state.status) {
      case MushafPackStatus.downloading:
      case MushafPackStatus.extracting:
      case MushafPackStatus.loading:
        final downloading = state.status == MushafPackStatus.downloading;
        action = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: downloading ? state.progress : null,
                color: accent,
                backgroundColor: fg.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              downloading
                  ? '${(state.progress * 100).toInt()}%'
                  : state.status == MushafPackStatus.extracting
                  ? l.fontExtractingLabel
                  : l.fontLoadingLabel,
              style: TextStyle(color: fg.withValues(alpha: 0.6)),
            ),
          ],
        );
      case MushafPackStatus.error:
        action = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.failedToLoad, style: TextStyle(color: fg)),
            TextButton.icon(
              onPressed: service.downloadAndInstall,
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        );
      case MushafPackStatus.idle:
      case MushafPackStatus.ready:
        action = FilledButton.icon(
          onPressed: service.downloadAndInstall,
          icon: const Icon(Icons.download_rounded),
          label: Text(l.mushafPackDownload(service.pack.sizeLabel)),
        );
    }

    return ColoredBox(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_outlined, size: 48, color: accent),
              const SizedBox(height: 16),
              Text(
                l.mushafPackTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.mushafPackBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranMushafPage extends StatefulWidget {
  final MushafPageContentCache contentCache;
  final MushafPackService? packService;
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

  /// Side of a double-page spread; null on a single page.
  final bool? rightOfSpread;

  const _QuranMushafPage({
    super.key,
    required this.contentCache,
    required this.packService,
    required this.pageNumber,
    this.rightOfSpread,
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
  });

  @override
  State<_QuranMushafPage> createState() => _QuranMushafPageState();
}

class _QuranMushafPageState extends State<_QuranMushafPage> {
  int? _pressedSurah;
  int? _pressedVerse;
  Timer? _pressedTimer;

  List<BookmarkModel> _bookmarks = [];
  StreamSubscription<BookmarkChange>? _bookmarkSub;
  StreamSubscription<void>? _khatmaSub;

  int get pageNumber => widget.pageNumber;

  @override
  void initState() {
    super.initState();
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

  @override
  void didUpdateWidget(_QuranMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != pageNumber) {
      _pressedTimer?.cancel();
      _pressedSurah = null;
      _pressedVerse = null;
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
    _pressedTimer?.cancel();
    _bookmarkSub?.cancel();
    _khatmaSub?.cancel();
    super.dispose();
  }

  void _onAyahLongPress(int surah, int ayah) {
    _pressedTimer?.cancel();
    setState(() {
      _pressedSurah = surah;
      _pressedVerse = ayah;
    });
    widget.onAyahLongPress?.call(surah, ayah);
    _pressedTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _pressedSurah = null;
        _pressedVerse = null;
      });
    });
  }

  Color _accentColor(BuildContext context, bool isDark) =>
      isDark ? context.primaryLightColor : context.primaryDarkColor;

  Color _bgColor(bool isDark) =>
      widget.customBgColor ??
      (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF9E8));

  Color _textColor(bool isDark) =>
      widget.customTextColor ??
      (isDark ? const Color(0xFFEEEAE0) : const Color(0xFF1A1A1A));

  /// Background highlight per ayah, with the same precedence the text reader
  /// used: pressed/playing, then star, note, bookmark, khatma start/end.
  Map<(int, int), Color> _highlights(MushafPageLayout layout, Color accent) {
    final khatmaService = getIt.isRegistered<KhatmaService>()
        ? getIt<KhatmaService>()
        : null;
    final khatmaRange =
        khatmaService != null &&
            khatmaService.enabled &&
            !khatmaService.isCompleted
        ? khatmaService.rangeDetailsForDay(
            khatmaService.currentDayIndex,
            khatmaService.planDays,
          )
        : null;

    final result = <(int, int), Color>{};
    for (final segment in layout.ayahs) {
      final key = (segment.surah, segment.ayah);
      if (result.containsKey(key)) continue;
      final (surahNum, v) = key;

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

      final isPressed = _pressedSurah == surahNum && _pressedVerse == v;
      final isPlaying =
          widget.playingSurahNumber == surahNum &&
          widget.playingAyahNumber == v;

      Color? color;
      if (isPressed || isPlaying) {
        color = accent.withValues(alpha: 0.2);
      } else if (hasStar) {
        color = Colors.amber.withValues(alpha: 0.28);
      } else if (hasNote) {
        color = Colors.orange.withValues(alpha: 0.28);
      } else if (hasBookmark) {
        color = (bookmarkColor ?? accent).withValues(alpha: 0.28);
      } else if (isKhatmaStart) {
        color = const Color(0xFF4CAF50).withValues(alpha: 0.28);
      } else if (isKhatmaEnd) {
        color = const Color(0xFFE53935).withValues(alpha: 0.28);
      }
      if (color != null) result[key] = color;
    }
    return result;
  }

  Set<(int, int)> _hiddenAyahs() => {
    if (widget.isMemorizationMode)
      for (final index in widget.hiddenAyahIndices)
        (widget.memorizedSurahNumber, index + 1),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = widget.packService;
    final packLayout = service?.layout;
    final pageLayout = packLayout?.pages[pageNumber];

    MushafPageContent pageContent;
    try {
      pageContent = widget.contentCache.getPage(pageNumber);
    } catch (_) {
      return _buildErrorPage(context, isDark);
    }
    if (service == null ||
        packLayout == null ||
        pageLayout == null ||
        pageContent.verses.isEmpty) {
      return _buildErrorPage(context, isDark);
    }

    final accent = _accentColor(context, isDark);
    final textColor = _textColor(isDark);
    final pack = service.pack;
    final pageImage = _MushafPageImage(
      file: service.pageFile(pageNumber),
      packLayout: packLayout,
      layout: pageLayout,
      tint: pack.tinted ? textColor : null,
      markerTint: pack.tinted ? accent : null,
      filter: !pack.tinted && isDark ? _tajweedDarkFilter : null,
      highlights: _highlights(pageLayout, accent),
      hidden: _hiddenAyahs(),
      background: _bgColor(isDark),
      bannerBuilder: (surah) =>
          _buildSurahBanner(context, surah, accent, textColor),
      onLongPress: _onAyahLongPress,
      onMissingFile: service.markBroken,
    );

    final firstSurah = pageContent.firstSurah;
    final juzNumber = pageContent.juzNumber;
    final hizbText = pageContent.hizbText;

    if (widget.displayMode == HorizontalPageDisplayMode.zoomed) {
      return _buildZoomedLayout(
        context,
        pageImage,
        packLayout,
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
                    height:
                        _baselineWidth / packLayout.aspectRatio +
                        _pageTopSpace +
                        _pageBottomSpace,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: _pageTopSpace,
                        bottom: _pageBottomSpace,
                      ),
                      child: pageImage,
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
    Widget pageImage,
    MushafPackLayout packLayout,
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
                    AspectRatio(
                      aspectRatio: packLayout.aspectRatio,
                      child: pageImage,
                    ),
                    SizedBox(
                      height:
                          MediaQuery.sizeOf(context).width *
                              _pageBottomSpace /
                              _baselineWidth +
                          _refH(context, 44),
                    ),
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
        // In a spread both pills sit by the spine, wherever the hizb falls.
        alignment: switch (widget.rightOfSpread) {
          true => Alignment.centerLeft,
          false => Alignment.centerRight,
          null => hasHizb ? Alignment.centerLeft : Alignment.centerRight,
        },
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

  /// Room for the header and footer overlays, in the 470-wide page units.
  static const double _pageTopSpace = 40;
  static const double _pageBottomSpace = 50;

  /// Lifts Tajweed ink and colors for dark backgrounds, as the font reader did.
  static const _tajweedDarkFilter = ColorFilter.matrix(<double>[
    0.3, 0, 0, 0, 180, //
    0, 0.3, 0, 0, 180, //
    0, 0, 0.3, 0, 180, //
    0, 0, 0, 1, 0, //
  ]);

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

/// One Mushaf page image with its themed overlays, sized by its parent to the
/// pack's aspect ratio. Layout rects are in image pixels.
class _MushafPageImage extends StatefulWidget {
  final File file;
  final MushafPackLayout packLayout;
  final MushafPageLayout layout;

  /// Mask packs: ink color, and the color of ayah-number glyphs.
  final Color? tint;
  final Color? markerTint;

  /// Color packs: optional whole-page filter (Tajweed dark mode).
  final ColorFilter? filter;
  final Map<(int, int), Color> highlights;
  final Set<(int, int)> hidden;
  final Color background;
  final Widget Function(int surah) bannerBuilder;
  final void Function(int surah, int ayah) onLongPress;
  final VoidCallback onMissingFile;

  const _MushafPageImage({
    required this.file,
    required this.packLayout,
    required this.layout,
    required this.tint,
    required this.markerTint,
    required this.filter,
    required this.highlights,
    required this.hidden,
    required this.background,
    required this.bannerBuilder,
    required this.onLongPress,
    required this.onMissingFile,
  });

  @override
  State<_MushafPageImage> createState() => _MushafPageImageState();
}

class _MushafPageImageState extends State<_MushafPageImage> {
  ImageStream? _stream;
  ImageInfo? _imageInfo;
  bool _failed = false;
  late final _listener = ImageStreamListener(_onImage, onError: _onError);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_MushafPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) _resolve();
  }

  /// Decodes at (at most) the screen's physical width instead of the full
  /// 1260 px, bucketed so pages share cache keys.
  ImageProvider _provider() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width * media.devicePixelRatio;
    final width = math.min(
      widget.packLayout.imageWidth,
      ((screenWidth / 120).ceil() * 120).clamp(120, 1 << 14),
    );
    return ResizeImage(FileImage(widget.file), width: width);
  }

  void _resolve() {
    final stream = _provider().resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream;
    _failed = false;
    stream.addListener(_listener);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    setState(() {
      _imageInfo?.dispose();
      _imageInfo = info;
      _failed = false;
    });
  }

  void _onError(Object error, StackTrace? stack) {
    debugPrint('Mushaf page ${widget.file.path}: $error');
    if (!widget.file.existsSync()) {
      widget.onMissingFile();
      return;
    }
    if (mounted) setState(() => _failed = true);
  }

  void _retry() {
    final key = _stream?.key;
    _stream?.removeListener(_listener);
    _stream = null;
    if (key != null) PaintingBinding.instance.imageCache.evict(key);
    _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _imageInfo?.dispose();
    super.dispose();
  }

  void _handleLongPress(LongPressStartDetails details, double scale) {
    final hit = widget.layout.ayahAt(details.localPosition / scale);
    if (hit != null) widget.onLongPress(hit.surah, hit.ayah);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: IconButton(
          onPressed: _retry,
          icon: const Icon(Icons.refresh),
          tooltip: AppLocalizations.of(context)!.retry,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / widget.packLayout.imageWidth;
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: const Duration(milliseconds: 400),
                  ),
                  (recognizer) =>
                      recognizer.onLongPressStart = (details) =>
                          _handleLongPress(details, scale),
                ),
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MushafPagePainter(
                    image: _imageInfo?.image,
                    layout: widget.layout,
                    scale: scale,
                    tint: widget.tint,
                    markerTint: widget.markerTint,
                    filter: widget.filter,
                    highlights: widget.highlights,
                    hidden: widget.hidden,
                    background: widget.background,
                  ),
                ),
              ),
              if (_imageInfo != null)
                for (final banner in widget.layout.banners)
                  Positioned.fromRect(
                    rect: _scaleRect(banner.rect, scale),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _bannerWidth,
                        height: _bannerHeight,
                        child: widget.bannerBuilder(banner.surah),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  /// Banner slot size in the 470-wide page units the generator used.
  static const _bannerWidth = 462.0;
  static const _bannerHeight = 60.0;
}

Rect _scaleRect(Rect rect, double scale) => Rect.fromLTRB(
  rect.left * scale,
  rect.top * scale,
  rect.right * scale,
  rect.bottom * scale,
);

class _MushafPagePainter extends CustomPainter {
  final ui.Image? image;
  final MushafPageLayout layout;
  final double scale;
  final Color? tint;
  final Color? markerTint;
  final ColorFilter? filter;
  final Map<(int, int), Color> highlights;
  final Set<(int, int)> hidden;
  final Color background;

  _MushafPagePainter({
    required this.image,
    required this.layout,
    required this.scale,
    required this.tint,
    required this.markerTint,
    required this.filter,
    required this.highlights,
    required this.hidden,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;

    for (final segment in layout.ayahs) {
      final color = highlights[(segment.surah, segment.ayah)];
      if (color == null) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          _scaleRect(segment.rect, scale),
          Radius.circular(4 * scale),
        ),
        Paint()..color = color,
      );
    }

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Offset.zero & size;
    // Filters apply per draw: no offscreen layer while pages scroll.
    Paint imagePaint(Color? color, ColorFilter? colorFilter) => Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : colorFilter;

    canvas.drawImageRect(image, src, dst, imagePaint(tint, filter));

    final markerTint = this.markerTint;
    if (markerTint != null && markerTint != tint) {
      final paint = imagePaint(markerTint, null);
      for (final marker in layout.markers) {
        canvas.save();
        canvas.clipRect(_scaleRect(marker.rect, scale));
        canvas.drawImageRect(image, src, dst, paint);
        canvas.restore();
      }
    }

    if (hidden.isNotEmpty) {
      final cover = Paint()..color = background;
      for (final segment in layout.ayahs) {
        if (hidden.contains((segment.surah, segment.ayah))) {
          canvas.drawRect(_scaleRect(segment.rect, scale), cover);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MushafPagePainter old) =>
      old.image != image ||
      old.layout != layout ||
      old.scale != scale ||
      old.tint != tint ||
      old.markerTint != markerTint ||
      old.filter != filter ||
      old.background != background ||
      !mapEquals(old.highlights, highlights) ||
      !setEquals(old.hidden, hidden);
}
