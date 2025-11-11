import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/presentation/widgets/hadith_details/empty_hadith_state.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_card.dart';
import 'package:huda/presentation/widgets/hadith_details/pagination_controls.dart';

class HadithList extends StatelessWidget {
  final HadithDetailsModel hadithDetail;
  final bool isDark;
  final String chapterNumber;
  final String bookName;
  final String chapterName;

  const HadithList({
    super.key,
    required this.hadithDetail,
    required this.isDark,
    required this.chapterNumber,
    required this.bookName,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    return hadithDetail.data!.isEmpty
        ? EmptyHadithState(isDark: isDark)
        : Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: hadithDetail.data!.length,
                    itemBuilder: (context, index) {
                      final hadith = hadithDetail.data![index];
                      return HadithCard(
                        hadith: hadith,
                        isDark: isDark,
                        chapterName: chapterName,
                      );
                    },
                  ),
                ),
                PaginationControls(
                  currentPage: hadithDetail.previous == null
                      ? 1
                      : hadithDetail.previous! + 1,
                  lastPage: hadithDetail.total! > hadithDetail.limit!
                      ? (hadithDetail.total! / hadithDetail.limit!).ceil()
                      : 1,
                  isDark: isDark,
                  chapterNumber: chapterNumber,
                  bookName: bookName,
                ),
              ],
            ),
          );
  }
}
