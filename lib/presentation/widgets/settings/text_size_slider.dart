import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class TextSizeSlider extends StatelessWidget {
  const TextSizeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<ThemeCubit>().state.textScaleFactor;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.small,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: "Amiri",
                fontWeight: FontWeight.w500,
                color: isDark
                    ? context.darkText.withValues(alpha: 0.8)
                    : context.lightText.withValues(alpha: 0.8),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${(scale * 100).round()}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: "Amiri",
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                ),
              ),
            ),
            Text(
              l10n.large,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: "Amiri",
                fontWeight: FontWeight.w500,
                color: isDark
                    ? context.darkText.withValues(alpha: 0.8)
                    : context.lightText.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 24.r),
            activeTrackColor: context.primaryColor,
            inactiveTrackColor: context.primaryColor.withValues(alpha: 0.2),
            thumbColor: context.primaryColor,
            overlayColor: context.primaryColor.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: scale,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            onChanged: (value) {
              context.read<ThemeCubit>().setTextScaleFactor(value);
            },
          ),
        ),
      ],
    );
  }
}

