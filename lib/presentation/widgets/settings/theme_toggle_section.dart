import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
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
            padding: EdgeInsets.all(
              context.responsive(mobile: 12.w, tablet: 14.0, desktop: 14.0),
            ),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.brightness_6_outlined,
              color: context.primaryColor,
              size: context.responsive(
                  mobile: 24.sp, tablet: 26.0, desktop: 26.0),
            ),
          ),
          SizedBox(
              width: context.responsive(
                  mobile: 16.w, tablet: 16.0, desktop: 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.theme,
                  style: TextStyle(
                    fontSize: context.responsive(
                        mobile: 18.sp, tablet: 20.0, desktop: 20.0),
                    fontWeight: FontWeight.w600,
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
