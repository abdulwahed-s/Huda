import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import '../../../../core/theme/theme_extension.dart';

class SurahCard extends StatelessWidget {
  final QuranModel surah;
  final AnimationController animationController;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.animationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final cardColor = Theme.of(context).cardColor;
    final radius = BorderRadius.circular(20.r);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 30.h * (1 - animationController.value)),
        child: Opacity(
          opacity: animationController.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color.lerp(cardColor, Colors.white, 0.05)!, cardColor]
                : [Colors.white, const Color(0xFFFAF8F3)],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : context.primaryColor.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
              blurRadius: 18.r,
              offset: Offset(0, 7.h),
            ),
            BoxShadow(
              color:
                  context.primaryColor.withValues(alpha: isDark ? 0.0 : 0.035),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardOrnamentPainter(
                    color: context.primaryColor,
                    isDark: isDark,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  splashColor: context.primaryColor.withValues(alpha: 0.08),
                  highlightColor: context.primaryColor.withValues(alpha: 0.04),
                  onTap: onTap,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _NumberStar(
                          number: surah.number ?? 0,
                          color: context.primaryColor,
                        ),
                        SizedBox(width: 14.w),
                        Expanded(child: _buildNames(context, langCode, isDark)),
                        SizedBox(width: 10.w),
                        _buildMeta(context, l10n, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNames(BuildContext context, String langCode, bool isDark) {
    final isArabic = langCode == 'ar';
    final isUrdu = langCode == 'ur';
    final arabicName = surah.name ?? '';
    final arabicShort = surah.names?['ar'] ?? arabicName;

    final String nameLine;
    final String? translationLine;
    final String? arabicLine;
    final bool nameIsArabic = isArabic || isUrdu;

    if (isArabic) {
      nameLine = arabicName;
      translationLine = null;
      arabicLine = null;
    } else if (isUrdu) {
      nameLine = arabicShort;
      translationLine = surah.localizedName(langCode);
      arabicLine = null;
    } else {
      nameLine = surah.localizedTransliteration(langCode) ?? '';
      translationLine = surah.localizedName(langCode);
      arabicLine = arabicShort;
    }

    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nameLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: nameIsArabic ? TextDirection.rtl : null,
          style: TextStyle(
            fontSize: nameIsArabic ? 18.sp : 15.5.sp,
            fontFamily: nameIsArabic ? 'uthmanic' : null,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: bodyColor,
          ),
        ),
        if (translationLine != null && translationLine.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Text(
            translationLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
        if (arabicLine != null && arabicLine.isNotEmpty) ...[
          SizedBox(height: 5.h),
          Text(
            arabicLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 17.sp,
              fontFamily: 'uthmanic',
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: context.primaryColor,
              fontFeatures: const [FontFeature.enable('liga')],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMeta(BuildContext context, AppLocalizations l10n, bool isDark) {
    final isMeccan = surah.revelationType == 'Meccan';

    final revAccent =
        isMeccan ? const Color(0xFFC9941E) : const Color(0xFF2E7D6B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _InfoChip(
          label: isMeccan ? l10n.meccan : l10n.medinan,
          icon: isMeccan ? Icons.brightness_5_rounded : Icons.nightlight_round,
          accent: revAccent,
          isDark: isDark,
        ),
        SizedBox(height: 8.h),
        _InfoChip(
          label: '${surah.numberOfAyahs} ${l10n.ayahs}',
          icon: Icons.menu_book_rounded,
          accent: context.primaryColor,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? accent.withValues(alpha: 0.95) : accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: fg),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberStar extends StatelessWidget {
  final int number;
  final Color color;

  const _NumberStar({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46.w,
      height: 46.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(46.w, 46.w),
            painter: _NumberBadgePainter(color),
          ),
          Padding(
            padding: EdgeInsets.all(13.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Path _octagramPath(Offset center, double radius) {
  Path diamond(double rotation) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = rotation + i * (math.pi / 2);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  return Path()
    ..addPath(diamond(0), Offset.zero)
    ..addPath(diamond(math.pi / 4), Offset.zero)
    ..fillType = PathFillType.nonZero;
}

class _NumberBadgePainter extends CustomPainter {
  final Color color;

  _NumberBadgePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final star = _octagramPath(center, r);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(star.shift(const Offset(0, 2)), glow);

    final rect = Rect.fromCircle(center: center, radius: r);
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.22)!,
          color,
          Color.lerp(color, Colors.black, 0.14)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawPath(star, fill);

    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawPath(_octagramPath(center, r - 5), facet);
  }

  @override
  bool shouldRepaint(covariant _NumberBadgePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CardOrnamentPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _CardOrnamentPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 6, 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: isDark ? 0.06 : 0.05);

    for (final factor in const [0.82, 0.56, 0.32]) {
      canvas.drawPath(_octagramPath(center, size.height * factor), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardOrnamentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
