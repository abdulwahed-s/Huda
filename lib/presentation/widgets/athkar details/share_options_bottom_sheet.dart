import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_option.dart';

class ShareOptionsBottomSheet extends StatelessWidget {
  final bool isGeneratingImage;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  const ShareOptionsBottomSheet({
    super.key,
    required this.isGeneratingImage,
    required this.onShareText,
    required this.onShareImage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppLocalizations.of(context)!.shareDhikr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ShareOption(
                  icon: Icons.text_fields,
                  title: AppLocalizations.of(context)!.shareAsText,
                  isLoading: false,
                  onTap: onShareText,
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ShareOption(
                  icon: Icons.image,
                  title: isGeneratingImage
                      ? AppLocalizations.of(context)!.generatingImage
                      : AppLocalizations.of(context)!.shareAsImage,
                  isLoading: isGeneratingImage,
                  onTap: onShareImage,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
