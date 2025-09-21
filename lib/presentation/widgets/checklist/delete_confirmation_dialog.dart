import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/checklist_item.dart';
import '../../../l10n/app_localizations.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            AppLocalizations.of(context)!.deleteTask,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: "Amiri"),
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10.r)),
        child: Text(
          '${AppLocalizations.of(context)!.deleteTaskConfirmation} "${item.title}"؟',
          style: TextStyle(fontSize: 14.sp, fontFamily: "Amiri"),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12.sp, fontFamily: "Amiri"),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, fontFamily: "Amiri"),
          ),
        ),
      ],
    );
  }
}
