import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class NavigateConfirmationDialog extends StatelessWidget {
  final BookmarkModel bookmark;
  final bool isDark;
  final VoidCallback onConfirm;

  const NavigateConfirmationDialog({
    super.key,
    required this.bookmark,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(Icons.navigation, color: Colors.green, size: 24.r),
          SizedBox(width: 12.w),
          Text(
            AppLocalizations.of(context)!.goToVerse,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.navigateToVerseQuestion,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.book,
                  size: 16.r,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                SizedBox(width: 8.w),
                Text(
                  '${bookmark.surahName} ${bookmark.surahNumber}:${bookmark.ayahNumber}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.goToVerse,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Amiri',
            ),
          ),
        ),
      ],
    );
  }
}

