import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/core/utils/responsive_utils.dart';

class ContinueReadingCard extends StatelessWidget {
  final bool hasLastRead;
  final VoidCallback? onTap;
  final String continueText;
  final String noActivityText;
  final String resumeText;
  final String noActivityDescription;

  const ContinueReadingCard({
    super.key,
    required this.hasLastRead,
    this.onTap,
    required this.continueText,
    required this.noActivityText,
    required this.resumeText,
    required this.noActivityDescription,
  });

  @override
  Widget build(BuildContext context) {
    final padding =
        context.responsive(mobile: 20.w, tablet: 24.w, desktop: 32.w);
    final iconPadding =
        context.responsive(mobile: 12.w, tablet: 16.w, desktop: 20.w);
    final mainIconSize =
        context.responsive(mobile: 24.sp, tablet: 32.sp, desktop: 40.sp);
    final titleSize =
        context.responsive(mobile: 16.sp, tablet: 20.sp, desktop: 24.sp);
    final subtitleSize =
        context.responsive(mobile: 12.sp, tablet: 14.sp, desktop: 16.sp);
    final arrowIconSize =
        context.responsive(mobile: 20.sp, tablet: 24.sp, desktop: 28.sp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasLastRead
                  ? [Colors.green.shade500, Colors.green.shade700]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: (hasLastRead ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  hasLastRead ? Icons.menu_book : Icons.history,
                  color: Colors.white,
                  size: mainIconSize,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLastRead ? continueText : noActivityText,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: "Amiri",
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hasLastRead ? resumeText : noActivityDescription,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: "Amiri",
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLastRead)
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(40, 40),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: arrowIconSize,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
