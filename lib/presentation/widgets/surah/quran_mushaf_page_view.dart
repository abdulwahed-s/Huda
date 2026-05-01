import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/utils/hizb_calculator.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/khatma_service.dart';
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

class _QuranMushafPageViewState extends State<QuranMushafPageView> {
  late PageController _pageController;
  late int _currentPage;
  bool _currentIsDoubleMode = false;
  DateTime _lastScrollTime = DateTime.now();

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
    _currentPage = widget.initialPageNumber.clamp(1, quran.totalPagesCount);

    _currentIsDoubleMode =
        widget.displayMode == HorizontalPageDisplayMode.doublePage &&
            widget.mode.isMushaf;
    _pageController = PageController(
        initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldBeDouble = _calculateIsDoubleMode(context);
    if (_currentIsDoubleMode != shouldBeDouble) {
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
          initialPage: _toControllerPage(_currentPage, _currentIsDoubleMode));
    }
  }

  @override
  void didUpdateWidget(QuranMushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldBeDouble = _calculateIsDoubleMode(context);
    if (oldWidget.mode != widget.mode ||
        oldWidget.displayMode != widget.displayMode ||
        oldWidget.flipDirection != widget.flipDirection ||
        _currentIsDoubleMode != shouldBeDouble) {
      final savedPage = _currentPage;
      _currentIsDoubleMode = shouldBeDouble;
      _pageController.dispose();
      _pageController = PageController(
          initialPage: _toControllerPage(savedPage, _currentIsDoubleMode));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIsDoubleMode) {
      final spreadCount = (quran.totalPagesCount / 2).ceil();
      return Listener(
          onPointerSignal: _handlePointerScroll,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              key: const ValueKey('horizontal_double'),
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
                final rightPage =
                    (spreadIndex * 2 + 1).clamp(1, quran.totalPagesCount);
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
                      child: _QuranMushafPage(
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
          ));
    }

    return Listener(
        onPointerSignal: _handlePointerScroll,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            key: ValueKey(
                '${widget.mode}_${widget.displayMode}_${widget.flipDirection}'),
            scrollDirection:
                widget.flipDirection == MushafFlipDirection.vertical
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
            },
            itemBuilder: (context, index) {
              return _QuranMushafPage(
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
        ));
  }
}

class _QuranMushafPage extends StatefulWidget {
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

