import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/presentation/widgets/surah/audio_controls_widget.dart';
import 'package:huda/presentation/widgets/surah/reader_selection_widget.dart';
import 'package:huda/presentation/widgets/surah/download_controls_widget.dart';
import 'package:huda/presentation/widgets/surah/audio_settings_widget.dart';
import 'package:huda/presentation/widgets/surah/translation_widget.dart';
import 'package:huda/presentation/widgets/surah/tafsir_widget.dart';

class AyahBottomSheetModal extends StatefulWidget {
  final Ayahs ayah;
  final int index;
  final int surahNumber;
  final int totalAyahs;
  final AudioPlayer audioPlayer;
  final int? playingAyahIndex;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isUserSeeking;
  final String? selectedReaderId;
  final String? selectedLanguage;
  final List<edition.Data> availableReaders;
  final bool isLoadingAudio;
  final audio.SurahAudioModel? currentSurahAudio;
  final bool loopEnabled;
  final bool autoplayEnabled;
  final bool isOfflineMode;
  final String? offlineMessage;
  final bool isDownloadingSingle;
  final bool isDownloadingAll;
  final String downloadProgressText;

  // Tafsir related
  final List<edition.Data> availableTafsirSources;
  final String? selectedTafsirId;
  final tafsir.TafsirModel? currentTafsir;
  final bool isLoadingTafsir;

  // Translation related
  final List<edition.Data> availableTranslationSources;
  final String? selectedTranslationId;
  final String? selectedTranslationLanguage;
  final tafsir.TafsirModel? currentTranslation;
  final bool isLoadingTranslation;

  // Callbacks
  final Function(int) onPlayPause;
  final Function(int) onPrevious;
  final Function(int) onNext;
  final Function(double) onSeek;
  final Function(bool) onUserSeekingChanged;
  final Function(String) onReaderSelected;
  final Function(String?) onLanguageSelected;
  final Function(bool?) onLoopChanged;
  final Function(bool?) onAutoplayChanged;
  final VoidCallback? onDownloadSingle;
  final VoidCallback? onDownloadAll;
  final Future<bool> Function() checkAllDownloaded;
  final Future<bool> Function() checkSingleDownloaded;
  final Function(String) onTafsirSelected;
  final Function(String) onTranslationSelected;
  final Function(String?) onTranslationLanguageSelected;
  final VoidCallback? onDownloadTafsir;
  final VoidCallback? onDownloadFullTafsir;
  final VoidCallback? onDownloadTranslation;
  final VoidCallback? onDownloadFullTranslation;

  // Download status callbacks
  final bool isDownloadingSurahTafsir;
  final bool isDownloadingAllTafsir;
  final bool isDownloadingSurahTranslation;
  final bool isDownloadingAllTranslation;
  final Future<bool> Function() checkSurahTafsirDownloaded;
  final Future<bool> Function() checkAllTafsirDownloaded;
  final Future<bool> Function() checkSurahTranslationDownloaded;
  final Future<bool> Function() checkAllTranslationDownloaded;
  final Future<bool> Function() checkCurrentAyahPlayable;

