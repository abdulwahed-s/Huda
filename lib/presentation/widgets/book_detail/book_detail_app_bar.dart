import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookDetailAppBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onSharePressed;

  const BookDetailAppBar({
    super.key,
    required this.title,
    required this.isDark,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80.h,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDark ? Colors.white : const Color(0xFF2C2C2C),
          size: 22.sp,
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56.w, bottom: 16.h, right: 70.w),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSharePressed,
          icon: Icon(
            Icons.share_rounded,
            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
            size: 22.sp,
          ),
        ),
      ],
    );
  }
}
