import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';
import 'package:huda/presentation/widgets/settings/theme_mode_description.dart';
import 'package:huda/presentation/widgets/settings/theme_toggle_button.dart';

class ThemeToggleSection extends StatelessWidget {
  final bool isDark;

  const ThemeToggleSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.brightness_6_outlined,
              color: context.primaryColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.theme,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Amiri",
                    color: isDark ? context.darkText : context.lightText,
                  ),
                ),
                SizedBox(height: 4.h),
                ThemeModeDescription(isDark: isDark),
              ],
            ),
          ),
          const ThemeToggleButton(),
        ],
      ),
    );
  }
}
