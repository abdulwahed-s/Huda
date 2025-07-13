import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/presentation/widgets/surah/bismillah_widget.dart';
import 'package:huda/presentation/widgets/surah/ayah_text_widget.dart';
import 'package:huda/presentation/widgets/surah/surah_loading_state_widget.dart';
import 'package:huda/presentation/widgets/surah/ayah_bottom_sheet_modal.dart';

// Import mixins
import 'surah/mixins/audio_manager_mixin.dart';
import 'surah/mixins/download_manager_mixin.dart';
import 'surah/mixins/offline_cache_manager_mixin.dart';
import 'surah/mixins/switch_handlers_mixin.dart';
import 'surah/mixins/modal_manager_mixin.dart';
import 'surah/mixins/state_validators_mixin.dart';

class SurahScreen extends StatelessWidget {
  final QuranModel surahInfo;

  const SurahScreen({super.key, required this.surahInfo});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SurahCubit()..loadSurah(surahInfo.number!),
        ),
        BlocProvider(
          create: (_) => context.read<AudioCubit>()
            ..fetchAudioInfo(surahInfo.number.toString()),
        ),
        BlocProvider(
          create: (_) =>
              TafsirCubit(context.read<TafsirRepository>())..fetchTafsirInfo(),
        ),
        BlocProvider(
          create: (_) => TranslationCubit(context.read<TranslationRepository>())
            ..fetchTranslationInfo(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            surahInfo.name ?? '',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocBuilder<SurahCubit, SurahState>(
          builder: (context, state) {
            if (state is SurahLoading) {
              return const SurahLoadingStateWidget();
            } else if (state is SurahLoaded) {
              return QuranPageView(
                surah: state.surah,
                surahNumber: surahInfo.number!,
              );
            } else if (state is SurahError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            } else {
              return const Center(
                child: Text('Unknown state'),
              );
            }
          },
        ),
      ),
    );
  }
}

class QuranPageView extends StatefulWidget {
  final SurahModel surah;
  final int surahNumber;

