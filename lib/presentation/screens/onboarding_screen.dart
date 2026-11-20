import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_identity.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_shell.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_alerts_ready_card.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final OnboardingCubit _cubit = context.read<OnboardingCubit>();
  late final PrayerTimesCubit _prayer = context.read<PrayerTimesCubit>();
  late final NotificationAccessController _access = _cubit.environment
      .createAccess(
        context.read<NotificationsCubit>(),
        _prayer.refreshNotificationSchedule,
      );
  late final Listenable _sources = prayerReadinessSources(_access);

  late final AnimationController _flood;
  late final StreamSubscription<OnboardingState> _steps;

  late final AnimationController _veil = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _switching = false;
  final _sheet = OnboardingSession();

  @override
  void initState() {
    super.initState();
    _flood = AnimationController(
      vsync: this,
      duration: OnboardingArcade.floodIn,
    );
    WidgetsBinding.instance.addObserver(this);
    _sources.addListener(_syncAvailability);
    _steps = _cubit.stream.listen((_) => _syncAvailability());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAvailability());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) _prayer.setLocalizations(l10n);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sources.removeListener(_syncAvailability);
    _steps.cancel();
    _access.dispose();
    _flood.dispose();
    _veil.dispose();
    super.dispose();
  }

  void _syncAvailability() {
    if (!mounted) return;
    final access = _access.access;
    if (access == null) return;
    final l10n = AppLocalizations.of(context)!;
    final items =
        buildPrayerReadinessItems(
          l10n: l10n,
          inputs: currentPrayerReadinessInputs(access),
          actions: prayerReadinessActions(context, _access),
        ).where(
          (item) =>
              item.kind != PrayerReadinessKind.notifications &&
              !PrayerAlertsReadyCard.snoozed(
                _cubit.environment.cache,
                item.kind,
              ),
        );
    final alertsOpen =
        _cubit.state.outcomeOf(OnboardingStep.permissions) ==
            StepOutcome.pending &&
        _cubit.state.outcomeOf(OnboardingStep.alerts) == StepOutcome.pending;
    _cubit.setAvailability(
      reliability:
          (access.notificationsEnabled && items.isNotEmpty) ||
          (alertsOpen && !access.notificationsEnabled),
      reminders: access.notificationsEnabled || alertsOpen,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    if (_cubit.state.current != OnboardingStep.location) return;
    final issue = prayerLocationIssueOf(
      _prayer.state,
      canOpenSettings: _cubit.environment.canOpenSettings,
    );
    if (issue == PrayerLocationIssue.denied ||
        issue == PrayerLocationIssue.blocked ||
        issue == PrayerLocationIssue.servicesOff) {
      unawaited(_retryLocationIfAccessRestored());
    }
  }

  Future<void> _retryLocationIfAccessRestored() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    await _prayer.refreshLocationAndPrayerTimes();
  }

  Future<void> _switchLanguage(Locale locale) async {
    final languages = context.read<LocalizationCubit>();
    if (_switching ||
        languages.state.locale.languageCode == locale.languageCode) {
      return;
    }
    _switching = true;
    final tokens = context.tokens;
    final fadeOut = tokens.motion.of(context, tokens.motion.medium);
    final fadeIn = tokens.motion.of(context, tokens.motion.long);
    Future<void> apply() async {
      final changed = languages.stream
          .firstWhere(
            (state) => state.locale.languageCode == locale.languageCode,
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => languages.state,
          );
      unawaited(
        languages.setLocale(locale).catchError((Object error) {
          debugPrint('Onboarding language not saved: $error');
        }),
      );
      await changed;
    }

    try {
      if (fadeOut == Duration.zero) {
        await apply();
        return;
      }
      _veil.duration = fadeOut;
      await _veil.reverse().orCancel;
      await apply();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _veil.duration = fadeIn;
      await _veil.forward().orCancel;
    } on TickerCanceled {
      return;
    } finally {
      _switching = false;
      if (mounted && !_veil.isAnimating && _veil.value < 1) _veil.value = 1;
    }
  }

  Future<void> _finish() async {
    if (_cubit.state.finishing) return;
    HudaHaptics.medium(context);
    final tokens = context.tokens;
    _flood.duration = tokens.motion.of(context, OnboardingArcade.floodIn);
    Future<void> flooded() async {
      if (_flood.duration == Duration.zero) return;
      try {
        await _flood.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }

    await Future.wait([_cubit.finish(), flooded()]);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoute.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final first = context.select<OnboardingCubit, bool>(
      (cubit) => !cubit.state.canGoBack,
    );
    return PopScope(
      canPop: first,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cubit.back();
      },
      child: OnboardingScope(
        environment: _cubit.environment,
        access: _access,
        finish: _finish,
        switchLanguage: _switchLanguage,
        veil: _veil,
        sheet: _sheet,
        child: OnboardingShell(onSkip: _finish),
      ),
    );
  }
}
