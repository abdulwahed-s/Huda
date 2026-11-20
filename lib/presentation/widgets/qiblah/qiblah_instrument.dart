import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:precise_compass/precise_compass.dart' show CompassAccuracy;
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/qiblah/qiblah_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_calibration.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_identity.dart';

enum QiblahPhase {
  locating,

  compass,

  noCompass,
}

class QiblahInstrument extends StatefulWidget {
  const QiblahInstrument({
    super.key,
    required this.readings,
    required this.onFailed,
    this.onRefreshLocation,
  });

  final Stream<QiblahReading>? readings;

  final ValueChanged<Object> onFailed;

  final VoidCallback? onRefreshLocation;

  @override
  State<QiblahInstrument> createState() => _QiblahInstrumentState();
}

class _QiblahInstrumentState extends State<QiblahInstrument>
    with TickerProviderStateMixin {
  StreamSubscription<QiblahReading>? _subscription;
  QiblahReading? _reading;

  late final AnimationController _heading = AnimationController.unbounded(
    vsync: this,
  );

  late final AnimationController _lock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    reverseDuration: const HudaMotion().short,
  );

  bool _aligned = false;

  bool _refreshing = false;
  bool _retrying = false;

  void _refreshLocation() {
    setState(() {
      _retrying = _reading?.fix == QiblahFixState.stale;
      _refreshing = true;
    });
    widget.onRefreshLocation?.call();
  }

  static const double _leaveTolerance = kQiblahAlignmentToleranceDeg + 2.5;

  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 90,
    ratio: 0.62,
  );

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(QiblahInstrument old) {
    super.didUpdateWidget(old);
    if (old.readings != widget.readings) _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = widget.readings?.listen(
      _onReading,
      onError: (Object error) => widget.onFailed(error),
    );
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _onReading(QiblahReading reading) {
    if (!mounted) return;
    final first = _reading == null || !_reading!.hasHeading;
    setState(() {
      _reading = reading;
      if (reading.fix != QiblahFixState.refining) _refreshing = false;
    });
    if (!reading.hasHeading) return;

    final current = _heading.value;
    final target = current + _wrap(reading.heading - current);
    if (_reduceMotion) {
      _heading.value = target;
    } else if (first) {
      _heading.value = target - 40;
      _heading.animateWith(SpringSimulation(_spring, target - 40, target, 0));
    } else {
      _heading.animateWith(
        SpringSimulation(_spring, current, target, _heading.velocity),
      );
    }

    final off = reading.delta.abs();
    final aligned = _aligned
        ? off <= _leaveTolerance
        : off <= kQiblahAlignmentToleranceDeg;
    if (aligned == _aligned) return;
    setState(() => _aligned = aligned);
    if (aligned) {
      HudaHaptics.medium(context);
      if (_reduceMotion) {
        _lock.value = 1;
      } else {
        _lock.forward();
      }
    } else if (_reduceMotion) {
      _lock.value = 0;
    } else {
      _lock.reverse();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _heading.dispose();
    _lock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    final phase = switch (reading) {
      null => QiblahPhase.locating,
      QiblahReading(hasHeading: false) => QiblahPhase.noCompass,
      _ => QiblahPhase.compass,
    };
    final bearing = reading?.qiblahBearing;
    return QiblahArrangement(
      dial: QiblahDial(
        phase: phase,
        bearing: bearing ?? 0,
        heading: _heading,
        lock: _lock,
      ),
      header: (start) => QiblahHeader(
        phase: phase,
        bearing: bearing,
        heading: _heading,
        aligned: _aligned,
        start: start,
      ),
      footer: (start) => QiblahFooter(
        phase: phase,
        reading: reading,
        aligned: _aligned,
        onRefreshLocation: widget.onRefreshLocation == null
            ? null
            : _refreshLocation,
        refreshing: _refreshing,
        retryingLocation: _retrying,
        start: start,
      ),
      calibrating: phase == QiblahPhase.compass && reading!.shouldCalibrate,
    );
  }
}

double _wrap(double degrees) {
  var d = degrees % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

class QiblahDial extends StatelessWidget {
  const QiblahDial({
    super.key,
    required this.phase,
    required this.bearing,
    required this.heading,
    required this.lock,
  });

  final QiblahPhase phase;
  final double bearing;
  final Animation<double> heading;
  final Animation<double> lock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = QiblahDialColors.of(context);
    final style = OrnamentStyle.of(context, onChrome: true);
    final motion = context.tokens.motion;
    final compass = phase == QiblahPhase.compass;
    final located = phase != QiblahPhase.locating;

    final face = RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: QiblahFacePainter(
          style: style,
          fill: colors.fill,
          ink: colors.ink,
          muted: colors.muted,
          cardinals: [
            l10n.qiblahNorthShort,
            l10n.qiblahEastShort,
            l10n.qiblahSouthShort,
            l10n.qiblahWestShort,
          ],
          letterStyle: theme.textTheme.titleMedium!,
          numeralStyle: theme.textTheme.labelSmall!.copyWith(letterSpacing: 0),
        ),
      ),
    );

    final alidade = RepaintBoundary(
      child: AnimatedBuilder(
        animation: lock,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: QiblahAlidadePainter(
            style: style,
            rule: colors.ink,
            fill: colors.fill,
            lock: QiblahLockStages(
              lock.value,
              releasing: lock.status == AnimationStatus.reverse,
            ),
          ),
        ),
      ),
    );

    final index = RepaintBoundary(
      child: AnimatedBuilder(
        animation: lock,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: QiblahIndexPainter(
            style: style,
            lock: QiblahLockStages(
              lock.value,
              releasing: lock.status == AnimationStatus.reverse,
            ),
            tolerance: kQiblahAlignmentToleranceDeg,
            showIndex: compass,
          ),
        ),
      ),
    );

    double turn(double degrees) => degrees * math.pi / 180;
    return Semantics(
      label: l10n.qiblahDirection,
      image: true,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: located ? 1 : 0.45,
          duration: motion.of(context, motion.long),
          curve: motion.standard,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (compass)
                AnimatedBuilder(
                  animation: heading,
                  builder: (context, child) => Transform.rotate(
                    angle: turn(-heading.value),
                    child: child,
                  ),
                  child: face,
                )
              else
                face,
              index,
              if (located)
                compass
                    ? AnimatedBuilder(
                        animation: heading,
                        builder: (context, child) => Transform.rotate(
                          angle: turn(bearing - heading.value),
                          child: child,
                        ),
                        child: alidade,
                      )
                    : Transform.rotate(angle: turn(bearing), child: alidade),
            ],
          ),
        ),
      ),
    );
  }
}

