import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show mapEquals, setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/quran/mushaf_page_content.dart';
import 'package:huda/core/quran/mushaf_pagination.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/surah/quran_ayah_flash.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
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

@immutable
class MushafLayout {
  const MushafLayout({this.twoPages, this.zoomed = false});

  final bool? twoPages;
  final bool zoomed;

  static const zoomKey = 'mushaf_zoomed';

  static MushafLayout read(CacheHelper cache) {
    final pages = cache.getData(key: HorizontalPageDisplayMode.key) as String?;
    final zoom = cache.getData(key: zoomKey);
    final legacyZoom = pages == HorizontalPageDisplayMode.zoomed.storageValue;
    return MushafLayout(
      twoPages: switch (pages) {
        null => null,
        _ when pages == HorizontalPageDisplayMode.doublePage.storageValue =>
          true,
        _ => false,
      },
      zoomed: zoom is bool ? zoom : legacyZoom,
    );
  }

  Future<void> write(CacheHelper cache) async {
    final pages = twoPages;
    if (pages == null) {
      await cache.removeData(key: HorizontalPageDisplayMode.key);
    } else {
      await cache.saveData(
        key: HorizontalPageDisplayMode.key,
        value:
            (pages
                    ? HorizontalPageDisplayMode.doublePage
                    : HorizontalPageDisplayMode.normal)
                .storageValue,
      );
    }
    await cache.saveData(key: zoomKey, value: zoomed);
  }

  MushafLayout copyWith({bool? twoPages, bool? zoomed}) => MushafLayout(
    twoPages: twoPages ?? this.twoPages,
    zoomed: zoomed ?? this.zoomed,
  );

  @override
  bool operator ==(Object other) =>
      other is MushafLayout &&
      other.twoPages == twoPages &&
      other.zoomed == zoomed;

  @override
  int get hashCode => Object.hash(twoPages, zoomed);

  @override
  String toString() => 'MushafLayout(${twoPages ?? 'auto'}, zoom: $zoomed)';
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

  final MushafLayout layout;
  final MushafFlipDirection flipDirection;

  final (int, int)? flashAyah;

  final VoidCallback? onFlashShown;

  const QuranMushafPageView({
    super.key,
    required this.initialPageNumber,
    required this.mode,
    this.flashAyah,
    this.onFlashShown,
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
    this.layout = const MushafLayout(),
    this.flipDirection = MushafFlipDirection.horizontal,
  });

  static Color paperOf(BuildContext context, [Color? custom]) {
    if (custom != null) return custom;
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surface
        : Color.lerp(scheme.surfaceContainerLowest, scheme.tertiary, 0.07)!;
  }

  static bool showsSpread(Size size, FoldInfo fold, {bool? twoPages}) {
    if (!allowsSpread(size, fold)) return false;
    if (twoPages != null) return twoPages;
    if (fold.splitsHorizontally) return true;
    return size.width >= 840 &&
        size.width >= size.height * 1.25 &&
        size.height >= 560;
  }

  static bool allowsSpread(Size size, FoldInfo fold) =>
      fold.splitsHorizontally || size.width > size.height;

  static bool keepsPageOffHinge(FoldInfo fold) =>
      fold.splitsHorizontally && (fold.isHalfOpened || fold.bounds.width > 0);

  @override
  State<QuranMushafPageView> createState() => _QuranMushafPageViewState();
}

