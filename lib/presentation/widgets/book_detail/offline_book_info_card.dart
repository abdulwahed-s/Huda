import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:intl/intl.dart';

class OfflineBookInfoCard extends StatelessWidget {
  final dynamic offlineBook;

  const OfflineBookInfoCard({
    super.key,
    required this.offlineBook,
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
            context.primaryColor.withValues(alpha: 0.03),
            context.primaryColor.withValues(alpha: 0.08),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download_done_rounded,
                      size: 16.sp,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Downloaded',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Downloaded on ${DateFormat('dd/MM/yyyy').format(offlineBook.downloadedAt)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (offlineBook.preparedBy.isNotEmpty)
            ...offlineBook.preparedBy.map((preparedBy) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getIconForType(preparedBy.type),
                      size: 16.sp,
                      color: context.primaryColor.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preparedBy.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  context.primaryColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (preparedBy.title != null)
                            Text(
                              preparedBy.title!,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
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
