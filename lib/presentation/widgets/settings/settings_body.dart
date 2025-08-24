import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            ThemeToggleSection(isDark: isDark),
            SizedBox(height: 24.h),
            TextSizeSection(isDark: isDark),
            SizedBox(height: 24.h),
            const LanguageSelectionSection(),
            SizedBox(height: 24.h),
            const ColorThemeSelectionSection(),
            SizedBox(height: 24.h),
            const SupportCard(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
