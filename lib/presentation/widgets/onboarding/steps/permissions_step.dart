import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/onboarding/steps/location_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/prayer_alerts_step.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';

enum OnboardingPermissionStatus { notAsked, working, allowed, problem }

class PermissionsStep extends StatefulWidget {
  const PermissionsStep({super.key});

  @override
  State<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends State<PermissionsStep> {
  bool _locating = false;
  bool _requesting = false;
  bool _declined = false;

  Future<void> _askLocation() async {
    if (_locating) return;
    final prayer = context.read<PrayerTimesCubit>();
    setState(() => _locating = true);
    try {
      await prayer.refreshLocationAndPrayerTimes();
    } catch (error) {
      debugPrint('Onboarding location failed: $error');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _askNotifications() async {
    final scope = OnboardingScope.read(context);
    final access = scope.access;
    setState(() => _requesting = true);
    try {
      await access.ready;
      if (!mounted) return;
      await access.requestNotifications(context, explain: false);
    } catch (error) {
      debugPrint('Onboarding notifications request failed: $error');
    }
    if (!mounted) return;
    final granted = access.access?.notificationsEnabled ?? false;
    setState(() {
      _requesting = false;
      _declined = !granted;
    });
    scope.sheet.notificationsDeclined = !granted;
    if (granted) {
      HudaHaptics.light(context);
      await scope.environment.cache.saveData(
        key: PrayerAlertsStep.answeredKey,
        value: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scope = OnboardingScope.of(context);
    final onboarding = context.read<OnboardingCubit>();
    final prayer = context.watch<PrayerTimesCubit>().state;
    return ListenableBuilder(
      listenable: scope.access,
      builder: (context, _) {
        final locating = _locating || prayer is PrayerTimesLoading;
        final issue = locating
            ? null
            : prayerLocationIssueOf(
                prayer,
                canOpenSettings: scope.environment.canOpenSettings,
              );
        final found = !locating && prayer is PrayerTimesLoaded;
        final OnboardingPermissionStatus locationStatus;
        final String locationDetail;
        OnboardingAction? locationFix;
        if (locating) {
          locationStatus = OnboardingPermissionStatus.working;
          locationDetail = l10n.setupLocating;
        } else if (found) {
          locationStatus = OnboardingPermissionStatus.allowed;
          final place = onboardingPlaceName(prayer);
          locationDetail = place == null
              ? l10n.setupPermissionAllowed
              : '${l10n.setupPermissionAllowed} · $place';
        } else if (issue != null) {
          locationStatus = OnboardingPermissionStatus.problem;
          switch (issue) {
            case PrayerLocationIssue.denied:
              locationDetail = l10n.setupPermissionNotAllowed;
              locationFix = OnboardingAction(
                l10n.tryAgain,
                onPressed: _askLocation,
              );
            case PrayerLocationIssue.blocked:
              locationDetail = l10n.setupPermissionNotAllowed;
              locationFix = OnboardingAction(
                l10n.openSettings,
                onPressed: () => Geolocator.openAppSettings(),
              );
            case PrayerLocationIssue.servicesOff:
              locationDetail = l10n.prayerSetupLocationServicesOff;
              locationFix = OnboardingAction(
                l10n.travelTurnOnLocation,
                onPressed: () => Geolocator.openLocationSettings(),
              );
            case PrayerLocationIssue.unavailable:
              locationDetail =
                  prayerLocationProblemIn(prayer) ==
                      PrayerLocationProblem.noDeviceLocation
                  ? l10n.prayerProblemNoDeviceLocation
                  : l10n.setupPermissionNotAllowed;
            case PrayerLocationIssue.failed:
              locationDetail = prayerLocationProblemTitle(
                l10n,
                prayerLocationProblemIn(prayer)!,
              );
              locationFix = OnboardingAction(
                l10n.tryAgain,
                onPressed: _askLocation,
              );
          }
        } else {
          locationStatus = OnboardingPermissionStatus.notAsked;
          locationDetail = l10n.setupPermissionNotAsked;
        }

        final access = scope.access.access;
        final granted = access?.notificationsEnabled ?? false;
        final needsSettings =
            (access?.notificationNeedsSettings ?? false) &&
            scope.environment.canOpenSettings;
        final OnboardingPermissionStatus alertsStatus;
        final String alertsDetail;
        OnboardingAction? alertsFix;
        if (_requesting) {
          alertsStatus = OnboardingPermissionStatus.working;
          alertsDetail = l10n.setupPermissionAsking;
        } else if (granted) {
          alertsStatus = OnboardingPermissionStatus.allowed;
          alertsDetail = l10n.setupPermissionAllowed;
        } else if (needsSettings || _declined) {
          alertsStatus = OnboardingPermissionStatus.problem;
          alertsDetail = l10n.setupPermissionNotAllowed;
          alertsFix = needsSettings
              ? OnboardingAction(
                  l10n.openSettings,
                  onPressed: scope.access.openNotificationSettings,
                )
              : OnboardingAction(l10n.tryAgain, onPressed: _askNotifications);
        } else {
          alertsStatus = OnboardingPermissionStatus.notAsked;
          alertsDetail = l10n.setupPermissionNotAsked;
        }

        final answered =
            locationStatus != OnboardingPermissionStatus.notAsked ||
            alertsStatus != OnboardingPermissionStatus.notAsked;
        final OnboardingAction primary;
        if (locationStatus == OnboardingPermissionStatus.notAsked) {
          primary = OnboardingAction(
            l10n.travelAllowLocation,
            key: const ValueKey('onboarding-allow-location'),
            onPressed: _askLocation,
          );
        } else if (locating) {
          primary = OnboardingAction(
            l10n.travelAllowLocation,
            busyLabel: l10n.setupLocating,
          );
        } else if (alertsStatus == OnboardingPermissionStatus.notAsked ||
            _requesting) {
          primary = OnboardingAction(
            l10n.setupAllowNotifications,
            key: const ValueKey('onboarding-allow-notifications'),
            busyLabel: _requesting ? l10n.setupPermissionAsking : null,
            onPressed: _askNotifications,
          );
        } else {
          primary = OnboardingAction(
            l10n.continueButton,
            advances: true,
            key: const ValueKey('onboarding-permissions-continue'),
            onPressed: () => onboarding.next(),
          );
        }
        final continuing =
            primary.key == const ValueKey('onboarding-permissions-continue');

        return OnboardingStepFrame(
          message: l10n.setupPermissionsMessage,
          primary: primary,
          quiet: continuing
              ? null
              : OnboardingAction(
                  l10n.setupSkipStep,
                  icon: onboardingSkipIcon,
                  key: const ValueKey('onboarding-permissions-later'),
                  onPressed: locating || _requesting
                      ? null
                      : () => onboarding.next(
                          answered ? StepOutcome.done : StepOutcome.skipped,
                        ),
                ),
          children: [
            OnboardingPermissionCard(
              key: const ValueKey('onboarding-permission-location'),
              icon: Icons.location_on_outlined,
              title: l10n.location,
              why: l10n.setupPermissionLocationWhy,
              status: locationStatus,
              detail: locationDetail,
              fix: locationFix,
            ),
            SizedBox(height: space.sm),
            OnboardingPermissionCard(
              key: const ValueKey('onboarding-permission-notifications'),
              icon: Icons.notifications_active_outlined,
              title: l10n.notifications,
              why: l10n.setupPermissionNotificationsWhy,
              status: alertsStatus,
              detail: alertsDetail,
              fix: alertsFix,
            ),
          ],
        );
      },
    );
  }
}

class OnboardingPermissionCard extends StatelessWidget {
  const OnboardingPermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.why,
    required this.status,
    required this.detail,
    this.fix,
  });

  final IconData icon;
  final String title;
  final String why;
  final OnboardingPermissionStatus status;
  final String detail;
  final OnboardingAction? fix;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final problem = status == OnboardingPermissionStatus.problem;
    final allowed = status == OnboardingPermissionStatus.allowed;
    Color tint(Color color, double light, double night) => Color.alphaBlend(
      color.withValues(alpha: dark ? night : light),
      scheme.surface,
    );
    final fix = this.fix;

    final Widget mark = problem
        ? Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint(scheme.error, 0.12, 0.22),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: scheme.error),
          )
        : HudaLamp(
            size: 48,
            child: Icon(
              allowed ? Icons.check_rounded : icon,
              size: 24,
              color: tokens.gilt,
            ),
          );

    final Color statusColor = switch (status) {
      OnboardingPermissionStatus.allowed => scheme.primary,
      OnboardingPermissionStatus.problem => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    final Widget statusMark = switch (status) {
      OnboardingPermissionStatus.working => HudaLampSpinner(
        size: MediaQuery.textScalerOf(context).scale(14),
      ),
      OnboardingPermissionStatus.allowed => Icon(
        Icons.check_circle_rounded,
        size: 18,
        color: statusColor,
      ),
      OnboardingPermissionStatus.problem => Icon(
        Icons.block_rounded,
        size: 18,
        color: statusColor,
      ),
      OnboardingPermissionStatus.notAsked => Icon(
        Icons.remove_rounded,
        size: 18,
        color: statusColor,
      ),
    };

    return Semantics(
      container: true,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.medium),
        decoration: BoxDecoration(
          color: problem
              ? tint(scheme.error, 0.04, 0.08)
              : allowed
              ? tint(scheme.primary, 0.05, 0.1)
              : scheme.surface,
          borderRadius: tokens.radius.card,
          border: Border.all(
            color: problem
                ? tint(scheme.error, 0.24, 0.32)
                : allowed
                ? scheme.primary.withValues(alpha: 0.4)
                : scheme.outline,
          ),
        ),
        padding: EdgeInsets.all(space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: mark),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  SizedBox(height: space.xxs),
                  Text(
                    why,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: space.sm),
                  HudaStateSwitcher(
                    stateKey: '$status$detail',
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          statusMark,
                          SizedBox(width: space.xs),
                          Expanded(
                            child: Text(
                              detail,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (fix != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: fix.onPressed,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.symmetric(horizontal: space.xs),
                        ),
                        child: Text(fix.label),
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
