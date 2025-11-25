import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class NextPrayerCountdownCardWidget extends StatelessWidget {
  final PrayerTimesLoaded state;
  final bool isDark;

  const NextPrayerCountdownCardWidget({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryColor.withValues(alpha: 0.1),
              context.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(16.w),
        child: StreamBuilder<NextPrayerCountdown>(
          stream: context.read<PrayerTimesCubit>().getNextPrayerCountdown(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.primaryColor,
                ),
              );
            }

            final countdown = snapshot.data!;
            return _buildCountdownContent(context, countdown, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildCountdownContent(
    BuildContext context,
    NextPrayerCountdown countdown,
    bool isDark,
  ) {
    // Calculate time display
    String hours, minutes, seconds, prefix;

    if (countdown.isPastPrayer) {
      // Show time that has passed since prayer
      final totalSeconds = countdown.secondsPassed;
      hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      prefix = '+';
    } else {
      // Show countdown to next prayer
      hours = countdown.duration.inHours.toString().padLeft(2, '0');
      minutes = (countdown.duration.inMinutes % 60).toString().padLeft(2, '0');
      seconds = (countdown.duration.inSeconds % 60).toString().padLeft(2, '0');
      prefix = '-';
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.timer,
              color: context.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              AppLocalizations.of(context)!.nextPrayerCountDown,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: "Amiri",
                color: context.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          _getLocalizedPrayerName(context, countdown.prayerName),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: "Amiri",
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            "$prefix $hours:$minutes:$seconds",
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              fontFamily: "monospace",
              color: context.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedPrayerName(BuildContext context, String prayerName) {
    final localizations = AppLocalizations.of(context)!;
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return localizations.fajr;
      case 'dhuhr':
        return localizations.dhuhr;
      case 'asr':
        return localizations.asr;
      case 'maghrib':
        return localizations.maghrib;
      case 'isha':
        return localizations.isha;
      default:
        return prayerName;
    }
  }
}
