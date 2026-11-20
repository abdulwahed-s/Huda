import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_alerts_ready_card.dart';

List<PrayerReadinessItem> onboardingReliabilityItems(BuildContext context) {
  final scope = OnboardingScope.of(context);
  return buildPrayerReadinessItems(
        l10n: AppLocalizations.of(context)!,
        inputs: currentPrayerReadinessInputs(scope.access.access),
        actions: prayerReadinessActions(context, scope.access),
      )
      .where(
        (item) =>
            item.kind != PrayerReadinessKind.notifications &&
            !PrayerAlertsReadyCard.snoozed(scope.environment.cache, item.kind),
      )
      .toList();
}

class ReliabilityStep extends StatefulWidget {
  const ReliabilityStep({super.key});

  static const answeredKey = 'prayer_setup_reliability_answered';

  @override
  State<ReliabilityStep> createState() => _ReliabilityStepState();
}

class _ReliabilityStepState extends State<ReliabilityStep> {
  final Set<PrayerReadinessKind> _seen = {};
  bool _busy = false;

  Future<void> _run(PrayerReadinessItem item) async {
    final access = OnboardingScope.read(context).access;
    setState(() => _busy = true);
    try {
      await item.action.onPressed();
    } catch (error) {
      debugPrint('Onboarding reliability action failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await access.refresh();
  }

  Future<void> _snooze(PrayerReadinessKind kind) async {
    final cache = OnboardingScope.read(context).environment.cache;
    await PrayerAlertsReadyCard.snooze(cache, kind);
    if (mounted) setState(() {});
  }

  Future<void> _finish(StepOutcome outcome) async {
    final scope = OnboardingScope.read(context);
    final onboarding = context.read<OnboardingCubit>();
    if (scope.environment.isAndroid) {
      await scope.environment.cache.saveData(
        key: ReliabilityStep.answeredKey,
        value: true,
      );
    }
    onboarding.next(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scope = OnboardingScope.of(context);
    return ListenableBuilder(
      listenable: prayerReadinessSources(scope.access),
      builder: (context, _) {
        final pending = onboardingReliabilityItems(context);
        _seen.addAll(pending.map((item) => item.kind));
        if (pending.isEmpty) {
          return OnboardingStepFrame(
            primary: OnboardingAction(
              l10n.continueButton,
              advances: true,
              onPressed: () => _finish(StepOutcome.done),
            ),
            children: [
              HudaStateSwitcher(
                stateKey: 'ready',
                child: OnboardingNotice(
                  icon: Icons.verified_rounded,
                  title: l10n.prayerSetupReliableOn,
                  message: l10n.prayerSetupAlertsHint,
                ),
              ),
            ],
          );
        }
        final item = pending.first;
        final warning = item.warning;
        final current = _seen.length - pending.length + 1;
        return OnboardingStepFrame(
          primary: OnboardingAction(
            item.action.label,
            key: ValueKey('onboarding-reliability-${item.kind.name}'),
            busyLabel: _busy ? item.action.label : null,
            onPressed: () => _run(item),
          ),
          quiet: OnboardingAction(
            l10n.setupSkipStep,
            icon: onboardingSkipIcon,
            onPressed: _busy ? null : () => _snooze(item.kind),
          ),
          children: [
            HudaStateSwitcher(
              stateKey: item.kind,
              child: HudaCard(
                padding: EdgeInsets.all(space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HudaIconMark(item.icon),
                        SizedBox(width: space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_seen.length > 1)
                                HudaEyebrow(
                                  l10n.setupReliableCount(
                                    current,
                                    _seen.length,
                                  ),
                                ),
                              Text(
                                item.title,
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: space.md),
                    Text(
                      item.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (warning != null) ...[
                      SizedBox(height: space.md),
                      OnboardingNotice(
                        problem: true,
                        icon: warning.icon,
                        title: warning.title,
                        message: warning.text,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