class QiblahHeader extends StatelessWidget {
  const QiblahHeader({
    super.key,
    required this.phase,
    required this.bearing,
    required this.heading,
    required this.aligned,
    required this.start,
  });

  final QiblahPhase phase;
  final double? bearing;
  final Animation<double> heading;
  final bool aligned;

  final bool start;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final bearing = this.bearing;
    final align = start ? TextAlign.start : TextAlign.center;
    final cross = start ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final large = context.windowClass.width >= WindowWidthClass.medium;
    final expanded = context.windowClass.width >= WindowWidthClass.expanded;

    final Widget body;
    final Object key;
    switch (phase) {
      case QiblahPhase.locating:
        key = 'locating';
        body = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HudaLampSpinner(size: 22, color: tokens.gilt),
            SizedBox(width: space.sm),
            Flexible(
              child: Text(
                l10n.qiblahFinding,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.onChrome,
                ),
              ),
            ),
          ],
        );
      case QiblahPhase.noCompass:
        key = 'no-compass';
        body = Text(
          l10n.qiblahNoCompassTitle,
          textAlign: align,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.onChrome,
          ),
        );
      case QiblahPhase.compass:
        key = 'compass';
        final facing = Semantics(
          liveRegion: true,
          child: Text(
            l10n.qiblahFacing,
            textAlign: align,
            style:
                (large
                        ? theme.textTheme.headlineLarge
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(color: tokens.onChrome),
          ),
        );
        final numeral =
            (expanded
                    ? context.type.counter
                    : large
                    ? theme.textTheme.displayLarge
                    : theme.textTheme.displayMedium)
                ?.copyWith(
                  color: tokens.onChrome,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );
        final turning = AnimatedBuilder(
          animation: heading,
          builder: (context, _) {
            final off = _wrap((bearing ?? 0) - heading.value);
            final right = off > 0;
            final degrees = off.abs().round();
            final label = right ? l10n.qiblahTurnRight : l10n.qiblahTurnLeft;
            return Semantics(
              label: '$label, $degrees°',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: cross,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: Text('$degrees°', style: numeral),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      if (!right)
                        Icon(
                          Icons.turn_left_rounded,
                          size: 24,
                          color: tokens.gilt,
                        ),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: space.xxs),
                          child: Text(
                            label,
                            textDirection: Directionality.of(context),
                            style:
                                (expanded
                                        ? theme.textTheme.headlineSmall
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(color: tokens.onChrome),
                          ),
                        ),
                      ),
                      if (right)
                        Icon(
                          Icons.turn_right_rounded,
                          size: 24,
                          color: tokens.gilt,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
        body = QiblahTextSwap(
          showSecond: aligned,
          alignment: start
              ? AlignmentDirectional.topStart
              : AlignmentDirectional.topCenter,
          first: turning,
          second: facing,
        );
    }

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bearing != null) ...[
          HudaEyebrow(
            l10n.qiblahFromNorth(qiblahDegrees(bearing)),
            color: tokens.gilt,
          ),
          SizedBox(height: space.xs),
        ],
        HudaStateSwitcher(
          stateKey: key,
          sequential: true,
          alignment: start
              ? AlignmentDirectional.topStart.resolve(
                  Directionality.of(context),
                )
              : Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Align(
              alignment: start
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              child: body,
            ),
          ),
        ),
      ],
    );
  }
}

