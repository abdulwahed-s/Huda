import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/common/app_shimmer.dart';

class AudiosLoadingWidget extends StatelessWidget {
  final bool isDark;

  const AudiosLoadingWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => AppShimmer(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: _ShimmerRow(isDark: isDark),
          ),
          childCount: 5,
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final bool isDark;
  const _ShimmerRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _ShimmerCassetteCard(isDark: isDark)),
          SizedBox(width: 16.w),
          Expanded(child: _ShimmerCassetteCard(isDark: isDark)),
        ],
      ),
    );
  }
}

class _ShimmerCassetteCard extends StatelessWidget {
  final bool isDark;
  const _ShimmerCassetteCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? Colors.grey[700]! : Colors.white;
    final soft = isDark ? Colors.grey[600]! : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.all(8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circle(8.w, fill),
              _circle(8.w, fill),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4.r)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
                  child: Column(
                    children: [
                      _rect(double.infinity, 10.h, fill),
                      SizedBox(height: 4.h),
                      _rect(double.infinity, 10.h, fill),
                      SizedBox(height: 4.h),
                      _rect(60.w, 10.h, fill),
                      SizedBox(height: 6.h),
                      _rect(80.w, 8.h, fill),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 62.h,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 14.h,
            margin: EdgeInsets.symmetric(horizontal: 18.w),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circle(8.w, fill),
              _circle(8.w, fill),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _rect(double width, double height, Color color) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3.r),
        ),
      );
}
