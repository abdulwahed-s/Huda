import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/book_chapters_model.dart';
import 'package:huda/presentation/widgets/hadith_chapters/chapter_card.dart';

class ChaptersList extends StatelessWidget {
  final List<Data> chapters;
  final String bookName;
  final bool isDark;

  const ChaptersList({
    super.key,
    required this.chapters,
    required this.isDark,
    required this.bookName,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;

    final sortedChapters = List<Data>.from(chapters)
      ..sort((a, b) {
        final aBookNumber = a.bookNumber!;
        final bBookNumber = b.bookNumber!;

        if (aBookNumber == "introduction" && bBookNumber == "introduction") {
          return 0;
        } else if (aBookNumber == "introduction") {
          return -1;
        } else if (bBookNumber == "introduction") {
          return 1;
        } else {
          final aMatch = RegExp(r'^(\d+)([a-zA-Z]*)$').firstMatch(aBookNumber);
          final bMatch = RegExp(r'^(\d+)([a-zA-Z]*)$').firstMatch(bBookNumber);

          final aNum = int.tryParse(aMatch?.group(1) ?? aBookNumber) ?? 0;
          final bNum = int.tryParse(bMatch?.group(1) ?? bBookNumber) ?? 0;

          if (aNum != bNum) {
            return aNum.compareTo(bNum);
          }

          final aSuffix = aMatch?.group(2) ?? '';
          final bSuffix = bMatch?.group(2) ?? '';
          return aSuffix.compareTo(bSuffix);
        }
      });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: sortedChapters.length,
        itemBuilder: (context, index) {
          final chapter = sortedChapters[index];
          return ChapterCard(
            chapter: chapter,
            isDark: isDark,
            currentLanguageCode: currentLanguageCode,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoute.hadithDetails,
                arguments: {
                  'chapterNumber': chapter.bookNumber!,
                  'bookName': bookName,
                  'chapterName': currentLanguageCode == "ar"
                      ? chapter.book![1].name!.toString()
                      : chapter.book![0].name.toString(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
