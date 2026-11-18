import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';

/// What happens to a message: a quiet note with a lock, under the fields.
class FeedbackPrivacyNote extends StatelessWidget {
  const FeedbackPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.feedbackPrivacyTitle, style: theme.textTheme.titleSmall),
                SizedBox(height: space.xxs),
                Text(
                  l10n.feedbackPrivacyDescription,
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
  }
}
