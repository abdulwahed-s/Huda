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
              time: DateFormat.jm(locale).format(times.fajr
                  .add(Duration(minutes: state.offsets['fajr'] ?? 0))),
              icon: Icons.wb_twilight,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.sunrise,
              time: DateFormat.jm(locale).format(times.sunrise
                  .add(Duration(minutes: state.offsets['sunrise'] ?? 0))),
              icon: Icons.wb_sunny_rounded,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.dhuhr,
              time: DateFormat.jm(locale).format(times.dhuhr
                  .add(Duration(minutes: state.offsets['dhuhr'] ?? 0))),
              icon: Icons.wb_sunny,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.asr,
              time: DateFormat.jm(locale).format(
                  times.asr.add(Duration(minutes: state.offsets['asr'] ?? 0))),
              icon: Icons.wb_sunny_outlined,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.maghrib,
              time: DateFormat.jm(locale).format(times.maghrib
                  .add(Duration(minutes: state.offsets['maghrib'] ?? 0))),
              icon: Icons.wb_twilight,
            ),
            const PrayerDivider(),
            PrayerTimeRow(
              prayerName: AppLocalizations.of(context)!.isha,
              time: DateFormat.jm(locale).format(times.isha
                  .add(Duration(minutes: state.offsets['isha'] ?? 0))),
              icon: Icons.nights_stay,
            ),
          ],
        ),
      ),
    );
  }
}
