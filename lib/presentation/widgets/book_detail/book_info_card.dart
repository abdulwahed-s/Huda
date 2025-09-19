import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class BookInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final List<dynamic> preparedBy;
  final String sectionTitle;

  const BookInfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.preparedBy,
    required this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.08),
            context.primaryColor.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: context.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Amiri',
              height: 1.5,
              color: Colors.grey[600],
            ),
          ),
          if (preparedBy.isNotEmpty) ...[
            SizedBox(height: 20.h),
            ...preparedBy.map((preparedBy) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _getIconForType(preparedBy.type),
                        size: 16.sp,
                        color: context.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        preparedBy.title ?? "Unknown",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'author':
        return Icons.person_rounded;
      case 'translator':
        return Icons.translate_rounded;
      case 'editor':
        return Icons.edit_rounded;
      case 'publisher':
        return Icons.business_rounded;
      case 'source':
        return Icons.source_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
