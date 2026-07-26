import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/home_customization/home_theme_preview.dart';

class CustomizationThemeBanner extends StatelessWidget {
  const CustomizationThemeBanner({
    super.key,
    required this.theme,
    required this.configuration,
  });

  final HomeThemeId theme;
  final HomeThemeConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackVertically = constraints.maxWidth < 620 || textScale > 1.35;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.16 : 0.09),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.26 : 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(homeThemeIcon(theme), color: accent, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      homeThemeName(context, theme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              homeThemeDescription(context, theme),
              maxLines: stackVertically ? 4 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
            ),
          ],
        );
        final preview = HomeThemePreview(
          key: ValueKey('selected-theme-preview-${theme.name}'),
          theme: theme,
          detail: HomeThemePreviewDetail.expanded,
          configuration: configuration,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.045 : 0.018),
              scheme.surface,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.11),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(stackVertically ? 16 : 20),
            child: stackVertically
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      const SizedBox(height: 18),
                      SizedBox(height: 190, child: preview),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 4, child: copy),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 6,
                        child: SizedBox(height: 210, child: preview),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