class QiblahFooter extends StatelessWidget {
  const QiblahFooter({
    super.key,
    required this.phase,
    required this.reading,
    required this.aligned,
    required this.start,
    this.onRefreshLocation,
    this.refreshing = false,
    this.retryingLocation = false,
  });

  final QiblahPhase phase;
  final QiblahReading? reading;
  final bool aligned;
  final bool start;
  final VoidCallback? onRefreshLocation;
  final bool refreshing;
  final bool retryingLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final align = start ? TextAlign.start : TextAlign.center;
    final large = context.windowClass.width >= WindowWidthClass.expanded;
    final muted =
        (large ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
            ?.copyWith(color: tokens.onChromeMuted);
    final reading = this.reading;
    final cross = start ? CrossAxisAlignment.start : CrossAxisAlignment.center;

    final String instruction;
    final List<Widget> notes = [];
    Object key;
    switch (phase) {
      case QiblahPhase.locating:
        key = 'locating';
        instruction = l10n.qiblahHoldFlat;
      case QiblahPhase.noCompass:
        key = 'no-compass';
        instruction = l10n.qiblahNoCompassMessage(
          qiblahDegrees(reading?.qiblahBearing ?? 0),
        );
      case QiblahPhase.compass:
        final r = reading!;
        key = 'compass';
        instruction = '';
        if (r.hasInterference) {
          notes.add(
            _QiblahNote(
              icon: Icons.warning_amber_rounded,
              text: l10n.qiblahInterference,
              warning: true,
            ),
          );
        }
        if (r.isTilted) {
          notes.add(
            _QiblahNote(
              icon: Icons.screen_rotation_alt_rounded,
              text: l10n.qiblahTilted,
              warning: true,
            ),
          );
        }
        final quality = switch (r.accuracy) {
          CompassAccuracy.high => l10n.qiblahAccuracyGood,
          CompassAccuracy.medium => l10n.qiblahAccuracyFair,
          CompassAccuracy.low ||
          CompassAccuracy.unreliable => l10n.qiblahAccuracyPoor,
          CompassAccuracy.unknown => null,
        };
        if (quality != null && notes.isEmpty) {
          final good = r.accuracy == CompassAccuracy.high;
          notes.add(
            _QiblahNote(
              icon: good
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              text: quality,
              good: good,
            ),
          );
        }
    }

    final calibrate =
        phase == QiblahPhase.compass && (reading?.shouldCalibrate ?? false);
    final motion = tokens.motion.of(context, tokens.motion.medium);
    final noteColumn = Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final note in notes) ...[SizedBox(height: space.xs), note],
      ],
    );
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaStateSwitcher(
          stateKey: calibrate,
          sequential: true,
          child: calibrate
              ? Padding(
                  padding: EdgeInsets.only(bottom: space.md),
                  child: const QiblahCalibrationCard(),
                )
              : const SizedBox(width: double.infinity),
        ),
        HudaStateSwitcher(
          stateKey: key,
          sequential: true,
          child: phase == QiblahPhase.compass
              ? QiblahTextSwap(
                  showSecond: aligned,
                  alignment: start
                      ? AlignmentDirectional.topStart
                      : AlignmentDirectional.topCenter,
                  first: Text(
                    l10n.qiblahTurnHint,
                    textAlign: align,
                    style: muted,
                  ),
                  second: Text(
                    l10n.qiblahFacingHint,
                    textAlign: align,
                    style: muted,
                  ),
                )
              : Text(instruction, textAlign: align, style: muted),
        ),
        if (motion == Duration.zero)
          noteColumn
        else
          AnimatedSize(
            duration: motion,
            curve: tokens.motion.standard,
            alignment: Alignment.topCenter,
            child: noteColumn,
          ),
        if (reading != null) ...[
          SizedBox(height: space.sm),
          QiblahLocationLine(
            reading: reading,
            onRefresh: onRefreshLocation,
            refreshing: refreshing,
            retrying: retryingLocation,
          ),
        ],
      ],
    );
  }
}

