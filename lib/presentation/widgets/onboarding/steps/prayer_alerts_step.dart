import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_identity.dart';
import 'package:huda/presentation/widgets/onboarding/steps/location_step.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';

/// Step 6: the call to prayer. A preview shows the alert as it will
/// arrive (the next prayer, its time, the adhan's words). Notifications are
/// asked for on the permissions step, not here:
/// - allowed: the adhan voice can be chosen; Continue answers the step;
/// - refused: what that means, the fix as a link ("Try again", or "Open
///   settings" when only Settings can turn them on), and "Continue without
///   alerts";
/// - put off ("Not now" there): Continue, and the Prayer screen asks later.
/// Granting or continuing without writes the key the Prayer screen reads,
/// so it doesn't ask again.
class PrayerAlertsStep extends StatefulWidget {
  const PrayerAlertsStep({super.key});

  static const answeredKey = 'prayer_setup_alerts_answered';

  @override
  State<PrayerAlertsStep> createState() => _PrayerAlertsStepState();
}

class _PrayerAlertsStepState extends State<PrayerAlertsStep> {
  bool _requesting = false;
  bool _declined = false;

  Future<void> _allow() async {
    final access = OnboardingScope.read(context).access;
    setState(() => _requesting = true);
    try {
      await access.ready;
      if (!mounted) return;
      await access.requestNotifications(context, explain: false);
    } catch (error) {
      debugPrint('Onboarding alerts request failed: $error');
    }
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _declined = !(access.access?.notificationsEnabled ?? false);
    });
    if (!_declined) HudaHaptics.light(context);
  }

  Future<void> _answer(StepOutcome outcome) async {
    final scope = OnboardingScope.read(context);
    final onboarding = context.read<OnboardingCubit>();
    await scope.environment.cache.saveData(
      key: PrayerAlertsStep.answeredKey,
      value: true,
    );
    onboarding.next(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scope = OnboardingScope.of(context);
    final onboarding = context.read<OnboardingCubit>();
    return ListenableBuilder(
      listenable: scope.access,
      builder: (context, _) {
        final access = scope.access.access;
        final granted = access?.notificationsEnabled ?? false;
        final needsSettings =
            (access?.notificationNeedsSettings ?? false) &&
            scope.environment.canOpenSettings;
        final declined =
            !granted &&
            (_declined || needsSettings || scope.sheet.notificationsDeclined);

        final OnboardingAction primary;
        final OnboardingAction? quiet;
        final Widget status;
        if (granted) {
          primary = OnboardingAction(
            l10n.continueButton,
            advances: true,
            key: const ValueKey('onboarding-alerts-continue'),
            onPressed: () async {
              // Saves a style picked a moment ago before moving on.
              await scope.environment.alerts?.call().flush();
              await _answer(StepOutcome.done);
            },
          );
          quiet = null;
          status = Column(
            key: const ValueKey('granted'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // The choice first (it's the step's one choice, in view on
            // every screen), then the alert as it will arrive.
            children: [
              if (scope.environment.alerts != null) ...[
                _AlertStyleChoice(controller: scope.environment.alerts!()),
                SizedBox(height: space.md),
              ],
              const _AdhanPreview(on: true),
              SizedBox(height: space.sm),
              Text(
                l10n.setupAdhanVoiceLater,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        } else if (declined) {
          // The one way on is lit; the fix is a link in the notice.
          primary = OnboardingAction(
            l10n.prayerSetupContinueWithoutAlerts,
            key: const ValueKey('onboarding-alerts-without'),
            onPressed: () => _answer(StepOutcome.skipped),
          );
          quiet = null;
          status = OnboardingNotice(
            key: const ValueKey('declined'),
            problem: true,
            icon: Icons.notifications_off_outlined,
            title: l10n.prayerNotificationsOffTitle,
            message: needsSettings
                ? l10n.prayerReadyNotificationsBlocked
                : l10n.prayerSetupAlertsDeclined,
            trailing: _requesting
                ? null
                : needsSettings
                ? OnboardingLink(
                    label: l10n.openSettings,
                    icon: Icons.settings_outlined,
                    onPressed: scope.access.openNotificationSettings,
                  )
                : OnboardingLink(
                    label: l10n.tryAgain,
                    icon: Icons.refresh_rounded,
                    onPressed: _allow,
                  ),
          );
        } else {
          // Put off on the permissions step: nothing is asked here.
          primary = OnboardingAction(
            l10n.continueButton,
            advances: true,
            key: const ValueKey('onboarding-alerts-later'),
            onPressed: () => onboarding.next(StepOutcome.skipped),
          );
          quiet = null;
          status = Column(
            key: const ValueKey('pending'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AdhanPreview(on: false),
              SizedBox(height: space.sm),
              // Off: the one place to turn them on is the permissions
              // step, a tap back.
              OnboardingNotice(
                icon: Icons.notifications_off_outlined,
                title: l10n.setupAlertsOff,
                message: l10n.prayerSetupAlertsDeclined,
                trailing: OnboardingLink(
                  key: const ValueKey('onboarding-alerts-permissions'),
                  label: l10n.setupAllowNotifications,
                  icon: Icons.notifications_active_outlined,
                  onPressed: () => onboarding.goTo(OnboardingStep.permissions),
                ),
              ),
            ],
          );
        }
        return OnboardingStepFrame(
          message: granted
              ? l10n.setupAdhanMessage
              : l10n.prayerSetupAlertsIntro,
          primary: primary,
          quiet: quiet,
          children: [
            HudaStateSwitcher(
              stateKey: granted
                  ? 'granted'
                  : declined
                  ? 'declined'
                  : 'pending',
              child: status,
            ),
          ],
        );
      },
    );
  }
}

/// The alert as it will arrive: Huda's mark, the next prayer and its
/// time, and the words the adhan alert carries. Its mark is unlit, with a
/// muted bell, while alerts aren't on.
class _AdhanPreview extends StatelessWidget {
  const _AdhanPreview({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prayer = context.watch<PrayerTimesCubit>().state;
    final next = prayer is PrayerTimesLoaded
        ? onboardingNextPrayer(prayer, DateTime.now())
        : null;
    final name = localizedPrayerName(l10n, next?.prayer ?? Prayer.dhuhr);
    final time = next == null
        ? null
        : DateFormat.jm(
            Localizations.localeOf(context).toString(),
          ).format(next.time);
    final card = Container(
      padding: EdgeInsets.all(space.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lit while alerts are on; an unlit mark with a muted bell when
          // they aren't. The words keep their contrast either way.
          on
              ? HudaLamp(
                  size: 40,
                  child: Padding(
                    padding: EdgeInsets.all(space.xs),
                    child: OnboardingLogo(color: tokens.gilt),
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      l10n.setupNow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: space.xxs),
                Text(
                  time == null ? name : '$name · $time',
                  style: theme.textTheme.titleSmall,
                ),
                SizedBox(height: space.xxs),
                Text(
                  l10n.notificationPrayerTimeBody(name),
                  // One line on phones, so the choices below stay in view.
                  maxLines: MediaQuery.sizeOf(context).width < 600 ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: l10n.prayerSetupAlertsHint,
      child: ExcludeSemantics(child: card),
    );
  }
}

/// How each prayer alerts, offered simply: the styles this device can use
/// (a notification, a short adhan, the full adhan; an alarm on iOS, a quiet
/// moment on desktops), one tap each. It edits Prayer's own alert settings
/// (the controller its sheet uses), so nothing is set twice; the voice,
/// volume and per-prayer choices stay in Prayer's settings.
class _AlertStyleChoice extends StatefulWidget {
  const _AlertStyleChoice({required this.controller});

  final PrayerAlertController<Object?> controller;

  @override
  State<_AlertStyleChoice> createState() => _AlertStyleChoiceState();
}

class _AlertStyleChoiceState extends State<_AlertStyleChoice> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final settings = controller.settings;
        final capabilities = controller.capabilities;
        if (settings == null || capabilities == null) {
          // Still reading the saved settings.
          return const SizedBox(
            height: 56,
            child: Center(child: HudaLampSpinner(size: 20)),
          );
        }
        final styles = [
          for (final style in capabilities.styles)
            if (style != PrayerAlertStyle.off &&
                !capabilities.unavailable.containsKey(style))
              style,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HudaEyebrow(l10n.setupAlertStyleLabel, header: true),
            SizedBox(height: space.sm),
            // Side by side as tiles (a mark and a name), so the chosen
            // one is in view even on small phones; what it does is said
            // once under them. One per row at large text.
            OnboardingOptionGrid(
              minTileWidth: 96,
              maxColumns: styles.length,
              columnChoices: [1, styles.length],
              children: [
                for (final style in styles)
                  OnboardingOption(
                    key: ValueKey('onboarding-alert-style-${style.name}'),
                    title: l10n.alertStyleOn(style, capabilities),
                    selected: settings.style == style,
                    previewWidth: 56,
                    preview: _StyleMark(
                      icon: prayerAlertStyleIcon(style),
                      selected: settings.style == style,
                    ),
                    onTap: () => controller.edit(SetPrayerAlertStyle(style)),
                  ),
              ],
            ),
            SizedBox(height: space.sm),
            HudaStateSwitcher(
              stateKey: settings.style,
              child: Text(
                l10n.alertStyleHintOn(settings.style, capabilities),
                key: ValueKey(settings.style),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: space.xs),
            if (controller.saveState == PrayerAlertSaveState.failed)
              OnboardingNotice(
                problem: true,
                message: l10n.setupAlertSaveFailed,
                trailing: OnboardingLink(
                  label: l10n.tryAgain,
                  icon: Icons.refresh_rounded,
                  onPressed: controller.retry,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A style's mark on a soft plate, lit with the primary when chosen.
class _StyleMark extends StatelessWidget {
  const _StyleMark({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: AnimatedContainer(
          duration: tokens.motion.of(context, tokens.motion.short),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radius.sm),
          ),
          // The mark at the start, clear of the tile's radio at the end.
          padding: EdgeInsetsDirectional.only(start: tokens.space.sm),
          alignment: AlignmentDirectional.centerStart,
          child: Icon(
            icon,
            size: 28,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
