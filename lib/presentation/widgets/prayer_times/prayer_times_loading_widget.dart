import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class PrayerTimesLoadingWidget extends StatelessWidget {
  const PrayerTimesLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            color: context.primaryColor,
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.loading,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: "Amiri",
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}