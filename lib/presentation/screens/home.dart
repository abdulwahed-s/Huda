import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/core/services/rating_service.dart';
import 'package:huda/core/services/update_service.dart';
import 'package:huda/core/services/whats_new_service.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/reciter_surahs_screen.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/home/exit_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/privacy/foss_crash_reporting_consent_prompt.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.startupDialogs = true});

  final bool startupDialogs;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  bool _isStartupDialogSequenceRunning = false;
  bool _isRatingCheckScheduled = false;
  bool _wasCurrent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HomeCubit>().loadHomeData();
    context.read<PrayerTimesCubit>().loadCachedPrayerTimes();
    if (widget.startupDialogs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runStartupDialogs();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      context.read<PrayerTimesCubit>().setLocalizations(localizations);
    }
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current && !_wasCurrent) {
      context.read<HomeCustomizationCubit>().load();
    }
    _wasCurrent = current;
  }

  Future<void> _runStartupDialogs() async {
    if (_isStartupDialogSequenceRunning) return;

    _isStartupDialogSequenceRunning = true;
    try {
      final showedCrashConsent =
          await FossCrashReportingConsentPrompt.showIfNeeded(context);
      if (showedCrashConsent || !mounted) return;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().loadHomeData();
      context.read<PrayerTimesCubit>().loadCachedPrayerTimes();
      context.read<IslamicEventCubit>().loadActiveEvent();
      if (widget.startupDialogs) _scheduleRatingCheckAfterResume();
    }
  }

  void _refreshHomeData() {
    context.read<HomeCubit>().loadHomeData();
    context.read<IslamicEventCubit>().loadActiveEvent();
  }

  void _failed() {
    if (!mounted) return;
    showHudaToast(
      context,
      message: AppLocalizations.of(context)!.unexpectedError,
      kind: HudaToastKind.failed,
    );
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
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<QuranPlayerCubit>()),
              BlocProvider.value(value: context.read<PlayerBarCubit>()),
              BlocProvider.value(value: context.read<DownloadProgressCubit>()),
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
      if (mounted) _refreshHomeData();
    } catch (_) {
      _failed();
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
      if (!mounted) return;
      QuranRadioCubit.pendingAutoPlay = station;
      await Navigator.pushNamed(context, AppRoute.quranRadio);
      if (mounted) {
        await context.read<QuranRadioCubit>().saveCurrentStation();
        _refreshHomeData();
      }
    } catch (_) {
      _failed();
    }
  }

  Future<void> _openSurah(int surahNumber, int? ayahNumber) async {
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
        arguments: ayahNumber == null
            ? {'surahInfo': surah, 'shouldRestorePosition': true}
            : {
                'surahInfo': surah,
                'shouldRestorePosition': false,
                'scrollToAyah': ayahNumber,
              },
      );
      if (mounted) _refreshHomeData();
    } catch (_) {
      _failed();
    }
  }

  Future<void> _openRadio() async {
    await Navigator.pushNamed(context, AppRoute.quranRadio);
    if (!mounted) return;
    await context.read<QuranRadioCubit>().saveCurrentStation();
    _refreshHomeData();
  }

  Future<void> _openQuran() async {
    await Navigator.pushNamed(context, AppRoute.homeQuran);
    if (mounted) _refreshHomeData();
  }

  Future<bool> _confirmExit() async {
    final size = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          anchorPoint: Offset(rtl ? 0 : size.width, size.height / 2),
          builder: (_) => const ExitConfirmationDialog(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final actions = HomeActions(
      openQuran: _openQuran,
      openPrayerTimes: () => Navigator.pushNamed(context, AppRoute.prayerTimes),
      openAudio: () => Navigator.pushNamed(context, AppRoute.quranAudio),
      openRadio: _openRadio,
      openBookmarks: () => Navigator.pushNamed(context, AppRoute.bookmarks),
      openSurah: (surah, ayah) => _openSurah(surah, ayah),
      openLastRead: (summary) =>
          _openSurah(summary['surahNumber'] as int, null),
      openLastReciter: (progress) =>
          _openLastReciterAudio(progress as QuranAudioProgress),
      openLastStation: (progress) =>
          _openLastRadioStation(progress as RadioStationProgress),
      retry: _refreshHomeData,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) SystemNavigator.pop();
      },
      child: HudaRevealScope(
        child: HomeLamplighter(child: HomeView(actions: actions)),
      ),
    );
  }
}
