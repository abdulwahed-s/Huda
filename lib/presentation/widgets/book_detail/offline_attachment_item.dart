import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class OfflineAttachmentItem extends StatelessWidget {
  final dynamic attachment;
  final VoidCallback onTap;

  const OfflineAttachmentItem({
    super.key,
    required this.attachment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                attachment.extensionType == 'PDF'
                    ? Icons.picture_as_pdf_rounded
                    : Icons.file_present_rounded,
                color: context.primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        attachment.extensionType,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '• ${attachment.size}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16.sp,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: context.primaryColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
