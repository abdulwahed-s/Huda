import 'dart:convert';
import 'package:huda/data/models/ayah_audio_range.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
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
import 'package:huda/presentation/widgets/surah/bookmark_section_widget.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/quran/quran.dart' as quran;

class AyahBottomSheetModalTabbed extends StatefulWidget {
  /// Share is an action, not a tab: the reader closes this sheet and
  /// opens Quran's share sheet with the ayah's translation and tafsir.
  final void Function(String? translation, String? tafsir)? onShare;

  /// Fetches the reciters again; [readersLoading] while it runs.
  final VoidCallback? onRetryReaders;
  final bool readersLoading;

  /// The same for the tafsir and translation sources.
  final VoidCallback? onRetryTafsir;
  final bool tafsirLoading;
  final VoidCallback? onRetryTranslation;
  final bool translationLoading;

  final Ayahs ayah;
  final int index;
  final int surahNumber;
  final int totalAyahs;
  final String? surahName;
  final String? surahEnglishName;
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

  final List<edition.Data> availableTafsirSources;
  final String? selectedTafsirId;
  final tafsir.TafsirModel? currentTafsir;
  final bool isLoadingTafsir;

  final List<edition.Data> availableTranslationSources;
  final String? selectedTranslationId;
  final String? selectedTranslationLanguage;
  final tafsir.TafsirModel? currentTranslation;
  final bool isLoadingTranslation;

  final AyahAudioRange? audioRange;
  final ValueChanged<AyahAudioRange?>? onAudioRangeChanged;
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

  final bool isDownloadingSurahTafsir;
  final bool isDownloadingAllTafsir;
  final bool isDownloadingSurahTranslation;
  final bool isDownloadingAllTranslation;
  final Future<bool> Function() checkSurahTafsirDownloaded;
  final Future<bool> Function() checkAllTafsirDownloaded;
  final Future<bool> Function() checkSurahTranslationDownloaded;
  final Future<bool> Function() checkAllTranslationDownloaded;
  final Future<bool> Function() checkCurrentAyahPlayable;
  final double Function()? getCurrentScrollPosition;

  const AyahBottomSheetModalTabbed({
    this.onShare,
    this.onRetryReaders,
    this.readersLoading = false,
    this.onRetryTafsir,
    this.tafsirLoading = false,
    this.onRetryTranslation,
    this.translationLoading = false,
    super.key,
    required this.ayah,
    required this.index,
    required this.surahNumber,
    required this.totalAyahs,
    this.surahName,
    this.surahEnglishName,
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
    this.audioRange,
    this.onAudioRangeChanged,
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
    this.getCurrentScrollPosition,
  });

  @override
  State<AyahBottomSheetModalTabbed> createState() =>
      _AyahBottomSheetModalTabbedState();
}

