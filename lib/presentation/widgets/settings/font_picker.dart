import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class FontPicker extends StatelessWidget {
  final String selectedFont;
  final ValueChanged<String> onFontSelected;

  const FontPicker({
    super.key,
    required this.selectedFont,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    final options = <_FontOption>[
      const _FontOption(
        value: AppFonts.amiri,
        title: 'Amiri',
        previewFamily: AppFonts.amiri,
      ),
      _FontOption(
        value: AppFonts.system,
        title: l.settingsSystemFont,
        subtitle: l.settingsSystemFontDescription,
        previewFamily: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark, l),
        SizedBox(height: 20.h),
        for (final option in options) ...[
          _buildFontOption(context, option, isDark, l),
          if (option != options.last) SizedBox(height: 12.h),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations l) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.text_fields_rounded,
            size: 24.sp,
            color: context.primaryColor,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsAppFont,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? context.darkText : context.lightText,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                l.settingsAppFontDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: (isDark ? context.darkText : context.lightText)
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontOption(
    BuildContext context,
    _FontOption option,
    bool isDark,
    AppLocalizations l,
  ) {
    final isSelected = option.value == selectedFont;
    final baseText = isDark ? context.darkText : context.lightText;
    final sample = option.subtitle ?? l.sampleTextPreview;

    return GestureDetector(
      onTap: () => onFontSelected(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.08)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? context.primaryColor
                : baseText.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: _previewStyle(
                      family: option.previewFamily,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? context.primaryColor : baseText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    sample,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _previewStyle(
                      family: option.previewFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: baseText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? context.primaryColor
                    : baseText.withValues(alpha: 0.3),
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _previewStyle({
    required String? family,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
  }) {
    if (family == null) {
      return TextStyle(
        inherit: false,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

class _FontOption {
  final String value;
  final String title;
  final String? subtitle;
  final String? previewFamily;

  const _FontOption({
    required this.value,
    required this.title,
    this.subtitle,
    required this.previewFamily,
  });
}
