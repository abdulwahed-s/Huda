import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AttachmentItem extends StatelessWidget {
  final dynamic attachment;
  final VoidCallback onTap;

  const AttachmentItem({
    super.key,
    required this.attachment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          attachment.extensionType == 'PDF'
              ? Icons.picture_as_pdf_rounded
              : Icons.file_present_rounded,
          color: context.primaryColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        attachment.description,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
          fontFamily: 'Amiri',
        ),
      ),
      subtitle: Text(
        attachment.extensionType,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        onPressed: onTap,
        icon: Icon(
          attachment.extensionType == 'PDF'
              ? Icons.open_in_new_rounded
              : Icons.download_rounded,
          color: context.primaryColor,
          size: 20.sp,
        ),
      ),
    );
  }
}
