import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class RefreshLocationButtonWidget extends StatelessWidget {
  const RefreshLocationButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 3,
        ),
        onPressed: () {
          context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes();
        },
        icon: Icon(Icons.refresh, size: 18.sp),
        label: Text(
          AppLocalizations.of(context)!.refreshLocation,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            fontFamily: "Amiri",
          ),
        ),
      ),
    );
  }
}