  const AyahBottomSheetModal({
    super.key,
    required this.ayah,
    required this.index,
    required this.surahNumber,
    required this.totalAyahs,
    required this.audioPlayer,
    required this.playingAyahIndex,
    required this.currentPosition,
    required this.totalDuration,
    required this.isUserSeeking,
    required this.selectedReaderId,
    required this.selectedLanguage,
    required this.availableReaders,
    required this.isLoadingAudio,
    required this.currentSurahAudio,
    required this.loopEnabled,
    required this.autoplayEnabled,
    required this.isOfflineMode,
    this.offlineMessage,
    required this.isDownloadingSingle,
    required this.isDownloadingAll,
    required this.downloadProgressText,
    required this.availableTafsirSources,
    required this.selectedTafsirId,
    required this.currentTafsir,
    required this.isLoadingTafsir,
    required this.availableTranslationSources,
    required this.selectedTranslationId,
    required this.selectedTranslationLanguage,
    required this.currentTranslation,
    required this.isLoadingTranslation,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.onUserSeekingChanged,
    required this.onReaderSelected,
    required this.onLanguageSelected,
    required this.onLoopChanged,
    required this.onAutoplayChanged,
    this.onDownloadSingle,
    this.onDownloadAll,
    required this.checkAllDownloaded,
    required this.checkSingleDownloaded,
    required this.onTafsirSelected,
    required this.onTranslationSelected,
    required this.onTranslationLanguageSelected,
    this.onDownloadTafsir,
    this.onDownloadFullTafsir,
    this.onDownloadTranslation,
    this.onDownloadFullTranslation,
    required this.isDownloadingSurahTafsir,
    required this.isDownloadingAllTafsir,
    required this.isDownloadingSurahTranslation,
    required this.isDownloadingAllTranslation,
    required this.checkSurahTafsirDownloaded,
    required this.checkAllTafsirDownloaded,
    required this.checkSurahTranslationDownloaded,
    required this.checkAllTranslationDownloaded,
    required this.checkCurrentAyahPlayable,
  });

  @override
  State<AyahBottomSheetModal> createState() => _AyahBottomSheetModalState();
}

class _AyahBottomSheetModalState extends State<AyahBottomSheetModal> {
  bool _isCurrentAyahPlayable = true;

  @override
  void initState() {
    super.initState();
    _checkAyahPlayability();
  }

  @override
  void didUpdateWidget(AyahBottomSheetModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check playability when offline mode, selected reader, or current surah audio changes
    if (oldWidget.isOfflineMode != widget.isOfflineMode ||
        oldWidget.selectedReaderId != widget.selectedReaderId ||
        oldWidget.currentSurahAudio != widget.currentSurahAudio) {
      _checkAyahPlayability();
    }
  }

