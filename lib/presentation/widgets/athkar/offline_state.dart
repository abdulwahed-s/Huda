import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class OfflineState extends StatelessWidget {
  const OfflineState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60.h),

            // Enhanced icon with background circle
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48.sp,
                color: Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 24.h),

            // Primary message with better typography
            Text(
              AppLocalizations.of(context)!.noInternetConnection,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),

            SizedBox(height: 12.h),

            // Secondary message with improved readability
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                AppLocalizations.of(context)!.noInternetSettings,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  fontFamily: 'Tajawal',
                  height: 1.4,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Enhanced retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<AthkarCubit>().loadAthkar(),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20.sp,
                ),
                label: Text(
                  AppLocalizations.of(context)!.retryArabic,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 24.w,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

