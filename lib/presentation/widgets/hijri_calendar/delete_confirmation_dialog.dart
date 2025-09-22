import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final HijriEvent event;
  final VoidCallback onDelete;

  const DeleteConfirmationDialog({
    super.key,
    required this.event,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20.w),
          SizedBox(width: 6.w),
          Text(
            AppLocalizations.of(context)!.deleteEvent,
            style: TextStyle(
              fontSize: 16.sp,
              fontFamily: "Amiri",
            ),
          ),
        ],
      ),
      content: Text(
          '${AppLocalizations.of(context)!.deleteConfirmation} "${event.title}"?',
          style: TextStyle(fontSize: 12.sp)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: "Amiri",
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onDelete,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontFamily: "Amiri",
            ),
          ),
        ),
      ],
    );
  }
}