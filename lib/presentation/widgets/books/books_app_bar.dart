import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class BooksAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;

  const BooksAppBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black,
      ),
      surfaceTintColor: Colors.transparent,
      title: Text(
        AppLocalizations.of(context)!.library,
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Amiri',
          color: isDark ? context.darkText : context.lightText,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16.w, left: 16.w),
          child: CircleAvatar(
            backgroundColor: context.primaryExtraLightColor,
            child: Icon(
              Icons.menu_book_rounded,
              color: context.primaryColor,
              size: 20.sp,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
