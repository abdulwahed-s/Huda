import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/books/language_badge.dart';

class LanguageSelectionList extends StatelessWidget {
  final List<MapEntry<String, dynamic>> languages;
  final ValueChanged<dynamic> onLanguageSelected;

  const LanguageSelectionList({
    super.key,
    required this.languages,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index].value;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onLanguageSelected(lang),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          LanguageBadge(language: lang.langsymbol),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              lang.langtranslation ?? lang.langsymbol ?? '',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? context.darkText
                                    : context.lightText,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
