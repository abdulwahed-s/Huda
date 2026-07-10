import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_divider.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_row.dart';
import 'package:intl/intl.dart';

class PrayerTimesCardWidget extends StatelessWidget {
  final PrayerTimesLoaded state;

  const PrayerTimesCardWidget({
    super.key,
    required this.state,
  });

  static String _formatTime(String locale, DateTime? base, int? offset) {
    if (base == null) return '--:--';
    return DateFormat.jm(locale)
        .format(base.add(Duration(minutes: offset ?? 0)));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final times = state.prayerTimes;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.primaryColor.withValues(alpha: 0.8),
              context.primaryColor,
            ],
          ),
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.prayerTimes,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showPrayerTimeAdjustmentSheet(context),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.fajr,
              time: _formatTime(locale, times.fajr, state.offsets['fajr']),
              icon: Icons.wb_twilight,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.sunrise,
              time:
                  _formatTime(locale, times.sunrise, state.offsets['sunrise']),
              iconAsset: 'assets/images/sunrise.svg.vec',
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.dhuhr,
              time: _formatTime(locale, times.dhuhr, state.offsets['dhuhr']),
              icon: Icons.wb_sunny,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.asr,
              time: _formatTime(locale, times.asr, state.offsets['asr']),
              icon: Icons.wb_sunny_outlined,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.maghrib,
              time:
                  _formatTime(locale, times.maghrib, state.offsets['maghrib']),
              iconAsset: 'assets/images/sunset.svg.vec',
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.isha,
              time: _formatTime(locale, times.isha, state.offsets['isha']),
              icon: Icons.nights_stay,
            ),
          ],
        ),
      ),
    );
  }
}
