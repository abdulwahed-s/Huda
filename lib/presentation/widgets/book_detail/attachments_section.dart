import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/book_detail/attachment_item.dart';

class AttachmentsSection extends StatelessWidget {
  final List<dynamic> attachments;
  final Function(dynamic) onAttachmentTap;

  const AttachmentsSection({
    super.key,
    required this.attachments,
    required this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              color: context.primaryColor,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)!.attachments,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                color: context.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.03),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                for (int index = 0; index < attachments.length; index++) ...[
                  AttachmentItem(
                    attachment: attachments[index],
                    onTap: () => onAttachmentTap(attachments[index]),
                  ),
                  if (index < attachments.length - 1)
                    Divider(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