class _AyahBottomSheetModalTabbedState
    extends State<AyahBottomSheetModalTabbed> {
  bool _isCurrentAyahPlayable = true;
  bool _isKhatmaEnd = false;
  int _selectedTabIndex = 0;

  /// Retry was tapped, so a reload reads "Retrying…", not "Updating…".
  bool _readersRetried = false;
  bool _tafsirRetried = false;
  bool _translationRetried = false;
  Map<String, dynamic>? _matchingAyahsData;
  bool _isLoadingMatchingAyahs = false;

  @override
  void initState() {
    super.initState();
    _checkAyahPlayability();
    _checkKhatmaEndStatus();
  }

  @override
  void didUpdateWidget(AyahBottomSheetModalTabbed oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOfflineMode != widget.isOfflineMode ||
        oldWidget.selectedReaderId != widget.selectedReaderId ||
        oldWidget.currentSurahAudio != widget.currentSurahAudio) {
      _checkAyahPlayability();
    }
  }

  void _checkKhatmaEndStatus() {
    try {
      final khatmaService = getIt<KhatmaService>();
      if (khatmaService.enabled && !khatmaService.isCompleted) {
        final details = khatmaService.rangeDetailsForDay(
          khatmaService.currentDayIndex,
          khatmaService.planDays,
        );
        if (widget.surahNumber == details.endSurah &&
            widget.ayah.numberInSurah == details.endVerse) {
          if (mounted) setState(() => _isKhatmaEnd = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _checkAyahPlayability() async {
    final isPlayable = await widget.checkCurrentAyahPlayable();
    if (mounted) {
      setState(() {
        _isCurrentAyahPlayable = isPlayable;
      });
    }
  }

  Future<void> _loadMatchingAyahs() async {
    if (_matchingAyahsData != null || _isLoadingMatchingAyahs) return;
    if (mounted) setState(() => _isLoadingMatchingAyahs = true);
    try {
      final jsonString = await rootBundle.loadString(
        'assets/json/matching-ayah.json',
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _matchingAyahsData = data;
          _isLoadingMatchingAyahs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMatchingAyahs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final isPlaying =
        widget.audioPlayer.playing && widget.playingAyahIndex == widget.index;
    final filteredReaders = widget.selectedLanguage != null
        ? widget.availableReaders
              .where((reader) => reader.language == widget.selectedLanguage)
              .toList()
        : widget.availableReaders;
    final availableLanguages =
        widget.availableReaders
            .map((reader) => reader.language ?? l10n.unknown)
            .toSet()
            .toList()
          ..sort();
    final availableTranslationLanguages =
        widget.availableTranslationSources
            .map((source) => source.language ?? l10n.unknown)
            .toSet()
            .toList()
          ..sort();
    final tabs = <(IconData, String)>[
      (Icons.volume_up_rounded, l10n.audio),
      (Icons.menu_book_rounded, l10n.tafsir),
      (Icons.translate_rounded, l10n.translation),
      (Icons.bookmark_outline_rounded, l10n.bookmark),
      (Icons.ios_share_rounded, l10n.share),
      (Icons.compare_arrows_rounded, l10n.quranSimilarTab),
    ];
    final Widget content = switch (_selectedTabIndex) {
      1 => _buildTafsirTab(widget.availableTafsirSources),
      2 => _buildTranslationTab(availableTranslationLanguages),
      3 => _buildBookmarkTab(),
      5 => _buildSimilarAyahsTab(),
      _ => _buildAudioTab(isPlaying, filteredReaders, availableLanguages),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ayahText(context),
        if (_isKhatmaEnd) ...[
          SizedBox(height: space.md),
          FilledButton.icon(
            key: const ValueKey('quran-wird-done'),
            onPressed: () async {
              try {
                await getIt<KhatmaService>().markTodayDone();
                if (context.mounted) Navigator.pop(context);
              } catch (_) {}
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(l10n.quranWirdDone),
          ),
        ],
        SizedBox(height: space.md),
        // Every action in one row that wraps: the sections, and Share last
        // in the same chip (it opens the share sheet instead of a section;
        // owner round 2).
        Wrap(
          spacing: space.xs,
          runSpacing: space.xs,
          children: [
            for (final (i, (icon, label)) in tabs.indexed)
              if (i != 4)
                ChoiceChip(
                  key: ValueKey('quran-ayah-tab-$i'),
                  // Lit when chosen: the mark takes the chip's warm text.
                  avatar: Icon(
                    icon,
                    size: 18,
                    color: _selectedTabIndex == i
                        ? context.tokens.onChrome
                        : null,
                  ),
                  label: Text(label),
                  selected: _selectedTabIndex == i,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selectedTabIndex = i),
                ),
            if (widget.onShare != null)
              ChoiceChip(
                key: const ValueKey('quran-ayah-share'),
                avatar: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l10n.share),
                selected: false,
                showCheckmark: false,
                onSelected: (_) => widget.onShare!(
                  _textOf(widget.currentTranslation),
                  _textOf(widget.currentTafsir),
                ),
              ),
          ],
        ),
        SizedBox(height: space.lg),
        HudaStateSwitcher(
          stateKey: _selectedTabIndex,
          alignment: AlignmentDirectional.topStart,
          child: content,
        ),
      ],
    );
  }

  /// The ayah, its rosette at the end, as on the reading page.
  Widget _ayahText(BuildContext context) {
    var text = widget.ayah.text ?? '';
    if (widget.ayah.numberInSurah == 1 &&
        widget.surahNumber != 1 &&
        widget.surahNumber != 9) {
      const bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      if (text.trim().startsWith(bismillah)) {
        text = text.trim().replaceFirst(bismillah, '').trim();
      }
    }
    final style = context.type.ayah.copyWith(
      fontFamily: getQuranFonts(),
      fontSize: 24,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$text '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: QuranAyahRosette(
              number: widget.ayah.numberInSurah ?? widget.index + 1,
              size: MediaQuery.textScalerOf(context).scale(24) * 1.15,
              lit:
                  widget.playingAyahIndex == widget.index &&
                  widget.audioPlayer.playing,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      style: style,
    );
  }

  /// A part of a tab: a small label with its mark, then the content.
  Widget _section(IconData icon, String title, Widget child) {
    final space = context.tokens.space;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.tertiary),
              SizedBox(width: space.xs),
              Expanded(child: HudaEyebrow(title, header: true)),
            ],
          ),
          SizedBox(height: space.sm),
          child,
        ],
      ),
    );
  }

  Widget _quiet(String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _buildAudioTab(
    bool isPlaying,
    List<edition.Data> filteredReaders,
    List<String> availableLanguages,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final controlIndex = widget.index;
    final isCurrentAyah = widget.playingAyahIndex == widget.index;
    final rangeActive = widget.audioRange?.contains(controlIndex) ?? false;
    return Column(
      key: const ValueKey('quran-ayah-audio'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selectedReaderId != null)
          _section(
            Icons.volume_up_rounded,
            l10n.audioControls,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isLoadingAudio && !widget.isOfflineMode)
                  Row(
                    children: [
                      const HudaLampSpinner(size: 24),
                      SizedBox(width: space.sm),
                      Expanded(child: _quiet(l10n.loadingAudio)),
                    ],
                  )
                else
                  AudioControlsWidget(
                    audioPlayer: widget.audioPlayer,
                    currentIndex: rangeActive
                        ? controlIndex - widget.audioRange!.startIndex
                        : controlIndex,
                    totalAyahs: rangeActive
                        ? widget.audioRange!.endIndex -
                              widget.audioRange!.startIndex +
                              1
                        : widget.totalAyahs,
                    currentPosition: isCurrentAyah
                        ? widget.currentPosition
                        : Duration.zero,
                    totalDuration: isCurrentAyah
                        ? widget.totalDuration
                        : Duration.zero,
                    isPlaying: isPlaying,
                    onPlayPause: () => widget.onPlayPause(
                      widget.audioRange != null &&
                              widget.playingAyahIndex == null
                          ? widget.audioRange!.startIndex
                          : controlIndex,
                    ),
                    onPrevious: controlIndex > 0
                        ? () => widget.onPrevious(controlIndex)
                        : null,
                    onNext: controlIndex < widget.totalAyahs - 1
                        ? () => widget.onNext(controlIndex)
                        : null,
                    onSeek: widget.onSeek,
                    onUserSeekingChanged: widget.onUserSeekingChanged,
                    isPlayButtonEnabled: _isCurrentAyahPlayable,
                  ),
                if (!widget.isLoadingAudio || widget.isOfflineMode) ...[
                  SizedBox(height: space.sm),
                  AudioSettingsWidget(
                    loopEnabled: widget.loopEnabled,
                    autoplayEnabled: widget.autoplayEnabled,
                    onLoopChanged: (value) {
                      if (value == true) widget.onAutoplayChanged(false);
                      widget.onLoopChanged(value);
                    },
                    onAutoplayChanged: (value) {
                      if (value == true) widget.onLoopChanged(false);
                      widget.onAutoplayChanged(value);
                    },
                    range: widget.audioRange,
                    totalAyahs: widget.totalAyahs,
                    initialIndex: widget.index,
                    onRangeChanged: widget.onAudioRangeChanged,
                  ),
                ],
              ],
            ),
          ),
        _section(
          Icons.record_voice_over_rounded,
          l10n.readerSelection,
          ReaderSelectionWidget(
            readers: filteredReaders,
            selectedReaderId: widget.selectedReaderId,
            selectedLanguage: widget.selectedLanguage,
            availableLanguages: availableLanguages,
            onReaderSelected: widget.onReaderSelected,
            onLanguageSelected: widget.onLanguageSelected,
            isLoading: widget.isLoadingAudio,
            offlineMessage: widget.offlineMessage,
            loadingReaders: widget.readersLoading,
            retrying: _readersRetried,
            onRetry: widget.onRetryReaders == null
                ? null
                : () {
                    setState(() => _readersRetried = true);
                    widget.onRetryReaders!();
                  },
          ),
        ),
        if (widget.selectedReaderId != null &&
            widget.currentSurahAudio != null &&
            !widget.isOfflineMode &&
            !widget.isLoadingAudio &&
            !kIsWeb)
          _section(
            Icons.download_rounded,
            l10n.audioDownloads,
            DownloadControlsWidget(
              canDownload: true,
              isDownloadingSingle: widget.isDownloadingSingle,
              isDownloadingAll: widget.isDownloadingAll,
              downloadProgressText: widget.downloadProgressText,
              onDownloadSingle: widget.onDownloadSingle,
              onDownloadAll: widget.onDownloadAll,
              checkAllDownloaded: widget.checkAllDownloaded,
              checkSingleDownloaded: widget.checkSingleDownloaded,
            ),
          ),
      ],
    );
  }

  Widget _buildTafsirTab(List<edition.Data> filteredTafsirSources) {
    final l10n = AppLocalizations.of(context)!;
    return KeyedSubtree(
      key: const ValueKey('quran-ayah-tafsir'),
      child: _section(
        Icons.menu_book_rounded,
        l10n.tafsirCommentary,
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
          offlineMessage: widget.isOfflineMode
              ? l10n.offlineTafsirUnavailable
              : null,
          loadingSources: widget.tafsirLoading,
          retrying: _tafsirRetried,
          onRetry: widget.onRetryTafsir == null
              ? null
              : () {
                  setState(() => _tafsirRetried = true);
                  widget.onRetryTafsir!();
                },
        ),
      ),
    );
  }

  Widget _buildTranslationTab(List<String> availableTranslationLanguages) {
    final l10n = AppLocalizations.of(context)!;
    return KeyedSubtree(
      key: const ValueKey('quran-ayah-translation'),
      child: _section(
        Icons.translate_rounded,
        l10n.translation,
        TranslationWidget(
          translationSources: widget.availableTranslationSources,
          selectedTranslationId: widget.selectedTranslationId,
          selectedTranslationLanguage: widget.selectedTranslationLanguage,
          availableTranslationLanguages: availableTranslationLanguages,
          currentTranslation: widget.currentTranslation,
          isLoadingTranslation: widget.isLoadingTranslation,
          ayahNumber: widget.ayah.numberInSurah!,
          onTranslationSelected: widget.onTranslationSelected,
          onTranslationLanguageSelected: widget.onTranslationLanguageSelected,
          onDownloadTranslation: widget.onDownloadTranslation,
          onDownloadFullTranslation: widget.onDownloadFullTranslation,
          canDownload: !widget.isOfflineMode,
          isDownloadingSurah: widget.isDownloadingSurahTranslation,
          isDownloadingAll: widget.isDownloadingAllTranslation,
          checkSurahDownloaded: widget.checkSurahTranslationDownloaded,
          checkAllDownloaded: widget.checkAllTranslationDownloaded,
          offlineMessage: widget.isOfflineMode
              ? l10n.offlineTranslationUnavailable
              : null,
          loadingSources: widget.translationLoading,
          retrying: _translationRetried,
          onRetry: widget.onRetryTranslation == null
              ? null
              : () {
                  setState(() => _translationRetried = true);
                  widget.onRetryTranslation!();
                },
        ),
      ),
    );
  }

  /// This ayah's text in a translation or tafsir edition, if loaded.
  String? _textOf(tafsir.TafsirModel? model) {
    final surahs = model?.data?.surahs;
    if (surahs == null) return null;
    for (final surah in surahs) {
      if (surah.number != widget.surahNumber) continue;
      final ayahs = surah.ayahs;
      final i = (widget.ayah.numberInSurah ?? widget.index + 1) - 1;
      if (ayahs == null || i < 0 || i >= ayahs.length) return null;
      return ayahs[i].text;
    }
    return null;
  }

  Widget _buildBookmarkTab() => BookmarkSection(
    key: const ValueKey('quran-ayah-bookmark'),
    surahNumber: widget.surahNumber,
    ayahNumber: widget.ayah.numberInSurah ?? widget.index + 1,
    ayahText: widget.ayah.text ?? '',
    surahName: widget.surahName ?? AppLocalizations.of(context)!.unknownSurah,
    getCurrentScrollPosition: widget.getCurrentScrollPosition,
  );

  Widget _buildSimilarAyahsTab() {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ayahKey = '${widget.surahNumber}:${widget.ayah.numberInSurah}';
    if (_matchingAyahsData == null) {
      if (!_isLoadingMatchingAyahs) Future.microtask(_loadMatchingAyahs);
      return const Padding(
        key: ValueKey('quran-similar-loading'),
        padding: EdgeInsets.all(32),
        child: Center(child: HudaLampSpinner(size: 28)),
      );
    }
    final matches = _matchingAyahsData![ayahKey] as List<dynamic>?;
    if (matches == null || matches.isEmpty) {
      return Padding(
        key: const ValueKey('quran-similar-none'),
        padding: EdgeInsets.symmetric(vertical: space.lg),
        child: Text(
          l10n.noSimilarAyahsFound,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      key: const ValueKey('quran-similar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _quiet(l10n.similarAyahsCountLabel(ayahKey, matches.length)),
        SizedBox(height: space.sm),
        for (final match in matches)
          Builder(
            builder: (context) {
              final matchedKey = match['matched_ayah_key'] as String;
              final parts = matchedKey.split(':');
              final surahNum = int.parse(parts[0]);
              final ayahNum = int.parse(parts[1]);
              final matchWords = match['match_words'] as List<dynamic>;
              var verse = '';
              try {
                verse = quran.getVerse(surahNum, ayahNum);
              } catch (_) {}
              final ref = QuranSurahRef.number(surahNum, language);
              return Padding(
                padding: EdgeInsets.only(bottom: space.sm),
                child: HudaCard(
                  onTap: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.pushReplacementNamed(
                      AppRoute.surahScreen,
                      arguments: {
                        'surahInfo': ref.asModel,
                        'scrollToAyah': ayahNum,
                        'shouldRestorePosition': false,
                      },
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          QuranSurahMark(number: surahNum, size: 28),
                          SizedBox(width: space.sm),
                          Expanded(
                            child: Text(
                              '${ref.title} · ${l10n.ayahNumber(ayahNum)}',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      if (verse.isNotEmpty) ...[
                        SizedBox(height: space.sm),
                        _buildHighlightedAyahText(verse, matchWords),
                      ],
                      SizedBox(height: space.xs),
                      Text(
                        l10n.similarAyahsMatchStats(
                          match['matched_words_count'] as int,
                          match['coverage'] as int,
                          match['score'] as int,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// The matched words in the primary ink, bold.
  Widget _buildHighlightedAyahText(String verse, List<dynamic> matchWords) {
    final scheme = Theme.of(context).colorScheme;
    final words = verse.split(' ');
    final highlighted = <int>{};
    for (final range in matchWords) {
      if (range is! List || range.isEmpty) continue;
      final start = (range[0] as int) - 1;
      final end = range.length >= 2 ? (range[1] as int) - 1 : start;
      for (var i = start; i <= end && i < words.length; i++) {
        if (i >= 0) highlighted.add(i);
      }
    }
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < words.length; i++)
            TextSpan(
              text: i < words.length - 1 ? '${words[i]} ' : words[i],
              style: highlighted.contains(i)
                  ? TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    )
                  : null,
            ),
        ],
      ),
      textDirection: TextDirection.rtl,
      style: context.type.ayah.copyWith(
        fontFamily: getQuranFonts(),
        fontSize: 20,
        color: scheme.onSurface,
      ),
    );
  }
}
