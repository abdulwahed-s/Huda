import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class LanguageSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const LanguageSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.darkTabBackground : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.searchLanguages,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          labelStyle: TextStyle(
            color: isDark
                ? context.darkText.withValues(alpha: 0.7)
                : context.lightText.withValues(alpha: 0.7),
          ),
        ),
        style: TextStyle(
          color: isDark ? context.darkText : context.lightText,
        ),
        onChanged: onChanged,
      ),
    );
  }
}