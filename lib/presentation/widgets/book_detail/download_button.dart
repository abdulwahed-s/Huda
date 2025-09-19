import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class DownloadButton extends StatelessWidget {
  final bool isBookDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback? onPressed;
  final String label;

  const DownloadButton({
    super.key,
    required this.isBookDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isBookDownloaded
                ? Colors.green
                : isDownloading
                    ? context.primaryColor.withValues(alpha: 0.5)
                    : context.primaryColor,
            width: 1.5),
        color: isBookDownloaded ? Colors.green.withValues(alpha: 0.1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              if (isDownloading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        stops: [downloadProgress, downloadProgress],
                        colors: [
                          context.primaryColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isDownloading)
                      SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: downloadProgress,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primaryColor,
                          ),
                        ),
                      )
                    else
                      Icon(
                        isBookDownloaded
                            ? Icons.download_done_rounded
                            : Icons.download_rounded,
                        color: isBookDownloaded
                            ? Colors.green
                            : onPressed != null
                                ? context.primaryColor
                                : context.primaryColor.withValues(alpha: 0.5),
                        size: 20.sp,
                      ),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: TextStyle(
                        color: isBookDownloaded
                            ? Colors.green
                            : onPressed != null
                                ? context.primaryColor
                                : context.primaryColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
