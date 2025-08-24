import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;

  const SettingsAppBar({super.key, required this.isDark});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.settings,
        style: TextStyle(
          fontFamily: "Amiri",
          fontWeight: FontWeight.w600,
          fontSize: 22.sp,
          color: isDark ? context.darkText : context.lightText,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? context.darkText : context.lightText,
      centerTitle: true,
    );
  }
}


