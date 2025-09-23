import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'quran_search_bar.dart';

class QuranAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onSearchClear;

  const QuranAppBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.onSearchClear,
  });

  @override
  Size get preferredSize => Size.fromHeight(120.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 120.h,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    context.primaryColor.withValues(alpha: 0.9),
                    context.primaryColor.withValues(alpha: 0.7),
                  ]
                : [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8),
                  ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25.r),
            bottomRight: Radius.circular(25.r),
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row with title and icon
                SizedBox(
                  height: 36.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Material(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.white.withValues(alpha: 0.2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.quranSurahs,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Theme toggle button
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                // Search bar
                QuranSearchBar(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onClear: onSearchClear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
