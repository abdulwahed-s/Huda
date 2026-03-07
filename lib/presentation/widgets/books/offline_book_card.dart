import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';

class OfflineBookCard extends StatelessWidget {
  final dynamic book;
  final bool isDark;

  const OfflineBookCard({
    super.key,
    required this.book,
    required this.isDark,
  });

  Color _getBookColor() {
    final colors = [
      const Color(0xFF1E3A8A), // Deep Blue
      const Color(0xFF064E3B), // Forest Green
      const Color(0xFF4C1D95), // Royal Purple
      const Color(0xFF7F1D1D), // Crimson Red
      const Color(0xFF78350F), // Rich Amber/Brown
      const Color(0xFF0F172A), // Slate
    ];
    int hash = book.title.toString().hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bookColor = _getBookColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.r),
          bottomLeft: Radius.circular(4.r),
          topRight: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToBookDetail(context, book),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4.r),
            bottomLeft: Radius.circular(4.r),
            topRight: Radius.circular(12.r),
            bottomRight: Radius.circular(12.r),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.r),
                bottomLeft: Radius.circular(4.r),
                topRight: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bookColor.withValues(alpha: 0.8),
                  bookColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 14.w,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        bottomLeft: Radius.circular(4.r),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 3.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomRight: Radius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: 20.w, right: 12.w, top: 12.h, bottom: 12.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(
                              Icons.download_done_rounded,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              (book.sourceLanguage ?? '').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            book.title ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 2.h,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBookDetail(BuildContext context, dynamic book) {
    Navigator.pushNamed(
      context,
      AppRoute.bookDetail,
      arguments: {
        'bookId': book.id.toString(),
        'language': book.language.toString(),
        'title': book.title.toString(),
      },
    );
  }
}
