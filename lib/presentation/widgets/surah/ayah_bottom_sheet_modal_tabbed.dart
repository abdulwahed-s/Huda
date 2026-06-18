import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:huda/core/utils/platform_utils.dart';
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
import 'package:huda/presentation/widgets/surah/share_widget.dart';
import 'package:huda/presentation/widgets/surah/bookmark_section_widget.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/core/quran/quran.dart' as quran;

class AyahBottomSheetModalTabbed extends StatefulWidget {
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
  bool _isAyahInWidget = false;
  bool _isCheckingWidgetStatus = false;
  bool _isKhatmaEnd = false;
  int _selectedTabIndex = 0;
  Map<String, dynamic>? _matchingAyahsData;
  bool _isLoadingMatchingAyahs = false;

  @override
  void initState() {
    super.initState();
    _checkAyahPlayability();
    _checkAyahWidgetStatus();
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
            khatmaService.currentDayIndex, khatmaService.planDays);
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
      final jsonString =
          await rootBundle.loadString('assets/json/matching-ayah.json');
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

  Future<void> _checkAyahWidgetStatus() async {
    if (_isCheckingWidgetStatus) return;

    setState(() {
      _isCheckingWidgetStatus = true;
    });

    try {
      String ayahText = widget.ayah.text ?? '';
      final isFirstAyah = widget.ayah.numberInSurah == 1;
      final shouldShowBismillah =
          isFirstAyah && widget.surahNumber != 1 && widget.surahNumber != 9;

      if (shouldShowBismillah) {
        const bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
        if (ayahText.trim().startsWith(bismillahText)) {
          ayahText = ayahText.trim().replaceFirst(bismillahText, '').trim();
        }
      }

      final isInWidget =
          await WidgetService.isVerseInCustomCollection(ayahText);

      if (mounted) {
        setState(() {
          _isAyahInWidget = isInWidget;
          _isCheckingWidgetStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAyahInWidget = false;
          _isCheckingWidgetStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        widget.audioPlayer.playing && widget.playingAyahIndex == widget.index;

    final filteredReaders = widget.selectedLanguage != null
        ? widget.availableReaders
            .where((reader) => reader.language == widget.selectedLanguage)
            .toList()
        : widget.availableReaders;

    final availableLanguages = widget.availableReaders
        .map((reader) =>
            reader.language ?? AppLocalizations.of(context)!.unknown)
        .toSet()
        .toList()
      ..sort();

    final filteredTafsirSources = widget.availableTafsirSources;

    final availableTranslationLanguages = widget.availableTranslationSources
        .map((source) =>
            source.language ?? AppLocalizations.of(context)!.unknown)
        .toSet()
        .toList()
      ..sort();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.darkCardBackground
            : context.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.accentColor.withValues(alpha: 0.2)
                : Colors.black12,
            blurRadius: 18.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 14.h, bottom: 20.h),
            width: 45.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.accentColor
                  : context.primaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.accentColor.withValues(alpha: 0.2)
                            : context.primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.accentColor.withValues(alpha: 0.1)
                              : context.primaryColor.withValues(alpha: 0.08),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? context.accentColor
                                        .withValues(alpha: 0.15)
                                    : context.primaryColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.ayahText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.sp,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? context.accentColor
                                      : context.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              (() {
                                String ayahText = widget.ayah.text ?? '';
                                final isFirstAyah =
                                    widget.ayah.numberInSurah == 1;
                                final shouldShowBismillah = isFirstAyah &&
                                    widget.ayah.number != 1 &&
                                    widget.ayah.number != 9;

                                if (shouldShowBismillah) {
                                  const bismillahText =
                                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
                                  if (ayahText
                                      .trim()
                                      .startsWith(bismillahText)) {
                                    ayahText = ayahText
                                        .trim()
                                        .replaceFirst(bismillahText, '')
                                        .trim();
                                  }
                                }
                                return ayahText;
                              })(),
                              style: TextStyle(
                                fontFamily: getQuranFonts(),
                                fontSize: 20.sp,
                                height: 2.0,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? context.darkText
                                    : context.lightText,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isKhatmaEnd)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A7A36),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final khatmaService = getIt<KhatmaService>();
                              await khatmaService.markTodayDone();
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            'أكملت هذا الورد',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.darkTabBackground
                          : context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(
                          icon: Icons.volume_up_rounded,
                          label: AppLocalizations.of(context)!.audio,
                          index: 0,
                          isSelected: _selectedTabIndex == 0,
                        ),
                        _buildTabButton(
                          icon: Icons.menu_book_rounded,
                          label: AppLocalizations.of(context)!.tafsir,
                          index: 1,
                          isSelected: _selectedTabIndex == 1,
                        ),
                        _buildTabButton(
                          icon: Icons.translate_rounded,
                          label: AppLocalizations.of(context)!.translation,
                          index: 2,
                          isSelected: _selectedTabIndex == 2,
                        ),
                        _buildTabButton(
                          icon: Icons.bookmark_outline_rounded,
                          label: AppLocalizations.of(context)!.bookmark,
                          index: 3,
                          isSelected: _selectedTabIndex == 3,
                        ),
                        _buildTabButton(
                          icon: Icons.share_rounded,
                          label: AppLocalizations.of(context)!.share,
                          index: 4,
                          isSelected: _selectedTabIndex == 4,
                        ),
                        if (PlatformUtils.isMobile)
                          _buildTabButton(
                            icon: Icons.widgets_rounded,
                            label: AppLocalizations.of(context)!.widget,
                            index: 5,
                            isSelected: _selectedTabIndex == 5,
                          ),
                        _buildTabButton(
                          icon: Icons.compare_arrows_rounded,
                          label: 'Similar',
                          index: 6,
                          isSelected: _selectedTabIndex == 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve:
                                const Interval(0.2, 1.0, curve: Curves.easeOut),
                          )),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.05),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.95,
                                end: 1.0,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: const Interval(0.0, 0.8,
                                    curve: Curves.easeOutBack),
                              )),
                              child: child,
                            ),
                          ),
                        );
                      },
                      layoutBuilder: (Widget? currentChild,
                          List<Widget> previousChildren) {
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          child: currentChild ?? const SizedBox.shrink(),
                        );
                      },
                      child: _getCurrentTabContent(
                        isPlaying,
                        filteredReaders,
                        availableLanguages,
                        filteredTafsirSources,
                        availableTranslationLanguages,
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentTabContent(
    bool isPlaying,
    List<edition.Data> filteredReaders,
    List<String> availableLanguages,
    List<edition.Data> filteredTafsirSources,
    List<String> availableTranslationLanguages,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return Container(
          key: const ValueKey('audio_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child:
                _buildAudioTab(isPlaying, filteredReaders, availableLanguages),
          ),
        );
      case 1:
        return Container(
          key: const ValueKey('tafsir_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildTafsirTab(filteredTafsirSources),
          ),
        );
      case 2:
        return Container(
          key: const ValueKey('translation_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildTranslationTab(availableTranslationLanguages),
          ),
        );
      case 3:
        return Container(
          key: const ValueKey('bookmark_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildBookmarkTab(),
          ),
        );
      case 4:
        return Container(
          key: const ValueKey('share_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildShareTab(),
          ),
        );
      case 5:
        return Container(
          key: const ValueKey('widget_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildWidgetTab(),
          ),
        );
      case 6:
        return Container(
          key: const ValueKey('similar_ayahs_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildSimilarAyahsTab(),
          ),
        );
      default:
        return Container(
          key: const ValueKey('audio_tab'),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child:
                _buildAudioTab(isPlaying, filteredReaders, availableLanguages),
          ),
        );
    }
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedTabIndex = index);
            if (index == 6) _loadMatchingAyahs();
          },
          borderRadius: BorderRadius.circular(10.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            margin: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode ? context.accentColor : context.primaryColor)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDarkMode
                                ? context.accentColor
                                : context.primaryColor)
                            .withValues(alpha: 0.4),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                        spreadRadius: 1.r,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                            ? context.accentColor
                            : context.primaryColor),
                    size: 20.r,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTab(bool isPlaying, List<edition.Data> filteredReaders,
      List<String> availableLanguages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedReaderId != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.2)
                    : context.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.accentColor.withValues(alpha: 0.15)
                            : context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 14.r,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? context.accentColor
                                    : context.primaryColor,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            AppLocalizations.of(context)!.audioControls,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? context.accentColor
                                  : context.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.isLoadingAudio ||
                    (widget.selectedReaderId != null &&
                        widget.currentSurahAudio == null))
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.primaryColor,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading audio...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.unableLoadAudio,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.accentColor.withValues(alpha: 0.2)
                  : context.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.1)
                    : context.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.accentColor.withValues(alpha: 0.15)
                          : context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14.r,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.accentColor
                              : context.primaryColor,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          AppLocalizations.of(context)!.readerSelection,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? context.accentColor
                                    : context.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
        if (widget.selectedReaderId != null && !kIsWeb)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.2)
                    : context.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? context.accentColor
                                    : context.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.audioDownloads,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? context.accentColor
                                  : context.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.accentColor.withValues(alpha: 0.2)
                  : context.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.1)
                    : context.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.accentColor
                              : context.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.audioSettings,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? context.accentColor
                                    : context.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AudioSettingsWidget(
                loopEnabled: widget.loopEnabled,
                autoplayEnabled: widget.autoplayEnabled,
                onLoopChanged: widget.onLoopChanged,
                onAutoplayChanged: widget.onAutoplayChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTafsirTab(List<edition.Data> filteredTafsirSources) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.accentColor.withValues(alpha: 0.2)
              : context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.accentColor.withValues(alpha: 0.1)
                : context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.accentColor
                          : context.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.tafsirCommentary,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.accentColor
                            : context.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                ? AppLocalizations.of(context)!.offlineTafsirUnavailable
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationTab(List<String> availableTranslationLanguages) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.accentColor.withValues(alpha: 0.2)
              : context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.accentColor
                          : context.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.translation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.accentColor
                            : context.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                ? AppLocalizations.of(context)!.offlineTranslationUnavailable
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ShareWidget(
        ayah: widget.ayah,
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        surahEnglishName: widget.surahEnglishName,
        selectedTranslationId: widget.selectedTranslationId,
        currentTranslation: widget.currentTranslation,
        selectedTafsirId: widget.selectedTafsirId,
        currentTafsir: widget.currentTafsir,
      ),
    );
  }

  Widget _buildBookmarkTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BookmarkSection(
        surahNumber: widget.surahNumber,
        ayahNumber: widget.ayah.numberInSurah ?? widget.index + 1,
        ayahText: widget.ayah.text ?? '',
        surahName:
            widget.surahName ?? AppLocalizations.of(context)!.unknownSurah,
        getCurrentScrollPosition: widget.getCurrentScrollPosition,
      ),
    );
  }

  Widget _buildWidgetTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAyahWidgetStatus();
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.widgets_rounded,
                  color: context.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.addToHomeWidget,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.addToWidgetDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[850]!,
                      ]
                    : [
                        Colors.grey[50]!,
                        Colors.white,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.3)
                    : context.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.accentColor.withValues(alpha: 0.2)
                        : context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.accentColor
                            : context.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.preview,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? context.accentColor
                                  : context.primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]?.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryColor.withValues(alpha: 0.7),
                              context.primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          (() {
                            String ayahText = widget.ayah.text ?? '';
                            final isFirstAyah = widget.ayah.numberInSurah == 1;
                            final shouldShowBismillah = isFirstAyah &&
                                widget.surahNumber != 1 &&
                                widget.surahNumber != 9;

                            if (shouldShowBismillah) {
                              const bismillahText =
                                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
                              if (ayahText.trim().startsWith(bismillahText)) {
                                ayahText = ayahText
                                    .trim()
                                    .replaceFirst(bismillahText, '')
                                    .trim();
                              }
                            }
                            return ayahText;
                          })(),
                          style: TextStyle(
                            fontFamily: getQuranFonts(),
                            fontSize: 18.sp,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                            shadows:
                                Theme.of(context).brightness == Brightness.dark
                                    ? [
                                        const Shadow(
                                          color: Colors.black26,
                                          blurRadius: 1,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 3,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryColor,
                              context.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.surahName != null ||
                    widget.ayah.numberInSurah != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]?.withValues(alpha: 0.5)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.surahName ?? ''} ${widget.ayah.numberInSurah != null ? '- Ayah ${widget.ayah.numberInSurah}' : ''}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isCheckingWidgetStatus
                  ? null
                  : (_isAyahInWidget ? null : () => _addAyahToWidget()),
              icon: Icon(_isCheckingWidgetStatus
                  ? Icons.hourglass_empty
                  : (_isAyahInWidget
                      ? Icons.check_circle
                      : Icons.add_box_rounded)),
              label: Text(_isCheckingWidgetStatus
                  ? AppLocalizations.of(context)!.checking
                  : (_isAyahInWidget
                      ? AppLocalizations.of(context)!.alreadyInWidget
                      : AppLocalizations.of(context)!.addToWidget)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAyahInWidget
                    ? Colors.grey.shade400
                    : context.primaryColor,
                foregroundColor:
                    _isAyahInWidget ? Colors.grey.shade600 : Colors.white,
                elevation: 2,
                shadowColor:
                    (_isAyahInWidget ? Colors.grey : context.primaryColor)
                        .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[900]?.withValues(alpha: 0.3)
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.addToWidgetInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[300]
                              : Colors.blue[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAyahToWidget() async {
    try {
      String ayahText = widget.ayah.text ?? '';
      final surahName =
          widget.surahName ?? AppLocalizations.of(context)!.unknownSurah;
      final ayahNumber = widget.ayah.numberInSurah ?? widget.index + 1;

      final isFirstAyah = ayahNumber == 1;
      final shouldShowBismillah =
          isFirstAyah && widget.surahNumber != 1 && widget.surahNumber != 9;

      if (shouldShowBismillah) {
        const bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
        if (ayahText.trim().startsWith(bismillahText)) {
          ayahText = ayahText.trim().replaceFirst(bismillahText, '').trim();
        }
      }

      final success = await WidgetService.addCustomVerse(
        ayahText,
        surahName: surahName,
        ayahNumber: ayahNumber,
      );

      if (success) {
        await WidgetService.forceUpdateWidget();

        _checkAyahWidgetStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.ayahAddedToWidget,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isAyahInWidget = true;
          _isCheckingWidgetStatus = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This ayah is already in your widget collection.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to add ayah to widget: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildSimilarAyahsTab() {
    final ayahKey = '${widget.surahNumber}:${widget.ayah.numberInSurah}';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highlightColor =
        isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF1B8A4E);

    if (_isLoadingMatchingAyahs) {
      return Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? context.accentColor : context.primaryColor,
            ),
          ),
        ),
      );
    }

    if (_matchingAyahsData == null) {
      Future.microtask(_loadMatchingAyahs);
      return Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? context.accentColor : context.primaryColor,
            ),
          ),
        ),
      );
    }

    final matches = _matchingAyahsData![ayahKey] as List<dynamic>?;

    if (matches == null || matches.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDarkMode
                ? context.accentColor.withValues(alpha: 0.2)
                : context.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 48.r,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context)!.noSimilarAyahsFound,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: highlightColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: highlightColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!
                .similarAyahsCountLabel(ayahKey, matches.length),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: highlightColor,
            ),
          ),
        ),
        ...matches.map((match) {
          final matchedKey = match['matched_ayah_key'] as String;
          final parts = matchedKey.split(':');
          final matchedSurahNum = int.parse(parts[0]);
          final matchedAyahNum = int.parse(parts[1]);
          final matchedWordsCount = match['matched_words_count'] as int;
          final coverage = match['coverage'] as int;
          final score = match['score'] as int;
          final matchWords = match['match_words'] as List<dynamic>;

          String verseText = '';
          String surahNameAr = '';
          String surahNameEn = '';
          try {
            verseText = quran.getVerse(matchedSurahNum, matchedAyahNum);
            surahNameAr = quran.getSurahNameArabic(matchedSurahNum);
            surahNameEn = quran.getSurahNameEnglish(matchedSurahNum);
          } catch (_) {}

          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? context.accentColor.withValues(alpha: 0.08)
                      : context.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Material(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              child: InkWell(
                onTap: () {
                  final surahInfo = QuranModel(
                    number: matchedSurahNum,
                    name: surahNameAr,
                    englishName: surahNameEn,
                    englishNameTranslation: surahNameEn,
                    numberOfAyahs: quran.getVerseCount(matchedSurahNum),
                    revelationType: quran.getPlaceOfRevelation(matchedSurahNum),
                  );
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pushReplacementNamed(
                    AppRoute.surahScreen,
                    arguments: {
                      'surahInfo': surahInfo,
                      'scrollToAyah': matchedAyahNum,
                      'shouldRestorePosition': false,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDarkMode
                          ? context.accentColor.withValues(alpha: 0.2)
                          : context.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            surahNameAr,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? context.accentColor.withValues(alpha: 0.2)
                                  : context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              matchedKey,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? context.accentColor
                                    : context.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      if (verseText.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: SizedBox(
                            width: double.infinity,
                            child: _buildHighlightedAyahText(
                              verseText,
                              matchWords,
                              highlightColor,
                              isDarkMode,
                            ),
                          ),
                        ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12.r,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .similarAyahsMatchStats(
                                      matchedWordsCount, coverage, score),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12.r,
                            color: isDarkMode
                                ? context.accentColor
                                : context.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHighlightedAyahText(
    String verse,
    List<dynamic> matchWords,
    Color highlightColor,
    bool isDarkMode,
  ) {
    final words = verse.split(' ');
    final Set<int> highlightedIndices = {};
    for (final range in matchWords) {
      if (range is! List || range.isEmpty) continue;
      final start = (range[0] as int) - 1;
      final end = range.length >= 2 ? (range[1] as int) - 1 : start;
      for (int i = start; i <= end && i < words.length; i++) {
        if (i >= 0) highlightedIndices.add(i);
      }
    }
    final spans = <TextSpan>[];
    for (int i = 0; i < words.length; i++) {
      final isHighlighted = highlightedIndices.contains(i);
      spans.add(TextSpan(
        text: i < words.length - 1 ? '${words[i]} ' : words[i],
        style: TextStyle(
          color: isHighlighted
              ? highlightColor
              : (isDarkMode ? Colors.white : Colors.black87),
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
        ),
      ));
    }
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: TextStyle(
          fontFamily: getQuranFonts(),
          fontSize: 20.sp,
          height: 2.0,
        ),
        children: spans,
      ),
    );
  }
}
