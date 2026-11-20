import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';

class PrivacyStep extends StatefulWidget {
  const PrivacyStep({super.key});

  @override
  State<PrivacyStep> createState() => _PrivacyStepState();
}

class _PrivacyStepState extends State<PrivacyStep> {
  bool? _saving;

  Future<void> _answer(bool allow) async {
    final environment = OnboardingScope.read(context).environment;
    final onboarding = context.read<OnboardingCubit>();
    setState(() => _saving = allow);
    try {
      await environment.setCrashConsent(allow);
    } catch (error) {
      debugPrint('Onboarding crash consent not saved: $error');
    }
    if (!mounted) return;
    setState(() => _saving = null);
    onboarding.next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saving = _saving;
    return OnboardingStepFrame(
      message: l10n.crashReportingConsentDescription,
      primary: OnboardingAction(
        l10n.crashReportingConsentAllow,
        key: const ValueKey('onboarding-privacy-allow'),
        busyLabel: saving == true ? l10n.prayerAlertSaving : null,
        onPressed: saving == null ? () => _answer(true) : null,
      ),
      quiet: OnboardingAction(
        l10n.crashReportingConsentDecline,
        icon: Icons.close_rounded,
        key: const ValueKey('onboarding-privacy-decline'),
        onPressed: saving == null ? () => _answer(false) : null,
      ),
      children: [
        HudaCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HudaIconMark(Icons.data_object_rounded),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.crashReportingSharedDataTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: space.xxs),
                    Text(
                      l10n.crashReportingSharedDataDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: space.xs),
            Expanded(
              child: Text(
                l10n.crashReportingPrivacyNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
