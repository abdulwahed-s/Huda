import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_identity.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

({Prayer prayer, DateTime time})? onboardingNextPrayer(
  PrayerTimesLoaded state,
  DateTime now,
) {
  const prayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];
  for (final prayer in prayers) {
    final time = state.prayerTimes.timeForPrayer(prayer);
    if (time != null && time.isAfter(now)) return (prayer: prayer, time: time);
  }
  final fajr = state.prayerTimes.fajr;
  return fajr == null ? null : (prayer: Prayer.fajr, time: fajr);
}

String? onboardingPlaceName(PrayerTimesLoaded state) {
  if (state.placemarks.isEmpty) return null;
  final place = state.placemarks.first;
  for (final name in [
    place.locality,
    place.subAdministrativeArea,
    place.administrativeArea,
    place.country,
  ]) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
  }
  return null;
}

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      debugPrint('Onboarding location failed: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _useLocation() =>
      _run(context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes);

  Future<void> _searchCity() async {
    if (_working) return;
    try {
      await pickPrayerCity(
        context,
        context.read<PrayerTimesCubit>(),
        onPicked: () {
          if (mounted) setState(() => _working = true);
        },
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scope = OnboardingScope.of(context);
    final onboarding = context.read<OnboardingCubit>();
    final state = context.watch<PrayerTimesCubit>().state;
    final locating = _working || state is PrayerTimesLoading;
    final issue = locating
        ? null
        : prayerLocationIssueOf(
            state,
            canOpenSettings: scope.environment.canOpenSettings,
          );
    final found = !locating && state is PrayerTimesLoaded;

    final searchCity = OnboardingLink(
      key: const ValueKey('onboarding-search-city'),
      label: l10n.prayerSetupSearchCity,
      icon: Icons.search_rounded,
      onPressed: locating ? null : _searchCity,
    );
    final tryAgain = OnboardingLink(
      label: l10n.tryAgain,
      icon: Icons.refresh_rounded,
      onPressed: _useLocation,
    );

    OnboardingLink link(String label, IconData icon, VoidCallback onPressed) =>
        OnboardingLink(label: label, icon: icon, onPressed: onPressed);
    final searchAction = OnboardingAction(
      l10n.prayerSetupSearchCity,
      key: const ValueKey('onboarding-search-city'),
      onPressed: _searchCity,
    );
    final OnboardingAction primary;
    final List<Widget> links;
    if (locating) {
      primary = OnboardingAction(
        l10n.prayerSetupUseMyLocation,
        busyLabel: l10n.setupLocating,
      );
      links = const [];
    } else if (found) {
      primary = OnboardingAction(
        l10n.continueButton,
        advances: true,
        key: const ValueKey('onboarding-location-continue'),
        onPressed: () => onboarding.next(),
      );
      links = [searchCity];
    } else {
      primary = searchAction;
      links = switch (issue) {
        PrayerLocationIssue.denied => [
          link(
            l10n.travelAllowLocation,
            Icons.my_location_rounded,
            _useLocation,
          ),
        ],
        PrayerLocationIssue.blocked => [
          link(
            l10n.openSettings,
            Icons.settings_outlined,
            () => Geolocator.openAppSettings(),
          ),
          tryAgain,
        ],
        PrayerLocationIssue.servicesOff => [
          link(
            l10n.travelTurnOnLocation,
            Icons.location_searching_rounded,
            () => Geolocator.openLocationSettings(),
          ),
          tryAgain,
        ],
        PrayerLocationIssue.unavailable ||
        PrayerLocationIssue.failed => [tryAgain],
        null => [
          OnboardingLink(
            key: const ValueKey('onboarding-use-location'),
            label: l10n.prayerSetupUseMyLocation,
            icon: Icons.my_location_rounded,
            onPressed: _useLocation,
          ),
        ],
      };
    }

    final Widget status;
    if (found) {
      status = _PrayerDay(
        key: const ValueKey('found'),
        state: state,
        place: onboardingPlaceName(state),
      );
    } else if (issue != null) {
      status = OnboardingNotice(
        key: ValueKey(issue),
        problem: true,
        icon: Icons.location_disabled_rounded,
        title: prayerLocationProblemTitle(
          l10n,
          prayerLocationProblemIn(state)!,
        ),
        message: prayerLocationProblemText(
          l10n,
          prayerLocationProblemIn(state)!,
        ),
      );
    } else {
      status = const SizedBox(key: ValueKey('idle'), width: double.infinity);
    }

    return OnboardingStepFrame(
      message: found ? null : l10n.prayerSetupLocationIntro,
      primary: primary,
      quiet: found
          ? null
          : OnboardingAction(
              l10n.setupSkipStep,
              icon: onboardingSkipIcon,
              onPressed: locating ? null : onboarding.skip,
            ),
      children: [
        HudaStateSwitcher(
          stateKey: found ? 'found' : (issue?.name ?? 'idle'),
          child: status,
        ),
        if (found || issue != null) SizedBox(height: space.xs),
        ...links,
      ],
    );
  }
}

class _PrayerDay extends StatelessWidget {
  const _PrayerDay({super.key, required this.state, required this.place});

  final PrayerTimesLoaded state;
  final String? place;

  static const _prayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.jm(locale);
    final next = onboardingNextPrayer(state, DateTime.now())?.prayer;
    final place = this.place;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final times = [
      for (final prayer in _prayers)
        (
          prayer: prayer,
          name: localizedPrayerName(l10n, prayer),
          time: state.prayerTimes.timeForPrayer(prayer),
        ),
    ];
    final tabular = const [FontFeature.tabularFigures()];

    Widget arch(bool lit) => SizedBox(
      width: 22,
      height: 30,
      child: CustomPaint(
        painter: _ArchMarkPainter(
          color: lit ? scheme.primary : scheme.onSurfaceVariant,
          fill: lit ? scheme.primary.withValues(alpha: 0.16) : null,
        ),
      ),
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: scheme.primary, size: 22),
              SizedBox(width: space.xs),
              Expanded(
                child: Text(
                  place ?? l10n.prayerSetupLocationTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          SizedBox(height: space.xxs),
          Text(
            l10n.setupTimesToday,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: space.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final column = (constraints.maxWidth - 4 * space.xs) / 5;
              if (column >= 84 * scale) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < times.length; i++) ...[
                        if (i > 0) SizedBox(width: space.xs),
                        Expanded(
                          child: _PrayerCell(
                            lit: times[i].prayer == next,
                            child: Column(
                              children: [
                                arch(times[i].prayer == next),
                                SizedBox(height: space.xs),
                                Text(
                                  times[i].name,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: times[i].prayer == next
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: space.xxs),
                                Text(
                                  times[i].time == null
                                      ? '–'
                                      : format.format(times[i].time!),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontFeatures: tabular,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < times.length; i++) ...[
                    if (i > 0) SizedBox(height: space.xxs),
                    _PrayerCell(
                      lit: times[i].prayer == next,
                      child: Row(
                        children: [
                          arch(times[i].prayer == next),
                          SizedBox(width: space.sm),
                          Expanded(
                            child: Text(
                              times[i].name,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            times[i].time == null
                                ? '–'
                                : format.format(times[i].time!),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFeatures: tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (next != null) ...[
            SizedBox(height: space.sm),
            Text(
              l10n.setupNextPrayer(localizedPrayerName(l10n, next), () {
                final time = onboardingNextPrayer(state, DateTime.now())?.time;
                return time == null ? '' : format.format(time);
              }()),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({required this.lit, required this.child});

  final bool lit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.xs,
        vertical: tokens.space.sm,
      ),
      decoration: BoxDecoration(
        color: lit
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: dark ? 0.16 : 0.07),
                scheme.surface,
              )
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(
          color: lit ? scheme.primary : scheme.outlineVariant,
          width: lit ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _ArchMarkPainter extends CustomPainter {
  const _ArchMarkPainter({required this.color, this.fill});

  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final (left, right) = OnboardingArcadePainter.archHalves(box);
    final fill = this.fill;
    if (fill != null) {
      canvas.drawPath(
        Path.combine(
          PathOperation.union,
          Path.from(left)
            ..lineTo(box.center.dx, box.bottom)
            ..close(),
          Path.from(right)
            ..lineTo(box.center.dx, box.bottom)
            ..close(),
        ),
        Paint()..color = fill,
      );
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..drawPath(left, paint)
      ..drawPath(right, paint);
  }

  @override
  bool shouldRepaint(_ArchMarkPainter old) =>
      old.color != color || old.fill != fill;
}