class _QiblahNote extends StatelessWidget {
  const _QiblahNote({
    required this.icon,
    required this.text,
    this.good = false,
    this.warning = false,
  });

  final IconData icon;
  final String text;
  final bool good;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final large = context.windowClass.width >= WindowWidthClass.expanded;
    final color = warning ? tokens.onChrome : tokens.onChromeMuted;
    return Semantics(
      liveRegion: warning,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: good || warning ? tokens.gilt : tokens.onChromeMuted,
          ),
          SizedBox(width: tokens.space.xs),
          Flexible(
            child: Text(
              text,
              style:
                  (warning
                          ? (large
                                ? theme.textTheme.labelLarge
                                : theme.textTheme.labelMedium)
                          : (large
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodySmall))
                      ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class QiblahLocationLine extends StatelessWidget {
  const QiblahLocationLine({
    super.key,
    required this.reading,
    this.onRefresh,
    this.refreshing = false,
    this.retrying = false,
  });

  final QiblahReading reading;
  final VoidCallback? onRefresh;

  final bool refreshing;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final large = context.windowClass.width >= WindowWidthClass.expanded;
    final style =
        (large ? theme.textTheme.labelLarge : theme.textTheme.labelMedium)
            ?.copyWith(color: tokens.onChromeMuted);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final km = reading.distanceKm;
    final distance = km == null
        ? null
        : NumberFormat.decimalPattern(locale).format(km.round());
    final place = reading.place;

    final Object key;
    final Widget line;
    switch (refreshing ? QiblahFixState.refining : reading.fix) {
      case QiblahFixState.refining:
        key = 'updating';
        line = _status(
          context,
          lead: HudaLampSpinner(size: 18, color: tokens.gilt),
          text: retrying ? l10n.stateRetrying : l10n.qiblahUpdatingLocation,
          style: style,
        );
      case QiblahFixState.stale:
        key = 'stale';
        line = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          spacing: space.xs,
          children: [
            _status(
              context,
              lead: Icon(
                Icons.location_off_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              text: l10n.qiblahLocationStale,
              style: style?.copyWith(color: tokens.onChrome),
            ),
            if (onRefresh != null)
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(l10n.retry),
              ),
          ],
        );
      case QiblahFixState.fresh:
        key = 'fresh';
        final text = distance == null
            ? null
            : place == null
            ? l10n.qiblahDistance(distance)
            : l10n.qiblahPlaceDistance(
                Directionality.of(context) == TextDirection.rtl
                    ? '$place\u200F'
                    : place,
                distance,
              );
        line = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null)
              Flexible(
                child: _status(
                  context,
                  lead: Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: tokens.onChromeMuted,
                  ),
                  text: text,
                  style: style,
                ),
              ),
            if (onRefresh != null)
              IconButton(
                tooltip: l10n.qiblahUpdateLocation,
                onPressed: onRefresh,
                color: tokens.onChromeMuted,
                icon: const Icon(Icons.my_location_rounded, size: 20),
              ),
          ],
        );
    }
    return HudaStateSwitcher(stateKey: key, sequential: true, child: line);
  }

  Widget _status(
    BuildContext context, {
    required Widget lead,
    required String text,
    TextStyle? style,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(top: 1), child: lead),
      SizedBox(width: context.tokens.space.xs),
      Flexible(child: Text(text, style: style)),
    ],
  );
}