  int get pageNumber => widget.pageNumber;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    try {
      _bookmarkSub = getIt<BookmarkService>()
          .bookmarkChanges
          .listen((_) => _loadBookmarks());
    } catch (_) {}
    try {
      _khatmaSub = getIt<KhatmaService>().khatmaChanges.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await getIt<BookmarkService>().getAllBookmarks();
      if (mounted) setState(() => _bookmarks = bookmarks);
    } catch (_) {}
  }

  @override
  void dispose() {
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

    List pageContent;
    try {
      pageContent = quran.getPageData(pageNumber);
    } catch (_) {
      return _buildErrorPage(context, isDark);
    }

    if (pageContent.isEmpty) {
      return _buildErrorPage(context, isDark);
    }

    final firstSurah = pageContent[0]['surah'] as int;
    final firstVerse = pageContent[0]['start'] as int;
    final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
    final hizbText = getHizbTextForPage(pageContent);

    if (widget.displayMode == HorizontalPageDisplayMode.zoomed) {
      return _buildZoomedLayout(
          context, pageContent, firstSurah, juzNumber, hizbText, isDark);
    }

    return Container(
      color: _bgColor(isDark),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1),
        ),
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
    List pageContent,
    int firstSurah,
    int juzNumber,
    String? hizbText,
    bool isDark,
  ) {
    return Container(
      color: _bgColor(isDark),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1),
        ),
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
                            child:
                                _buildPageContent(context, pageContent, isDark),
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
          horizontal: _refW(context, 16), vertical: _refH(context, 10)),
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
    List pageContent,
    bool isDark,
  ) {
    final textColor = _textColor(isDark);
    final accent = _accentColor(context, isDark);
    final fontPrefix = widget.useTajweedFonts ? 'QCF_T' : 'QCF_P';
    final pageFontFamily =
        '$fontPrefix${pageNumber.toString().padLeft(3, '0')}';
    final fontSize = _verseFontSize(context, pageNumber);
    final lineHeight = _pageLineHeight(pageNumber);

    final List<InlineSpan> spans = [];

    for (final section in pageContent) {
      final surahNum = section['surah'] as int;
      final startVerse = section['start'] as int;
      final endVerse = section['end'] as int;

      for (int v = startVerse; v <= endVerse; v++) {
        if (v == startVerse && v == 1) {
          spans.add(WidgetSpan(
            child: _buildSurahBanner(context, surahNum, accent, textColor),
          ));

          if (pageNumber != 1 && pageNumber != 187) {
            spans.add(
              TextSpan(
                text: " ﱁ  ﱂﱃﱄ\n",
                style: TextStyle(
                  fontFamily: 'QCF_P001',
                  fontSize: 24.0,
                  color: textColor,
                ),
              ),
            );
          }
        }

        final String verseKey = '${surahNum}_$v';
        if (!_verseRecognizers.containsKey(verseKey)) {
          _verseRecognizers[verseKey] = LongPressGestureRecognizer(
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

        final rawQcf = quran.getVerseQCF(surahNum, v, verseEndSymbol: false);
        final isFirstVerseOnPage = v == (pageContent[0]['start'] as int) &&
            surahNum == (pageContent[0]['surah'] as int);
        final String qcfText = (isFirstVerseOnPage && rawQcf.length > 1)
            ? '${rawQcf.substring(0, 1)}\u200A${rawQcf.substring(1)}'
            : rawQcf;

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

        final khatmaService = getIt<KhatmaService>();
        final bool isKhatmaActive =
            khatmaService.enabled && !khatmaService.isCompleted;
        bool isKhatmaStart = false;
        bool isKhatmaEnd = false;

        if (isKhatmaActive) {
          final details = khatmaService.rangeDetailsForDay(
              khatmaService.currentDayIndex, khatmaService.planDays);
          if (surahNum == details.startSurah && v == details.startVerse) {
            isKhatmaStart = true;
          }
          if (surahNum == details.endSurah && v == details.endVerse) {
            isKhatmaEnd = true;
          }
        }

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
        final bool isPlaying = widget.playingSurahNumber == surahNum &&
            widget.playingAyahNumber == v;

        final Color? effectiveBgColor = (isPressed || isPlaying)
            ? accent.withValues(alpha: 0.2)
            : bookmarkBgColor;

        final int ayahIndex = v - 1;
        final bool isHidden = widget.isMemorizationMode &&
            surahNum == widget.memorizedSurahNumber &&
            widget.hiddenAyahIndices.contains(ayahIndex);
        final Color verseColor =
            isHidden ? textColor.withValues(alpha: 0) : textColor;

        final Paint? tajweedDarkPaint =
            (!isHidden && isDark && widget.useTajweedFonts)
                ? (Paint()
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
                  ]))
                : null;

        spans.add(TextSpan(
          text: qcfText,
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: pageFontFamily,
            fontSize: fontSize,
            color: tajweedDarkPaint == null ? verseColor : null,
            foreground: tajweedDarkPaint,
            height: lineHeight,
            backgroundColor: isHidden ? null : effectiveBgColor,
          ),
        ));

        spans.add(TextSpan(
          text: quran.getVerseNumberQCF(surahNum, v),
          style: TextStyle(
            fontFamily: pageFontFamily,
            color: accent,
            height: 1.35,
          ),
        ));
      }
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
    final double minAllPagesFontSize =
        (_baselineWidth * 0.045).clamp(18.0, 34.0);
    final double minFirstPagesFontSize =
        (_refDesignW * 0.075).clamp(26.0, 36.0);

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

    final double bannerWidth =
        hasHizb ? _refW(context, 180) : _refW(context, 90);
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
                  padding: EdgeInsets.symmetric(
                    horizontal: _refW(context, 16),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(pageStr, style: textStyle),
                        ),
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
              : Center(
                  child: Text(pageStr, style: textStyle),
                ),
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
      'الثلاثون'
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
