import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show Bidi;

TextDirection shareTextDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

@immutable
class ShareImagePalette {
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color glow;
  final Color gold;
  final Color paper;
  final Color ink;
  final Color inkMuted;
  final Color accentInk;

  const ShareImagePalette({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.glow,
    required this.gold,
    required this.paper,
    required this.ink,
    required this.inkMuted,
    required this.accentInk,
  });

  factory ShareImagePalette.fromSeed(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final saturation = math.min(hsl.saturation, 0.6);
    HSLColor tone(double lightness, [double? maxSaturation]) => hsl
        .withSaturation(math.min(saturation, maxSaturation ?? saturation))
        .withLightness(lightness);

    return ShareImagePalette(
      backgroundTop: tone(0.2).toColor(),
      backgroundBottom: tone(0.085).toColor(),
      glow: tone(0.42).toColor(),
      gold: const Color(0xFFD9B872),
      paper: const Color(0xFFFFFCF4),
      ink: tone(0.14, 0.3).toColor(),
      inkMuted: tone(0.32, 0.18).toColor(),
      accentInk: tone(0.3).toColor(),
    );
  }

  static ShareImagePalette of(BuildContext context) =>
      ShareImagePalette.fromSeed(Theme.of(context).colorScheme.primary);
}

class BrandedShareFrame extends StatelessWidget {
  static const double width = 420;
  static const String logoAsset = 'assets/images/huda.png';

  final ShareImagePalette palette;
  final String sectionLabel;
  final IconData sectionIcon;
  final String? title;
  final String? subtitle;
  final TextDirection? titleDirection;
  final Widget child;
  final Widget? footnote;

  const BrandedShareFrame({
    super.key,
    required this.palette,
    required this.sectionLabel,
    required this.sectionIcon,
    this.title,
    this.subtitle,
    this.titleDirection,
    required this.child,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.backgroundTop, palette.backgroundBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GeometricPatternPainter(
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.05),
                    radius: 0.95,
                    colors: [
                      palette.glow.withValues(alpha: 0.38),
                      palette.glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ShareHeader(
                    palette: palette,
                    sectionLabel: sectionLabel,
                    sectionIcon: sectionIcon,
                    title: title,
                    subtitle: subtitle,
                    titleDirection: titleDirection,
                  ),
                  const SizedBox(height: 22),
                  _PaperCard(palette: palette, child: child),
                  if (footnote != null) ...[
                    const SizedBox(height: 14),
                    footnote!,
                  ],
                  const SizedBox(height: 24),
                  _BrandFooter(palette: palette),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  final ShareImagePalette palette;
  final String sectionLabel;
  final IconData sectionIcon;
  final String? title;
  final String? subtitle;
  final TextDirection? titleDirection;

  const _ShareHeader({
    required this.palette,
    required this.sectionLabel,
    required this.sectionIcon,
    required this.title,
    required this.subtitle,
    required this.titleDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Hairline(color: palette.gold, width: 32, fadeTowardStart: true),
            const SizedBox(width: 10),
            Icon(sectionIcon, color: palette.gold, size: 15),
            const SizedBox(width: 8),
            Text(
              sectionLabel,
              style: TextStyle(
                color: palette.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: isRtl ? 0 : 1,
              ),
            ),
            const SizedBox(width: 10),
            _Hairline(color: palette.gold, width: 32, fadeTowardStart: false),
          ],
        ),
        if (title != null && title!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            textAlign: TextAlign.center,
            textDirection: titleDirection,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaperCard extends StatelessWidget {
  final ShareImagePalette palette;
  final Widget child;

  const _PaperCard({required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: child,
          ),
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Positioned.fill(
              child: Align(
                alignment: alignment,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _Star(color: palette.gold, size: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  final ShareImagePalette palette;

  const _BrandFooter({required this.palette});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShareOrnamentDivider(color: palette.gold.withValues(alpha: 0.6)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              key: const ValueKey('share_image_logo'),
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.gold.withValues(alpha: 0.5)),
              ),
              child: const ImageIcon(
                AssetImage(BrandedShareFrame.logoAsset),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizations.shareImageTagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ShareOrnamentDivider extends StatelessWidget {
  final Color color;
  final double starSize;

  const ShareOrnamentDivider({
    super.key,
    required this.color,
    this.starSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Hairline(color: color, fadeTowardStart: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _Star(color: color, size: starSize),
        ),
        Expanded(child: _Hairline(color: color, fadeTowardStart: false)),
      ],
    );
  }
}

class ShareInfoChip extends StatelessWidget {
  final ShareImagePalette palette;
  final IconData icon;
  final String label;
  final TextDirection? textDirection;

  const ShareInfoChip({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: palette.accentInk.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.accentInk.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: palette.accentInk),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                textDirection: textDirection,
                style: TextStyle(
                  color: palette.accentInk,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareSectionHeading extends StatelessWidget {
  final ShareImagePalette palette;
  final IconData icon;
  final String label;

  const ShareSectionHeading({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: palette.accentInk.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: palette.accentInk),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.accentInk,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class ShareFootnote extends StatelessWidget {
  final IconData icon;
  final String text;

  const ShareFootnote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.62);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  final Color color;
  final double? width;
  final bool fadeTowardStart;

  const _Hairline({
    required this.color,
    required this.fadeTowardStart,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [color.withValues(alpha: 0), color];
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: fadeTowardStart ? colors : colors.reversed.toList(),
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final Color color;
  final double size;

  const _Star({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(color: color),
    );
  }
}

Path _eightPointStar(Offset center, double outerRadius, double innerRadius) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final radius = i.isEven ? outerRadius : innerRadius;
    final angle = -math.pi / 2 + i * math.pi / 8;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

class _StarPainter extends CustomPainter {
  final Color color;

  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    canvas.drawPath(
      _eightPointStar(size.center(Offset.zero), radius, radius * 0.62),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}

class _GeometricPatternPainter extends CustomPainter {
  static const double _tile = 60;

  final Color color;

  const _GeometricPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (var y = 0.0; y < size.height + _tile; y += _tile) {
      for (var x = 0.0; x < size.width + _tile; x += _tile) {
        final center = Offset(x, y);
        canvas.drawPath(
          _eightPointStar(center, _tile * 0.36, _tile * 0.26),
          paint,
        );
        canvas.drawCircle(center, _tile * 0.1, paint);
        canvas.drawCircle(
          center + const Offset(_tile / 2, _tile / 2),
          _tile * 0.05,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GeometricPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
