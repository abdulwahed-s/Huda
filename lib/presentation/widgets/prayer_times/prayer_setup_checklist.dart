import 'package:flutter/material.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// The one question before there are times: where is the user? Two equal
/// ways to answer (this device's location, or a city), so a page about
/// prayer times never insists on location. A problem from the last try
/// shows above them with its own fix; alerts are set up after the times
/// (the ready card), never before.
class PrayerPlaceStep extends StatelessWidget {
  const PrayerPlaceStep({
    super.key,
    required this.problem,
    required this.canUseDeviceLocation,
    required this.canOpenSettings,
    required this.onUseLocation,
    required this.onChooseCity,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    this.locating = false,
    this.choosing = false,
  });

  final PrayerLocationProblem? problem;

  /// False where the device has no location at all (Linux): a city only.
  final bool canUseDeviceLocation;
  final bool canOpenSettings;
  final bool locating;
  final bool choosing;
  final Future<void> Function() onUseLocation;
  final Future<void> Function() onChooseCity;
  final Future<void> Function() onOpenAppSettings;
  final Future<void> Function() onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final palette = PrayerPalette.of(context);
    final busy = locating || choosing;
    final problem = this.problem;
    final deviceAction = canUseDeviceLocation
        ? prayerLocationFixAction(
            l10n,
            problem,
            canOpenSettings: canOpenSettings,
            onUseLocation: onUseLocation,
            onOpenAppSettings: onOpenAppSettings,
            onOpenLocationSettings: onOpenLocationSettings,
          )
        : null;
    final city = PrayerSetupAction(
      l10n.prayerChooseCity,
      Icons.search_rounded,
      onChooseCity,
    );

    Widget button(PrayerSetupAction action, {required bool running}) =>
        FilledButton.tonalIcon(
          key: ValueKey('prayer-place-${action.icon.codePoint}'),
          onPressed: busy ? null : action.onPressed,
          icon: running
              ? const HudaLampSpinner(size: 18)
              : Icon(action.icon, size: 20),
          label: Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
        );

    final buttons = [
      if (deviceAction != null) button(deviceAction, running: locating),
      button(city, running: choosing),
    ];

