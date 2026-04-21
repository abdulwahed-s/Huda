import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/presentation/widgets/settings/color_theme_selection_section.dart';
import 'package:huda/presentation/widgets/settings/language_selection_section.dart';
import 'package:huda/presentation/widgets/settings/support_card.dart';
import 'package:huda/presentation/widgets/settings/text_size_section.dart';
import 'package:huda/presentation/widgets/settings/theme_toggle_section.dart';

class SettingsBody extends StatelessWidget {
  final bool isDark;

  const SettingsBody({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.responsive(
              mobile: double.infinity,
              tablet: double.infinity,
              desktop: double.infinity,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  context.responsive(mobile: 20.w, tablet: 24.0, desktop: 24.0),
              vertical:
                  context.responsive(mobile: 8.h, tablet: 12.0, desktop: 12.0),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                ThemeToggleSection(isDark: isDark),
                SizedBox(
                    height: context.responsive(
                        mobile: 24.h, tablet: 24.0, desktop: 24.0)),
                TextSizeSection(isDark: isDark),
                SizedBox(
                    height: context.responsive(
                        mobile: 24.h, tablet: 24.0, desktop: 24.0)),
                const LanguageSelectionSection(),
                SizedBox(
                    height: context.responsive(
                        mobile: 24.h, tablet: 24.0, desktop: 24.0)),
                const ColorThemeSelectionSection(),
                SizedBox(
                    height: context.responsive(
                        mobile: 24.h, tablet: 24.0, desktop: 24.0)),
                const SupportCard(),
                SizedBox(
                    height: context.responsive(
                        mobile: 32.h, tablet: 32.0, desktop: 32.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
