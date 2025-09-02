import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class LanguagePicker extends StatelessWidget {
  final Locale selectedLocale;
  final Function(Locale) onLocaleSelected;

  const LanguagePicker({
    super.key,
    required this.selectedLocale,
    required this.onLocaleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section with improved design
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.language_outlined,
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
                    l10n.language,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Amiri",
                      color: isDark ? context.darkText : context.lightText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getLanguageDisplayName(selectedLocale.languageCode, l10n),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: "Amiri",
                      color: isDark
                          ? context.darkText.withValues(alpha: 0.7)
                          : context.lightText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        // Language dropdown with better design
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark
                ? context.darkCardBackground.withValues(alpha: 0.7)
                : context.lightSurface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: DropdownButton<Locale>(
            value: selectedLocale,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: isDark ? context.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            icon: Icon(
              Icons.expand_more_rounded,
              color: context.primaryColor,
              size: 24.sp,
            ),
            items: LocalizationCubit.supportedLocales.map((locale) {
              final isCurrentSelected = selectedLocale == locale;
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isCurrentSelected
                        ? context.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      // Language flag/badge
                      Container(
                        width: 36.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getLanguageGradient(locale.languageCode),
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2.r,
                              offset: Offset(0, 1.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            locale.languageCode.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Amiri",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          _getLanguageDisplayName(locale.languageCode, l10n),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontFamily: "Amiri",
                            fontWeight: isCurrentSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color:
                                isDark ? context.darkText : context.lightText,
                          ),
                        ),
                      ),
                      if (isCurrentSelected)
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (locale) {
              if (locale != null) {
                onLocaleSelected(locale);
              }
            },
          ),
        ),
      ],
    );
  }

  String _getLanguageDisplayName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'en':
        return l10n.english;
      case 'ar':
        return l10n.arabic;
      case 'tr':
        return l10n.turkish;
      case 'fr':
        return l10n.french;
      case 'es':
        return l10n.spanish;
      case 'de':
        return l10n.german;
      case 'ru':
        return l10n.russian;
      case 'ur':
        return l10n.urdu;
      case 'ms':
        return l10n.malay;
      case 'bn':
        return l10n.bengali;
      default:
        return languageCode.toUpperCase();
    }
  }

  List<Color> _getLanguageGradient(String languageCode) {
    switch (languageCode) {
      case 'en':
        return [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)]; // Blue
      case 'ar':
        return [const Color(0xFF059669), const Color(0xFF047857)]; // Green
      case 'tr':
        return [const Color(0xFFDC2626), const Color(0xFFB91C1C)]; // Red
      case 'fr':
        return [const Color(0xFF4338CA), const Color(0xFF3730A3)]; // Indigo
      case 'es':
        return [const Color(0xFFEA580C), const Color(0xFFD97706)]; // Orange
      case 'de':
        return [const Color(0xFFD97706), const Color(0xFFB45309)]; // Amber
      case 'ru':
        return [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]; // Purple
      case 'ur':
        return [const Color(0xFF0D9488), const Color(0xFF0F766E)]; // Teal
      case 'ms':
        return [const Color(0xFFDB2777), const Color(0xFFBE185D)]; // Pink
      case 'bn':
        return [const Color(0xFF059669), const Color(0xFF065F46)]; // Emerald
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)]; // Gray
    }
  }
}
