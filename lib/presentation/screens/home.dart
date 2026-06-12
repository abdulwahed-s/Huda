import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/core/services/rating_service.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/presentation/screens/reciter_surahs_screen.dart';
import 'package:huda/presentation/widgets/home/home_app_bar.dart';
import 'package:huda/presentation/widgets/home/home_background.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:upgrader/upgrader.dart';
import 'package:huda/presentation/widgets/home/exit_confirmation_dialog.dart';
import 'package:huda/core/services/whats_new_service.dart';

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
    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        WhatsNewService.checkAndShow(context);
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        RatingService.instance.checkAndShowRatingDialog(context);
      }
    });
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
      debugPrint('🏠 Home screen: Refreshing data on app resume');

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          RatingService.instance.checkAndShowRatingDialog(context);
        }
      });
    }
  }

  void _refreshHomeData() {
    context.read<HomeCubit>().loadHomeData();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening reciter: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening radio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening last read surah: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
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
      child: UpgradeAlert(
        barrierDismissible: false,
        showReleaseNotes: true,
        showIgnore: false,
        upgrader: getIt<Upgrader>(),
        child: Scaffold(
          body: HomeBackground(
            isDarkMode: isDarkMode,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ignore: prefer_const_constructors
                HomeAppBar(),
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
                    openLastReciterAudio: (progress) =>
                        _openLastReciterAudio(progress as QuranAudioProgress),
                    openLastRadioStation: (progress) =>
                        _openLastRadioStation(progress as RadioStationProgress),
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
