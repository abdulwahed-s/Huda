import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/l10n/app_localizations.dart';

class PermissionSetupWidget extends StatelessWidget {
  final MiqaatLockPermissions permissions;
  final VoidCallback onRefresh;

  const PermissionSetupWidget({
    super.key,
    required this.permissions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    const warningColor = Color(0xFFF59E0B);
    final warningBg =
        isDark ? warningColor.withValues(alpha: 0.08) : const Color(0xFFFFFBEB);
    final warningBorder =
        isDark ? warningColor.withValues(alpha: 0.25) : const Color(0xFFFDE68A);

    return Container(
      decoration: BoxDecoration(
        color: warningBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: warningBorder, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: warningColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        warningColor,
                        warningColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: warningColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.permissionsRequired,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color:
                              isDark ? Colors.white : const Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.permissionsRequiredDescription,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark
                              ? theme.hintColor
                              : const Color(0xFFB45309),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                if (Platform.isAndroid) ...[
                  _buildPermissionItem(
                    context: context,
                    icon: Icons.accessibility_new_rounded,
                    title: l10n.accessibilityService,
                    description: l10n.accessibilityServiceDescription,
                    isGranted: permissions.accessibilityEnabled,
                    onTap: () => _showAccessibilityDialog(context),
                  ),
                  SizedBox(height: 10.h),
                  _buildPermissionItem(
                    context: context,
                    icon: Icons.layers_rounded,
                    title: l10n.overlayPermission,
                    description: l10n.overlayPermissionDescription,
                    isGranted: permissions.overlayPermissionGranted,
                    onTap: () => context
                        .read<MiqaatLockCubit>()
                        .requestOverlayPermission(),
                  ),
                ] else if (Platform.isIOS) ...[
                  _buildPermissionItem(
                    context: context,
                    icon: Icons.hourglass_bottom_rounded,
                    title: l10n.screenTimeAccess,
                    description: l10n.screenTimeAccessDescription,
                    isGranted: permissions.screenTimeAuthorized,
                    onTap: () => context
                        .read<MiqaatLockCubit>()
                        .requestScreenTimeAuthorization(),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
                label: Text(
                  l10n.checkPermissions,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? warningColor : const Color(0xFF92400E),
                  backgroundColor: isDark
                      ? warningColor.withValues(alpha: 0.1)
                      : warningColor.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFFF59E0B);
    const darkAccent = Color(0xFFD97706);
    final l10n = AppLocalizations.of(context)!;

    final dialogBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final subtleBg =
        isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFFFBEB);
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFDE68A);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: isDark ? 0 : 8,
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, darkAccent],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.accessibility_new_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.accessibilityServiceRequiredDialogTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: isDark ? Colors.white : const Color(0xFF78350F),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      dividerColor.withValues(alpha: 0),
                      dividerColor,
                      dividerColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.accessibilityServiceRequiredDialogDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: subtleBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: dividerColor, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? accentColor.withValues(alpha: 0.15)
                            : accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: isDark ? accentColor : darkAccent,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        l10n.accessibilityServiceRequiredDialogPrivacy,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color:
                              isDark ? Colors.white60 : const Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<MiqaatLockCubit>().openAccessibilitySettings();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.agree,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white54 : Colors.black45,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final grantedColor = const Color(0xFF10B981);
    final pendingColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final grantedBg = isDark
        ? grantedColor.withValues(alpha: 0.1)
        : grantedColor.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isGranted ? grantedBg : pendingColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isGranted
                  ? grantedColor.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE5E7EB)),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isGranted
                      ? grantedColor.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : icon,
                  color: isGranted ? grantedColor : theme.hintColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: isGranted
                            ? grantedColor
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.hintColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              if (isGranted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: grantedColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: grantedColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
