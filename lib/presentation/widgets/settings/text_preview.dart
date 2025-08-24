import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class TextPreview extends StatelessWidget {
  final bool isDark;

  const TextPreview({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<ThemeCubit>().state.textScaleFactor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.sampleTextPreview,
        style: TextStyle(
          fontSize: 16.sp * scale,
          height: 1.5,
          fontFamily: "Amiri",
          color: isDark ? context.darkText : context.lightText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

