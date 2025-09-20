import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/checklist_item.dart';
import 'package:huda/l10n/app_localizations.dart';

class ChecklistItemCard extends StatelessWidget {
  final ChecklistItem item;
  final bool isCompleted;
  final bool isToday;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isDark;

  const ChecklistItemCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isToday,
    required this.onToggle,
    required this.onDelete,
    required this.isDark,
  });

  String _getItemTypeDisplayName(ChecklistItemType type, BuildContext context) {
    switch (type) {
      case ChecklistItemType.prayer:
        return AppLocalizations.of(context)!.itemTypePrayer;
      case ChecklistItemType.quran:
        return AppLocalizations.of(context)!.itemTypeQuran;
      case ChecklistItemType.athkar:
        return AppLocalizations.of(context)!.itemTypeAthkar;
      case ChecklistItemType.custom:
        return AppLocalizations.of(context)!.itemTypeCustom;
    }
  }

  String _getFrequencyDisplayName(
      RepetitionFrequency frequency, BuildContext context) {
    switch (frequency) {
      case RepetitionFrequency.daily:
        return AppLocalizations.of(context)!.frequencyDaily;
      case RepetitionFrequency.every2Days:
        return AppLocalizations.of(context)!.frequencyEvery2Days;
      case RepetitionFrequency.every3Days:
        return AppLocalizations.of(context)!.frequencyEvery3Days;
      case RepetitionFrequency.every4Days:
        return AppLocalizations.of(context)!.frequencyEvery4Days;
      case RepetitionFrequency.every5Days:
        return AppLocalizations.of(context)!.frequencyEvery5Days;
      case RepetitionFrequency.every6Days:
        return AppLocalizations.of(context)!.frequencyEvery6Days;
      case RepetitionFrequency.weekly:
        return AppLocalizations.of(context)!.frequencyWeekly;
    }
  }

  Color _getItemTypeColor(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.prayer:
        return const Color(0xFF2E7D32); // Islamic green
      case ChecklistItemType.quran:
        return const Color(0xFF1976D2); // Blue
      case ChecklistItemType.athkar:
        return const Color(0xFF7B1FA2); // Purple
      case ChecklistItemType.custom:
        return const Color(0xFFFF6F00); // Orange
    }
  }

  IconData _getItemTypeIcon(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.prayer:
        return Icons.mosque;
      case ChecklistItemType.quran:
        return Icons.menu_book;
      case ChecklistItemType.athkar:
        return Icons.favorite;
      case ChecklistItemType.custom:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = _getItemTypeColor(item.type);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? itemColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1.2.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          splashColor: itemColor.withValues(alpha: 0.2),
          onTap: isToday ? onToggle : null,
          child: CheckboxListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            title: Text(
              item.title,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.grey[100] : Colors.grey[800]),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: "Amiri",
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _getItemTypeDisplayName(item.type, context),
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Amiri",
                      ),
                    ),
                  ),
                  if (item.frequency != RepetitionFrequency.daily)
                    Padding(
                      padding: EdgeInsets.only(top: 3.h),
                      child: Text(
                        _getFrequencyDisplayName(item.frequency, context),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                          fontFamily: "Amiri",
                        ),
                      ),
                    ),
                ],
              ),
            ),
            value: isCompleted,
            onChanged: isToday ? (value) => onToggle() : null,
            activeColor: itemColor,
            checkColor: Colors.white,
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getItemTypeIcon(item.type),
                    color: itemColor,
                    size: 18.sp,
                  ),
                ),
                if (!item.isDefault && isToday)
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
