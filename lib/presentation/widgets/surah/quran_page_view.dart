import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/get_fonts.dart';
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
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/surah/quran_reader_parts.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/ayah_bottom_sheet_modal_tabbed.dart';
import 'package:huda/presentation/widgets/surah/quran_share_sheet.dart';
import 'package:huda/presentation/widgets/surah/quran_ayah_marks.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/presentation/widgets/surah/memorization_completed_dialog.dart';
import 'package:huda/core/routes/app_route.dart';

import '../../../core/mixins/surah/audio_manager_mixin.dart';
import '../../../core/mixins/surah/download_manager_mixin.dart';
import '../../../core/mixins/surah/offline_cache_manager_mixin.dart';
import '../../../core/mixins/surah/switch_handlers_mixin.dart';
import '../../../core/mixins/surah/modal_manager_mixin.dart';
import '../../../core/mixins/surah/state_validators_mixin.dart';
import '../../../core/mixins/surah/reading_position_tracker_mixin.dart';

import 'package:huda/core/utils/ui_performance_utils.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/surah/quran_ayah_flash.dart';

class QuranPageView extends StatefulWidget {
  final SurahModel surah;
  final int surahNumber;
  final int? scrollToAyah;

  final bool flashAyah;

  final VoidCallback? onFlashShown;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;
  final Color? customBgColor;
  final Color? customTextColor;

  final ValueChanged<int>? onOpenSurah;

  final BuildContext? overlayContext;

  final bool showHeader;

  static const double measure = 720;

  static bool isWide(Size size) => size.width >= 840 && size.height >= 560;

  static double? sheetWidth(Size size) =>
      isWide(size) ? math.min(size.width - 96, 1000) : null;

  static double ayahScale(Size size) => !isWide(size)
      ? 1
      : size.width >= 1280
      ? 1.3
      : 1.18;

  @visibleForTesting
  static final debugPlayingAyah = ValueNotifier<int?>(null);

  const QuranPageView({
    super.key,
    required this.surah,
    required this.surahNumber,
    this.scrollToAyah,
    this.flashAyah = false,
    this.onFlashShown,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
    this.customBgColor,
    this.customTextColor,
    this.onOpenSurah,
    this.overlayContext,
    this.showHeader = true,
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
        ReadingPositionTracker,
        SingleTickerProviderStateMixin {
  late final AnimationController _flash;

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
      updateReadingPosition(ayahNumber: playingAyahIndex! + 1, position: 0.0);
    }
  }

  void _onDebugPlaying() {
    if (!mounted) return;
    setState(() => playingAyahIndex = QuranPageView.debugPlayingAyah.value);
  }

  @override
  void initState() {
    super.initState();
    _flash = QuranAyahFlash.controller(this);
    if (QuranPageView.debugPlayingAyah.value != null) {
      playingAyahIndex = QuranPageView.debugPlayingAyah.value;
    }
    QuranPageView.debugPlayingAyah.addListener(_onDebugPlaying);
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
          '📍 Auto-restoring reading position (Continue Reading flow)',
        );
        _restoreScrollPosition();
      } else {
        debugPrint('🚫 Skipping auto-restore (fresh start from Surah list)');
      }

      final readingService = getIt<ReadingPositionService>();
      final lastRead = readingService.getLastReadSummary();

