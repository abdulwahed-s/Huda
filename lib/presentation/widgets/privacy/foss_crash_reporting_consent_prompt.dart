import 'package:flutter/material.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/core/services/crash_reporting_consent.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';

abstract final class FossCrashReportingConsentPrompt {
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (!CrashReportingConsent.requiresExplicitConsent ||
        await CrashReportingConsent.getDecision() != null ||
        !context.mounted) {
      return false;
    }

    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const CrashReportingConsentDialog(),
    );

    await CrashReporter.setFossConsent(allowed == true);
    return true;
  }
}

class CrashReportingConsentDialog extends StatelessWidget {
  const CrashReportingConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    space.lg,
                    space.lg,
                    space.lg,
                    space.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: HudaLamp(
                          size: 56,
                          child: Icon(Icons.shield_outlined),
                        ),
                      ),
                      SizedBox(height: space.md),
                      Text(
                        l10n.crashReportingConsentTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      SizedBox(height: space.xs),
                      Text(
                        l10n.crashReportingConsentDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: space.lg),
                      Container(
                        padding: EdgeInsets.all(space.md),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(tokens.radius.md),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: MergeSemantics(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.data_object_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                              SizedBox(width: space.sm),
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: space.md),
                      MergeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                            SizedBox(width: space.sm),
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
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(space.lg, 0, space.lg, space.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: FilledButton(
                        key: const ValueKey('consent-allow'),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          l10n.crashReportingConsentAllow,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: space.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: OutlinedButton(
                        key: const ValueKey('consent-decline'),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          l10n.crashReportingConsentDecline,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
