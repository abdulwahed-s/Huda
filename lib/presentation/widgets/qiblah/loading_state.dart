import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class LoadingState extends StatelessWidget {
  final bool isDark;

  const LoadingState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? context.darkGradientEnd : context.primaryColor,
            strokeWidth: 3,
          ),
          SizedBox(height: 24.h),
          Text(
            AppLocalizations.of(context)!.findingQiblahDirection,
            style: TextStyle(
              fontFamily: "Amiri",
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

