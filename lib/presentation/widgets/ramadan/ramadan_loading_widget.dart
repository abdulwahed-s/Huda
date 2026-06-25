import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/common/app_shimmer.dart';

class RamadanLoadingWidget extends StatelessWidget {
  final bool isDark;

  const RamadanLoadingWidget({super.key, required this.isDark});

  Widget _buildSkeletonBox(double width, double height, {double? radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 8.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final cardColor = isDark ? Colors.white10 : Colors.black12;

    return AppShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                _buildSkeletonBox(56.r, 56.r, radius: 28.r),
                SizedBox(height: 14.h),
                _buildSkeletonBox(150.w, 24.h),
                SizedBox(height: 8.h),
                _buildSkeletonBox(60.w, 16.h),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      _buildSkeletonBox(42.r, 42.r, radius: 12.r),
                      SizedBox(height: 10.h),
                      _buildSkeletonBox(60.w, 14.h),
                      SizedBox(height: 8.h),
                      _buildSkeletonBox(80.w, 26.h),
                      SizedBox(height: 12.h),
                      _buildSkeletonBox(70.w, 20.h),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      _buildSkeletonBox(42.r, 42.r, radius: 12.r),
                      SizedBox(height: 10.h),
                      _buildSkeletonBox(60.w, 14.h),
                      SizedBox(height: 8.h),
                      _buildSkeletonBox(80.w, 26.h),
                      SizedBox(height: 12.h),
                      _buildSkeletonBox(70.w, 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSkeletonBox(34.r, 34.r, radius: 10.r),
                    SizedBox(width: 10.w),
                    _buildSkeletonBox(120.w, 18.h),
                  ],
                ),
                SizedBox(height: 18.h),
                _buildSkeletonBox(double.infinity, 10.h, radius: 6.r),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(40.w, 12.h),
                        SizedBox(height: 4.h),
                        _buildSkeletonBox(50.w, 16.h),
                      ],
                    ),
                    _buildSkeletonBox(80.w, 24.h, radius: 8.r),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSkeletonBox(40.w, 12.h),
                        SizedBox(height: 4.h),
                        _buildSkeletonBox(50.w, 16.h),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSkeletonBox(34.r, 34.r, radius: 10.r),
                    SizedBox(width: 10.w),
                    _buildSkeletonBox(100.w, 18.h),
                    const Spacer(),
                    _buildSkeletonBox(30.r, 30.r, radius: 15.r),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                        child: _buildSkeletonBox(double.infinity, 48.h,
                            radius: 12.r)),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: _buildSkeletonBox(double.infinity, 48.h,
                            radius: 12.r)),
                  ],
                ),
                SizedBox(height: 16.h),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        _buildSkeletonBox(32.w, 32.h, radius: 8.r),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBox(80.w, 14.h),
                              SizedBox(height: 4.h),
                              _buildSkeletonBox(60.w, 12.h),
                            ],
                          ),
                        ),
                        _buildSkeletonBox(24.r, 24.r, radius: 12.r),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
