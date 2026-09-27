import 'package:flutter/material.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

enum PrayerSetupAlerts {
  pending,

  declined,
  granted,

  skipped,
}

enum PrayerSetupReliability { pending, done, skipped }

class PrayerSetupChecklist extends StatelessWidget {
  const PrayerSetupChecklist({
    super.key,
    required this.state,
    required this.alerts,
    required this.alertsNeedSettings,
    required this.reliability,
    required this.canOpenSettings,
    required this.onAllowAlerts,
    required this.onOpenAlertSettings,
    required this.onContinueWithoutAlerts,
    required this.onAllowReliability,
    required this.onUseExactAlarms,
    required this.onSkipReliability,
    required this.onUseLocation,
    required this.onSearchCity,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    this.busy = false,
  });

  final PrayerTimesState state;
  final PrayerSetupAlerts alerts;

  final bool alertsNeedSettings;

  final PrayerSetupReliability? reliability;

  final bool canOpenSettings;

  final bool busy;
  final Future<void> Function() onAllowAlerts;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onContinueWithoutAlerts;
  final Future<void> Function() onAllowReliability;
  final Future<void> Function() onUseExactAlarms;
  final Future<void> Function() onSkipReliability;
  final Future<void> Function() onUseLocation;
  final Future<void> Function() onSearchCity;
  final Future<void> Function() onOpenAppSettings;
  final Future<void> Function() onOpenLocationSettings;

