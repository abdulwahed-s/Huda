import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FrequencyDialog {
  static Future<void> show(BuildContext context, int currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: const Icon(Icons.repeat, color: Colors.blue),
            ),
            SizedBox(width: 10.w),
            Text(
              AppLocalizations.of(context)!.athkarFrequency,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.howOftenReceiveAthkar,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Amiri',
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.minutes,
                hintText: AppLocalizations.of(context)!.minutesExample,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                suffixText: AppLocalizations.of(context)!.minutesUnit,
                prefixIcon: const Icon(Icons.access_time),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.blue),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.recommendedMinutes,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 10 && value <= 1440) {
                final cubit = context.read<NotificationsCubit>();
                cubit.setContext(context);
                cubit.setRandomAthkarFrequency(value);
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.validNumberMinutes,
                      style: const TextStyle(fontFamily: 'Amiri'),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.save,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
        ],
      ),
    );
  }
}
