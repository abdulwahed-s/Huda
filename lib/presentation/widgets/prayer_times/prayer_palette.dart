import 'package:flutter/material.dart';

@immutable
class PrayerPalette {
  const PrayerPalette._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.page,
    required this.card,
    required this.cardRaised,
    required this.border,
    required this.divider,
    required this.tint,
    required this.tintStrong,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.warning,
    required this.error,
    required this.success,
    required this.heroStart,
    required this.heroEnd,
  });

  factory PrayerPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final primary = scheme.primary;
    final page = scheme.surface;
    Color over(double alpha) =>
        Color.alphaBlend(primary.withValues(alpha: alpha), page);
    return PrayerPalette._(
      isDark: dark,
      primary: primary,
      onPrimary: scheme.onPrimary,
      page: page,
      card: over(dark ? 0.10 : 0.045),
      cardRaised: dark ? over(0.16) : Colors.white,
      border: primary.withValues(alpha: dark ? 0.26 : 0.13),
      divider: scheme.onSurface.withValues(alpha: dark ? 0.09 : 0.07),
      tint: primary.withValues(alpha: dark ? 0.18 : 0.08),
      tintStrong: primary.withValues(alpha: dark ? 0.30 : 0.14),
      ink: scheme.onSurface,
      muted: scheme.onSurface.withValues(alpha: dark ? 0.70 : 0.64),
      faint: scheme.onSurface.withValues(alpha: dark ? 0.44 : 0.40),
      warning: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      error: dark ? const Color(0xFFF87171) : const Color(0xFFC62828),
      success: dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      heroStart: Color.lerp(primary, Colors.white, dark ? 0.04 : 0.10)!,
      heroEnd: Color.lerp(primary, Colors.black, dark ? 0.50 : 0.38)!,
    );
  }

  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color page;

  final Color card;

  final Color cardRaised;
  final Color border;
  final Color divider;

  final Color tint;
  final Color tintStrong;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color warning;
  final Color error;
  final Color success;
  final Color heroStart;
  final Color heroEnd;

  BoxDecoration cardDecoration({double radius = 22, Color? color}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );
}

class PrayerStarPainter extends CustomPainter {
  const PrayerStarPainter({required this.color, this.strokeWidth = 1.4});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final center = size.center(Offset.zero);
    final side = size.shortestSide * 0.62;
    for (final angle in const [0.0, 0.7853981633974483]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PrayerStarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
