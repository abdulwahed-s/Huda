import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';

class CustomizationThemeBanner extends StatelessWidget {
  const CustomizationThemeBanner({
    super.key,
    required this.theme,
    required this.onEdit,
  });

  final HomeThemeId theme;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final name = homeThemeName(context, theme);
    final description = homeThemeDescription(context, theme);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2, bottom: 7),
              child: Text(
                l10n.homeStyle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Semantics(
              container: true,
              button: true,
              label: '${l10n.homeStyle}. $name. $description',
              excludeSemantics: true,
              onTap: onEdit,
              child: Material(
                key: const ValueKey('home-style-selector'),
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.82),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onEdit,
                  splashColor: accent.withValues(alpha: 0.12),
                  highlightColor: accent.withValues(alpha: 0.045),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 8, 9),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            homeThemeIcon(theme),
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.25,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.085),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: accent,
                            size: 23,
                          ),
                        ),
                      ],
                    ),
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
