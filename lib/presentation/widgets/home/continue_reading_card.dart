import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
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
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  hasLastRead ? Icons.menu_book : Icons.history,
                  color: Colors.white,
                  size: 24.sp,
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: "Amiri",
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hasLastRead ? resumeText : noActivityDescription,
                      style: TextStyle(
                        fontSize: 12.sp,
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
                    size: 20.sp,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
