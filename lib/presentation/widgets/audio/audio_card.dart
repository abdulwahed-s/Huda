import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/data/models/audios_response.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioCard extends StatelessWidget {
  final AudioItem audio;
  final bool isDark;
  final bool isDownloaded;

  const AudioCard({
    super.key,
    required this.audio,
    required this.isDark,
    this.isDownloaded = false,
  });

  Color _getCassetteColor() {
    const colors = [
      Color(0xFF1E3A8A),
      Color(0xFF064E3B),
      Color(0xFF4C1D95),
      Color(0xFF7F1D1D),
      Color(0xFF78350F),
      Color(0xFF0F172A),
      Color(0xFF1A3A4A),
    ];
    return colors[audio.title.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final author =
        audio.preparedBy.isNotEmpty ? (audio.preparedBy.first.title ?? '') : '';
    final cassetteColor = _getCassetteColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(context),
          borderRadius: BorderRadius.circular(8.r),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(cassetteColor, Colors.white, 0.08)!,
                  cassetteColor,
                  Color.lerp(cassetteColor, Colors.black, 0.1)!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_ScrewHole(), _ScrewHole()],
                  ),
                  SizedBox(height: 4.h),
                  _LabelSticker(
                    audio: audio,
                    author: author,
                    isDownloaded: isDownloaded,
                    cassetteColor: cassetteColor,
                  ),
                  SizedBox(height: 6.h),
                  SizedBox(
                    height: 62.h,
                    child: _TapeWindow(),
                  ),
                  SizedBox(height: 6.h),
                  _HeadGap(),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_ScrewHole(), _ScrewHole()],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoute.audioDetail,
      arguments: {
        'audioId': audio.id.toString(),
        'language': audio.translatedLanguage,
        'title': audio.title,
      },
    );
  }
}

class _ScrewHole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}

class _LabelSticker extends StatelessWidget {
  final AudioItem audio;
  final String author;
  final bool isDownloaded;
  final Color cassetteColor;

  const _LabelSticker({
    required this.audio,
    required this.author,
    required this.isDownloaded,
    required this.cassetteColor,
  });

  String _languageName(BuildContext context) {
    final state = context.watch<AudioLanguagesCubit>().state;
    String name = audio.sourceLanguage;
    if (state is AudioLanguagesLoaded) {
      for (final lang in state.languages) {
        if (lang.langsymbol == audio.sourceLanguage) {
          name = lang.langtranslation ?? audio.sourceLanguage;
          break;
        }
      }
    }
    final isArabicUi = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabicUi && name.length > 1) {
      if (!name.startsWith('ال')) name = 'ال$name';
      if (!name.endsWith('ة')) name = '$nameة';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EF),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(
            color: const Color(0xFFE0D5C0),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RuledLinesPainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: cassetteColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.audioInLanguage(
                              _languageName(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w800,
                              color: cassetteColor,
                            ),
                          ),
                        ),
                        if (isDownloaded) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.download_done_rounded,
                            size: 9.sp,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
                  child: Column(
                    children: [
                      Text(
                        audio.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                          height: 1.3,
                        ),
                      ),
                      if (author.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          author,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDAD0BE).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final lineSpacing = size.height / 7;
    final startY = size.height * 0.22;
    for (double y = startY; y < size.height - 4; y += lineSpacing) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TapeWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: CustomPaint(painter: _TapeWindowPainter()),
    );
  }
}

class _TapeWindowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftCenter = Offset(size.width * 0.3, size.height * 0.43);
    final rightCenter = Offset(size.width * 0.7, size.height * 0.43);
    final maxRadius = math.min(size.width * 0.2, size.height * 0.35);

    final leftTapeR = maxRadius * 1.35;
    final rightTapeR = maxRadius * 0.85;
    final hubR = maxRadius * 0.45;
    final holeR = maxRadius * 0.16;

    final tapePaint = Paint()
      ..color = const Color(0xFF3A2515).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftCenter, leftTapeR, tapePaint);
    canvas.drawCircle(rightCenter, rightTapeR, tapePaint);

    final bottomY = size.height * 0.88;
    final tapePathPaint = Paint()
      ..color = const Color(0xFF4A3020).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(
        leftCenter.dx + leftTapeR * math.sin(0.4),
        leftCenter.dy + leftTapeR * math.cos(0.4),
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        bottomY + 2,
        size.width * 0.32,
        bottomY,
      )
      ..lineTo(size.width * 0.68, bottomY)
      ..quadraticBezierTo(
        size.width * 0.75,
        bottomY + 2,
        rightCenter.dx - rightTapeR * math.sin(0.4),
        rightCenter.dy + rightTapeR * math.cos(0.4),
      );
    canvas.drawPath(path, tapePathPaint);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.20, bottomY), 2.0, guidePaint);
    canvas.drawCircle(Offset(size.width * 0.50, bottomY + 2), 1.8, guidePaint);
    canvas.drawCircle(Offset(size.width * 0.80, bottomY), 2.0, guidePaint);

    final hubPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftCenter, hubR, hubPaint);
    canvas.drawCircle(rightCenter, hubR, hubPaint);

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final entry in [
      (leftCenter, leftTapeR),
      (rightCenter, rightTapeR),
    ]) {
      final (center, tapeR) = entry;
      for (int i = 0; i < 3; i++) {
        final angle = i * 2 * math.pi / 3;
        canvas.drawLine(
          Offset(
            center.dx + holeR * 1.6 * math.cos(angle),
            center.dy + holeR * 1.6 * math.sin(angle),
          ),
          Offset(
            center.dx + tapeR * 0.8 * math.cos(angle),
            center.dy + tapeR * 0.8 * math.sin(angle),
          ),
          spokePaint,
        );
      }
    }

    final holePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftCenter, holeR, holePaint);
    canvas.drawCircle(rightCenter, holeR, holePaint);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(leftCenter, leftTapeR, rimPaint);
    canvas.drawCircle(rightCenter, rightTapeR, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeadGap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14.h,
      margin: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 22.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
