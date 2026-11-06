import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/surah/quran_reader_parts.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/presentation/widgets/surah/ayah_bottom_sheet_modal_tabbed.dart';
import 'package:huda/presentation/widgets/surah/quran_share_sheet.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/utils/ui_performance_utils.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

import 'package:huda/core/mixins/surah/audio_manager_mixin.dart';
import 'package:huda/core/mixins/surah/download_manager_mixin.dart';
import 'package:huda/core/mixins/surah/offline_cache_manager_mixin.dart';
import 'package:huda/core/mixins/surah/switch_handlers_mixin.dart';
import 'package:huda/core/mixins/surah/modal_manager_mixin.dart';
import 'package:huda/core/mixins/surah/state_validators_mixin.dart';

class MushafInteractiveWrapper extends StatefulWidget {
  final SurahModel surah;
  final int surahNumber;
  final int initialPageNumber;
  final QuranReadingMode mode;
  final MushafLayout layout;
  final MushafFlipDirection flipDirection;
  final ValueChanged<int>? onPageChanged;

  /// The page's surah, for the chrome's title, and the reader's actions
  /// (Surahs, Display, More), shown with Back when the chrome is.
  final String title;
  final List<Widget> actions;
  final Color? customBgColor;
  final Color? customTextColor;

  /// Verse of [surahNumber] whose ayah sheet opens once this is shown.
  final int? initialAyahSheet;

  /// Long-press on an ayah of another surah; the screen switches to it.
  final void Function(int surahNumber, int verseNumber)? onOtherSurahAyah;

  /// (surah, ayah) to light up once its page shows; see
  /// [QuranMushafPageView.flashAyah].
  final (int, int)? flashAyah;
  final VoidCallback? onFlashShown;

  const MushafInteractiveWrapper({
    super.key,
    required this.surah,
    required this.surahNumber,
    required this.initialPageNumber,
    required this.mode,
    this.layout = const MushafLayout(),
    this.flipDirection = MushafFlipDirection.horizontal,
    this.onPageChanged,
    this.title = '',
    this.actions = const [],
    this.customBgColor,
    this.customTextColor,
    this.initialAyahSheet,
    this.onOtherSurahAyah,
    this.flashAyah,
    this.onFlashShown,
  });

  @override
  State<MushafInteractiveWrapper> createState() =>
      _MushafInteractiveWrapperState();
}