  const QuranPageView({
    super.key,
    required this.surah,
    required this.surahNumber,
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
        StateValidatorsMixin {
  // Core audio variables
  final AudioPlayer audioPlayer = AudioPlayer();
  int? playingAyahIndex;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isUserSeeking = false;

  // Reader and language selection
  String? selectedReaderId;
  String? selectedLanguage;
  List<edition.Data> _availableReaders = [];
  bool isLoadingAudio = false;
  audio.SurahAudioModel? currentSurahAudio;

  // Audio controls
  bool loopEnabled = false;
  bool autoplayEnabled = true;

  // Connection and offline mode
  bool isOfflineMode = false;

  // Download states
  bool isDownloadingSingleAyah = false;
  bool isDownloadingAllAyahs = false;
  String downloadProgressText = '';

  // Modal state
  bool isBottomSheetOpen = false;
  StateSetter? modalStateSetter;

  // Tafsir variables
  List<edition.Data> _availableTafsirSources = [];
  String? selectedTafsirId;
  tafsir.TafsirModel? currentTafsir;
  bool isLoadingTafsir = false;
  bool isDownloadingSurahTafsir = false;
  bool isDownloadingAllTafsir = false;

  // Translation variables
  List<edition.Data> _availableTranslationSources = [];
  String? selectedTranslationId;
  String? selectedTranslationLanguage;
  tafsir.TafsirModel? currentTranslation;
  bool isLoadingTranslation = false;
  bool isDownloadingSurahTranslation = false;
  bool isDownloadingAllTranslation = false;

  // Getter implementations for mixins
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
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
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
      child: Container(
        color: const Color(0xFFFFFBE6),
        child: PageView.builder(
          itemCount: 1,
          itemBuilder: (context, pageIndex) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (widget.surah.number != 1 && widget.surah.number != 9)
                    const BismillahWidget(),
                  const SizedBox(height: 20),
                  ...widget.surah.ayahs!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ayah = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      child: AyahTextWidget(
                        ayah: ayah,
                        index: index,
                        playingAyahIndex: playingAyahIndex,
                        selectedReaderId: selectedReaderId,
                        surahNumber: widget.surahNumber,
                        onTap: () => onAyahTap(index),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Implement required methods from mixins
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
    if (audioPlayer.state == PlayerState.playing) {
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

  // Event handlers for BlocListeners
  void _handleAudioStateChanges(BuildContext context, AudioState state) {
    if (state is AudioLoaded) {
      setState(() {
        _availableReaders = state.surahAudioModel.data ?? [];

        // Update audio state when AudioLoaded changes
        if (state.currentSurahAudio != null) {
          currentSurahAudio = state.currentSurahAudio;
          isLoadingAudio = false;
        } else if (selectedReaderId != null) {
          // Reader is selected but no audio yet - keep loading
          currentSurahAudio = null;
          isLoadingAudio = true;
        } else {
          // No reader selected
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
      // Refresh offline cache when offline state changes
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
      // Refresh offline cache when new downloads complete
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
      // Refresh offline cache when tafsir state changes
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafsir downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh offline cache when new downloads complete
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TafsirError) {
      setState(() {
        isLoadingTafsir = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tafsir error: ${state.message}'),
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
      // Refresh offline cache when translation state changes
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh offline cache when new downloads complete
      if (isOfflineMode && offlineCacheLoaded) {
        preloadOfflineCache();
      }
    } else if (state is TranslationError) {
      setState(() {
        isLoadingTranslation = false;
      });
      safeModalSetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation error: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAyahBottomSheet(int index) async {
    final ayah = widget.surah.ayahs![index];
    isBottomSheetOpen = true;

    // If in offline mode and cache not loaded, preload it first
    if (isOfflineMode && !offlineCacheLoaded && !isCacheLoading) {
      await preloadOfflineCache();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (modalContext) {
        return BlocBuilder<AudioCubit, AudioState>(
          bloc: context.read<AudioCubit>(),
          builder: (blocContext, audioState) {
            List<edition.Data> allAvailableReaders = [];
            bool modalIsOfflineMode =
                isOfflineMode; // Use stored offline mode state
            String? offlineMessage;

            if (audioState is AudioLoaded) {
              allAvailableReaders = audioState.surahAudioModel.data ?? [];
              // Don't change offline mode just because we get AudioLoaded state
            } else if (audioState is AudioOfflineWithDownloads) {
              allAvailableReaders = audioState.surahAudioModel.data ?? [];
              modalIsOfflineMode = true;
              // Update stored offline mode
              if (!isOfflineMode) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    isOfflineMode = true;
                  });
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
              // If cache is loaded and has content, don't set offline message
              // Update stored offline mode
              if (!isOfflineMode) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    isOfflineMode = true;
                  });
                });
              }
            }

            if (allAvailableReaders.isEmpty && !modalIsOfflineMode) {
              allAvailableReaders = _availableReaders;
            }

            return StatefulBuilder(
              builder: (modalContext, setModalState) {
                modalStateSetter = setModalState;

                // Handle offline mode data loading
                List<edition.Data> availableReadersForModal;
                List<edition.Data> availableTafsirForModal;
                List<edition.Data> availableTranslationForModal;

                if (modalIsOfflineMode) {
                  if (isCacheLoading) {
                    // Show loading state - use current available data as fallback
                    availableReadersForModal = _availableReaders;
                    availableTafsirForModal = _availableTafsirSources;
                    availableTranslationForModal = _availableTranslationSources;
                    // Ensure loading message is shown
                    if (offlineMessage?.contains('Loading') != true) {
                      offlineMessage = 'Loading offline content...';
                    }
                  } else if (offlineCacheLoaded) {
                    // Use cached data
                    availableReadersForModal = cachedDownloadedReaders;
                    availableTafsirForModal = cachedDownloadedTafsirSources;
                    availableTranslationForModal =
                        cachedDownloadedTranslationSources;
                    // Clear loading message when cache is loaded
                    if (offlineMessage?.contains('Loading') == true) {
                      offlineMessage = null;
                    }
                  } else {
                    // Cache not loaded yet, trigger loading and show fallback
                    preloadOfflineCache();
                    availableReadersForModal = _availableReaders;
                    availableTafsirForModal = _availableTafsirSources;
                    availableTranslationForModal = _availableTranslationSources;
                    offlineMessage = 'Loading offline content...';
                  }
                } else {
                  // Online mode - use live data
                  availableReadersForModal = allAvailableReaders;
                  availableTafsirForModal = _availableTafsirSources;
                  availableTranslationForModal = _availableTranslationSources;
                }

                return AyahBottomSheetModal(
                  ayah: ayah,
                  index: index,
                  surahNumber: widget.surahNumber,
                  totalAyahs: widget.surah.ayahs?.length ?? 0,
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
                  availableTranslationSources: availableTranslationForModal,
                  selectedTranslationId: selectedTranslationId,
                  selectedTranslationLanguage: selectedTranslationLanguage,
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
                  onAutoplayChanged: (value) =>
                      setModalState(() => autoplayEnabled = value ?? true),
                  onDownloadSingle: () =>
                      downloadSingleAyah(index, ayah, setModalState),
                  onDownloadAll: () => downloadAllSurahAyahs(setModalState),
                  checkAllDownloaded: areAllAyahsDownloaded,
                  checkSingleDownloaded: () => isSingleAyahDownloaded(index),
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
                  isDownloadingSurahTranslation: isDownloadingSurahTranslation,
                  isDownloadingAllTranslation: isDownloadingAllTranslation,
                  checkSurahTafsirDownloaded: isSurahTafsirDownloaded,
                  checkAllTafsirDownloaded: isAllTafsirDownloaded,
                  checkSurahTranslationDownloaded: isSurahTranslationDownloaded,
                  checkAllTranslationDownloaded: isAllTranslationDownloaded,
                  checkCurrentAyahPlayable: () => isCurrentAyahPlayable(index),
                );
              },
            );
          },
        );
      },
    ).then((_) => onBottomSheetClosed());
  }
}
