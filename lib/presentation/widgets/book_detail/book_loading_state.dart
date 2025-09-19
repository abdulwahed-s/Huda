import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/book_detail/shimmer_loading.dart';

class BookLoadingState extends StatelessWidget {
  const BookLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          ShimmerContainer(height: 56.h, width: double.infinity),
          SizedBox(height: 16.h),
          ShimmerContainer(height: 48.h, width: double.infinity),
          SizedBox(height: 24.h),
          ShimmerCard(height: 200.h),
          SizedBox(height: 24.h),
          ShimmerCard(height: 120.h),
        ],
      ),
    );
  }
}
