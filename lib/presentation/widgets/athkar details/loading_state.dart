import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class LoadingState extends StatelessWidget {
  final ColorScheme colorScheme;

  const LoadingState({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)!.loading,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
