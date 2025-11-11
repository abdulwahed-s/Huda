import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class HadithStatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const HadithStatusBadge({
    super.key,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim().toLowerCase();

    final color = _getStatusColor(normalizedStatus);
    final translated = _getTranslatedStatus(context, normalizedStatus);

    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: color, width: 1.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            translated,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: "Amiri",
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String normalizedStatus) {
    if (normalizedStatus.contains('sahih')) {
      return Colors.green[600]!;
    } else if (normalizedStatus.contains('hasan')) {
      return Colors.orange[600]!;
    } else if (normalizedStatus.contains('da') ||
        normalizedStatus.contains('dai') ||
        normalizedStatus.contains('weak')) {
      return Colors.red[600]!;
    } else if (normalizedStatus.contains('mawdu') ||
        normalizedStatus.contains('fabricated')) {
      return Colors.red[800]!;
    } else if (normalizedStatus.contains('shadh') ||
        normalizedStatus.contains('munkar') ||
        normalizedStatus.contains('gharib')) {
      return Colors.blueGrey[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  String _getTranslatedStatus(BuildContext context, String normalizedStatus) {
    final t = AppLocalizations.of(context)!;

    if (normalizedStatus.contains('sahih') &&
        normalizedStatus.contains('hasan')) {
      return '${t.hasan} ${t.sahih}';
    } else if (normalizedStatus.contains('sahih in chain')) {
      return '${t.sahih} (${t.chain})';
    } else if (normalizedStatus.contains('hasan in chain')) {
      return '${t.hasan} (${t.chain})';
    } else if (normalizedStatus.contains('da') &&
        normalizedStatus.contains('chain')) {
      return '${t.daif} (${t.chain})';
    } else if (normalizedStatus.contains('sahih')) {
      return t.sahih;
    } else if (normalizedStatus.contains('hasan')) {
      return t.hasan;
    } else if (normalizedStatus.contains('da') ||
        normalizedStatus.contains('weak')) {
      return t.daif;
    } else if (normalizedStatus.contains('mawdu') ||
        normalizedStatus.contains('fabricated')) {
      return t.mawdu;
    } else if (normalizedStatus.contains('shadh')) {
      return t.shadh;
    } else if (normalizedStatus.contains('munkar')) {
      return t.munkar;
    } else if (normalizedStatus.contains('gharib')) {
      return t.gharib;
    } else {
      return status;
    }
  }
}
