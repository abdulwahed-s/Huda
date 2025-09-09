import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/hadith_chapters/chapter_card.dart';

class ChaptersList extends StatelessWidget {
  final List<dynamic> chapters;
  final bool isDark;

  const ChaptersList({
    super.key,
    required this.chapters,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          return ChapterCard(
            chapter: chapter,
            isDark: isDark,
            currentLanguageCode: currentLanguageCode,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoute.hadithDetails,
                arguments: {
                  'chapterId': chapter.chapterNumber!.toString(),
                  'bookId': chapter.bookSlug!.toString(),
                  'chapterName': currentLanguageCode == "ur"
                      ? chapter.chapterUrdu!.toString()
                      : currentLanguageCode == "ar"
                          ? chapter.chapterArabic!.toString()
                          : chapter.chapterEnglish!.toString(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
