import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PrayerTimeCardsWidget extends StatefulWidget {
  final DateTime fajrTime;
  final DateTime maghribTime;
  final bool isDark;

  const PrayerTimeCardsWidget({
    super.key,
    required this.fajrTime,
    required this.maghribTime,
    required this.isDark,
  });

  @override
  State<PrayerTimeCardsWidget> createState() => _PrayerTimeCardsWidgetState();
}

class _PrayerTimeCardsWidgetState extends State<PrayerTimeCardsWidget> {
  late Timer _timer;
  Duration _fajrCountdown = Duration.zero;
  Duration _maghribCountdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdowns();
    });
  }

  void _updateCountdowns() {
    final now = DateTime.now();

    if (widget.fajrTime.isAfter(now)) {
      _fajrCountdown = widget.fajrTime.difference(now);
    } else {
      final tomorrowFajr = widget.fajrTime.add(const Duration(days: 1));
      _fajrCountdown = tomorrowFajr.difference(now);
    }

    if (widget.maghribTime.isAfter(now)) {
      _maghribCountdown = widget.maghribTime.difference(now);
    } else {
      final tomorrowMaghrib = widget.maghribTime.add(const Duration(days: 1));
      _maghribCountdown = tomorrowMaghrib.difference(now);
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary =
        widget.isDark ? context.primaryLightColor : context.primaryColor;

    return Row(
      children: [
        Expanded(
          child: _buildPrayerCard(
            title: l10n.fajr,
            time: widget.fajrTime,
            countdown: _fajrCountdown,
            icon: Icons.wb_twilight_rounded,
            primary: primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildPrayerCard(
            title: l10n.maghrib,
            time: widget.maghribTime,
            countdown: _maghribCountdown,
            iconAsset: 'assets/images/sunset.svg.vec',
            primary: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard({
    required String title,
    required DateTime time,
    required Duration countdown,
    IconData? icon,
    String? iconAsset,
    required Color primary,
  }) {
    assert(icon != null || iconAsset != null);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
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
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: _PrayerCardIcon(
              icon: icon,
              iconAsset: iconAsset,
              color: primary,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(time),
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black87,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _formatCountdown(countdown),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: primary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCardIcon extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final double size;

  const _PrayerCardIcon({
    required this.icon,
    required this.iconAsset,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null) {
      return SvgPicture(
        AssetBytesLoader(iconAsset!),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Icon(
      icon,
      color: color,
      size: size,
    );
  }
}
