import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/qiblah/qiblah_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class PermissionDeniedState extends StatelessWidget {
  final String message;
  final bool isDark;
  final bool isPermanent;

  const PermissionDeniedState({
    super.key,
    required this.message,
    required this.isDark,
    required this.isPermanent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 64.w,
              color: Colors.orange.shade400,
            ),
            SizedBox(height: 24.h),
            Text(
              AppLocalizations.of(context)!.locationPermissionRequired,
              style: TextStyle(
                fontFamily: "Amiri",
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Amiri",
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: isPermanent
                  ? () async {
                      await AppSettings.openAppSettings();
                      await Future.delayed(const Duration(seconds: 5));
                      if (context.mounted) {
                        context.read<QiblahCubit>().loadQiblah();
                      }
                    }
                  : () => context.read<QiblahCubit>().loadQiblah(),
              icon: Icon(isPermanent ? Icons.settings : Icons.refresh),
              label: Text(
                isPermanent
                    ? AppLocalizations.of(context)!.openSettings
                    : AppLocalizations.of(context)!.retry,
                style: const TextStyle(
                  fontFamily: "Amiri",
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
