import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/presentation/widgets/hadith_details/action_buttons_row.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_heading.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_status_badge.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';

class HadithCard extends StatelessWidget {
  final Data hadith;
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
    final currentLanguageCode = context
        .read<LocalizationCubit>()
        .state
        .locale
        .languageCode;
    final selectedHadith = hadith.hadithForLanguage(currentLanguageCode);
    if (selectedHadith == null) return const SizedBox.shrink();

    final body = selectedHadith.body ?? '';
    final entries = hadith.hadith ?? const <Hadith>[];
    String status = '';
    for (final entry in entries) {
      for (final grade in entry.grades ?? const <Grades>[]) {
        if (grade.grade?.trim().isNotEmpty == true) {
          status = grade.grade!;
          break;
        }
      }
      if (status.isNotEmpty) break;
    }

    return Column(
      children: [
        if (selectedHadith.chapterTitle?.trim().isNotEmpty == true)
          HadithHeading(heading: selectedHadith.chapterTitle!, isDark: isDark),
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
                hadithBody: body,
                status: status,
                isDark: isDark,
                chapterName: chapterName,
                languageCode: selectedHadith.lang ?? currentLanguageCode,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: HadithText(
                  text: body,
                  isDark: isDark,
                  currentLanguageCode:
                      selectedHadith.lang ?? currentLanguageCode,
                ),
              ),
              if (status.isNotEmpty)
                HadithStatusBadge(status: status, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}
