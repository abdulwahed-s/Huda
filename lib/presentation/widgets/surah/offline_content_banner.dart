import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// What can't be fetched while offline, said quietly over what still works
/// (saved readers, tafsir, translations).
class OfflineContentBanner extends StatelessWidget {
  final String message;

  const OfflineContentBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: tokens.radius.control,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space.sm),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.space.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
