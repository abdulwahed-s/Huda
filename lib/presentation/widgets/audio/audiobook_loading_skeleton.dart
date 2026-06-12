import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:huda/presentation/widgets/audio/audiobook_top_bar.dart';

class AudiobookLoadingSkeleton extends StatelessWidget {
  final bool isDark;

  const AudiobookLoadingSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final shimmerHighlight =
        isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return SafeArea(
      child: Column(
        children: [
          AudiobookTopBar(isDark: isDark),
          SizedBox(height: 16.h),
          Center(
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Container(
                width: 240.w,
                height: 240.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Shimmer.fromColors(
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
            child: Column(
              children: [
                Container(
                  width: 180.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: 120.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShimmerCircle(size: 30.w),
                  _ShimmerCircle(size: 42.w),
                  _ShimmerCircle(size: 72.w),
                  _ShimmerCircle(size: 42.w),
                  _ShimmerCircle(size: 30.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double size;

  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
