import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class FastingProgressWidget extends StatefulWidget {
  final DateTime fajrTime;
  final DateTime maghribTime;
  final bool isDark;

  const FastingProgressWidget({
    super.key,
    required this.fajrTime,
    required this.maghribTime,
    required this.isDark,
  });

  @override
  State<FastingProgressWidget> createState() => _FastingProgressWidgetState();
}

class _FastingProgressWidgetState extends State<FastingProgressWidget>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _progressAnim;
  double _targetProgress = 0.0;
  bool _isFasting = true;
  Duration _totalDuration = Duration.zero;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgress();
    });
  }

  void _updateProgress() {
    final now = DateTime.now();
    final fajr = widget.fajrTime;
    final maghrib = widget.maghribTime;

    if (now.isAfter(fajr) && now.isBefore(maghrib)) {
      _isFasting = true;
      _totalDuration = maghrib.difference(fajr);
      final elapsed = now.difference(fajr);
      _remaining = maghrib.difference(now);
      _targetProgress = elapsed.inSeconds / _totalDuration.inSeconds;
    } else {
      _isFasting = false;
      DateTime nextFajr;
      DateTime currentMaghrib;

      if (now.isAfter(maghrib)) {
        currentMaghrib = maghrib;
        nextFajr = fajr.add(const Duration(days: 1));
      } else {
        currentMaghrib = maghrib.subtract(const Duration(days: 1));
        nextFajr = fajr;
      }

      _totalDuration = nextFajr.difference(currentMaghrib);
      final elapsed = now.difference(currentMaghrib);
      _remaining = nextFajr.difference(now);
      _targetProgress = _totalDuration.inSeconds > 0
          ? elapsed.inSeconds / _totalDuration.inSeconds
          : 0.0;
    }

    _targetProgress = _targetProgress.clamp(0.0, 1.0);
    _progressAnim.animateTo(_targetProgress,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressAnim.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary =
        widget.isDark ? context.primaryLightColor : context.primaryColor;
    final totalHours = _totalDuration.inHours;
    final totalMinutes = _totalDuration.inMinutes.remainder(60);
    final remainingHours = _remaining.inHours + 1;

    final String durationText;
    final String leftLabel;
    final String leftTime;
    final String rightLabel;
    final String rightTime;
    final String remainingText;

    if (_isFasting) {
      durationText = l10n.durationOfFasting(totalHours, totalMinutes);
      leftLabel = l10n.imsaakLabel;
      leftTime = _formatTime(widget.fajrTime);
      rightLabel = l10n.iftarLabel;
      rightTime = _formatTime(widget.maghribTime);
      remainingText = l10n.remainingForIftar(remainingHours);
    } else {
      durationText = l10n.durationOfIftar(totalHours, totalMinutes);
      leftLabel = l10n.iftarLabel;
      leftTime = _formatTime(widget.maghribTime);
      rightLabel = l10n.imsaakLabel;
      rightTime = _formatTime(widget.fajrTime);
      remainingText = l10n.remainingForImsaak(remainingHours);
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color:
            widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: widget.isDark
            ? null
            : Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
        boxShadow: widget.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _isFasting
                      ? Icons.restaurant_rounded
                      : Icons.restaurant_menu_rounded,
                  color: primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: CustomPaint(
                  painter: _RoundedProgressPainter(
                    progress: _progressAnim.value,
                    activeColor: primary,
                    trackColor: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : primary.withValues(alpha: 0.1),
                    textDirection: Directionality.of(context),
                  ),
                  size: Size(double.infinity, 10.h),
                ),
              );
            },
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leftLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    leftTime,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    remainingText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rightLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: _isFasting
                          ? primary
                          : (widget.isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    rightTime,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: _isFasting
                          ? primary
                          : (widget.isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundedProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final TextDirection textDirection;

  _RoundedProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    final radius = Radius.circular(size.height / 2);
    final isRTL = textDirection == TextDirection.rtl;

    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, size.width, size.height, radius),
      trackPaint,
    );

    if (progress > 0) {
      final activeWidth = max(size.height, size.width * progress);

      final activeRect = isRTL
          ? Rect.fromLTRB(size.width - activeWidth, 0, size.width, size.height)
          : Rect.fromLTRB(0, 0, activeWidth, size.height);

      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: isRTL
              ? [activeColor, activeColor.withValues(alpha: 0.7)]
              : [activeColor.withValues(alpha: 0.7), activeColor],
        ).createShader(activeRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, radius),
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoundedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.textDirection != textDirection;
  }
}
