import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';

extension ThemeExtension on BuildContext {
  AppColorScheme get appColors {
    final themeState = read<ThemeCubit>().state;
    return AppColors.getColorScheme(themeState.colorTheme);
  }

  AppColorScheme get watchAppColors {
    final themeState = watch<ThemeCubit>().state;
    return AppColors.getColorScheme(themeState.colorTheme);
  }

  Color get primaryColor => appColors.primary;

  Color get accentColor => appColors.accent;

  Color get primaryVariantColor => appColors.primaryVariant;

  Color get primaryLightColor => appColors.primaryLight;

  Color get primaryDarkColor => appColors.primaryDark;

  Color get accentDarkColor => appColors.accentDark;

  Color get primaryExtraLightColor => appColors.primaryExtraLight;

  Color get primarySurfaceColor => appColors.primarySurface;

  Color get darkGradientStart => appColors.darkGradientStart;
  Color get darkGradientMid => appColors.darkGradientMid;
  Color get darkGradientEnd => appColors.darkGradientEnd;

  Color get darkCardBackground => appColors.darkCardBackground;
  Color get lightSurface => appColors.lightSurface;
  Color get darkText => appColors.darkText;
  Color get lightText => appColors.lightText;
  Color get darkTabBackground => appColors.darkTabBackground;
}
