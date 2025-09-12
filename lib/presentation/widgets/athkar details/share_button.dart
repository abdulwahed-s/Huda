import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShareButton extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onShare;

  const ShareButton({
    super.key,
    required this.colorScheme,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        onPressed: onShare,
        icon: Icon(
          Icons.share_outlined,
          color: colorScheme.primary,
          size: 20.w,
        ),
        padding: EdgeInsets.all(8.w),
        constraints: BoxConstraints(
          minWidth: 40.w,
          minHeight: 40.w,
        ),
      ),
    );
  }
}
