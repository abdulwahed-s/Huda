import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';

void showSpecialEventDialog(
    BuildContext context, String eventKey, bool isDarkMode) {
  HapticFeedback.mediumImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) =>
        _EventDialogContent(eventKey: eventKey, isDarkMode: isDarkMode),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

class _EventDialogContent extends StatefulWidget {
  final String eventKey;
  final bool isDarkMode;

  const _EventDialogContent({
    required this.eventKey,
    required this.isDarkMode,
  });

  @override
  State<_EventDialogContent> createState() => _EventDialogContentState();
}

class _EventDialogContentState extends State<_EventDialogContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = EventPalette.forEvent(widget.eventKey, widget.isDarkMode);
    final l10n = AppLocalizations.of(context)!;
    final content = _DialogEventContent.forEvent(widget.eventKey, l10n);
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    final maxWidth = context.responsive(
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 480.0,
      desktop: 520.0,
    );

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: maxWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.gradient[0],
                palette.gradient[1],
                palette.gradient[2],
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: palette.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DialogPatternPainter(
                          color: palette.pattern,
                          animValue: _anim.value,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DialogDecorationPainter(
                          eventKey: widget.eventKey,
                          animValue: _anim.value,
                          accentColor: palette.accent,
                          glowColor: palette.glow,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(
                          mobile: 24.w,
                          tablet: 32.w,
                          desktop: 40.w,
                        ),
                        vertical: context.responsive(
                          mobile: 28.w,
                          tablet: 34.w,
                          desktop: 40.w,
                        ),
                      ),
                      child: _buildBody(
                          context, palette, content, l10n, isArabic),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(EventPalette palette, double width) {
    return Center(
      child: Container(
        width: width,
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.accent.withValues(alpha: 0),
              palette.accent.withValues(alpha: 0.5),
              palette.accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EventPalette palette,
      _DialogEventContent content, AppLocalizations l10n, bool isArabic) {
    final titleSize = context.responsive(
      mobile: 22.sp,
      tablet: 26.sp,
      desktop: 30.sp,
    );
    final arabicSize = context.responsive(
      mobile: 20.sp,
      tablet: 24.sp,
      desktop: 28.sp,
    );
    final translationSize = context.responsive(
      mobile: 14.sp,
      tablet: 16.sp,
      desktop: 18.sp,
    );
    final sourceSize = context.responsive(
      mobile: 12.sp,
      tablet: 13.sp,
      desktop: 14.sp,
    );
    final guidanceSize = context.responsive(
      mobile: 13.sp,
      tablet: 15.sp,
      desktop: 17.sp,
    );
    final iconContainerSize = context.responsive(
      mobile: 56.w,
      tablet: 68.w,
      desktop: 80.w,
    );
    final iconSize = context.responsive(
      mobile: 28.sp,
      tablet: 36.sp,
      desktop: 42.sp,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withValues(alpha: 0.12),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(palette.icon, size: iconSize, color: palette.accent),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          _getTitle(l10n, widget.eventKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: palette.text,
            fontFamily: "Amiri",
            height: 1.3,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _getSubtitle(l10n, widget.eventKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: translationSize,
            color: palette.subtitle,
            fontFamily: "Amiri",
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        _buildDivider(palette, 40.w),
        SizedBox(height: 24.h),
        if (isArabic) ...[
          Text(
            content.arabicText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: arabicSize,
              color: palette.accent,
              fontFamily: "Amiri",
              height: 1.8,
              letterSpacing: 0.5,
            ),
          ),
        ] else ...[
          Text(
            content.arabicText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: arabicSize,
              color: palette.accent,
              fontFamily: "Amiri",
              height: 1.8,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 20.h),
          Center(
            child: Container(
              width: 24.w,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.accent.withValues(alpha: 0),
                    palette.accent.withValues(alpha: 0.35),
                    palette.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            content.translation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: translationSize,
              color: palette.subtitle,
              fontFamily: "Amiri",
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
        SizedBox(height: 20.h),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
            child: Text(
              content.source,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sourceSize,
                color: palette.accent.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        _buildDivider(palette, 40.w),
        SizedBox(height: 20.h),
        Text(
          content.guidance,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: guidanceSize,
            color: palette.text.withValues(alpha: 0.85),
            fontFamily: "Amiri",
            height: 1.7,
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  static String _getTitle(AppLocalizations l10n, String eventKey) {
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadan,
      'last_ten_ramadan' => l10n.eventLastTenRamadan,
      'eid_al_fitr' => l10n.eventEidAlFitr,
      'eid_al_adha' => l10n.eventEidAlAdha,
      'day_of_arafah' => l10n.eventDayOfArafah,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjah,
      'ashura' => l10n.eventAshura,
      'days_of_tashreeq' => l10n.eventDaysTashreeq,
      _ => eventKey,
    };
  }

  static String _getSubtitle(AppLocalizations l10n, String eventKey) {
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadanSubtitle,
      'last_ten_ramadan' => l10n.eventLastTenRamadanSubtitle,
      'eid_al_fitr' => l10n.eventEidAlFitrSubtitle,
      'eid_al_adha' => l10n.eventEidAlAdhaSubtitle,
      'day_of_arafah' => l10n.eventDayOfArafahSubtitle,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjahSubtitle,
      'ashura' => l10n.eventAshuraSubtitle,
      'days_of_tashreeq' => l10n.eventDaysTashreeqSubtitle,
      _ => '',
    };
  }
}

class _DialogEventContent {
  final String arabicText;
  final String translation;
  final String source;
  final String guidance;

  const _DialogEventContent({
    required this.arabicText,
    required this.translation,
    required this.source,
    required this.guidance,
  });

  static _DialogEventContent forEvent(
      String eventKey, AppLocalizations l10n) {
    return switch (eventKey) {
      'ramadan' => _DialogEventContent(
          arabicText: l10n.eventRamadanArabic,
          translation: l10n.eventRamadanTranslation,
          source: l10n.eventRamadanSource,
          guidance: l10n.eventRamadanGuidance,
        ),
      'last_ten_ramadan' => _DialogEventContent(
          arabicText: l10n.eventLastTenRamadanArabic,
          translation: l10n.eventLastTenRamadanTranslation,
          source: l10n.eventLastTenRamadanSource,
          guidance: l10n.eventLastTenRamadanGuidance,
        ),
      'eid_al_fitr' => _DialogEventContent(
          arabicText: l10n.eventEidAlFitrArabic,
          translation: l10n.eventEidAlFitrTranslation,
          source: l10n.eventEidAlFitrSource,
          guidance: l10n.eventEidAlFitrGuidance,
        ),
      'eid_al_adha' => _DialogEventContent(
          arabicText: l10n.eventEidAlAdhaArabic,
          translation: l10n.eventEidAlAdhaTranslation,
          source: l10n.eventEidAlAdhaSource,
          guidance: l10n.eventEidAlAdhaGuidance,
        ),
      'day_of_arafah' => _DialogEventContent(
          arabicText: l10n.eventDayOfArafahArabic,
          translation: l10n.eventDayOfArafahTranslation,
          source: l10n.eventDayOfArafahSource,
          guidance: l10n.eventDayOfArafahGuidance,
        ),
      'first_ten_dhul_hijjah' => _DialogEventContent(
          arabicText: l10n.eventFirstTenDhulHijjahArabic,
          translation: l10n.eventFirstTenDhulHijjahTranslation,
          source: l10n.eventFirstTenDhulHijjahSource,
          guidance: l10n.eventFirstTenDhulHijjahGuidance,
        ),
      'ashura' => _DialogEventContent(
          arabicText: l10n.eventAshuraArabic,
          translation: l10n.eventAshuraTranslation,
          source: l10n.eventAshuraSource,
          guidance: l10n.eventAshuraGuidance,
        ),
      'days_of_tashreeq' => _DialogEventContent(
          arabicText: l10n.eventDaysTashreeqArabic,
          translation: l10n.eventDaysTashreeqTranslation,
          source: l10n.eventDaysTashreeqSource,
          guidance: l10n.eventDaysTashreeqGuidance,
        ),
      _ => const _DialogEventContent(
          arabicText: '',
          translation: '',
          source: '',
          guidance: '',
        ),
    };
  }
}

class _DialogPatternPainter extends CustomPainter {
  final Color color;
  final double animValue;

  _DialogPatternPainter({required this.color, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const tileSize = 50.0;
    final drift = animValue * tileSize * 0.3;
    final cols = (size.width / tileSize).ceil() + 2;
    final rows = (size.height / tileSize).ceil() + 2;

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final cx = c * tileSize + drift;
        final cy = r * tileSize + drift * 0.5;
        _drawStar(canvas, Offset(cx, cy), tileSize * 0.3, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final r = i.isEven ? radius : radius * 0.42;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DialogPatternPainter old) =>
      old.animValue != animValue || old.color != color;
}

class _DialogDecorationPainter extends CustomPainter {
  final String eventKey;
  final double animValue;
  final Color accentColor;
  final Color glowColor;

  _DialogDecorationPainter({
    required this.eventKey,
    required this.animValue,
    required this.accentColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawCornerGlow(canvas, size);

    final shimmerWidth = w * 0.35;
    final total = w + shimmerWidth;
    final xPos = animValue * total - shimmerWidth;
    final shimmerPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(xPos, 0),
        Offset(xPos + shimmerWidth, 0),
        [
          const Color(0x00FFFFFF),
          const Color(0x08FFFFFF),
          const Color(0x00FFFFFF),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), shimmerPaint);
  }

  void _drawCornerGlow(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final topRight = Offset(w, 0);
    final gradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        topRight,
        w * 0.5,
        [
          glowColor.withValues(alpha: 0.06),
          glowColor.withValues(alpha: 0.02),
          glowColor.withValues(alpha: 0),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(topRight, w * 0.5, gradientPaint);

    final bottomLeft = Offset(0, h);
    final bottomPaint = Paint()
      ..shader = ui.Gradient.radial(
        bottomLeft,
        w * 0.4,
        [
          accentColor.withValues(alpha: 0.04),
          accentColor.withValues(alpha: 0),
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(bottomLeft, w * 0.4, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _DialogDecorationPainter old) =>
      old.animValue != animValue ||
      old.eventKey != eventKey ||
      old.accentColor != accentColor;
}
