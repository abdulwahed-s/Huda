import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class BooksAppBar extends StatelessWidget {
  final bool isDark;

  const BooksAppBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black,
      ),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: false,
      expandedHeight: 140.h,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(
          start: 50.w,
          bottom: 5.h,
        ),
        title: Text(
          AppLocalizations.of(context)!.library,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            color: isDark ? context.darkText : context.lightText,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? context.darkCardBackground : Colors.white,
                    isDark ? Colors.grey[900]! : Colors.grey[50]!,
                  ],
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -30.w,
              top: -10.h,
              child: Icon(
                Icons.menu_book_rounded,
                size: 140.sp,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.03),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
