import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ColorMigrationHelper {
  static final Map<int, String> colorMigrationMap = {
    0xFF674B5D: 'context.primaryColor',
    0xFF8B6F8B: 'context.primaryVariantColor',
    0xFFA688A6: 'context.primaryLightColor',
    0xFF4C1D95: 'context.primaryDarkColor',
    0xFF8B5CF6: 'context.accentColor',
    0xFF6D28D9: 'context.accentDarkColor',
  };

  static Color getPrimaryWithOpacity(BuildContext context, double opacity) {
    return context.primaryColor.withValues(alpha: opacity);
  }

  static Color getAccentWithOpacity(BuildContext context, double opacity) {
    return context.accentColor.withValues(alpha: opacity);
  }

  static LinearGradient getPrimaryGradient(BuildContext context) {
    final colors = context.appColors;
    return LinearGradient(
      colors: [
        colors.primary,
        colors.primaryVariant,
        colors.primaryLight,
      ],
    );
  }

  static LinearGradient getDarkGradient(BuildContext context) {
    final colors = context.appColors;
    return LinearGradient(
      colors: [
        colors.primaryDark,
        colors.primary,
        colors.primaryVariant,
      ],
    );
  }
}

class MigratedSurahAppBar extends StatelessWidget {
  const MigratedSurahAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watchAppColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  colors.primaryDark.withValues(alpha: 0.8),
                  colors.primary.withValues(alpha: 0.9),
                  colors.primaryVariant,
                ]
              : [
                  colors.primary,
                  colors.primaryVariant,
                  colors.primaryLight,
                ],
        ),
      ),
    );
  }
}
