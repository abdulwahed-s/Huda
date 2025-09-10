import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_card.dart';
import 'package:huda/presentation/widgets/hadith_details/pagination_controls.dart';

class HadithList extends StatelessWidget {
  final dynamic hadithDetail;
  final bool isDark;
  final String chapterId;
  final String bookId;
  final String chapterName;

  const HadithList({
    super.key,
    required this.hadithDetail,
    required this.isDark,
    required this.chapterId,
    required this.bookId,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: hadithDetail.hadiths!.data!.length,
              itemBuilder: (context, index) {
                final hadith = hadithDetail.hadiths!.data![index];
                return HadithCard(
                  hadith: hadith,
                  isDark: isDark,
                  chapterName: chapterName,
                );
              },
            ),
          ),
          PaginationControls(
            currentPage: hadithDetail.hadiths!.currentPage!,
            lastPage: hadithDetail.hadiths!.lastPage!,
            isDark: isDark,
            chapterId: chapterId,
            bookId: bookId,
          ),
        ],
      ),
    );
  }
}
