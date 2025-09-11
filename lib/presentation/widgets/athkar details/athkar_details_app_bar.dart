import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AthkarDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final ColorScheme colorScheme;

  const AthkarDetailsAppBar({
    super.key,
    required this.title,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.primary,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}