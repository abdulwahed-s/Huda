import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
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
        Row(
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
                Icons.language_outlined,
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
                    l10n.language,
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 18.sp, tablet: 20.0, desktop: 20.0),
                      fontWeight: FontWeight.w600,
                      color: isDark ? context.darkText : context.lightText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getLanguageDisplayName(selectedLocale.languageCode, l10n),
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 14.sp, tablet: 15.0, desktop: 15.0),
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
        SizedBox(
            height:
                context.responsive(mobile: 24.h, tablet: 24.0, desktop: 24.0)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                context.responsive(mobile: 16.w, tablet: 16.0, desktop: 16.0),
            vertical:
                context.responsive(mobile: 4.h, tablet: 4.0, desktop: 4.0),
          ),
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
              size: context.responsive(
                  mobile: 24.sp, tablet: 24.0, desktop: 24.0),
            ),
            items: LocalizationCubit.supportedLocales.map((locale) {
              final isCurrentSelected = selectedLocale == locale;
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(
                        mobile: 8.w, tablet: 10.0, desktop: 10.0),
                    vertical: context.responsive(
                        mobile: 8.h, tablet: 10.0, desktop: 10.0),
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentSelected
                        ? context.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: context.responsive(
                            mobile: 36.w, tablet: 36.0, desktop: 36.0),
                        height: context.responsive(
                            mobile: 24.h, tablet: 24.0, desktop: 24.0),
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
                              fontSize: context.responsive(
                                  mobile: 10.sp, tablet: 11.0, desktop: 11.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          width: context.responsive(
                              mobile: 16.w, tablet: 16.0, desktop: 16.0)),
                      Expanded(
                        child: Text(
                          _getLanguageDisplayName(locale.languageCode, l10n),
                          style: TextStyle(
                            fontSize: context.responsive(
                                mobile: 15.sp, tablet: 16.0, desktop: 16.0),
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
                          padding: EdgeInsets.all(
                            context.responsive(
                                mobile: 4.w, tablet: 5.0, desktop: 5.0),
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: context.responsive(
                                mobile: 16.sp, tablet: 16.0, desktop: 16.0),
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
        return [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)];
      case 'ar':
        return [const Color(0xFF059669), const Color(0xFF047857)];
      case 'tr':
        return [const Color(0xFFDC2626), const Color(0xFFB91C1C)];
      case 'fr':
        return [const Color(0xFF4338CA), const Color(0xFF3730A3)];
      case 'es':
        return [const Color(0xFFEA580C), const Color(0xFFD97706)];
      case 'de':
        return [const Color(0xFFD97706), const Color(0xFFB45309)];
      case 'ru':
        return [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
      case 'ur':
        return [const Color(0xFF0D9488), const Color(0xFF0F766E)];
      case 'ms':
        return [const Color(0xFFDB2777), const Color(0xFFBE185D)];
      case 'bn':
        return [const Color(0xFF059669), const Color(0xFF065F46)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }
}
