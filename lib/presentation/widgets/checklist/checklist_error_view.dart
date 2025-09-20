import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../l10n/app_localizations.dart';

class ChecklistErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ChecklistErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: colors.accent),
          SizedBox(height: 12.h),
          Text('Error: $message', style: TextStyle(fontSize: 14.sp, fontFamily: "Amiri")),
          SizedBox(height: 12.h),
          ElevatedButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.retry)),
        ],
      ),
    );
  }
}