String qiblahDegrees(num value, {bool plusMinus = false}) =>
    '\u200E${plusMinus ? '±' : ''}${value.round()}°\u200E';

class QiblahTextSwap extends StatelessWidget {
  const QiblahTextSwap({
    super.key,
    required this.showSecond,
    required this.first,
    required this.second,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final bool showSecond;
  final Widget first;
  final Widget second;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    final motion = context.tokens.motion;
    final duration = motion.of(context, motion.medium);
    Widget layer(Widget child, {required bool shown}) => ExcludeSemantics(
      excluding: !shown,
      child: IgnorePointer(
        ignoring: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: duration,
          curve: shown
              ? const Interval(0.5, 1, curve: Curves.easeOut)
              : const Interval(0, 0.5, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
    return Stack(
      alignment: alignment,
      children: [
        layer(first, shown: !showSecond),
        layer(second, shown: showSecond),
      ],
    );
  }
}

typedef QiblahPartBuilder = Widget Function(bool start);

class QiblahArrangement extends StatelessWidget {
  const QiblahArrangement({
    super.key,
    required this.dial,
    required this.header,
    required this.footer,
    this.calibrating = false,
  });

  final Widget dial;
  final QiblahPartBuilder header;
  final QiblahPartBuilder footer;

  final bool calibrating;

  static double maxDialFor(Size size) => size.shortestSide >= 900 ? 680 : 560;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final size = MediaQuery.sizeOf(context);
    if (fold.separatorAxis == Axis.horizontal) return _tabletop(context, fold);
    final wide = size.width >= 600 && size.width > size.height * 1.1;
    final beside =
        fold.separatorAxis == Axis.vertical ||
        wide ||
        (context.windowClass.isCompactHeight && size.width > size.height);
    if (!beside) return _stacked(context);
    if (fold.separatorAxis == Axis.vertical) {
      return AdaptivePanes(
        twoPaneMinWidth: 0,
        divider: const SizedBox(width: 1),
        primary: _ReadoutPane(header: header, footer: footer),
        secondary: _DialPane(dial: dial),
      );
    }
    return _beside(context);
  }

  Widget _beside(BuildContext context) {
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = space.gutter(box.maxWidth);
        final gap = box.maxWidth >= 840 ? space.giant : space.xxl;
        final maxDial = maxDialFor(MediaQuery.sizeOf(context));
        final readoutWidth = math.min(400.0, box.maxWidth * 0.4);
        final dialSize = math
            .min(
              math.min(box.maxHeight - insets.vertical - space.md * 2, maxDial),
              box.maxWidth -
                  insets.horizontal -
                  gutter * 2 -
                  readoutWidth -
                  gap,
            )
            .clamp(0.0, maxDial)
            .toDouble();
        return Padding(
          padding: EdgeInsets.only(
            left: insets.left + gutter,
            right: insets.right + gutter,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: readoutWidth,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(padding: insets.copyWith(left: 0, right: 0)),
                  child: _ReadoutPane(
                    header: header,
                    footer: footer,
                    sidePadding: false,
                  ),
                ),
              ),
              SizedBox(width: gap),
              Padding(
                padding: EdgeInsets.only(
                  top: insets.top,
                  bottom: insets.bottom,
                ),
                child: SizedBox.square(dimension: dialSize, child: dial),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stacked(BuildContext context) {
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = space.gutter(box.maxWidth);
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, insets.top + space.md, gutter, space.xl),
        );
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final words = (calibrating ? 320.0 : 240.0) * scale;
        final width = box.maxWidth - padding.horizontal;
        final maxDial = maxDialFor(MediaQuery.sizeOf(context));
        final dialSize = math
            .min(width, box.maxHeight - padding.vertical - words)
            .clamp(math.min(width, math.max(200.0, width * 0.65)), maxDial)
            .toDouble();
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, box.maxHeight - padding.vertical),
            ),
            child: Center(
              child: ReadableWidth(
                maxWidth: math.max(maxDial, 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    header(false),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: space.md),
                      child: SizedBox.square(dimension: dialSize, child: dial),
                    ),
                    footer(false),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tabletop(BuildContext context, FoldInfo fold) {
    final data = MediaQuery.of(context);
    final space = context.tokens.space;
    MediaQueryData half({required bool upper, required double height}) =>
        data.copyWith(
          size: Size(data.size.width, height),
          padding: upper
              ? data.padding.copyWith(bottom: 0)
              : data.padding.copyWith(top: 0),
          viewPadding: upper
              ? data.viewPadding.copyWith(bottom: 0)
              : data.viewPadding.copyWith(top: 0),
          displayFeatures: const [],
        );
    final bottomHeight = data.size.height - fold.end;
    return Column(
      children: [
        SizedBox(
          height: fold.start,
          child: MediaQuery(
            data: half(upper: true, height: fold.start),
            child: _DialPane(dial: dial),
          ),
        ),
        SizedBox(height: fold.end - fold.start),
        Expanded(
          child: MediaQuery(
            data: half(upper: false, height: bottomHeight),
            child: Builder(
              builder: (context) => SingleChildScrollView(
                padding: context.scrollPadding(
                  EdgeInsets.fromLTRB(space.xl, space.lg, space.xl, space.xl),
                ),
                child: Center(
                  child: ReadableWidth(
                    maxWidth: 520,
                    child: Column(
                      children: [
                        header(false),
                        SizedBox(height: space.lg),
                        footer(false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialPane extends StatelessWidget {
  const _DialPane({required this.dial});

  final Widget dial;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        insets.left + space.lg,
        insets.top + space.md,
        insets.right + space.lg,
        insets.bottom + space.md,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final side = math.min(
            QiblahArrangement.maxDialFor(MediaQuery.sizeOf(context)),
            math.min(box.maxWidth, box.maxHeight),
          );
          return Center(
            child: SizedBox.square(dimension: math.max(0, side), child: dial),
          );
        },
      ),
    );
  }
}

class _ReadoutPane extends StatelessWidget {
  const _ReadoutPane({
    required this.header,
    required this.footer,
    this.sidePadding = true,
  });

  final QiblahPartBuilder header;
  final QiblahPartBuilder footer;

  final bool sidePadding;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final padding = context.scrollPadding(
          EdgeInsetsDirectional.fromSTEB(
            sidePadding ? space.xxl : 0,
            insets.top + space.md,
            sidePadding ? space.lg : 0,
            space.xl,
          ).resolve(Directionality.of(context)),
        );
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, box.maxHeight - padding.vertical),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header(true),
                    SizedBox(height: space.xl),
                    footer(true),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
