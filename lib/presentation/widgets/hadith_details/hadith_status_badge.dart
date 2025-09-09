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
    return Padding(
      padding: EdgeInsets.only(left: 20.0.w, right: 20.0.w, bottom: 20.0.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: _getStatusColor(status),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.0.w,
            vertical: 8.0.h,
          ),
          child: Text(
            _getTranslatedStatus(context, status),
            style: TextStyle(
              fontSize: 14.0.sp,
              fontFamily: "Amiri",
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sahih':
      case 'sahih':
        return Colors.green[600]!;
      case 'Da`eef':
      case 'da`eef':
        return Colors.red[600]!;
      case 'Hasan':
      case 'hasan':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getTranslatedStatus(BuildContext context, String status) {
    switch (status) {
      case 'Sahih':
      case 'sahih':
        return AppLocalizations.of(context)!.sahih;
      case 'Da`eef':
      case 'da`eef':
        return AppLocalizations.of(context)!.daif;
      case 'Hasan':
      case 'hasan':
        return AppLocalizations.of(context)!.hasan;
      default:
        return status;
    }
  }
}
