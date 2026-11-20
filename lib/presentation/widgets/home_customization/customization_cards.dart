import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';

class EditableHomeFeatureCard extends StatelessWidget {
  const EditableHomeFeatureCard({
    super.key,
    required this.feature,
    required this.primary,
    required this.lifted,
    required this.onMove,
  });

  final HomeFeatureDefinition feature;

  final bool primary;
  final bool lifted;
  final VoidCallback onMove;

  static double extentFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return 48 + 8 + 42 * scale + 8 + 48 + 24;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final id = feature.id;
    final plate = HomePlate(size: 48, art: homeToolArt(id));
    return _EditorCard(
      lifted: lifted,
      child: Padding(
        padding: EdgeInsets.all(space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                plate,
                const Spacer(),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: space.xs),
            Expanded(
              child: Text(
                feature.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            SizedBox(height: space.xs),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label:
                    '${primary ? l10n.moveToViewMore : l10n.moveToHome}: '
                    '${feature.title}',
                excludeSemantics: true,
                child: OutlinedButton.icon(
                  key: ValueKey('feature-move-${id.name}'),
                  onPressed: onMove,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: space.xs),
                  ),
                  icon: Icon(
                    primary
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    primary ? l10n.viewMore : l10n.onHome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditableHomeSectionCard extends StatelessWidget {
  const EditableHomeSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.lifted,
  });

  final String title;
  final IconData icon;
  final bool lifted;

  static double extentFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return 56 + (scale - 1).clamp(0.0, 1.0) * 28;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _EditorCard(
      lifted: lifted,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: space.md),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: space.sm),
            Icon(icon, size: 20, color: scheme.primary),
            SizedBox(width: space.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.lifted, required this.child});

  final bool lifted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: tokens.motion.of(context, tokens.motion.short),
      curve: tokens.motion.standard,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: tokens.radius.card,
        border: Border.all(
          color: lifted ? scheme.primary : scheme.outlineVariant,
          width: lifted ? tokens.stroke.fine : tokens.stroke.hairline,
        ),
        boxShadow: lifted
            ? [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
