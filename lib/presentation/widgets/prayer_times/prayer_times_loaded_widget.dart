import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class PrayerTimesLoadedWidget extends StatelessWidget {
  final PrayerTimesLoaded state;

  const PrayerTimesLoadedWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: context.primaryColor,
          size: 20.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.location,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: "Amiri",
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                state.placemarks.isNotEmpty
                    ? '${state.placemarks.first.country}, ${state.placemarks.first.locality}'
                    : AppLocalizations.of(context)!.unknown,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Amiri",
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
