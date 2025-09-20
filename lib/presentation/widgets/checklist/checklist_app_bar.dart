import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class ChecklistAppBar extends StatelessWidget {
  final VoidCallback onTodayPressed;
  final bool isDark;

  const ChecklistAppBar({
    super.key,
    required this.onTodayPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.primary,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Material(
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.white.withValues(alpha: 0.2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.islamicChecklistTitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colors.darkText : Colors.white,
                    fontFamily: "Amiri",
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.today,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                  onPressed: onTodayPressed,
                  tooltip: AppLocalizations.of(context)!.backToToday,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
