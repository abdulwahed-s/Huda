import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class AudioDetailSkeletonLoader extends StatelessWidget {
  final bool isDark;
  const AudioDetailSkeletonLoader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerBase =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;
    final shimmerHighlight =
        isDark ? Colors.white.withValues(alpha: 0.14) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 340.h,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 130.w,
                        height: 130.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _shimmerBar(200.w, 20.h),
                      SizedBox(height: 8.h),
                      _shimmerBar(120.w, 14.h),
                      SizedBox(height: 10.h),
                      _shimmerBar(80.w, 24.h, radius: 12.r),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _shimmerBar(double.infinity, 52.h, radius: 16.r)),
                      SizedBox(width: 12.w),
                      _shimmerBar(52.w, 52.h, radius: 16.r),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  _shimmerBar(120.w, 14.h),
                  SizedBox(height: 8.h),
                  _shimmerBar(double.infinity, 14.h),
                  SizedBox(height: 6.h),
                  _shimmerBar(double.infinity, 14.h),
                  SizedBox(height: 6.h),
                  _shimmerBar(200.w, 14.h),
                  SizedBox(height: 28.h),
                  _shimmerBar(100.w, 18.h),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 16.h),
                          child: Row(
                            children: [
                              _shimmerCircle(36.w),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _shimmerBar(double.infinity, 13.h),
                                    SizedBox(height: 6.h),
                                    _shimmerBar(80.w, 11.h),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              _shimmerCircle(26.w),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _shimmerBar(double width, double height, {double? radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 8),
      ),
    );
  }

  static Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
