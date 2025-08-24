import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class ThemeModeDescription extends StatelessWidget {
  final bool isDark;

  const ThemeModeDescription({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final themeMode = themeState.themeMode;
        final isDarkMode = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return Text(
          isDarkMode
              ? AppLocalizations.of(context)!.darkmode
              : AppLocalizations.of(context)!.lightmode,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: "Amiri",
            color: isDark
                ? context.darkText.withValues(alpha: 0.7)
                : context.lightText.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}

