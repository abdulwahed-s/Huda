import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/athkar/athkar_card.dart';
import 'package:huda/presentation/widgets/athkar/empty_state.dart';
import 'package:huda/presentation/widgets/athkar/results_count.dart';
import 'package:huda/presentation/widgets/athkar/stats_card.dart';

class LoadedStateContent extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final List<dynamic> athkarList;
  final String searchQuery;

  const LoadedStateContent({
    super.key,
    required this.fadeAnimation,
    required this.athkarList,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final filteredList = searchQuery.isEmpty
        ? athkarList
        : athkarList.where((item) {
            final query = searchQuery.toLowerCase();
            return item.titleAr.toLowerCase().contains(query) ||
                item.titleEn.toLowerCase().contains(query);
          }).toList();

    if (filteredList.isEmpty) {
      return const EmptyState();
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Statistics card
            if (searchQuery.isEmpty) StatsCard(totalCount: athkarList.length),

            // Results count
            if (searchQuery.isNotEmpty)
              ResultsCount(count: filteredList.length),

            // Athkar list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                return AthkarCard(
                  item: filteredList[index],
                  index: index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
