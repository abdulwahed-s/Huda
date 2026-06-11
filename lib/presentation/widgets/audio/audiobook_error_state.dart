import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';




class AudiobookErrorState extends StatelessWidget {
  final String message;
  final bool isDark;

  const AudiobookErrorState({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? context.darkText : context.lightText;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 72.sp, color: Colors.red.shade400),
              SizedBox(height: 20.h),
              Text(
                l10n.oopsSomethingWentWrong,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: textColor,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: textColor.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 36.h),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.back),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