class _MushafInteractiveWrapperState extends State<MushafInteractiveWrapper>
    with
        AudioManagerMixin,
        DownloadManagerMixin,
        OfflineCacheManagerMixin,
        SwitchHandlersMixin,
        ModalManagerMixin,
        StateValidatorsMixin {
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
  void initState() {
    super.initState();
    setupAudioListeners();
    checkOfflineStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSourcesFromCurrentCubitState();
      final verse = widget.initialAyahSheet;
      if (mounted && verse != null) _onMushafAyahTap(widget.surahNumber, verse);
    });
  }

  void _initSourcesFromCurrentCubitState() {
    if (!mounted) return;

    final tafsirSources = context.read<TafsirCubit>().lastKnownSources;
    final translationSources = context
        .read<TranslationCubit>()
        .lastKnownSources;
    final audioReaders = context.read<AudioCubit>().lastKnownReaders;

    setState(() {
      if (_availableTafsirSources.isEmpty && tafsirSources.isNotEmpty) {
        _availableTafsirSources = tafsirSources;
      }
      if (_availableTranslationSources.isEmpty &&
          translationSources.isNotEmpty) {
        _availableTranslationSources = translationSources;
      }
      if (_availableReaders.isEmpty && audioReaders.isNotEmpty) {
        _availableReaders = audioReaders;
      }
    });
  }

  bool _appBarVisible = false;

  /// The mode's page pack, when it reads page images.
  MushafPackService? get _pack {
    final pack = widget.mode.pack;
    if (pack == null) return null;
    try {
      return getIt<MushafPackService>(instanceName: pack.name);
    } catch (_) {
      return null;
    }
  }

  void _toggleAppBar() {
    setState(() => _appBarVisible = !_appBarVisible);
  }

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          GestureDetector(
            onTap: _toggleAppBar,
            behavior: HitTestBehavior.translucent,
            child: BlocBuilder<MemorizationCubit, MemorizationState>(
              builder: (context, memState) {
                final isMemorizationMode =
                    memState is MemorizationModeUpdated &&
                    memState.isMemorizationMode;
                final hiddenAyahIndices = isMemorizationMode
                    ? memState.hiddenAyahIndices
                    : const <int>{};
                final memSurahNumber = isMemorizationMode
                    ? memState.surahNumber
                    : 0;

                return QuranMushafPageView(
                  key: ValueKey(
                    '${widget.mode}_${widget.layout}_${widget.flipDirection}',
                  ),
                  initialPageNumber: widget.initialPageNumber,
                  mode: widget.mode,
                  layout: widget.layout,
                  flipDirection: widget.flipDirection,
                  flashAyah: widget.flashAyah,
                  onFlashShown: widget.onFlashShown,
                  playingSurahNumber: widget.surahNumber,
                  playingAyahNumber: playingAyahIndex != null
                      ? playingAyahIndex! + 1
                      : null,
                  isMemorizationMode: isMemorizationMode,
                  hiddenAyahIndices: hiddenAyahIndices,
                  memorizedSurahNumber: memSurahNumber,
                  customBgColor: widget.customBgColor,
                  customTextColor: widget.customTextColor,
                  onPageChanged: (page) {
                    widget.onPageChanged?.call(page);

                    if (isMemorizationMode) {
                      try {
                        final pageData = widget.mode.pagination.sectionsOf(
                          page,
                        );
                        final hasMemoSurah = pageData.any(
                          (s) => (s['surah'] as int) == memSurahNumber,
                        );
                        if (!hasMemoSurah) {
                          context
                              .read<MemorizationCubit>()
                              .toggleMemorizationMode([], 0);
                        }
                      } catch (_) {}
                    }
                  },
                  onAyahLongPress: _onMushafAyahTap,
                );
              },
            ),
          ),
          _buildOverlayAppBar(context),
          // The recitation's controls, with the chrome.
          if (playingAyahIndex != null)
            AnimatedPositioned(
              duration: _chromeDuration(context),
              curve: context.tokens.motion.standard,
              left: 0,
              right: 0,
              bottom: _appBarVisible ? 0 : -240,
              child: QuranPlayerBar(
                ayah: playingAyahIndex! + 1,
                total: widget.surah.ayahs?.length ?? 0,
                playing: isAudioPlaying,
                position: currentPosition,
                duration: totalDuration,
                onPrevious: playingAyahIndex! > 0 ? _previousAyah : null,
                onPlayPause: _togglePlayPause,
                onNext:
                    playingAyahIndex! < (widget.surah.ayahs?.length ?? 1) - 1
                    ? _nextAyah
                    : null,
                onOpen: () => _showAyahBottomSheet(playingAyahIndex!),
              ),
            ),
        ],
      ),
    );
  }

  Duration _chromeDuration(BuildContext context) =>
      context.tokens.motion.of(context, context.tokens.motion.medium);

  /// Back, the page's surah and the reader's actions, on the page's
  /// surface; a tap on the page shows and hides it.
  Widget _buildOverlayAppBar(BuildContext context) {
    // The side column already holds Back and the actions (closed Duo).
    if (HudaChromeFrame.hasSideChrome(context)) return const SizedBox();
    // While the pages still need downloading, Back and Display stay in
    // view: there's no page to tap.
    final pack = _pack;
    if (pack == null) return _overlayAppBar(context, _appBarVisible);
    return StreamBuilder<MushafPackState>(
      stream: pack.stateStream,
      initialData: pack.currentState,
      builder: (context, _) =>
          _overlayAppBar(context, _appBarVisible || !pack.isReady),
    );
  }

  Widget _overlayAppBar(BuildContext context, bool visible) {
    final scheme = Theme.of(context).colorScheme;
    final height = kToolbarHeight + MediaQuery.paddingOf(context).top;
    return AnimatedPositioned(
      duration: _chromeDuration(context),
      curve: context.tokens.motion.standard,
      top: visible ? 0 : -(height + 8),
      left: 0,
      right: 0,
      height: height,
      // Depth from tone, not a shadow: the page's surface with a hairline.
      child: Material(
        color: scheme.surfaceContainer,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        child: AppBar(
          key: const ValueKey('quran-mushaf-chrome'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: HudaSystemUi.over(
            top: Theme.of(context).brightness,
            bottom: Theme.of(context).brightness,
          ),
          title: Text(widget.title),
          actions: widget.actions,
        ),
      ),
    );
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
        playingAyahIndex! < (widget.surah.ayahs?.length ?? 1) - 1) {
      final nextIndex = playingAyahIndex! + 1;
      playAyahAudio(nextIndex);
    }
  }

  void _onMushafAyahTap(int surahNumber, int verseNumber) {
    final isSameSurah = surahNumber == widget.surahNumber;
    final int ayahIndex = verseNumber - 1;

    if (isSameSurah &&
        widget.surah.ayahs != null &&
        ayahIndex >= 0 &&
        ayahIndex < widget.surah.ayahs!.length) {
      _showAyahBottomSheet(ayahIndex);
    } else if (widget.onOtherSurahAyah != null) {
      // Audio and highlight follow this widget's surah; switch first.
      stopAudioIfPlaying();
      widget.onOtherSurahAyah!(surahNumber, verseNumber);
    } else {
      _showAyahBottomSheetForVerse(surahNumber, verseNumber);
    }
  }

  /// "Al-Baqarah · Ayah 2", the ayah sheet's title.
  String _ayahSheetTitle(int surah, int ayah) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    return '${QuranSurahRef.number(surah, language).title} · '
        '${l10n.ayahNumber(ayah)}';
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

    if (!mounted) return;

    showHudaSheet<void>(
      context: context,
      title: _ayahSheetTitle(widget.surahNumber, ayah.numberInSurah ?? index + 1),
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
                      if (mounted) setState(() => isOfflineMode = true);
                    });
                  }
                } else if (audioState is ReaderOffline) {
                  modalIsOfflineMode = true;
                  if (isCacheLoading) {
                    offlineMessage = AppLocalizations.of(context)!.quranOfflineLoading;
                  } else if (!offlineCacheLoaded) {
                    offlineMessage = AppLocalizations.of(context)!.quranOfflineLoading;
                  } else if (cachedDownloadedReaders.isEmpty &&
                      cachedDownloadedTafsirSources.isEmpty &&
                      cachedDownloadedTranslationSources.isEmpty) {
                    offlineMessage = AppLocalizations.of(
                      context,
                    )!.offlineAudioUnavailable;
                  }
                  if (!isOfflineMode) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => isOfflineMode = true);
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
                        if (offlineMessage != AppLocalizations.of(context)!.quranOfflineLoading) {
                          offlineMessage = AppLocalizations.of(context)!.quranOfflineLoading;
                        }
                      } else if (offlineCacheLoaded) {
                        availableReadersForModal = cachedDownloadedReaders;
                        availableTafsirForModal = cachedDownloadedTafsirSources;
                        availableTranslationForModal =
                            cachedDownloadedTranslationSources;
                        if (offlineMessage == AppLocalizations.of(context)!.quranOfflineLoading) {
                          offlineMessage = null;
                        }
                      } else {
                        preloadOfflineCache();
                        availableReadersForModal = _availableReaders;
                        availableTafsirForModal = _availableTafsirSources;
                        availableTranslationForModal =
                            _availableTranslationSources;
                        offlineMessage = AppLocalizations.of(context)!.quranOfflineLoading;
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
                    onRetryTranslation: translationCubit.fetchTranslationInfo,
                    onRetryReaders: () =>
                        audioCubit.fetchAudioInfo('${widget.surahNumber}'),
                    onShare: (translation, tafsir) {
                      Navigator.pop(modalContext);
                      shareAyah(
                        context,
                        surah: widget.surahNumber,
                        ayah: ayah.numberInSurah ?? index + 1,
                        text: ayah.text ?? '',
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
                        getCurrentScrollPosition: () => 0.0,
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

  void _showAyahBottomSheetForVerse(int surahNum, int verseNum) {
    final verseText = quran.getVerse(surahNum, verseNum);
    final totalVerses = quran.getVerseCount(surahNum);
    final ayah = Ayahs(
      number: verseNum,
      text: verseText,
      numberInSurah: verseNum,
      juz: quran.getJuzNumber(surahNum, verseNum),
      page: widget.mode.pagination.pageOf(surahNum, verseNum),
    );

    final memorizationCubit = context.read<MemorizationCubit>();
    final surahCubit = context.read<SurahCubit>();
    isBottomSheetOpen = true;

    showHudaSheet<void>(
      context: context,
      title: _ayahSheetTitle(surahNum, verseNum),
      sideSheet: true,
      builder: (modalContext) {
        return Builder(
          builder: (draggableContext) {
            return StatefulBuilder(
              builder: (modalContext, setModalState) {
                modalStateSetter = setModalState;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: memorizationCubit),
                    BlocProvider.value(value: surahCubit),
                  ],
                  child: AyahBottomSheetModalTabbed(
                    onShare: (translation, tafsir) {
                      Navigator.pop(modalContext);
                      shareAyah(
                        context,
                        surah: surahNum,
                        ayah: verseNum,
                        text: ayah.text ?? '',
                        translation: translation,
                        tafsir: tafsir,
                      );
                    },
                    ayah: ayah,
                    index: verseNum - 1,
                    surahNumber: surahNum,
                    totalAyahs: totalVerses,
                    surahName: quran.getSurahNameArabic(surahNum),
                    surahEnglishName: quran.getSurahNameEnglish(surahNum),
                    audioPlayer: audioPlayer,
                    playingAyahIndex: playingAyahIndex,
                    currentPosition: currentPosition,
                    totalDuration: totalDuration,
                    isUserSeeking: isUserSeeking,
                    selectedReaderId: selectedReaderId,
                    selectedLanguage: selectedLanguage,
                    availableReaders: _availableReaders,
                    isLoadingAudio: isLoadingAudio,
                    currentSurahAudio: currentSurahAudio,
                    loopEnabled: loopEnabled,
                    autoplayEnabled: autoplayEnabled,
                    isOfflineMode: isOfflineMode,
                    isDownloadingSingle: isDownloadingSingleAyah,
                    isDownloadingAll: isDownloadingAllAyahs,
                    downloadProgressText: downloadProgressText,
                    availableTafsirSources: _availableTafsirSources,
                    selectedTafsirId: selectedTafsirId,
                    currentTafsir: currentTafsir,
                    isLoadingTafsir: isLoadingTafsir,
                    availableTranslationSources: _availableTranslationSources,
                    selectedTranslationId: selectedTranslationId,
                    selectedTranslationLanguage: selectedTranslationLanguage,
                    currentTranslation: currentTranslation,
                    isLoadingTranslation: isLoadingTranslation,
                    onPlayPause: playPauseAudio,
                    onPrevious: (_) {},
                    onNext: (_) {},
                    onSeek: seekToPosition,
                    onUserSeekingChanged: (seeking) =>
                        setState(() => isUserSeeking = seeking),
                    onReaderSelected: (readerId) =>
                        switchReader(readerId, setModalState),
                    onLanguageSelected: (language) =>
                        switchLanguage(language, setModalState),
                    onLoopChanged: (value) =>
                        setModalState(() => loopEnabled = value ?? false),
                    onAutoplayChanged: (value) =>
                        setModalState(() => autoplayEnabled = value ?? true),
                    checkAllDownloaded: () async => false,
                    checkSingleDownloaded: () async => false,
                    onTafsirSelected: (tafsirId) {
                      setState(() {
                        selectedTafsirId = tafsirId;
                        isLoadingTafsir = true;
                      });
                      setModalState(() {});
                      context
                          .read<TafsirCubit>()
                          .fetchSurahTafsirWithCacheCheck(tafsirId, surahNum);
                    },
                    onTranslationSelected: (translationId) {
                      setState(() {
                        selectedTranslationId = translationId;
                        isLoadingTranslation = true;
                      });
                      setModalState(() {});
                      context
                          .read<TranslationCubit>()
                          .fetchSurahTranslationWithCacheCheck(
                            translationId,
                            surahNum,
                          );
                    },
                    onTranslationLanguageSelected: (language) =>
                        switchTranslationLanguage(language, setModalState),
                    isDownloadingSurahTafsir: isDownloadingSurahTafsir,
                    isDownloadingAllTafsir: isDownloadingAllTafsir,
                    isDownloadingSurahTranslation:
                        isDownloadingSurahTranslation,
                    isDownloadingAllTranslation: isDownloadingAllTranslation,
                    checkSurahTafsirDownloaded: () async => false,
                    checkAllTafsirDownloaded: () async => false,
                    checkSurahTranslationDownloaded: () async => false,
                    checkAllTranslationDownloaded: () async => false,
                    checkCurrentAyahPlayable: () async => !isOfflineMode,
                    getCurrentScrollPosition: () => 0.0,
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => onBottomSheetClosed());
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
    UIPerformanceUtils.debounce('mushaf_audio_state_change', () {
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
      if (!offlineCacheLoaded) preloadOfflineCache();
    } else if (state is ReaderOffline) {
      setState(() => isLoadingAudio = false);
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
      setState(() => isLoadingAudio = true);
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TafsirOfflineNoContent) {
    } else if (state is SurahTafsirLoaded) {
      setState(() {
        currentTafsir = state.tafsirModel;
        isLoadingTafsir = false;
      });
      safeModalSetState();
    } else if (state is SurahTafsirLoading) {
      setState(() => isLoadingTafsir = true);
      safeModalSetState();
    } else if (state is TafsirDownloadInProgress) {
      setState(() => isDownloadingSurahTafsir = true);
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TafsirError) {
      setState(() => isLoadingTafsir = false);
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TranslationOfflineNoContent) {
    } else if (state is SurahTranslationLoaded) {
      setState(() {
        currentTranslation = state.translationModel;
        isLoadingTranslation = false;
      });
      safeModalSetState();
    } else if (state is SurahTranslationLoading) {
      setState(() => isLoadingTranslation = true);
      safeModalSetState();
    } else if (state is TranslationDownloadInProgress) {
      setState(() => isDownloadingSurahTranslation = true);
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TranslationError) {
      setState(() => isLoadingTranslation = false);
      safeModalSetState();
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.translationError(state.message),
      );
    }
  }
}
