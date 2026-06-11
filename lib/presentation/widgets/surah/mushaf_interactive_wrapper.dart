import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
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
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/utils/ui_performance_utils.dart';
import 'package:huda/core/quran/quran.dart' as quran;

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
  final HorizontalPageDisplayMode displayMode;
  final MushafFlipDirection flipDirection;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onMenuTapped;
  final Color? customBgColor;
  final Color? customTextColor;

  const MushafInteractiveWrapper({
    super.key,
    required this.surah,
    required this.surahNumber,
    required this.initialPageNumber,
    required this.mode,
    this.displayMode = HorizontalPageDisplayMode.normal,
    this.flipDirection = MushafFlipDirection.horizontal,
    this.onPageChanged,
    this.onMenuTapped,
    this.customBgColor,
    this.customTextColor,
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
    });
  }

  void _initSourcesFromCurrentCubitState() {
    if (!mounted) return;

    // Use lastKnown* getters which persist across state transitions
    // (e.g. TafsirLoaded → SurahTafsirLoaded) so we never see empty sources
    // after a mode switch even when the cubit is mid-way through loading.
    final tafsirSources = context.read<TafsirCubit>().lastKnownSources;
    final translationSources =
        context.read<TranslationCubit>().lastKnownSources;
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

  void _toggleAppBar() {
    setState(() => _appBarVisible = !_appBarVisible);
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
                final memSurahNumber =
                    isMemorizationMode ? memState.surahNumber : 0;

                return QuranMushafPageView(
                  key: ValueKey(
                      '${widget.mode}_${widget.displayMode}_${widget.flipDirection}'),
                  initialPageNumber: widget.initialPageNumber,
                  mode: widget.mode,
                  displayMode: widget.displayMode,
                  flipDirection: widget.flipDirection,
                  playingSurahNumber: widget.surahNumber,
                  playingAyahNumber:
                      playingAyahIndex != null ? playingAyahIndex! + 1 : null,
                  isMemorizationMode: isMemorizationMode,
                  hiddenAyahIndices: hiddenAyahIndices,
                  memorizedSurahNumber: memSurahNumber,
                  customBgColor: widget.customBgColor,
                  customTextColor: widget.customTextColor,
                  onPageChanged: (page) {
                    widget.onPageChanged?.call(page);

                    if (isMemorizationMode) {
                      try {
                        final pageData = quran.getPageData(page);
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
          if (playingAyahIndex != null && currentSurahAudio != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 12.w,
              right: 12.w,
              bottom: _appBarVisible ? 16.h : -(180.h),
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
                            'Ayah ${playingAyahIndex! + 1} of ${widget.surah.ayahs?.length ?? 0}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAyahBottomSheet(playingAyahIndex!),
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
                                  (widget.surah.ayahs?.length ?? 1) - 1
                              ? () => _nextAyah()
                              : null,
                          icon: Icon(
                            Icons.skip_next,
                            color: playingAyahIndex! <
                                    (widget.surah.ayahs?.length ?? 1) - 1
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
        ],
      ),
    );
  }

  Widget _buildOverlayAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _appBarVisible
          ? 0
          : -(kToolbarHeight + MediaQuery.of(context).padding.top + 20),
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8.h,
          bottom: 10.h,
          left: 12.w,
          right: 12.w,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colors.primaryDark.withValues(alpha: 0.95),
                    colors.primary.withValues(alpha: 0.95),
                  ]
                : [
                    colors.primary.withValues(alpha: 0.95),
                    colors.primaryVariant.withValues(alpha: 0.95),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: IconButton(
                onPressed: () => widget.onMenuTapped?.call(),
                icon: Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    } else {
      _showAyahBottomSheetForVerse(surahNumber, verseNumber);
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

    if (!mounted) return;

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
                      if (mounted) setState(() => isOfflineMode = true);
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
                        if (offlineMessage?.contains('Loading') != true) {
                          offlineMessage = 'Loading offline content...';
                        }
                      } else if (offlineCacheLoaded) {
                        availableReadersForModal = cachedDownloadedReaders;
                        availableTafsirForModal = cachedDownloadedTafsirSources;
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
      page: quran.getPageNumber(surahNum, verseNum),
    );

    final memorizationCubit = context.read<MemorizationCubit>();
    final surahCubit = context.read<SurahCubit>();
    isBottomSheetOpen = true;

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
            return StatefulBuilder(
              builder: (modalContext, setModalState) {
                modalStateSetter = setModalState;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: memorizationCubit),
                    BlocProvider.value(value: surahCubit),
                  ],
                  child: AyahBottomSheetModalTabbed(
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
                    // Use surahNum (the tapped ayah's surah), not
                    // widget.surahNumber (the navigation surah), so that
                    // cross-surah ayahs in double-page mode fetch the correct
                    // tafsir/translation content.
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
                              translationId, surahNum);
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
    if (state is TafsirLoaded) {
      setState(() {
        _availableTafsirSources = state.tafsirModel.data ?? [];
      });
    } else if (state is TafsirOffline) {
      setState(() {
        _availableTafsirSources = state.tafsirModel.data ?? [];
      });
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tafsirDownloadSuccess),
          backgroundColor: Colors.green,
        ),
      );
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TafsirError) {
      setState(() => isLoadingTafsir = false);
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
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.translationDownloadSuccess),
          backgroundColor: Colors.green,
        ),
      );
      if (isOfflineMode && offlineCacheLoaded) preloadOfflineCache();
    } else if (state is TranslationError) {
      setState(() => isLoadingTranslation = false);
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
}
