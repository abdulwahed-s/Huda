import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.loadingPreferences,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }
}

