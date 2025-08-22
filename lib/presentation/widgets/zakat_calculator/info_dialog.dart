import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      backgroundColor: Theme.of(context).cardColor,
      elevation: 10,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.info_rounded,
              color: context.primaryColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.aboutZakat,
              style: TextStyle(
                fontFamily: "Amiri",
                color: context.primaryColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(16.r),
        child: SingleChildScrollView(
          child: Text(
            AppLocalizations.of(context)!.zakatDescription,
            style: TextStyle(
              fontSize: 15.sp,
              height: 1.6,
              color: Colors.grey[700],
              fontFamily: "Amiri",
            ),
          ),
        ),
      ),
      actions: [
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: TextStyle(
                fontFamily: "Amiri",
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      actionsPadding: EdgeInsets.all(20.r),
    );
  }
}