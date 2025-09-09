import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/hadith_details/action_buttons_row.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_heading.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_status_badge.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';

class HadithCard extends StatelessWidget {
  final dynamic hadith;
  final bool isDark;
  final String chapterName;

  const HadithCard({
    super.key,
    required this.hadith,
    required this.isDark,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;

    return Column(
      children: [
        if (hadith.headingArabic != null)
          HadithHeading(
            heading: _getHeadingText(hadith, currentLanguageCode),
            isDark: isDark,
          ),
        Container(
          margin: EdgeInsets.only(bottom: 16.0.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActionButtonsRow(
                hadith: hadith,
                isDark: isDark,
                chapterName: chapterName,
                context: context,
              ),
              HadithText(
                text: _getHadithText(hadith, currentLanguageCode),
                isDark: isDark,
                currentLanguageCode: currentLanguageCode,
              ),
              HadithStatusBadge(
                status: hadith.status!,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getHeadingText(dynamic hadith, String languageCode) {
    return languageCode == "en" && hadith.headingEnglish != ""
        ? hadith.headingEnglish!
        : languageCode == "ar"
            ? hadith.headingArabic!
            : languageCode == "ur" && hadith.headingUrdu! != ""
                ? hadith.headingUrdu!
                : hadith.headingArabic != ""
                    ? hadith.headingArabic!
                    : '';
  }

  String _getHadithText(dynamic hadith, String languageCode) {
    return languageCode == "en" && hadith.hadithEnglish != ""
        ? hadith.hadithEnglish!
        : languageCode == "ar"
            ? hadith.hadithArabic!
            : languageCode == "ur" && hadith.hadithUrdu != ""
                ? hadith.hadithUrdu!
                : hadith.hadithArabic != ""
                    ? hadith.hadithArabic!
                    : '';
  }
}
