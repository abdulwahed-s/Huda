import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';

class SamsungLockWidgetSetup extends StatefulWidget {
  const SamsungLockWidgetSetup({super.key});

  @override
  State<SamsungLockWidgetSetup> createState() => _SamsungLockWidgetSetupState();
}

class _SamsungLockWidgetSetupState extends State<SamsungLockWidgetSetup> {
  late final Future<bool> _showGuidance = _isSamsungTarget();

  Future<bool> _isSamsungTarget() async {
    if (!PlatformUtils.isAndroid) return false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      // This scopes setup guidance; it does not claim to detect picker eligibility.
      return info.manufacturer.toLowerCase() == 'samsung' &&
          info.version.sdkInt >= 36;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _showGuidance,
    builder: (context, snapshot) {
      if (snapshot.data != true) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context)!;
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: colors.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.samsungLockWidgetsTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                l10n.samsungLockWidgetsInstructions,
                style: TextStyle(fontSize: 13.sp, height: 1.5),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.samsungLockWidgetsHint,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