      if (!widget.isBookmarkVisit &&
          (lastRead == null || lastRead['surahNumber'] != widget.surahNumber)) {
        debugPrint('🆕 Setting initial reading position for new surah');
        updateReadingPosition(ayahNumber: 1, position: 0.0);
      } else if (widget.isBookmarkVisit) {
        debugPrint('🔖 Bookmark visit - skipping reading position updates');
      } else {
        debugPrint(
          '🔄 Skipping initial position - will restore saved position',
        );
      }
    });
  }

  void _syncSourcesFromCubits() {
    final tafsirSources = context.read<TafsirCubit>().lastKnownSources;
    final translationSources = context
        .read<TranslationCubit>()
        .lastKnownSources;
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
    QuranPageView.debugPlayingAyah.removeListener(_onDebugPlaying);
    _flash.dispose();
    _saveFinalPosition();

    super.dispose();
  }

  void _saveFinalPosition() {
    if (widget.isBookmarkVisit) {
      debugPrint('🔖 Bookmark visit ending - not saving position');
      return;
    }

    debugPrint('💾 Screen dispose - relying on mixin\'s throttled saves');
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

      final int targetIndex = savedAyah;

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

    final ayat = widget.surah.ayahs?.length ?? 1;
    return visibleItem.index.clamp(1, ayat);
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
    final language = Localizations.localeOf(context).languageCode;
    final ref = QuranSurahRef.number(widget.surahNumber, language);
    final colors = QuranPageColors.of(
      context,
      customPage: widget.customBgColor,
      customInk: widget.customTextColor,
    );
    final font = getQuranFonts();
    final ayat = widget.surah.ayahs ?? const <Ayahs>[];
    final space = context.tokens.space;
    final playing = playingAyahIndex;
    final flashTarget = widget.flashAyah ? widget.scrollToAyah : null;
    final found = flashTarget == null
        ? null
        : QuranAyahFlash.drive(context, _flash);
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
      child: ColoredBox(
        color: colors.page,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final gutter = space.gutter(width);
                  final area = Size(width, MediaQuery.sizeOf(context).height);
                  final sheet = QuranPageView.sheetWidth(area);
                  final side = sheet == null
                      ? math.max(gutter, (width - QuranPageView.measure) / 2)
                      : (width - sheet) / 2 + space.xxl;
                  final ayahScale = QuranPageView.ayahScale(area);
                  final compact = context.windowClass.isCompactHeight;
                  final list = QuranIlluminate(
                    builder: (context, draw) =>
                        BlocBuilder<MemorizationCubit, MemorizationState>(
                          builder: (context, memState) {
                            final memorizing =
                                memState is MemorizationModeUpdated &&
                                memState.isMemorizationMode;
                            return ScrollablePositionedList.builder(
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              itemCount: ayat.length + 2,
                              padding: context.scrollPadding(
                                EdgeInsets.fromLTRB(side, 0, side, space.xl),
                              ),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  if (!widget.showHeader) {
                                    return SizedBox(height: space.md);
                                  }
                                  return QuranSurahHeader(
                                    surah: ref,
                                    colors: colors,
                                    fontFamily: font,
                                    draw: draw,
                                    compact: compact,
                                    scale: ayahScale,
                                  );
                                }
                                if (index == ayat.length + 1) {
                                  return QuranSurahEnd(
                                    surah: widget.surahNumber,
                                    onOpen: _openSurah,
                                  );
                                }
                                final ayahIndex = index - 1;
                                final ayah = ayat[ayahIndex];
                                final hidden =
                                    memorizing &&
                                    memState.hiddenAyahIndices.contains(
                                      ayahIndex,
                                    );
                                final translation =
                                    selectedTranslationId != null &&
                                        currentTranslation != null
                                    ? _getTranslationTextForAyah(ayahIndex)
                                    : null;
                                return Column(
                                  children: [
                                    if (ayahIndex > 0)
                                      QuranAyahRule(colors: colors),
                                    QuranAyahBlock(
                                      scale: ayahScale,
                                      number: ayah.numberInSurah ?? index,
                                      text: _getAyahText(ayah),
                                      colors: colors,
                                      fontFamily: font,
                                      translation: translation,
                                      translationSource: translation == null
                                          ? null
                                          : _getTranslationSourceName(),
                                      marks: QuranAyahMarks(
                                        surahNumber: widget.surahNumber,
                                        ayahNumber: ayah.numberInSurah ?? index,
                                      ),
                                      playing: playing == ayahIndex,
                                      found:
                                          (ayah.numberInSurah ?? index) ==
                                              flashTarget
                                          ? found
                                          : null,
                                      hidden: hidden,
                                      listening: hidden && memState.isListening,
                                      onTap: () {
                                        if (hidden) {
                                          context
                                              .read<MemorizationCubit>()
                                              .startListening();
                                        } else {
                                          onAyahTap(ayahIndex);
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                  );
                  if (sheet == null) return list;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: colors.backdrop),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: (width - sheet) / 2,
                        width: sheet,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.page,
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: colors.accent.withValues(alpha: 0.35),
                                width: context.tokens.stroke.hairline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      list,
                    ],
                  );
                },
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final bar = playing == null
                    ? const SizedBox(width: double.infinity)
                    : QuranPlayerBar(
                        ayah: playing + 1,
                        total: ayat.length,
                        playing: isAudioPlaying,
                        position: currentPosition,
                        duration: totalDuration,
                        onPrevious: playing > 0 ? _previousAyah : null,
                        onPlayPause: _togglePlayPause,
                        onNext: playing < ayat.length - 1 ? _nextAyah : null,
                        onOpen: () => _showAyahBottomSheet(playing),
                      );
                final sheet = QuranPageView.sheetWidth(
                  Size(constraints.maxWidth, MediaQuery.sizeOf(context).height),
                );
                final player = sheet == null || playing == null
                    ? bar
                    : ColoredBox(
                        color: colors.backdrop,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: sheet),
                            child: bar,
                          ),
                        ),
                      );
                final tokens = context.tokens;
                final duration = tokens.motion.of(
                  context,
                  tokens.motion.medium,
                );
                if (duration == Duration.zero) return player;
                return AnimatedSize(
                  duration: duration,
                  curve: tokens.motion.standard,
                  alignment: Alignment.topCenter,
                  child: player,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSurah(int number) {
    final open = widget.onOpenSurah;
    if (open != null) {
      open(number);
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      AppRoute.surahScreen,
      arguments: {
        'surahInfo': QuranSurahRef.index[number - 1],
        'scrollToAyah': null,
        'shouldRestorePosition': false,
      },
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
      return AppLocalizations.of(context)!.translationNotAvailable;
    }

    final surah = currentTranslation!.data!.surahs!.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => tafsir.Surahs(),
    );

    if (surah.ayahs == null || surah.ayahs!.length <= ayahIndex) {
      return AppLocalizations.of(context)!.translationNotAvailable;
    }

    return surah.ayahs![ayahIndex].text ??
        AppLocalizations.of(context)!.translationNotAvailable;
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
    } else if (state is AudioOffline || state is AudioError) {
      setState(() => isLoadingAudio = false);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => safeModalSetState());
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
    BuildContext context,
    TranslationState state,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) => safeModalSetState());
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

  String _ayahSheetTitle(int ayah) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final surah = QuranSurahRef.number(widget.surahNumber, language);
    return '${surah.title} · ${l10n.ayahNumber(ayah)}';
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
      showHudaSheet<void>(
        context: widget.overlayContext ?? context,
        title: _ayahSheetTitle(ayah.numberInSurah ?? index + 1),
        sideSheet: true,
        builder: (modalContext) {
          return Builder(
            builder: (draggableContext) {
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
                      offlineMessage = AppLocalizations.of(
                        context,
                      )!.quranOfflineLoading;
                    } else if (!offlineCacheLoaded) {
                      offlineMessage = AppLocalizations.of(
                        context,
                      )!.quranOfflineLoading;
                    } else if (cachedDownloadedReaders.isEmpty &&
                        cachedDownloadedTafsirSources.isEmpty &&
                        cachedDownloadedTranslationSources.isEmpty) {
                      offlineMessage = AppLocalizations.of(
                        context,
                      )!.offlineAudioUnavailable;
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

                          if (offlineMessage !=
                              AppLocalizations.of(
                                context,
                              )!.quranOfflineLoading) {
                            offlineMessage = AppLocalizations.of(
                              context,
                            )!.quranOfflineLoading;
                          }
                        } else if (offlineCacheLoaded) {
                          availableReadersForModal = cachedDownloadedReaders;
                          availableTafsirForModal =
                              cachedDownloadedTafsirSources;
                          availableTranslationForModal =
                              cachedDownloadedTranslationSources;

                          if (offlineMessage ==
                              AppLocalizations.of(
                                context,
                              )!.quranOfflineLoading) {
                            offlineMessage = null;
                          }
                        } else {
                          preloadOfflineCache();
                          availableReadersForModal = _availableReaders;
                          availableTafsirForModal = _availableTafsirSources;
                          availableTranslationForModal =
                              _availableTranslationSources;
                          offlineMessage = AppLocalizations.of(
                            context,
                          )!.quranOfflineLoading;
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
                          readersLoading: audioCubit.state is ReaderLoading,
                          tafsirLoading: tafsirCubit.state is TafsirLoading,
                          onRetryTafsir: tafsirCubit.fetchTafsirInfo,
                          translationLoading:
                              translationCubit.state is TranslationLoading,
                          onRetryTranslation:
                              translationCubit.fetchTranslationInfo,
                          onRetryReaders: () => audioCubit.fetchAudioInfo(
                            '${widget.surahNumber}',
                          ),
                          onShare: (translation, tafsir) {
                            Navigator.pop(modalContext);
                            shareAyah(
                              widget.overlayContext ?? context,
                              surah: widget.surahNumber,
                              ayah: ayah.numberInSurah ?? index + 1,
                              text: _getAyahText(ayah),
                              translation: translation,
                              tafsir: tafsir,
                            );
                          },
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
                          audioRange: audioRange,
                          onAudioRangeChanged: configureAudioRange,
                          onPlayPause: playPauseAudio,
                          onPrevious: (currentIndex) =>
                              skipToPreviousAyah(currentIndex),
                          onNext: (currentIndex) => skipToNextAyah(
                            currentIndex,
                            widget.surah.ayahs?.length ?? 0,
                          ),
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
                            () => autoplayEnabled = value ?? true,
                          ),
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
                                language,
                                setModalState,
                              ),
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

    final int targetIndex = targetAyah;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        final scrolled = _itemScrollController.scrollTo(
          index: targetIndex,
          alignment: widget.flashAyah ? 0.03 : 0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
        _currentVisibleAyah = targetAyah;
        debugPrint('✅ Scrolled to bookmarked ayah $targetAyah');
        if (!widget.flashAyah) return;
        await scrolled;
        if (!mounted) return;
        widget.onFlashShown?.call();
        unawaited(_flash.forward(from: 0));
      });
    });
  }
}
