import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 16,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: 32.sp,
                color: Colors.red.shade600,
              ),
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              AppLocalizations.of(context)!.exitDialog,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: "Amiri",
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            SizedBox(height: 12.h),

            // Content
            Text(
              AppLocalizations.of(context)!.exitConfirmation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: "Amiri",
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),

            SizedBox(height: 24.h),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: "Amiri",
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop(true);
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.red.withValues(alpha: 0.3),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        Colors.red.shade700.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.yes,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: "Amiri",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}