  bool get _alertsOpen =>
      alerts == PrayerSetupAlerts.pending ||
      alerts == PrayerSetupAlerts.declined;
  bool get _reliabilityOpen =>
      !_alertsOpen && reliability == PrayerSetupReliability.pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = <_Step>[
      _alertsStep(l10n),
      if (reliability != null) _reliabilityStep(l10n),
      _locationStep(l10n),
    ];
    final current = steps.indexWhere((step) => step.status == _Status.active);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SetupHeader(),
        const SizedBox(height: 20),
        _SetupProgress(current: current, steps: steps),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: _StepCard(
              key: ValueKey('${steps[i].title}-${steps[i].status}'),
              number: i + 1,
              total: steps.length,
              step: steps[i],
              busy: busy,
            ),
          ),
          if (i < steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  _Step _alertsStep(AppLocalizations l10n) {
    final declined = alerts == PrayerSetupAlerts.declined;
    return _Step(
      icon: Icons.notifications_active_rounded,
      title: l10n.prayerSetupAlertsTitle,
      status: switch (alerts) {
        PrayerSetupAlerts.pending ||
        PrayerSetupAlerts.declined => _Status.active,
        PrayerSetupAlerts.granted => _Status.done,
        PrayerSetupAlerts.skipped => _Status.skipped,
      },
      summary: switch (alerts) {
        PrayerSetupAlerts.granted => l10n.prayerSetupAlertsOn,
        PrayerSetupAlerts.skipped => l10n.prayerSetupAlertsSkipped,
        _ => l10n.prayerSetupAlertsHint,
      },
      message: l10n.prayerSetupAlertsIntro,
      warning: declined
          ? (
              title: l10n.prayerNotificationsOffTitle,
              text: l10n.prayerSetupAlertsDeclined,
              icon: Icons.notifications_off_outlined,
            )
          : null,
      primary: declined && alertsNeedSettings && canOpenSettings
          ? _Action(
              l10n.openSettings,
              Icons.settings_outlined,
              onOpenAlertSettings,
            )
          : _Action(
              declined ? l10n.tryAgain : l10n.prayerSetupAlertsAllow,
              Icons.notifications_active_outlined,
              onAllowAlerts,
            ),
      links: [
        if (declined)
          _Action(
            l10n.prayerSetupContinueWithoutAlerts,
            Icons.arrow_forward_rounded,
            onContinueWithoutAlerts,
          ),
      ],
    );
  }

  _Step _reliabilityStep(AppLocalizations l10n) => _Step(
    icon: Icons.battery_charging_full_rounded,
    title: l10n.prayerSetupReliableTitle,
    status: _alertsOpen
        ? _Status.upcoming
        : switch (reliability!) {
            PrayerSetupReliability.pending => _Status.active,
            PrayerSetupReliability.done => _Status.done,
            PrayerSetupReliability.skipped => _Status.skipped,
          },
    summary: switch (reliability!) {
      PrayerSetupReliability.done => l10n.prayerSetupReliableOn,
      PrayerSetupReliability.skipped when !_alertsOpen =>
        l10n.prayerSetupSkipped,
      _ => l10n.prayerSetupReliableHint,
    },
    message: l10n.prayerSetupReliableIntro,
    primary: _Action(
      l10n.keepRemindersReliable,
      Icons.battery_saver_outlined,
      onAllowReliability,
    ),
    links: [
      _Action(l10n.exactAlarmTitle, Icons.alarm_on_outlined, onUseExactAlarms),
      _Action(
        l10n.prayerSetupSkip,
        Icons.arrow_forward_rounded,
        onSkipReliability,
      ),
    ],
  );

  _Step _locationStep(AppLocalizations l10n) {
    final open = !_alertsOpen && !_reliabilityOpen;
    final useLocation = _Action(
      l10n.prayerSetupUseMyLocation,
      Icons.my_location_rounded,
      onUseLocation,
    );
    final tryAgain = _Action(
      l10n.tryAgain,
      Icons.refresh_rounded,
      onUseLocation,
    );
    final searchCity = _Action(
      l10n.prayerSetupSearchCity,
      Icons.search_rounded,
      onSearchCity,
    );
    ({String title, String text, IconData icon}) problem(String text) => (
      title: l10n.prayerIssueLocationAccess,
      text: text,
      icon: Icons.location_disabled_rounded,
    );

    final ({
      ({String title, String text, IconData icon})? warning,
      _Action primary,
      List<_Action> links,
    })
    view = switch (state) {
      PrayerTimesLocationDenied() => (
        warning: problem(l10n.prayerSetupLocationDeclined),
        primary: _Action(
          l10n.travelAllowLocation,
          Icons.location_on_outlined,
          onUseLocation,
        ),
        links: [searchCity],
      ),
      PrayerTimesLocationPermanentlyDenied() when canOpenSettings => (
        warning: problem(l10n.prayerSetupLocationBlocked),
        primary: _Action(
          l10n.openSettings,
          Icons.settings_outlined,
          onOpenAppSettings,
        ),
        links: [searchCity, tryAgain],
      ),
      PrayerTimesLocationServiceDisabled() when canOpenSettings => (
        warning: problem(l10n.prayerSetupLocationServicesOff),
        primary: _Action(
          l10n.travelTurnOnLocation,
          Icons.location_on_outlined,
          onOpenLocationSettings,
        ),
        links: [searchCity, tryAgain],
      ),
      PrayerTimesLocationPermanentlyDenied() ||
      PrayerTimesLocationServiceDisabled() => (
        warning: problem(l10n.prayerSetupLocationFailed),
        primary: searchCity,
        links: [tryAgain],
      ),
      PrayerTimesError() => (
        warning: problem(l10n.prayerSetupLocationFailed),
        primary: tryAgain,
        links: [searchCity],
      ),
      _ => (warning: null, primary: useLocation, links: [searchCity]),
    };

    return _Step(
      icon: Icons.location_on_rounded,
      title: l10n.prayerSetupLocationTitle,
      status: open ? _Status.active : _Status.upcoming,
      summary: l10n.prayerSetupLocationHint,
      message: l10n.prayerSetupLocationIntro,
      warning: view.warning,
      primary: view.primary,
      links: view.links,
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;
}

enum _Status { active, done, skipped, upcoming }

class _Step {
  const _Step({
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
  final _Status status;

  final String summary;
  final String message;
  final ({String title, String text, IconData icon})? warning;
  final _Action primary;
  final List<_Action> links;
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    return Column(
      children: [
        SizedBox(
          width: 148,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PrayerStarPainter(color: palette.tintStrong),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.heroStart, palette.heroEnd],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.prayerSetupTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.prayerSetupSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupProgress extends StatelessWidget {
  const _SetupProgress({required this.current, required this.steps});

  final int current;
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final shown = current < 0 ? steps.length : current + 1;
    return Semantics(
      label: l10n.prayerSetupStepLabel(shown, steps.length),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: switch (steps[i].status) {
                    _Status.done => palette.primary,
                    _Status.skipped => palette.warning.withValues(alpha: 0.7),
                    _Status.active => palette.primary.withValues(alpha: 0.45),
                    _Status.upcoming => palette.tintStrong,
                  },
                ),
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.number,
    required this.total,
    required this.step,
    required this.busy,
  });

  final int number;
  final int total;
  final _Step step;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.prayerSetupStepLabel(number, total),
      child: step.status == _Status.active
          ? _ActiveStep(number: number, total: total, step: step, busy: busy)
          : _CollapsedStep(number: number, step: step),
    );
  }
}

class _CollapsedStep extends StatelessWidget {
  const _CollapsedStep({required this.number, required this.step});

  final int number;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final upcoming = step.status == _Status.upcoming;
    final (badgeColor, badgeFill) = switch (step.status) {
      _Status.done => (
        palette.success,
        palette.success.withValues(alpha: 0.14),
      ),
      _Status.skipped => (
        palette.warning,
        palette.warning.withValues(alpha: 0.14),
      ),
      _ => (palette.faint, palette.tint),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: palette.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: badgeFill),
            alignment: Alignment.center,
            child: switch (step.status) {
              _Status.done => Icon(
                Icons.check_rounded,
                size: 19,
                color: badgeColor,
              ),
              _Status.skipped => Icon(
                Icons.remove_rounded,
                size: 19,
                color: badgeColor,
              ),
              _ => Text(
                '$number',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: upcoming ? palette.muted : palette.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  step.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: step.status == _Status.skipped
                        ? palette.warning
                        : palette.faint,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            step.icon,
            size: 20,
            color: upcoming ? palette.faint : badgeColor,
          ),
        ],
      ),
    );
  }
}

class _ActiveStep extends StatelessWidget {
  const _ActiveStep({
    required this.number,
    required this.total,
    required this.step,
    required this.busy,
  });

  final int number;
  final int total;
  final _Step step;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final warning = step.warning;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.primary.withValues(alpha: palette.isDark ? 0.6 : 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(step.icon, color: palette.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prayerSetupStepLabel(number, total),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      step.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              height: 1.5,
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            _WarningNote(
              title: warning.title,
              text: warning.text,
              icon: warning.icon,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('prayer-setup-primary'),
            onPressed: busy ? null : step.primary.onPressed,
            icon: busy
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onPrimary,
                    ),
                  )
                : Icon(step.primary.icon, size: 20),
            label: Text(
              step.primary.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              disabledBackgroundColor: palette.primary.withValues(alpha: 0.55),
              disabledForegroundColor: palette.onPrimary,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (step.links.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final link in step.links)
                  TextButton.icon(
                    onPressed: busy ? null : link.onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primary,
                    ),
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

class _WarningNote extends StatelessWidget {
  const _WarningNote({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final color = palette.warning;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.ink.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
