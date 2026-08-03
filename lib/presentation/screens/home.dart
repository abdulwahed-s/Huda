import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/update_service.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/core/services/rating_service.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/reciter_surahs_screen.dart';
import 'package:huda/presentation/widgets/home/home_background.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:huda/presentation/widgets/home/themes/classic_home_header.dart';
import 'package:huda/presentation/widgets/home/exit_confirmation_dialog.dart';
import 'package:huda/core/services/whats_new_service.dart';
import 'package:huda/presentation/screens/home_customization.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _entranceStarted = false;
  bool _entranceScheduled = false;
  bool _isStartupDialogSequenceRunning = false;
  bool _isRatingCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    context.read<HomeCubit>().loadHomeData();
    context.read<PrayerTimesCubit>().loadCachedPrayerTimes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupDialogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animationController
        ..stop()
        ..value = 1;
      _entranceStarted = true;
    } else if (!_entranceStarted && TickerMode.valuesOf(context).enabled) {
      _scheduleEntrance();
    }
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      context.read<PrayerTimesCubit>().setLocalizations(localizations);
    }
  }

  void _scheduleEntrance() {
    if (_entranceStarted || _entranceScheduled) return;
    _entranceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceScheduled = false;
      if (!mounted || _entranceStarted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _animationController.value = 1;
        _entranceStarted = true;
        return;
      }
      if (!TickerMode.valuesOf(context).enabled) return;
      _entranceStarted = true;
      _animationController.forward(from: 0);
    });
  }

  Future<void> _runStartupDialogs() async {
    if (_isStartupDialogSequenceRunning) return;

    _isStartupDialogSequenceRunning = true;
    try {
      final showedUpdate = await UpdateService.checkAndShow(context);
      if (showedUpdate || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await WhatsNewService.checkAndShow(context);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await RatingService.instance.checkAndShowRatingDialog(context);
    } finally {
      _isStartupDialogSequenceRunning = false;
    }
  }

  Future<void> _scheduleRatingCheckAfterResume() async {
    if (_isStartupDialogSequenceRunning || _isRatingCheckScheduled) return;

    _isRatingCheckScheduled = true;
    try {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        await RatingService.instance.checkAndShowRatingDialog(context);
      }
    } finally {
      _isRatingCheckScheduled = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().loadHomeData();
      context.read<PrayerTimesCubit>().loadCachedPrayerTimes();
      context.read<IslamicEventCubit>().loadActiveEvent();
      debugPrint('🏠 Home screen: Refreshing data on app resume');

      _scheduleRatingCheckAfterResume();
    }
  }

  void _refreshHomeData() {
    context.read<HomeCubit>().loadHomeData();
    context.read<IslamicEventCubit>().loadActiveEvent();
    debugPrint('🏠 Home screen: Manual refresh triggered');
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const ExitConfirmationDialog();
          },
        ) ??
        false;
  }

  Future<void> _openLastReciterAudio(QuranAudioProgress progress) async {
    final reciter = Reciter(
      id: progress.reciterId,
      name: progress.reciterName,
      letter: progress.reciterLetter,
      moshaf: [
        Moshaf(
          id: progress.moshafId,
          name: progress.moshafName,
          server: progress.moshafServer,
          surahTotal: progress.moshafSurahTotal,
          moshafType: progress.moshafType,
          surahList: progress.moshafSurahList,
        ),
      ],
    );

    try {
      final jsonData = jsonDecode(progress.jsonData) as List;

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<QuranPlayerCubit>()),
                BlocProvider.value(value: context.read<PlayerBarCubit>()),
                BlocProvider.value(
                    value: context.read<DownloadProgressCubit>()),
              ],
              child: ReciterSurahsScreen(
                reciter: reciter,
                moshaf: reciter.moshaf.first,
                jsonData: jsonData,
                initialSurahIndex: progress.surahIndex,
                initialPositionMs: progress.positionMs,
              ),
            ),
          ),
        );

        if (mounted) {
          _refreshHomeData();
        }
      }
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.unexpectedError,
        );
      }
    }
  }

  Future<void> _openLastRadioStation(RadioStationProgress progress) async {
    try {
      final station = RadioStation(
        id: progress.stationId,
        name: progress.stationName,
        url: progress.stationUrl,
        recentDate: DateTime.now().toIso8601String(),
      );

      if (mounted) {
        QuranRadioCubit.pendingAutoPlay = station;
        await Navigator.pushNamed(context, AppRoute.quranRadio);

        if (mounted) {
          await context.read<QuranRadioCubit>().saveCurrentStation();
          _refreshHomeData();
        }
      }
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.unexpectedError,
        );
      }
    }
  }

  Future<void> _openLastReadSurah(Map<String, dynamic> lastReadSummary) async {
    final surahNumber = lastReadSummary['surahNumber'] as int;

    try {
      final quranCubit = QuranCubit();
      await quranCubit.loadQuran();

      final surah = quranCubit.surahs.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => throw Exception('Surah not found'),
      );

      if (mounted) {
        await Navigator.pushNamed(
          context,
          AppRoute.surahScreen,
          arguments: {
            'surahInfo': surah,
            'shouldRestorePosition': true,
          },
        );

        if (mounted) {
          _refreshHomeData();
        }
      }
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.unexpectedError,
        );
      }
    }
  }

  Future<void> _openSurahAt(int surahNumber, int ayahNumber) async {
    try {
      final quranCubit = QuranCubit();
      await quranCubit.loadQuran();
      final surah = quranCubit.surahs.firstWhere(
        (item) => item.number == surahNumber,
        orElse: () => throw Exception('Surah not found'),
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoute.surahScreen,
        arguments: {
          'surahInfo': surah,
          'shouldRestorePosition': false,
          'scrollToAyah': ayahNumber,
        },
      );
      if (mounted) _refreshHomeData();
    } catch (error) {
      if (!mounted) return;
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.unexpectedError,
      );
    }
  }

  Future<void> _openCustomization() async {
    final customization = context.read<HomeCustomizationCubit>();
    final home = context.read<HomeCubit>();
    final events = context.read<IslamicEventCubit>();
    final prayer = context.read<PrayerTimesCubit>();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    await Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        pageBuilder: (_, animation, secondaryAnimation) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: customization),
            BlocProvider.value(value: home),
            BlocProvider.value(value: events),
            BlocProvider.value(value: prayer),
          ],
          child: const HomeCustomizationScreen(),
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.975, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: HomeBackground(
          isDarkMode: isDarkMode,
          child: BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
            buildWhen: (previous, current) {
              final previousTheme = previous is HomeCustomizationReady
                  ? previous.preferences.selectedTheme
                  : null;
              final currentTheme = current is HomeCustomizationReady
                  ? current.preferences.selectedTheme
                  : null;
              return previousTheme != currentTheme;
            },
            builder: (context, customization) {
              final selectedTheme = customization is HomeCustomizationReady
                  ? customization.preferences.selectedTheme
                  : HomeThemeId.classic;
              final scrollView = CustomScrollView(
                physics: selectedTheme != HomeThemeId.classic
                    ? const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      )
                    : const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (selectedTheme == HomeThemeId.classic)
                    ClassicHomeHeaderSliver(
                      entranceAnimation: _animationController,
                      onCustomize: _openCustomization,
                    ),
                  SliverSafeArea(
                    top: false,
                    left: false,
                    right: false,
                    sliver: HomeContent(
                      animationController: _animationController,
                      fadeAnimation: _fadeAnimation,
                      slideAnimation: _slideAnimation,
                      refreshHomeData: _refreshHomeData,
                      openLastReadSurah: _openLastReadSurah,
                      openLastReciterAudio: (progress) => _openLastReciterAudio(
                        progress as QuranAudioProgress,
                      ),
                      openLastRadioStation: (progress) => _openLastRadioStation(
                        progress as RadioStationProgress,
                      ),
                      openSurah: _openSurahAt,
                      onCustomize: _openCustomization,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              );
              if (selectedTheme != HomeThemeId.classic) return scrollView;
              return ClassicHomeSystemOverlay(
                isDark: isDarkMode,
                child: scrollView,
              );
            },
          ),
        ),
      ),
    );
  }
}
