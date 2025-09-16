import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class BookDescription extends StatelessWidget {
  final String description;
  final bool isDark;

  const BookDescription({
    super.key,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 14.sp,
        fontFamily: 'Amiri',
        color: isDark
            ? context.darkText.withValues(alpha: 0.8)
            : context.lightText.withValues(alpha: 0.7),
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
