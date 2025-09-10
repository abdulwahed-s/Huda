import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class AthkarCard extends StatelessWidget {
  final dynamic item;
  final int index;

  const AthkarCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/athkarDetail', arguments: {
            'athkarId': item.id.toString(),
            'title': item.titleAr as String,
            'titleEn': item.titleEn as String,
          });
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? context.darkTabBackground : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arabic title
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  item.titleAr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.darkText : context.lightText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),

              // Divider
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      context.primaryColor.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // English title
              Text(
                item.titleEn,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: 'Tajawal',
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
              ),

              SizedBox(height: 12.h),

              // Action indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.clickForDetails,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'Tajawal',
                        color: context.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: context.primaryColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
