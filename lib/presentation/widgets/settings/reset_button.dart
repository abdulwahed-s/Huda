import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class ResetButton extends StatelessWidget {
  final double scale;

  const ResetButton({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scale != 1.0
            ? context.primaryColor.withValues(alpha: 0.1)
            : context.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextButton.icon(
        onPressed: scale != 1.0
            ? () {
                context.read<ThemeCubit>().setTextScaleFactor(1.0);
              }
            : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(
          Icons.refresh_rounded,
          size: 18.sp,
          color: scale != 1.0
              ? context.primaryColor
              : context.primaryColor.withValues(alpha: 0.5),
        ),
        label: Text(
          AppLocalizations.of(context)!.reset,
          style: TextStyle(
            fontSize: 13.sp,
            fontFamily: "Amiri",
            fontWeight: FontWeight.w600,
            color: scale != 1.0
                ? context.primaryColor
                : context.primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

