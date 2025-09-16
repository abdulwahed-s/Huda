import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/presentation/widgets/books/offline_book_card.dart';
import 'package:huda/presentation/widgets/books/offline_status_widget.dart';

class BooksOfflineWidget extends StatelessWidget {
  final BooksOfflineLoaded state;
  final bool isDark;
  final VoidCallback onRetry;

  const BooksOfflineWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => OfflineBookCard(
                book: state.offlineBooks[index],
                isDark: isDark,
              ),
              childCount: state.offlineBooks.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: OfflineStatusWidget(
            count: state.offlineBooks.length,
            isDark: isDark,
            onRetry: onRetry,
          ),
        ),
      ],
    );
  }
}
