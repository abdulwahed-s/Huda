import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClipboardSnackbar {
  static void showCopySnackbar(
    BuildContext context,
    String text,
    AppLocalizations appLocalizations,
  ) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              appLocalizations.messageCopied,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}