class _QuranMushafPageViewState extends State<QuranMushafPageView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  bool _flashStarted = false;

  void _onFlashReady() {
    if (_flashStarted) return;
    _flashStarted = true;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      widget.onFlashShown?.call();
      unawaited(_flash.forward(from: 0));
    });
  }

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
    if (!widget.mode.isMushaf) return false;
    return QuranMushafPageView.showsSpread(
      MediaQuery.sizeOf(context),
      FoldInfo.of(context),
      twoPages: widget.layout.twoPages,
    );
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
    _flash = QuranAyahFlash.controller(this);
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.initialPageNumber.clamp(1, _pageCount);

    _currentIsDoubleMode = false;
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
        oldWidget.layout != widget.layout ||
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
    _flash.dispose();
    _contentCache.clear();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _packService;
    if (service == null) return _insetPages(context, null);
    return StreamBuilder<MushafPackState>(
      stream: service.stateStream,
      initialData: service.currentState,
      builder: (context, _) => service.isReady
          ? _insetPages(context, service)
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
    bool scrolls = true,
  }) => _QuranMushafPage(
    key: ValueKey(pageNumber),
    contentCache: _contentCache,
    packService: service,
    pageNumber: pageNumber,
    rightOfSpread: rightOfSpread,
    playingSurahNumber: widget.playingSurahNumber,
    playingAyahNumber: widget.playingAyahNumber,
    flashAyah: _flashStarted && _flash.isCompleted ? null : widget.flashAyah,
    flashLevel: QuranAyahFlash.drive(context, _flash),
    onFlashReady: _onFlashReady,
    isMemorizationMode: widget.isMemorizationMode,
    hiddenAyahIndices: widget.hiddenAyahIndices,
    memorizedSurahNumber: widget.memorizedSurahNumber,
    onAyahTap: widget.onAyahTap,
    onAyahLongPress: widget.onAyahLongPress,
    customBgColor: widget.customBgColor,
    customTextColor: widget.customTextColor,
    zoomed: widget.layout.zoomed,
    scrolls: scrolls,
  );

  Widget _insetPages(BuildContext context, MushafPackService? service) =>
      Padding(
        padding: MediaQuery.paddingOf(context).copyWith(bottom: 0),
        child: _buildPageView(context, service),
      );

  Widget _buildPageView(BuildContext context, MushafPackService? service) {
    if (_currentIsDoubleMode) {
      final spreadCount = (_pageCount / 2).ceil();
      return _framePages(
        context,
        single: false,
        Listener(
          onPointerSignal: _handlePointerScroll,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              allowImplicitScrolling: true,
              key: ObjectKey(_pageController),
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
              itemCount: spreadCount,
              onPageChanged: (spreadIndex) {
                final rightPage = (spreadIndex * 2 + 1).clamp(1, _pageCount);
                setState(() => _currentPage = rightPage);
                widget.onPageChanged?.call(rightPage);
              },
              itemBuilder: (context, spreadIndex) {
                final rightPage = spreadIndex * 2 + 1;
                final leftPage = spreadIndex * 2 + 2;
                final fold = FoldInfo.of(context);
                final band = fold.splitsHorizontally ? fold.bounds.width : 0.0;
                if (widget.layout.zoomed) {
                  return ColoredBox(
                    color: QuranMushafPageView.paperOf(
                      context,
                      widget.customBgColor,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _page(
                                  service,
                                  rightPage.clamp(1, _pageCount),
                                  rightOfSpread: true,
                                  scrolls: false,
                                ),
                              ),
                              SizedBox(width: math.max(band, 16)),
                              Expanded(
                                child: leftPage <= _pageCount
                                    ? _page(
                                        service,
                                        leftPage,
                                        rightOfSpread: false,
                                        scrolls: false,
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                          if (band <= 0)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _page(
                        service,
                        rightPage.clamp(1, _pageCount),
                        rightOfSpread: true,
                      ),
                    ),
                    if (band > 0)
                      SizedBox(width: band)
                    else
                      Container(
                        width: 1.0,
                        color: Theme.of(context).colorScheme.outlineVariant,
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
        ),
      );
    }

    final pages = Listener(
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
    return _framePages(context, pages, single: true);
  }

  Widget _framePages(
    BuildContext context,
    Widget pages, {
    required bool single,
  }) {
    final fold = FoldInfo.of(context);
    final bounds = fold.bounds;
    if (single && QuranMushafPageView.keepsPageOffHinge(fold)) {
      final media = MediaQuery.of(context);
      final right = math.max(
        0.0,
        media.size.width - fold.end - media.padding.right,
      );
      return Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: right, child: pages),
          const Expanded(child: SizedBox()),
        ],
      );
    }
    if (!fold.isTabletop) return pages;
    return Column(
      children: [
        SizedBox(
          height: math.max(0, bounds.top - MediaQuery.paddingOf(context).top),
          child: pages,
        ),
        SizedBox(height: bounds.height),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: _TabletopPageControls(
              page: _currentPage,
              pageCount: _pageCount,
              onPrevious: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              ),
              onNext: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletopPageControls extends StatelessWidget {
  const _TabletopPageControls({
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(space.md),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: l10n.previous,
            onPressed: page > 1 ? onPrevious : null,
            icon: const Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.chevron_right_rounded),
            ),
          ),
          SizedBox(width: space.lg),
          Text(l10n.mushafPageNumber(page), style: theme.textTheme.titleMedium),
          SizedBox(width: space.lg),
          IconButton.outlined(
            tooltip: l10n.next,
            onPressed: page < pageCount ? onNext : null,
            icon: const Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.chevron_left_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final state = service.currentState;
    final Widget body;
    switch (state.status) {
      case MushafPackStatus.downloading:
      case MushafPackStatus.extracting:
      case MushafPackStatus.loading:
        final downloading = state.status == MushafPackStatus.downloading;
        body = HudaStateView(
          title: l.mushafPackTitle,
          mark: HudaStateMark.lit,
          icon: Icons.auto_stories_rounded,
          message: downloading
              ? '${(state.progress * 100).toInt()}%'
              : state.status == MushafPackStatus.extracting
              ? l.fontExtractingLabel
              : l.fontLoadingLabel,
          actions: [
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  const HudaLampSpinner(size: 20),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: downloading ? state.progress : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case MushafPackStatus.error:
        body = HudaErrorState(
          title: l.mushafPackTitle,
          message: l.failedToLoad,
          onRetry: service.downloadAndInstall,
        );
      case MushafPackStatus.idle:
      case MushafPackStatus.ready:
        body = HudaPermissionState(
          icon: Icons.download_rounded,
          title: l.mushafPackTitle,
          explanation: l.mushafPackBody,
          allowLabel: l.mushafPackDownload(service.pack.sizeLabel),
          onAllow: service.downloadAndInstall,
        );
    }
    return ColoredBox(
      key: const ValueKey('quran-mushaf-pack'),
      color: QuranMushafPageView.paperOf(context, customBgColor),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: customTextColor ?? theme.colorScheme.onSurface),
        child: body,
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

  final (int, int)? flashAyah;
  final Animation<double>? flashLevel;
  final VoidCallback? onFlashReady;
  final bool isMemorizationMode;
  final Set<int> hiddenAyahIndices;
  final int memorizedSurahNumber;
  final void Function(int surahNumber, int verseNumber)? onAyahTap;
  final void Function(int surahNumber, int verseNumber)? onAyahLongPress;
  final Color? customBgColor;
  final Color? customTextColor;

  final bool zoomed;

  final bool scrolls;

  final bool? rightOfSpread;

  const _QuranMushafPage({
    super.key,
    required this.contentCache,
    required this.packService,
    required this.pageNumber,
    this.rightOfSpread,
    this.playingSurahNumber,
    this.playingAyahNumber,
    this.flashAyah,
    this.flashLevel,
    this.onFlashReady,
    this.isMemorizationMode = false,
    this.hiddenAyahIndices = const {},
    this.memorizedSurahNumber = 0,
    this.onAyahTap,
    this.onAyahLongPress,
    this.customBgColor,
    this.customTextColor,
    this.zoomed = false,
    this.scrolls = true,
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
      Theme.of(context).colorScheme.primary;

  Color _bgColor(bool isDark) =>
      QuranMushafPageView.paperOf(context, widget.customBgColor);

  Color _textColor(bool isDark) =>
      widget.customTextColor ?? Theme.of(context).colorScheme.onSurface;

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

      final scheme = Theme.of(context).colorScheme;
      Color? color;
      if (isPressed || isPlaying) {
        color = accent.withValues(alpha: 0.2);
      } else if (hasStar) {
        color = scheme.tertiary.withValues(alpha: 0.24);
      } else if (hasNote) {
        color = scheme.secondary.withValues(alpha: 0.22);
      } else if (hasBookmark) {
        color = (bookmarkColor ?? accent).withValues(alpha: 0.28);
      } else if (isKhatmaStart || isKhatmaEnd) {
        color = accent.withValues(alpha: 0.14);
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
    final flash = widget.flashAyah;
    final flashHere =
        flash != null &&
        pageLayout.ayahs.any((a) => (a.surah, a.ayah) == flash);
    final pageImage = _MushafPageImage(
      flash: flashHere ? flash : null,
      flashLevel: widget.flashLevel,
      flashColor: Theme.of(context).colorScheme.tertiary,
      revealFlash: widget.zoomed,
      onFlashReady: widget.onFlashReady,
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

    if (widget.zoomed) {
      final zoomed = _buildZoomedLayout(
        context,
        pageImage,
        packLayout,
        firstSurah,
        juzNumber,
        hizbText,
        isDark,
        scrolls: widget.scrolls,
      );
      if (!widget.scrolls) return zoomed;
      return ColoredBox(
        color: _bgColor(isDark),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _filledMaxWidth),
            child: zoomed,
          ),
        ),
      );
    }
    return _buildFittedLayout(
      context,
      pageImage,
      packLayout,
      firstSurah,
      juzNumber,
      hizbText,
      isDark,
    );
  }

  static const double _filledMaxWidth = 900;

  Widget _buildFittedLayout(
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
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _baselineWidth,
              height:
                  _baselineWidth / packLayout.aspectRatio +
                  _pageTopSpace +
                  _pageBottomSpace,
              child: Column(
                children: [
                  SizedBox(
                    height: _pageTopSpace,
                    child: _buildHeader(
                      context,
                      firstSurah,
                      juzNumber,
                      isDark,
                      scale: 1,
                    ),
                  ),
                  Expanded(child: pageImage),
                  SizedBox(
                    height: _pageBottomSpace,
                    child: _buildFooter(context, hizbText, isDark, scale: 1),
                  ),
                ],
              ),
            ),
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
    bool isDark, {
    bool scrolls = true,
  }) {
    final bottomInset = scrolls ? MediaQuery.paddingOf(context).bottom : 0.0;
    return Container(
      color: _bgColor(isDark),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / _baselineWidth;
          final page = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _pageTopSpace * scale,
                child: _buildHeader(
                  context,
                  firstSurah,
                  juzNumber,
                  isDark,
                  scale: scale,
                ),
              ),
              AspectRatio(
                aspectRatio: packLayout.aspectRatio,
                child: pageImage,
              ),
              SizedBox(
                height: _pageBottomSpace * scale,
                child: _buildFooter(context, hizbText, isDark, scale: scale),
              ),
              SizedBox(height: bottomInset),
            ],
          );
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1)),
            child: scrolls
                ? SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: page,
                  )
                : page,
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int surahNumber,
    int juzNumber,
    bool isDark, {
    required double scale,
  }) {
    final accent = _accentColor(context, isDark);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 10 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'سورة ${quran.getSurahNameArabic(surahNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16 * scale,
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'الجزء ${_getJuzNameArabic(juzNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16 * scale,
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
    const size = Size(
      _MushafPageImageState._bannerWidth,
      _MushafPageImageState._bannerHeight,
    );
    final cartouche = QuranHeadpiecePainter.cartoucheRect(size);
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: _bgColor(Theme.of(context).brightness == Brightness.dark),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: QuranHeadpiecePainter(
                color: Theme.of(context).colorScheme.primary,
                panel: _bgColor(
                  Theme.of(context).brightness == Brightness.dark,
                ),
                stroke: 1.3,
              ),
            ),
          ),
          Positioned.fromRect(
            rect: cartouche.deflate(cartouche.height * 0.1),
            child: FittedBox(
              child: Text(
                'surah${surahNum.toString().padLeft(3, '0')}',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'arsura',
                  fontSize: 40,
                  height: 1.1,
                  color: textColor,
                ),
              ),
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
        style: context.type.arabicLabel.copyWith(color: _textColor(isDark)),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    String? hizbText,
    bool isDark, {
    required double scale,
  }) {
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
      fontSize: 13 * scale,
      color: textBase.withValues(alpha: 0.85),
      fontWeight: FontWeight.bold,
    );

    final double bannerWidth = hasHizb ? 180 * scale : 90 * scale;
    final double bannerHeight = 28 * scale;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8 * scale,
        left: 12 * scale,
        right: 12 * scale,
      ),
      child: Align(
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
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
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

  static const double _baselineWidth = 470;

  static const double _pageTopSpace = 40;
  static const double _pageBottomSpace = 50;

  static const _tajweedDarkFilter = ColorFilter.matrix(<double>[
    0.3, 0, 0, 0, 180,
    0, 0.3, 0, 0, 180,
    0, 0, 0.3, 0, 180,
    0, 0, 0, 1, 0,
  ]);
}

class _MushafPageImage extends StatefulWidget {
  final File file;
  final MushafPackLayout packLayout;
  final MushafPageLayout layout;

  final Color? tint;
  final Color? markerTint;

  final ColorFilter? filter;
  final Map<(int, int), Color> highlights;
  final Set<(int, int)> hidden;
  final Color background;
  final Widget Function(int surah) bannerBuilder;
  final void Function(int surah, int ayah) onLongPress;
  final VoidCallback onMissingFile;

  final (int, int)? flash;
  final Animation<double>? flashLevel;
  final Color flashColor;

  final bool revealFlash;

  final VoidCallback? onFlashReady;

  const _MushafPageImage({
    this.flash,
    this.flashLevel,
    this.flashColor = const Color(0x00000000),
    this.revealFlash = false,
    this.onFlashReady,
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
    if (oldWidget.flash != widget.flash) _reportFlash();
  }

  void _reportFlash() {
    final flash = widget.flash;
    if (flash == null || _imageInfo == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.flash != flash) return;
      final box = context.findRenderObject();
      if (widget.revealFlash && box is RenderBox && box.hasSize) {
        final scale = box.size.width / widget.packLayout.imageWidth;
        Rect? area;
        for (final segment in widget.layout.ayahs) {
          if ((segment.surah, segment.ayah) != flash) continue;
          final rect = _scaleRect(segment.rect, scale);
          area = area?.expandToInclude(rect) ?? rect;
        }
        if (area != null) {
          box.showOnScreen(
            rect: area.inflate(48),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      }
      widget.onFlashReady?.call();
    });
  }

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
    final first = _imageInfo == null;
    setState(() {
      _imageInfo?.dispose();
      _imageInfo = info;
      _failed = false;
    });
    if (first) _reportFlash();
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
                    flash: widget.flash,
                    flashLevel: widget.flashLevel,
                    flashColor: widget.flashColor,
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

  final (int, int)? flash;
  final Animation<double>? flashLevel;
  final Color flashColor;

  _MushafPagePainter({
    this.flash,
    this.flashLevel,
    this.flashColor = const Color(0x00000000),
    required this.image,
    required this.layout,
    required this.scale,
    required this.tint,
    required this.markerTint,
    required this.filter,
    required this.highlights,
    required this.hidden,
    required this.background,
  }) : super(repaint: flashLevel);

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

    final flash = this.flash;
    final level = (flashLevel?.value ?? 0).clamp(0.0, 1.0);
    if (flash != null && level > 0) {
      final wash = Path();
      final feet = <Rect>[];
      for (final segment in layout.ayahs) {
        if ((segment.surah, segment.ayah) != flash) continue;
        final rect = _scaleRect(segment.rect, scale);
        wash.addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(6 * scale)),
        );
        feet.add(rect);
      }
      canvas.drawPath(
        wash,
        Paint()..color = flashColor.withValues(alpha: 0.22 * level),
      );
      final rule = Paint()
        ..strokeWidth = (2 * scale).clamp(1.0, 2.5)
        ..strokeCap = StrokeCap.round
        ..color = flashColor.withValues(alpha: 0.8 * level);
      for (final rect in feet) {
        final inset = rect.width * 0.04 + 6 * scale;
        final y = rect.bottom - rule.strokeWidth;
        canvas.drawLine(
          Offset(rect.left + inset, y),
          Offset(rect.right - inset, y),
          rule,
        );
      }
    }

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Offset.zero & size;
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
      old.flash != flash ||
      old.flashLevel != flashLevel ||
      old.flashColor != flashColor ||
      !mapEquals(old.highlights, highlights) ||
      !setEquals(old.hidden, hidden);
}
