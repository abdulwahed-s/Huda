import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

abstract final class PrayerTodayVisualStyle {
  static Color toolsSurfaceTop(BuildContext context, bool isDark) {
    final base = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF7FAFF);
    return Color.alphaBlend(
      context.primaryColor.withValues(alpha: isDark ? 0.12 : 0.045),
      base,
    );
  }

  static BoxDecoration toolsSurface(BuildContext context, bool isDark) {
    final top = toolsSurfaceTop(context, isDark);
    final bottom = Color.alphaBlend(
      context.accentColor.withValues(alpha: isDark ? 0.055 : 0.022),
      isDark ? const Color(0xFF0E141B) : const Color(0xFFFFFFFF),
    );
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ),
    );
  }
}