    return Container(
      padding: EdgeInsets.all(tokens.space.md),
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem != null && !busy) ...[
            PrayerSetupWarningNote(
              key: ValueKey('prayer-place-problem-${problem.name}'),
              title: prayerLocationProblemTitle(l10n, problem),
              text: prayerLocationProblemText(l10n, problem),
              icon: Icons.location_disabled_rounded,
            ),
            SizedBox(height: tokens.space.md),
          ],
          // Side by side when both fit at the current text size, else
          // stacked; either way the same weight.
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final sideBySide =
                  buttons.length == 2 && constraints.maxWidth / scale >= 400;
              if (!sideBySide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, b) in buttons.indexed) ...[
                      if (i > 0) SizedBox(height: tokens.space.xs),
                      b,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  SizedBox(width: tokens.space.xs),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The device-location button for [problem]: what fixes it, or "Use my
/// location" when nothing has gone wrong.
PrayerSetupAction prayerLocationFixAction(
  AppLocalizations l10n,
  PrayerLocationProblem? problem, {
  required bool canOpenSettings,
  required Future<void> Function() onUseLocation,
  required Future<void> Function() onOpenAppSettings,
  required Future<void> Function() onOpenLocationSettings,
}) => switch (problem) {
  null => PrayerSetupAction(
    l10n.prayerSetupUseMyLocation,
    Icons.my_location_rounded,
    onUseLocation,
  ),
  PrayerLocationProblem.denied => PrayerSetupAction(
    l10n.travelAllowLocation,
    Icons.my_location_rounded,
    onUseLocation,
  ),
  PrayerLocationProblem.blocked when canOpenSettings => PrayerSetupAction(
    l10n.openSettings,
    Icons.settings_outlined,
    onOpenAppSettings,
  ),
  PrayerLocationProblem.servicesOff when canOpenSettings => PrayerSetupAction(
    l10n.travelTurnOnLocation,
    Icons.location_searching_rounded,
    onOpenLocationSettings,
  ),
  _ => PrayerSetupAction(l10n.tryAgain, Icons.refresh_rounded, onUseLocation),
};

/// A short name for [problem], above its explanation.
String prayerLocationProblemTitle(
  AppLocalizations l10n,
  PrayerLocationProblem problem,
) => switch (problem) {
  PrayerLocationProblem.denied ||
  PrayerLocationProblem.blocked ||
  PrayerLocationProblem.servicesOff ||
  PrayerLocationProblem.noDeviceLocation => l10n.prayerIssueLocationAccess,
  PrayerLocationProblem.noFix => l10n.setupLocationFailedTitle,
  _ => l10n.prayerProblemPlaceTitle,
};

/// What happened and what to do, for [problem]. Never a raw error.
String prayerLocationProblemText(
  AppLocalizations l10n,
  PrayerLocationProblem problem,
) => switch (problem) {
  PrayerLocationProblem.denied => l10n.prayerProblemDenied,
  PrayerLocationProblem.blocked => l10n.prayerProblemBlocked,
  PrayerLocationProblem.servicesOff => l10n.prayerProblemServicesOff,
  PrayerLocationProblem.noDeviceLocation => l10n.prayerProblemNoDeviceLocation,
  PrayerLocationProblem.noFix => l10n.prayerProblemNoFix,
  PrayerLocationProblem.timeZone => l10n.prayerProblemTimeZone,
  PrayerLocationProblem.placeInvalid => l10n.prayerProblemPlaceInvalid,
  PrayerLocationProblem.saveFailed => l10n.prayerProblemSaveFailed,
  PrayerLocationProblem.calculation => l10n.prayerProblemCalculation,
  PrayerLocationProblem.unknown => l10n.prayerProblemUnknown,
};

/// The problem [state] reports, if any.
PrayerLocationProblem? prayerLocationProblemIn(PrayerTimesState state) =>
    state is PrayerTimesNeedsPlace ? state.problem : null;

/// Why the location couldn't be used, grouped by the fix, for onboarding's
/// location and permissions steps.
enum PrayerLocationIssue {
  /// Declined this time: ask again.
  denied,

  /// Declined for good: only Settings can turn it back on.
  blocked,

  /// Location services are off on the device.
  servicesOff,

  /// No location here (Linux), or blocked where no settings page opens.
  unavailable,

  /// The location or the place couldn't be used.
  failed,
}

/// The location issue [state] shows, or null when there is none.
PrayerLocationIssue? prayerLocationIssueOf(
  PrayerTimesState state, {
  required bool canOpenSettings,
}) => switch (prayerLocationProblemIn(state)) {
  null => null,
  PrayerLocationProblem.denied => PrayerLocationIssue.denied,
  PrayerLocationProblem.blocked when canOpenSettings =>
    PrayerLocationIssue.blocked,
  PrayerLocationProblem.servicesOff when canOpenSettings =>
    PrayerLocationIssue.servicesOff,
  PrayerLocationProblem.blocked ||
  PrayerLocationProblem.servicesOff ||
  PrayerLocationProblem.noDeviceLocation => PrayerLocationIssue.unavailable,
  _ => PrayerLocationIssue.failed,
};

class PrayerSetupAction {
  const PrayerSetupAction(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;
}

enum PrayerSetupStepStatus { active, done, skipped, upcoming }

class PrayerSetupStep {
  const PrayerSetupStep({
    required this.icon,
    required this.title,
    required this.status,
    required this.summary,
    required this.message,
    required this.primary,
    this.warning,
    this.links = const [],
  });

  final IconData icon;
  final String title;
  final PrayerSetupStepStatus status;

  final String summary;
  final String message;
  final ({String title, String text, IconData icon})? warning;
  final PrayerSetupAction primary;
  final List<PrayerSetupAction> links;
}

/// Before there are times: the day path with no sun yet (an empty
/// horizon), "Where are you?" and why it matters.
class PrayerSetupHeader extends StatelessWidget {
  const PrayerSetupHeader({
    super.key,
    this.skyHeight = 64,
    this.cityOnly = false,
  });

  /// Taller beside the place step on wide windows.
  final double skyHeight;

  /// The device has no location: the message asks for a city only.
  final bool cityOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    // The living sky at the device's time (no place, no times yet), the
    // question over it and room for the horizon below.
    return PrayerSkyBand(
      skyRoom: skyHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.prayerWhereTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.onChrome,
              ),
            ),
          ),
          SizedBox(height: tokens.space.xxs),
          Text(
            cityOnly ? l10n.prayerWhereMessageCityOnly : l10n.prayerWhereMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.onChromeMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerSetupActiveStep extends StatelessWidget {
  const PrayerSetupActiveStep({
    super.key,
    required this.number,
    required this.total,
    required this.step,
    required this.busy,
    this.heading,
  });

  final int number;
  final int total;
  final PrayerSetupStep step;
  final bool busy;

  /// Replaces "Step n of m" above the title.
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final warning = step.warning;

    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.space.md,
        tokens.space.md,
        tokens.space.md,
        tokens.space.xs,
      ),
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HudaIconMark(step.icon),
              SizedBox(width: tokens.space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HudaEyebrow(
                      heading ?? l10n.prayerSetupStepLabel(number, total),
                    ),
                    Text(
                      step.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space.sm),
          Text(
            step.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
          if (warning != null) ...[
            SizedBox(height: tokens.space.sm),
            PrayerSetupWarningNote(
              title: warning.title,
              text: warning.text,
              icon: warning.icon,
            ),
          ],
          SizedBox(height: tokens.space.md),
          FilledButton.icon(
            key: const ValueKey('prayer-setup-primary'),
            onPressed: busy ? null : step.primary.onPressed,
            icon: busy
                ? const HudaLampSpinner(size: 18)
                : Icon(step.primary.icon, size: 20),
            label: Text(
              step.primary.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          if (step.links.isNotEmpty) ...[
            SizedBox(height: tokens.space.xxs),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final link in step.links)
                  TextButton.icon(
                    onPressed: busy ? null : link.onPressed,
                    icon: Icon(link.icon, size: 18),
                    label: Text(link.label),
                  ),
              ],
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class PrayerSetupWarningNote extends StatelessWidget {
  const PrayerSetupWarningNote({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
    this.tone = PrayerAttentionTone.warning,
  });

  final String title;
  final String text;

  /// Kept for callers; the lamp's station carries the tone now.
  final IconData icon;
  final PrayerAttentionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    // The same voice as the page's notices: a lamp with a piece of the day
    // path, then what happened. No tinted box.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrayerNoticeLamp(tone: tone, size: 36),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: space.xxs / 2),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
