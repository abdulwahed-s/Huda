import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/search_result_model.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/presentation/widgets/quran_home/surah_card.dart';
import 'package:huda/presentation/widgets/quran_home/ayah_search_result_widget.dart';
import 'package:huda/presentation/widgets/quran_home/search_divider_widget.dart';

class SearchResultList extends StatelessWidget {
  final List<SearchResult> searchResults;
  final AnimationController animationController;
  final Function(QuranModel) onSurahTap;
  final Function(AyahSearchResult) onAyahTap;

  const SearchResultList({
    super.key,
    required this.searchResults,
    required this.animationController,
    required this.onSurahTap,
    required this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final result = searchResults[index];

        switch (result.type) {
          case SearchResultType.surah:
            return SurahCard(
              surah: result.surah!,
              animationController: animationController,
              onTap: () => onSurahTap(result.surah!),
            );
          case SearchResultType.ayah:
            return AyahSearchResultWidget(
              ayahResult: result.ayahResult!,
              onTap: () => onAyahTap(result.ayahResult!),
            );
          case SearchResultType.divider:
            return const SearchDividerWidget(title: 'الآيات');
        }
      },
    );
  }
}
