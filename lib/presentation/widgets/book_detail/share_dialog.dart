import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ShareDialog extends StatelessWidget {
  final String title;
  final VoidCallback onShareAsPdf;
  final VoidCallback onShareAsMessage;

  const ShareDialog({
    super.key,
    required this.title,
    required this.onShareAsPdf,
    required this.onShareAsMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.share_rounded, color: context.primaryColor),
          SizedBox(width: 12.w),
          const Text(
            'Share Book',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'How would you like to share "$title"?',
        style: const TextStyle(fontFamily: 'Amiri'),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogButton(
              context: context,
              icon: Icons.picture_as_pdf_rounded,
              label: 'Share as PDF',
              onTap: onShareAsPdf,
            ),
            SizedBox(height: 8.h),
            _buildDialogButton(
              context: context,
              icon: Icons.message_rounded,
              label: 'Share in Message',
              onTap: onShareAsMessage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.primaryColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.primaryColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
