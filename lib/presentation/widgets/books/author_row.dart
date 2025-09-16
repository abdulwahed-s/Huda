import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AuthorRow extends StatelessWidget {
  final String author;

  const AuthorRow({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.person_rounded,
          size: 16.sp,
          color: isDark
              ? context.darkText.withValues(alpha: 0.6)
              : context.lightText.withValues(alpha: 0.6),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            author,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark
                  ? context.darkText.withValues(alpha: 0.6)
                  : context.lightText.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
