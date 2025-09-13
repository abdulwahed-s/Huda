import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final BookmarkModel bookmark;
  final bool isDark;
  final VoidCallback onDelete;

  const DeleteConfirmationDialog({
    super.key,
    required this.bookmark,
    required this.isDark,
    required this.onDelete,
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
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.r),
          SizedBox(width: 12.w),
          Text(
            AppLocalizations.of(context)!.deleteBookmark,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.deleteBookmarkConfirmation,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontFamily: 'Amiri',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontFamily: 'Amiri',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.delete,
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

