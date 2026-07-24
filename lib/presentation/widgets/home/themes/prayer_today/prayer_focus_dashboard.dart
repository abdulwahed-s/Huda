import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/focused_theme_layout.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_visual_style.dart';
import 'package:huda/presentation/widgets/home/shared/prayer_location_formatter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:vector_graphics/vector_graphics.dart';

class PrayerFocusDashboard extends StatefulWidget {
  const PrayerFocusDashboard({
    super.key,
    required this.isDark,
    required this.onOpenPrayerTimes,
    this.entranceAnimation,
    this.header,
    this.event,
  });

  final bool isDark;
  final VoidCallback onOpenPrayerTimes;
  final Animation<double>? entranceAnimation;
  final Widget? header;
  final Widget? event;

  @override
  State<PrayerFocusDashboard> createState() => _PrayerFocusDashboardState();
}

class _PrayerFocusDashboardState extends State<PrayerFocusDashboard>
    with SingleTickerProviderStateMixin {
  static const _completeAnimation = AlwaysStoppedAnimation<double>(1);

  late final AnimationController _readinessController;
  PrayerTimesCubit? _prayerCubit;
  Stream<NextPrayerCountdown>? _countdownStream;
  bool _readinessStarted = false;
  bool _readinessScheduled = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;

  Animation<double> get _entranceAnimation =>
      widget.entranceAnimation ?? _completeAnimation;

  @override
  void initState() {
    super.initState();
    _readinessController = AnimationController(
      vsync: this,
      duration: PrayerTodayMotion.readiness,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.read<PrayerTimesCubit>();
    if (!identical(cubit, _prayerCubit)) {
      _prayerCubit = cubit;
      _countdownStream = null;
      _readinessStarted = false;
      _readinessController.value = 0;
    }

    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (_reduceMotion) {
      _readinessController.value = 1;
    } else if (!_readinessStarted) {
      _readinessController.value = 0;
    }
    if (cubit.state is PrayerTimesLoaded) _startReadiness();
  }

  void _startReadiness({bool afterFirstPaint = true}) {
    if (_readinessStarted || _readinessScheduled) return;
    if (_reduceMotion) {
      _readinessController.value = 1;
      _readinessStarted = true;
      return;
    }
    if (!_tickerEnabled) return;
    if (!afterFirstPaint) {
      _readinessStarted = true;
      _readinessController.forward(from: 0);
      return;
    }

    _readinessScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readinessScheduled = false;
      if (!mounted || _readinessStarted) return;
      if (_prayerCubit?.state is! PrayerTimesLoaded) return;
      if (_reduceMotion) {
        _readinessController.value = 1;
        _readinessStarted = true;
        return;
      }
      if (!_tickerEnabled) return;

      _readinessStarted = true;
      _readinessController.forward(from: 0);
    });
  }

  void _handlePrayerState(BuildContext context, PrayerTimesState state) {
    if (state is PrayerTimesLoaded) {
      _startReadiness(afterFirstPaint: false);
    } else {
      _countdownStream = null;
    }
  }

  Stream<NextPrayerCountdown> _streamForLoadedState() =>
      _countdownStream ??= _prayerCubit!.getNextPrayerCountdown();

  @override
  void dispose() {
    _readinessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return _PrayerCanvasShell(
      isDark: widget.isDark,
      entranceAnimation: _entranceAnimation,
      child: FocusedThemeContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.header case final header?) header,
            if (widget.event case final event?) event,
            BlocConsumer<PrayerTimesCubit, PrayerTimesState>(
              listener: _handlePrayerState,
              builder: (context, state) {
                late final Widget canvas;
                if (state is PrayerTimesLoaded) {
                  canvas = _LoadedPrayerCanvas(
                    key: const ValueKey('prayer-loaded-canvas'),
                    state: state,
                    countdownStream: _streamForLoadedState(),
                    entranceAnimation: _entranceAnimation,
                    readinessAnimation: _readinessController,
                  );
                } else if (state is PrayerTimesInitial ||
                    state is PrayerTimesLoading) {
                  canvas = const _PrayerCanvasLoading(
                    key: ValueKey('prayer-loading-canvas'),
                  );
                } else {
                  final l10n = AppLocalizations.of(context)!;
                  final details = switch (state) {
                    PrayerTimesLocationDenied() => (
                        Icons.location_off_rounded,
                        l10n.locationPermissionDenied,
                      ),
                    PrayerTimesLocationPermanentlyDenied() => (
                        Icons.location_off_rounded,
                        l10n.locationPermissionPermanentlyDenied,
                      ),
                    PrayerTimesLocationServiceDisabled() => (
                        Icons.location_disabled_rounded,
                        l10n.locationServicesDisabled,
                      ),
                    PrayerTimesError(:final message) => (
                        Icons.error_outline_rounded,
                        message,
                      ),
                    _ => (
                        Icons.add_location_alt_rounded,
                        l10n.prayerSetupRequired,
                      ),
                  };
                  canvas = _UnavailablePrayerCanvas(
                    key: ValueKey('prayer-unavailable-${state.runtimeType}'),
                    icon: details.$1,
                    message: details.$2,
                    onOpenPrayerTimes: widget.onOpenPrayerTimes,
                  );
                }

                if (reduceMotion) return canvas;
                const duration = PrayerTodayMotion.stateChange;
                return AnimatedSize(
                  duration: duration,
                  curve: PrayerTodayMotion.entranceCurve,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    key: const ValueKey('prayer-canvas-state-switcher'),
                    duration: duration,
                    switchInCurve: PrayerTodayMotion.entranceCurve,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => AnimatedBuilder(
                      animation: animation,
                      child: child,
                      builder: (context, child) => ExcludeSemantics(
                        excluding: animation.status == AnimationStatus.reverse,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    child: canvas,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedPrayerCanvas extends StatefulWidget {
  const _LoadedPrayerCanvas({
    super.key,
    required this.state,
    required this.countdownStream,
    required this.entranceAnimation,
    required this.readinessAnimation,
  });

  final PrayerTimesLoaded state;
  final Stream<NextPrayerCountdown> countdownStream;
  final Animation<double> entranceAnimation;
  final Animation<double> readinessAnimation;

  @override
  State<_LoadedPrayerCanvas> createState() => _LoadedPrayerCanvasState();
}

class _LoadedPrayerCanvasState extends State<_LoadedPrayerCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _motionAllowed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: PrayerTodayMotion.pulse,
    );
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );
    widget.readinessAnimation.addStatusListener(_handleReadinessStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _LoadedPrayerCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readinessAnimation != widget.readinessAnimation) {
      oldWidget.readinessAnimation.removeStatusListener(_handleReadinessStatus);
      widget.readinessAnimation.addStatusListener(_handleReadinessStatus);
    }
    _syncPulse();
  }

  void _handleReadinessStatus(AnimationStatus status) {
    if (mounted) _syncPulse();
  }

  void _syncPulse() {
    final motionEnabled =
        _motionAllowed && widget.readinessAnimation.value >= 1;
    if (!motionEnabled) {
      _pulseController
        ..stop()
        ..value = 0;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    widget.readinessAnimation.removeStatusListener(_handleReadinessStatus);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final pulse = reduceMotion ? const AlwaysStoppedAnimation(0.0) : _pulse;
    return Semantics(
      container: true,
      label: AppLocalizations.of(context)!.prayerTimes,
      child: StreamBuilder<NextPrayerCountdown>(
        stream: widget.countdownStream,
        builder: (context, snapshot) {
          final countdownValue = snapshot.data;
          final now = DateTime.now();
          final locale = Localizations.localeOf(context).toString();
          final hijri = HijriCalendar.fromDate(now);
          final moments = _adjustedMoments(
            context,
            widget.state,
            widget.state.prayerTimes,
          );
          final progress = _intervalProgress(now, moments, countdownValue);

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrayerTodayMotionReveal(
                  key: const ValueKey('prayer-context-reveal'),
                  animation: widget.entranceAnimation,
                  begin: 0.10,
                  end: 0.40,
                  secondaryAnimation: widget.readinessAnimation,
                  secondaryBegin: 0,
                  secondaryEnd: 0.30,
                  distance: 5,
                  child: _IntegratedPrayerContext(
                    gregorian: intl.DateFormat.yMMMMEEEEd(locale).format(now),
                    hijri: '${hijri.hDay} '
                        '${_hijriMonth(context, hijri.hMonth)} '
                        '${hijri.hYear}',
                    location: prayerLocationLabel(context, widget.state),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final split = constraints.maxWidth >= 760 && scale <= 1.35;
                    final countdown = _CountdownFocus(
                      countdown: countdownValue,
                      progress: progress,
                      pulse: pulse,
                      moments: moments,
                      locale: locale,
                      entranceAnimation: widget.entranceAnimation,
                      readinessAnimation: widget.readinessAnimation,
                    );
                    final schedule = _PrayerDaySchedule(
                      moments: moments,
                      locale: locale,
                      nextPrayerName: countdownValue?.prayerName,
                      now: now,
                      entranceAnimation: widget.entranceAnimation,
                      readinessAnimation: widget.readinessAnimation,
                    );
                    if (!split) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          countdown,
                          const SizedBox(height: 18),
                          schedule,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 4, child: countdown),
                        PrayerTodayMotionReveal(
                          animation: widget.entranceAnimation,
                          begin: 0.36,
                          end: 0.60,
                          secondaryAnimation: widget.readinessAnimation,
                          secondaryBegin: 0.28,
                          secondaryEnd: 0.58,
                          child: Container(
                            width: 1,
                            height: 220,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            color: Colors.white.withValues(alpha: 0.13),
                          ),
                        ),
                        Expanded(flex: 8, child: schedule),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrayerCanvasShell extends StatelessWidget {
  const _PrayerCanvasShell({
    required this.isDark,
    required this.entranceAnimation,
    required this.child,
  });

  final bool isDark;
  final Animation<double> entranceAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: entranceAnimation,
      child: child,
      builder: (context, content) {
        final gradientProgress = PrayerTodayMotion.phase(
          entranceAnimation.value,
          begin: 0,
          end: 0.52,
        );
        final atmosphereProgress = PrayerTodayMotion.phase(
          entranceAnimation.value,
          begin: 0.08,
          end: 0.70,
        );
        final edgeProgress = PrayerTodayMotion.phase(
          entranceAnimation.value,
          begin: 0.50,
          end: 0.82,
        );
        final finalColors = _prayerCanvasColors(context, isDark);
        final quietOverlay =
            isDark ? const Color(0xFF06131B) : context.primaryDarkColor;
        final colors = [
          for (final color in finalColors)
            Color.lerp(
              Color.alphaBlend(
                quietOverlay.withValues(alpha: isDark ? 0.24 : 0.18),
                color,
              ),
              color,
              gradientProgress,
            )!,
        ];

        return AnnotatedRegion<SystemUiOverlayStyle>(
          key: const ValueKey('prayer-home-system-overlay'),
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemStatusBarContrastEnforced: false,
          ),
          child: ClipRect(
            key: const ValueKey('prayer-atmosphere-canvas'),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: reduceMotion || entranceAnimation.value < 1
                        ? Duration.zero
                        : PrayerTodayMotion.stateChange,
                    curve: PrayerTodayMotion.stateCurve,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: colors,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('prayer-atmosphere-paint'),
                      painter: _PrayerAtmospherePainter(
                        ink: Colors.white,
                        accent: const Color(0xFFF3D58A),
                        progress: atmosphereProgress,
                      ),
                    ),
                  ),
                ),
                content!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        end: PrayerTodayVisualStyle.toolsSurfaceTop(
                          context,
                          isDark,
                        ),
                      ),
                      duration: reduceMotion || entranceAnimation.value < 1
                          ? Duration.zero
                          : PrayerTodayMotion.stateChange,
                      curve: PrayerTodayMotion.stateCurve,
                      builder: (context, color, _) => RepaintBoundary(
                        child: CustomPaint(
                          key: const ValueKey('prayer-canvas-edge-paint'),
                          painter: _PrayerCanvasEdgePainter(
                            color: color ??
                                PrayerTodayVisualStyle.toolsSurfaceTop(
                                  context,
                                  isDark,
                                ),
                            progress: edgeProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IntegratedPrayerContext extends StatelessWidget {
  const _IntegratedPrayerContext({
    required this.gregorian,
    required this.hijri,
    required this.location,
  });

  final String gregorian;
  final String hijri;
  final String? location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: '${l10n.gregorianDate}: $gregorian. '
          '${l10n.hijriDate}: $hijri${location == null ? '' : '. $location'}',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : PrayerTodayMotion.stateChange,
          child: Wrap(
            key: ValueKey('$gregorian|$hijri|$location'),
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 9,
            runSpacing: 7,
            children: [
              _ContextDatum(
                icon: Icons.calendar_today_outlined,
                text: gregorian,
              ),
              const _ContextDot(),
              _ContextDatum(icon: Icons.brightness_2_outlined, text: hijri),
              if (location != null) ...[
                const _ContextDot(),
                _ContextDatum(
                  icon: Icons.location_on_outlined,
                  text: location!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextDatum extends StatelessWidget {
  const _ContextDatum({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.58)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ContextDot extends StatelessWidget {
  const _ContextDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CountdownFocus extends StatelessWidget {
  const _CountdownFocus({
    required this.countdown,
    required this.progress,
    required this.pulse,
    required this.moments,
    required this.locale,
    required this.entranceAnimation,
    required this.readinessAnimation,
  });

  final NextPrayerCountdown? countdown;
  final double progress;
  final Animation<double> pulse;
  final List<_PrayerMoment> moments;
  final String locale;
  final Animation<double> entranceAnimation;
  final Animation<double> readinessAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = countdown;
    final duration = value == null
        ? null
        : value.isPastPrayer
            ? Duration(seconds: value.secondsPassed)
            : value.duration;
    final countdownText =
        duration == null ? '--:--:--' : _formatDuration(duration);
    final matching = _findMoment(moments, value?.prayerName);
    final targetTime = matching?.time == null
        ? null
        : intl.DateFormat.jm(locale).format(matching!.time!);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stateDuration = reduceMotion || readinessAnimation.value < 1
        ? Duration.zero
        : PrayerTodayMotion.stateChange;
    final prayerName = value?.prayerName ?? l10n.nextPrayer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrayerTodayMotionReveal(
          key: const ValueKey('prayer-name-reveal'),
          animation: entranceAnimation,
          begin: 0.16,
          end: 0.48,
          secondaryAnimation: readinessAnimation,
          secondaryBegin: 0.04,
          secondaryEnd: 0.42,
          distance: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.nextPrayerCountDown,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 3),
              Semantics(
                container: true,
                liveRegion: true,
                label: prayerName,
                child: ExcludeSemantics(
                  child: AnimatedSwitcher(
                    duration: stateDuration,
                    switchInCurve: PrayerTodayMotion.entranceCurve,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.center,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    transitionBuilder: (child, animation) => ClipRect(
                      child: FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: PrayerTodayMotion.entranceCurve,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                    ),
                    child: Text(
                      prayerName,
                      key: ValueKey(prayerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrayerTodayMotionReveal(
          key: const ValueKey('prayer-countdown-ring-reveal'),
          animation: entranceAnimation,
          begin: 0.22,
          end: 0.64,
          secondaryAnimation: readinessAnimation,
          secondaryBegin: 0.10,
          secondaryEnd: 0.68,
          distance: 7,
          beginScale: 0.985,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final diameter =
                  constraints.maxWidth.clamp(156.0, 186.0).toDouble();
              return SizedBox.square(
                key: const ValueKey('prayer-countdown-ring'),
                dimension: diameter,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: AnimatedSwitcher(
                        key: const ValueKey(
                          'prayer-countdown-ring-transition',
                        ),
                        duration: stateDuration,
                        switchInCurve: PrayerTodayMotion.entranceCurve,
                        switchOutCurve: Curves.easeInCubic,
                        child: _StableCountdownRing(
                          key: ValueKey(
                            'prayer-ring-$prayerName-'
                            '${value?.isPastPrayer == true ? 'past' : 'next'}',
                          ),
                          targetProgress: progress,
                          pulse: pulse,
                          revealAnimation: readinessAnimation,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Semantics(
                                label: value?.isPastPrayer == true
                                    ? '+$countdownText'
                                    : countdownText,
                                child: ExcludeSemantics(
                                  child: Text(
                                    value?.isPastPrayer == true
                                        ? '+$countdownText'
                                        : countdownText,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (targetTime != null) ...[
                              const SizedBox(height: 5),
                              Semantics(
                                label: targetTime,
                                child: ExcludeSemantics(
                                  child: AnimatedSwitcher(
                                    duration: stateDuration,
                                    child: Text(
                                      targetTime,
                                      key: ValueKey(targetTime),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.62),
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StableCountdownRing extends StatefulWidget {
  const _StableCountdownRing({
    super.key,
    required this.targetProgress,
    required this.pulse,
    required this.revealAnimation,
  });

  final double targetProgress;
  final Animation<double> pulse;
  final Animation<double> revealAnimation;

  @override
  State<_StableCountdownRing> createState() => _StableCountdownRingState();
}

class _StableCountdownRingState extends State<_StableCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: PrayerTodayMotion.countdownTick,
    );
    _progressAnimation = AlwaysStoppedAnimation(widget.targetProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _settleImmediately();
    }
  }

  @override
  void didUpdateWidget(covariant _StableCountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress == widget.targetProgress) return;

    final current = _progressAnimation.value;
    final target = widget.targetProgress;
    final shouldSettle = MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled ||
        target < current - 0.015 ||
        (target - current).abs() > 0.24;
    if (shouldSettle) {
      _settleImmediately();
      return;
    }

    _progressAnimation = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: PrayerTodayMotion.stateCurve,
      ),
    );
    _progressController.forward(from: 0);
  }

  void _settleImmediately() {
    _progressController.stop();
    _progressAnimation = AlwaysStoppedAnimation(widget.targetProgress);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        key: const ValueKey('prayer-countdown-ring-painter'),
        painter: _CountdownRingPainter(
          progress: _progressAnimation,
          pulse: widget.pulse,
          reveal: widget.revealAnimation,
        ),
      ),
    );
  }
}

class _PrayerDaySchedule extends StatelessWidget {
  const _PrayerDaySchedule({
    required this.moments,
    required this.locale,
    required this.nextPrayerName,
    required this.now,
    required this.entranceAnimation,
    required this.readinessAnimation,
  });

  final List<_PrayerMoment> moments;
  final String locale;
  final String? nextPrayerName;
  final DateTime now;
  final Animation<double> entranceAnimation;
  final Animation<double> readinessAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeIndex = moments.indexWhere(
      (moment) =>
          nextPrayerName != null &&
          moment.name.toLowerCase() == nextPrayerName!.toLowerCase(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrayerTodayMotionReveal(
          key: const ValueKey('prayer-schedule-heading-reveal'),
          animation: entranceAnimation,
          begin: 0.34,
          end: 0.58,
          secondaryAnimation: readinessAnimation,
          secondaryBegin: 0.30,
          secondaryEnd: 0.56,
          distance: 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final showToday = scale <= 1.45 || constraints.maxWidth >= 360;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.prayerTimes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (showToday) ...[
                    const SizedBox(width: 12),
                    Text(
                      l10n.today,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.50),
                          ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns =
                constraints.maxWidth >= 290 && scale <= 1.65 ? 3 : 2;
            final extent = scale > 1.45 ? 102.0 : 86.0;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: extent,
              ),
              itemCount: moments.length,
              itemBuilder: (context, index) {
                final moment = moments[index];
                final highlighted = index == activeIndex;
                final past = !highlighted &&
                    moment.time != null &&
                    moment.time!.isBefore(now);
                final distanceFromFocus =
                    activeIndex < 0 ? index : (index - activeIndex).abs();
                final rootBegin =
                    (0.40 + distanceFromFocus * 0.035).clamp(0.40, 0.60);
                final rootEnd =
                    (0.66 + distanceFromFocus * 0.035).clamp(0.66, 0.84);
                final readyBegin =
                    (0.38 + distanceFromFocus * 0.055).clamp(0.38, 0.66);
                final readyEnd =
                    (0.72 + distanceFromFocus * 0.055).clamp(0.72, 0.96);
                return PrayerTodayMotionReveal(
                  key: ValueKey('prayer-schedule-reveal-${moment.keyName}'),
                  animation: entranceAnimation,
                  begin: rootBegin.toDouble(),
                  end: rootEnd.toDouble(),
                  secondaryAnimation: readinessAnimation,
                  secondaryBegin: readyBegin.toDouble(),
                  secondaryEnd: readyEnd.toDouble(),
                  distance: 5,
                  beginScale: 0.99,
                  child: _PrayerMomentTile(
                    moment: moment,
                    locale: locale,
                    highlighted: highlighted,
                    past: past,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PrayerMomentTile extends StatelessWidget {
  const _PrayerMomentTile({
    required this.moment,
    required this.locale,
    required this.highlighted,
    required this.past,
  });

  final _PrayerMoment moment;
  final String locale;
  final bool highlighted;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration =
        reduceMotion ? Duration.zero : PrayerTodayMotion.stateChange;
    const highlightAccent = Color(0xFFF3D58A);
    const foreground = Colors.white;
    final highlightStart = Color.lerp(
      context.primaryDarkColor,
      const Color(0xFF07131B),
      isDark ? 0.62 : 0.32,
    )!;
    final highlightEnd = Color.lerp(
      context.primaryDarkColor,
      context.primaryColor,
      isDark ? 0.18 : 0.34,
    )!;
    final highlightColors = isDark
        ? [highlightStart, highlightEnd]
        : [
            context.primaryLightColor.withValues(alpha: 0.30),
            highlightAccent.withValues(alpha: 0.16),
          ];
    final formattedTime = _formatPrayerTime(locale, moment.time);
    final tile = AnimatedContainer(
      duration: duration,
      curve: PrayerTodayMotion.stateCurve,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? null
            : Colors.white.withValues(alpha: moment.isSunrise ? 0.045 : 0.065),
        gradient: highlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlightColors,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? highlightAccent.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: past ? 0.055 : 0.10),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: highlightAccent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: AnimatedOpacity(
        opacity: past ? 0.50 : 1,
        duration: duration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PrayerMomentGlyph(
                  moment: moment,
                  color: highlighted
                      ? highlightAccent
                      : foreground.withValues(alpha: 0.70),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    moment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: foreground.withValues(
                            alpha: highlighted ? 0.90 : 0.78,
                          ),
                          fontWeight:
                              highlighted ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedTime,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      key: ValueKey('prayer-schedule-${moment.keyName}'),
      container: true,
      selected: highlighted,
      label: '${moment.name}, $formattedTime',
      child: ExcludeSemantics(child: tile),
    );
  }
}

class _PrayerMomentGlyph extends StatelessWidget {
  const _PrayerMomentGlyph({required this.moment, required this.color});

  final _PrayerMoment moment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = moment.iconAsset;
    if (asset != null) {
      return SvgPicture(
        AssetBytesLoader(asset),
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(moment.icon, size: 16, color: color);
  }
}

class _UnavailablePrayerCanvas extends StatelessWidget {
  const _UnavailablePrayerCanvas({
    super.key,
    required this.icon,
    required this.message,
    required this.onOpenPrayerTimes,
  });

  final IconData icon;
  final String message;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final hijri = HijriCalendar.fromDate(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 76),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntegratedPrayerContext(
            gregorian: intl.DateFormat.yMMMMEEEEd(locale).format(now),
            hijri: '${hijri.hDay} '
                '${_hijriMonth(context, hijri.hMonth)} ${hijri.hYear}',
            location: null,
          ),
          const SizedBox(height: 34),
          Center(
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 35),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onOpenPrayerTimes,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: context.primaryDarkColor,
              ),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(l10n.setUpPrayerTimes),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCanvasLoading extends StatelessWidget {
  const _PrayerCanvasLoading({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({required double height, double? width, double radius = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Semantics(
      label: AppLocalizations.of(context)!.loading,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 74),
        child: Column(
          children: [
            block(height: 16, width: 250),
            const SizedBox(height: 30),
            block(height: 22, width: 130),
            const SizedBox(height: 12),
            block(height: 176, width: 176, radius: 88),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 290 ? 3 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 76,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => block(height: 76),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.pulse,
    required this.reveal,
  }) : super(repaint: Listenable.merge([progress, pulse, reveal]));

  final Animation<double> progress;
  final Animation<double> pulse;
  final Animation<double> reveal;

  double get effectiveProgress =>
      progress.value *
      PrayerTodayMotion.phase(reveal.value, begin: 0.10, end: 0.68);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final revealValue =
        PrayerTodayMotion.phase(reveal.value, begin: 0.10, end: 0.68);
    final pulseValue = pulse.value;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.11 * revealValue);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + pulseValue * 0.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF3D58A).withValues(
        alpha: (0.10 + pulseValue * 0.035) * revealValue,
      );
    final foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF3D58A)],
      ).createShader(rect);
    const start = -math.pi / 2;
    final sweep = math.pi * 2 * effectiveProgress.clamp(0.0, 1.0);
    canvas.drawCircle(center, radius, background);
    if (sweep > 0) {
      canvas.drawArc(rect, start, sweep, false, glow);
      canvas.drawArc(rect, start, sweep, false, foreground);
    }
    final dotAngle = start + sweep;
    canvas.drawCircle(
      Offset(
        center.dx + math.cos(dotAngle) * radius,
        center.dy + math.sin(dotAngle) * radius,
      ),
      (4.2 + pulseValue * 0.45) * revealValue,
      Paint()..color = const Color(0xFFFFE7AA).withValues(alpha: revealValue),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.reveal != reveal;
}

class _PrayerCanvasEdgePainter extends CustomPainter {
  const _PrayerCanvasEdgePainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    canvas
      ..save()
      ..translate(0, (1 - value) * 48);
    final edge = Path()
      ..moveTo(0, size.height - 42)
      ..cubicTo(
        size.width * 0.17,
        size.height - 76,
        size.width * 0.34,
        size.height - 18,
        size.width * 0.55,
        size.height - 43,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height - 64,
        size.width * 0.86,
        size.height - 18,
        size.width,
        size.height - 34,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(edge, Paint()..color = color);

    final highlight = Path()
      ..moveTo(0, size.height - 46)
      ..cubicTo(
        size.width * 0.24,
        size.height - 78,
        size.width * 0.37,
        size.height - 21,
        size.width * 0.56,
        size.height - 47,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height - 68,
        size.width * 0.87,
        size.height - 23,
        size.width,
        size.height - 38,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.12 * value),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrayerCanvasEdgePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

class _PrayerAtmospherePainter extends CustomPainter {
  const _PrayerAtmospherePainter({
    required this.ink,
    required this.accent,
    required this.progress,
  });

  final Color ink;
  final Color accent;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(
        size.width * (1 - value) * 0.004,
        size.height * (1 - value) * 0.003,
      )
      ..translate(size.width / 2, size.height / 2)
      ..scale(0.992 + value * 0.008)
      ..translate(-size.width / 2, -size.height / 2);

    _drawEngravedFrieze(canvas, size);
    _drawMihrab(canvas, size);
    _drawGeometricLattice(canvas, size);
    _drawRosette(
      canvas,
      Offset(size.width - (size.width < 520 ? 44 : 62), 92),
      size.width < 520 ? 26 : 34,
    );
    _drawArabesqueVines(canvas, size);
    if (size.width >= 650) _drawHangingLantern(canvas, size);

    canvas.restore();
  }

  void _drawEngravedFrieze(Canvas canvas, Size size) {
    const y = 48.0;
    final hairline = Paint()
      ..color = ink.withValues(alpha: 0.075 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final gold = Paint()
      ..color = accent.withValues(alpha: 0.085 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas
      ..drawLine(const Offset(0, y - 8), Offset(size.width, y - 8), hairline)
      ..drawLine(const Offset(0, y + 8), Offset(size.width, y + 8), hairline);

    for (var x = -8.0; x <= size.width + 16; x += 32) {
      final diamond = Path()
        ..moveTo(x, y - 8)
        ..lineTo(x + 12, y)
        ..lineTo(x, y + 8)
        ..lineTo(x - 12, y)
        ..close();
      final inner = Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + 6, y)
        ..lineTo(x, y + 4)
        ..lineTo(x - 6, y)
        ..close();
      canvas
        ..drawPath(diamond, hairline)
        ..drawPath(inner, gold)
        ..drawCircle(Offset(x, y), 1.25, gold);
    }
  }

  void _drawMihrab(Canvas canvas, Size size) {
    final compact = size.width < 760;
    final contentMargin = math.max(0.0, (size.width - 1120) / 2);
    final wideMargins = contentMargin >= 140;
    final centerX = compact
        ? size.width * 0.5
        : wideMargins
            ? contentMargin * 0.5
            : size.width * 0.19;
    final halfWidth = math.min(
      compact
          ? size.width * 0.31
          : wideMargins
              ? contentMargin * 0.34
              : 145.0,
      146.0,
    );
    final top = compact ? 74.0 : 66.0;
    final bottom = math.min(size.height - 82, top + (compact ? 285 : 265));
    final line = Paint()
      ..color = ink.withValues(alpha: 0.095 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05;
    final gold = Paint()
      ..color = accent.withValues(alpha: 0.105 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    Path arch(double inset, double topInset) {
      final left = centerX - halfWidth + inset;
      final right = centerX + halfWidth - inset;
      final peak = top + topInset;
      final shoulder = peak + halfWidth * 0.72;
      return Path()
        ..moveTo(left, bottom)
        ..lineTo(left, shoulder)
        ..cubicTo(
          left,
          peak + halfWidth * 0.30,
          centerX - halfWidth * 0.24,
          peak + halfWidth * 0.20,
          centerX,
          peak,
        )
        ..cubicTo(
          centerX + halfWidth * 0.24,
          peak + halfWidth * 0.20,
          right,
          peak + halfWidth * 0.30,
          right,
          shoulder,
        )
        ..lineTo(right, bottom);
    }

    canvas
      ..drawPath(arch(0, 0), line)
      ..drawPath(arch(9, 11), gold)
      ..drawPath(arch(17, 21), line);

    final baseY = bottom - 2;
    canvas
      ..drawLine(
        Offset(centerX - halfWidth - 6, baseY),
        Offset(centerX + halfWidth + 6, baseY),
        line,
      )
      ..drawLine(
        Offset(centerX - halfWidth + 8, baseY + 7),
        Offset(centerX + halfWidth - 8, baseY + 7),
        gold,
      );

    _drawRosette(canvas, Offset(centerX, top + 58), 18);
  }

  void _drawGeometricLattice(Canvas canvas, Size size) {
    final compact = size.width < 760;
    final line = Paint()
      ..color = ink.withValues(
        alpha: (compact ? 0.042 : 0.052) * progress,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    final gold = Paint()
      ..color = accent.withValues(alpha: 0.052 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final startY = compact ? 106.0 : 82.0;
    final endY = size.height - 92;

    if (compact) {
      for (var y = startY; y < endY; y += 68) {
        _drawEightPointStar(canvas, Offset(22, y), 11, 4.8, line);
        _drawEightPointStar(
          canvas,
          Offset(size.width - 22, y + 30),
          11,
          4.8,
          gold,
        );
        canvas
          ..drawLine(Offset(22, y + 11), Offset(22, y + 57), line)
          ..drawLine(
            Offset(size.width - 22, y + 41),
            Offset(size.width - 22, math.min(y + 87, endY)),
            gold,
          );
      }
      return;
    }

    final contentMargin = math.max(0.0, (size.width - 1120) / 2);
    if (contentMargin >= 140) {
      final leftAnchor = contentMargin * 0.52;
      final rightAnchor = size.width - leftAnchor;
      for (var y = startY; y < endY; y += 96) {
        final stagger = ((y - startY) ~/ 96).isOdd ? 16.0 : 0.0;
        _drawEightPointStar(
          canvas,
          Offset(leftAnchor + stagger, y),
          11,
          4.6,
          line,
        );
        _drawEightPointStar(
          canvas,
          Offset(rightAnchor - stagger, y + 34),
          11,
          4.6,
          gold,
        );
      }
      return;
    }

    final startX = size.width * 0.43;
    for (var y = startY; y < endY; y += 62) {
      final stagger = ((y - startY) ~/ 62).isOdd ? 31.0 : 0.0;
      for (var x = startX + stagger; x < size.width + 24; x += 62) {
        _drawEightPointStar(canvas, Offset(x, y), 13, 5.4, line);
        canvas.drawCircle(Offset(x, y), 3.2, gold);
      }
    }
  }

  void _drawRosette(Canvas canvas, Offset center, double radius) {
    final line = Paint()
      ..color = ink.withValues(alpha: 0.085 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    final gold = Paint()
      ..color = accent.withValues(alpha: 0.12 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas
      ..drawCircle(center, radius, line)
      ..drawCircle(center, radius * 0.72, gold)
      ..drawCircle(center, radius * 0.20, line);
    _drawEightPointStar(canvas, center, radius * 0.84, radius * 0.34, gold);

    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * radius * 0.48,
        center.dy + math.sin(angle) * radius * 0.48,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      final petal = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.52,
        height: radius * 0.20,
      );
      canvas.drawOval(petal, line);
      canvas.restore();
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    Paint paint,
  ) {
    final star = Path();
    for (var index = 0; index < 16; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + index * math.pi / 8;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      index == 0
          ? star.moveTo(point.dx, point.dy)
          : star.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(star..close(), paint);
  }

  void _drawArabesqueVines(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ink.withValues(alpha: 0.068 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;
    final gold = Paint()
      ..color = accent.withValues(alpha: 0.085 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    final baseY = size.height - 58;
    final reach = math.min(size.width * 0.27, 180.0);

    final left = Path()
      ..moveTo(-8, baseY)
      ..cubicTo(
        reach * 0.18,
        baseY - 74,
        reach * 0.66,
        baseY - 94,
        reach,
        baseY - 140,
      )
      ..cubicTo(
        reach * 0.70,
        baseY - 124,
        reach * 0.42,
        baseY - 148,
        reach * 0.58,
        baseY - 176,
      );
    canvas.drawPath(left, line);

    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(left, gold);
    canvas.restore();

    for (final leaf in [
      (Offset(reach * 0.25, baseY - 56), -0.72),
      (Offset(reach * 0.52, baseY - 89), -0.15),
      (Offset(reach * 0.78, baseY - 120), -0.92),
      (Offset(reach * 0.55, baseY - 150), 0.32),
    ]) {
      _drawLeaf(canvas, leaf.$1, leaf.$2, 15, line);
      _drawLeaf(
        canvas,
        Offset(size.width - leaf.$1.dx, leaf.$1.dy),
        math.pi - leaf.$2,
        15,
        gold,
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.48, -length * 0.30, length, 0)
      ..quadraticBezierTo(length * 0.48, length * 0.30, 0, 0)
      ..close();
    canvas
      ..drawPath(leaf, paint)
      ..drawLine(Offset.zero, Offset(length, 0), paint);
    canvas.restore();
  }

  void _drawHangingLantern(Canvas canvas, Size size) {
    final centerX = size.width * 0.92;
    final line = Paint()
      ..color = accent.withValues(alpha: 0.11 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(centerX, 56), Offset(centerX, 112), line);
    final lantern = Path()
      ..moveTo(centerX - 8, 112)
      ..lineTo(centerX + 8, 112)
      ..lineTo(centerX + 13, 128)
      ..lineTo(centerX + 7, 150)
      ..lineTo(centerX - 7, 150)
      ..lineTo(centerX - 13, 128)
      ..close();
    canvas
      ..drawPath(lantern, line)
      ..drawLine(
        Offset(centerX - 9, 128),
        Offset(centerX + 9, 128),
        line,
      )
      ..drawCircle(
        Offset(centerX, 133),
        5,
        Paint()..color = accent.withValues(alpha: 0.045 * progress),
      );
  }

  @override
  bool shouldRepaint(covariant _PrayerAtmospherePainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.progress != progress;
}

class _PrayerMoment {
  const _PrayerMoment({
    required this.keyName,
    required this.name,
    required this.time,
    this.icon,
    this.iconAsset,
    this.isSunrise = false,
  }) : assert(icon != null || iconAsset != null);

  final String keyName;
  final String name;
  final DateTime? time;
  final IconData? icon;
  final String? iconAsset;
  final bool isSunrise;
}

List<_PrayerMoment> _adjustedMoments(
  BuildContext context,
  PrayerTimesLoaded state,
  DailyPrayerTimes times,
) {
  final l10n = AppLocalizations.of(context)!;
  _PrayerMoment moment(
    String key,
    String name,
    DateTime? time, {
    IconData? icon,
    String? iconAsset,
    bool sunrise = false,
  }) {
    return _PrayerMoment(
      keyName: key,
      name: name,
      time: time?.add(Duration(minutes: state.offsets[key] ?? 0)),
      icon: icon,
      iconAsset: iconAsset,
      isSunrise: sunrise,
    );
  }

  return [
    moment('fajr', l10n.fajr, times.fajr, icon: Icons.wb_twilight),
    moment(
      'sunrise',
      l10n.sunrise,
      times.sunrise,
      iconAsset: 'assets/images/sunrise.svg.vec',
      sunrise: true,
    ),
    moment('dhuhr', l10n.dhuhr, times.dhuhr, icon: Icons.wb_sunny),
    moment('asr', l10n.asr, times.asr, icon: Icons.wb_sunny_outlined),
    moment(
      'maghrib',
      l10n.maghrib,
      times.maghrib,
      iconAsset: 'assets/images/sunset.svg.vec',
    ),
    moment('isha', l10n.isha, times.isha, icon: Icons.nights_stay),
  ];
}

double _intervalProgress(
  DateTime now,
  List<_PrayerMoment> moments,
  NextPrayerCountdown? countdown,
) {
  if (countdown == null) return 0;
  if (countdown.isPastPrayer) return 1;
  final index = moments.indexWhere(
    (moment) => moment.name.toLowerCase() == countdown.prayerName.toLowerCase(),
  );
  if (index < 0 || moments[index].time == null) return 0;
  var target = moments[index].time!;
  while (!target.isAfter(now)) {
    target = target.add(const Duration(days: 1));
  }
  DateTime start;
  if (index > 0 && moments[index - 1].time != null) {
    start = moments[index - 1].time!;
  } else {
    start = moments.last.time ?? target.subtract(const Duration(hours: 6));
  }
  while (!start.isBefore(target)) {
    start = start.subtract(const Duration(days: 1));
  }
  final total = target.difference(start).inMilliseconds;
  if (total <= 0) return 0;
  return (now.difference(start).inMilliseconds / total).clamp(0.0, 1.0);
}

_PrayerMoment? _findMoment(List<_PrayerMoment> moments, String? name) {
  if (name == null) return null;
  for (final moment in moments) {
    if (moment.name.toLowerCase() == name.toLowerCase()) return moment;
  }
  return null;
}

List<Color> _prayerCanvasColors(BuildContext context, bool isDark) {
  if (isDark) {
    return [
      Color.alphaBlend(
        context.primaryColor.withValues(alpha: 0.22),
        const Color(0xFF071822),
      ),
      context.primaryDarkColor,
    ];
  }
  return [
    context.primaryDarkColor,
    context.primaryColor,
    Color.lerp(context.primaryColor, context.primaryLightColor, 0.72)!,
  ];
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatPrayerTime(String locale, DateTime? time) {
  if (time == null) return '--:--';
  return intl.DateFormat.jm(locale).format(time);
}

String _hijriMonth(BuildContext context, int month) {
  final l10n = AppLocalizations.of(context)!;
  return [
    l10n.muharram,
    l10n.safar,
    l10n.rabiAlAwwal,
    l10n.rabiAlThani,
    l10n.jumadaAlAwwal,
    l10n.jumadaAlThani,
    l10n.rajab,
    l10n.shaban,
    l10n.ramadan,
    l10n.shawwal,
    l10n.dhuAlQidah,
    l10n.dhuAlHijjah,
  ][month - 1];
}