  Future<void> _checkAyahPlayability() async {
    final isPlayable = await widget.checkCurrentAyahPlayable();
    if (mounted) {
      setState(() {
        _isCurrentAyahPlayable = isPlayable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.audioPlayer.state == PlayerState.playing &&
        widget.playingAyahIndex == widget.index;

    // Filter readers by language
    final filteredReaders = widget.selectedLanguage != null
        ? widget.availableReaders
            .where((reader) => reader.language == widget.selectedLanguage)
            .toList()
        : widget.availableReaders;

    // Get available languages
    final availableLanguages = widget.availableReaders
        .map((reader) => reader.language ?? 'Unknown')
        .toSet()
        .toList()
      ..sort();

    // Filter tafsir sources
    final filteredTafsirSources = widget.availableTafsirSources;

    // Get available translation languages
    final availableTranslationLanguages = widget.availableTranslationSources
        .map((source) => source.language ?? 'Unknown')
        .toSet()
        .toList()
      ..sort();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'آية ${widget.ayah.numberInSurah}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromARGB(255, 103, 43, 93),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ayah text
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  widget.ayah.text ?? '',
                  style: const TextStyle(
                    fontFamily: 'uthmanic',
                    fontSize: 20,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Audio controls
            if (widget.selectedReaderId != null)
              Column(
                children: [
                  if (widget.isLoadingAudio ||
                      (widget.selectedReaderId != null &&
                          widget.currentSurahAudio == null))
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 103, 43, 93),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading audio...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else if (widget.currentSurahAudio != null)
                    AudioControlsWidget(
                      audioPlayer: widget.audioPlayer,
                      currentIndex: widget.index,
                      totalAyahs: widget.totalAyahs,
                      currentPosition: widget.playingAyahIndex == widget.index
                          ? widget.currentPosition
                          : Duration.zero,
                      totalDuration: widget.playingAyahIndex == widget.index
                          ? widget.totalDuration
                          : Duration.zero,
                      isPlaying: isPlaying,
                      onPlayPause: () => widget.onPlayPause(widget.index),
                      onPrevious: widget.index > 0
                          ? () => widget.onPrevious(widget.index)
                          : null,
                      onNext: widget.index < widget.totalAyahs - 1
                          ? () => widget.onNext(widget.index)
                          : null,
                      onSeek: widget.onSeek,
                      onUserSeekingChanged: widget.onUserSeekingChanged,
                      isPlayButtonEnabled: _isCurrentAyahPlayable,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        'Unable to load audio for this reader',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),

            // Reader selection
            ReaderSelectionWidget(
              readers: filteredReaders,
              selectedReaderId: widget.selectedReaderId,
              selectedLanguage: widget.selectedLanguage,
              availableLanguages: availableLanguages,
              onReaderSelected: widget.onReaderSelected,
              onLanguageSelected: widget.onLanguageSelected,
              isLoading: widget.isLoadingAudio,
              offlineMessage: widget.offlineMessage,
            ),
            const SizedBox(height: 20),

            // Download controls
            DownloadControlsWidget(
              canDownload: widget.selectedReaderId != null &&
                  widget.currentSurahAudio != null &&
                  !widget.isOfflineMode &&
                  !widget.isLoadingAudio,
              isDownloadingSingle: widget.isDownloadingSingle,
              isDownloadingAll: widget.isDownloadingAll,
              downloadProgressText: widget.downloadProgressText,
              onDownloadSingle: widget.onDownloadSingle,
              onDownloadAll: widget.onDownloadAll,
              checkAllDownloaded: widget.checkAllDownloaded,
              checkSingleDownloaded: widget.checkSingleDownloaded,
            ),
            const SizedBox(height: 20),

            // Tafsir section
            TafsirWidget(
              tafsirSources: filteredTafsirSources,
              selectedTafsirId: widget.selectedTafsirId,
              currentTafsir: widget.currentTafsir,
              isLoadingTafsir: widget.isLoadingTafsir,
              ayahNumber: widget.ayah.numberInSurah!,
              onTafsirSelected: widget.onTafsirSelected,
              onDownloadTafsir: widget.onDownloadTafsir,
              onDownloadFullTafsir: widget.onDownloadFullTafsir,
              canDownload: !widget.isOfflineMode,
              isDownloadingSurah: widget.isDownloadingSurahTafsir,
              isDownloadingAll: widget.isDownloadingAllTafsir,
              checkSurahDownloaded: widget.checkSurahTafsirDownloaded,
              checkAllDownloaded: widget.checkAllTafsirDownloaded,
            ),
            const SizedBox(height: 20),

            // Translation section
            TranslationWidget(
              translationSources: widget.availableTranslationSources,
              selectedTranslationId: widget.selectedTranslationId,
              selectedTranslationLanguage: widget.selectedTranslationLanguage,
              availableTranslationLanguages: availableTranslationLanguages,
              currentTranslation: widget.currentTranslation,
              isLoadingTranslation: widget.isLoadingTranslation,
              ayahNumber: widget.ayah.numberInSurah!,
              onTranslationSelected: widget.onTranslationSelected,
              onTranslationLanguageSelected:
                  widget.onTranslationLanguageSelected,
              onDownloadTranslation: widget.onDownloadTranslation,
              onDownloadFullTranslation: widget.onDownloadFullTranslation,
              canDownload: !widget.isOfflineMode,
              isDownloadingSurah: widget.isDownloadingSurahTranslation,
              isDownloadingAll: widget.isDownloadingAllTranslation,
              checkSurahDownloaded: widget.checkSurahTranslationDownloaded,
              checkAllDownloaded: widget.checkAllTranslationDownloaded,
            ),
            const SizedBox(height: 20),

            // Audio settings
            AudioSettingsWidget(
              loopEnabled: widget.loopEnabled,
              autoplayEnabled: widget.autoplayEnabled,
              onLoopChanged: widget.onLoopChanged,
              onAutoplayChanged: widget.onAutoplayChanged,
            ),

            // Bottom padding for better scrolling
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
