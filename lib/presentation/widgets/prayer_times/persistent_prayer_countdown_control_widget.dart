import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';

class PersistentPrayerCountdownControlWidget extends StatefulWidget {
  const PersistentPrayerCountdownControlWidget({super.key});

  @override
  State<PersistentPrayerCountdownControlWidget> createState() =>
      _PersistentPrayerCountdownControlWidgetState();
}

class _PersistentPrayerCountdownControlWidgetState
    extends State<PersistentPrayerCountdownControlWidget> {
  late PersistentPrayerCountdownService _countdownService;

  @override
  void initState() {
    super.initState();
    _countdownService = getIt<PersistentPrayerCountdownService>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? Colors.grey[800]!.withValues(alpha: 0.8) : Colors.white,
              isDark
                  ? Colors.grey[850]!.withValues(alpha: 0.9)
                  : Colors.grey[50]!,
            ],
          ),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purple.shade300],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .persistentPrayerCountdown,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: "Amiri",
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          AppLocalizations.of(context)!
                              .persistentPrayerCountdownDescription,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontFamily: "Amiri",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Status indicator section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _countdownService.isRunning
                      ? [
                          Colors.green.withValues(alpha: 0.1),
                          Colors.green.withValues(alpha: 0.05)
                        ]
                      : [
                          Colors.red.withValues(alpha: 0.1),
                          Colors.red.withValues(alpha: 0.05)
                        ],
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: _countdownService.isRunning
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: _countdownService.isRunning
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_countdownService.isRunning
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _countdownService.isRunning ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _countdownService.isRunning
                              ? AppLocalizations.of(context)!.active
                              : AppLocalizations.of(context)!.stopped,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _countdownService.isRunning
                                ? Colors.green
                                : Colors.red,
                            fontFamily: "Amiri",
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _countdownService.isRunning
                              ? AppLocalizations.of(context)!
                                  .persistentPrayerCountdownRunning
                              : AppLocalizations.of(context)!
                                  .persistentPrayerCountdownStopped,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                            fontFamily: "Amiri",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: (_countdownService.isRunning
                              ? Colors.green
                              : Colors.red)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _countdownService.isRunning ? "ON" : "OFF",
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: _countdownService.isRunning
                            ? Colors.green
                            : Colors.red,
                        fontFamily: "Amiri",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Control buttons section
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withValues(alpha: 0.3)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.control_camera,
                        color: Colors.grey[600],
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        AppLocalizations.of(context)!
                            .persistentPrayerCountdownServiceControls,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          fontFamily: "Amiri",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildControlButton(
                          label: AppLocalizations.of(context)!.start,
                          icon: Icons.play_arrow,
                          color: Colors.green,
                          isEnabled: !_countdownService.isRunning,
                          onPressed: _startService,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildControlButton(
                          label: AppLocalizations.of(context)!.stop,
                          icon: Icons.stop,
                          color: Colors.red,
                          isEnabled: _countdownService.isRunning,
                          onPressed: _stopService,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  SizedBox(
                    width: double.infinity,
                    child: _buildControlButton(
                      label: AppLocalizations.of(context)!.restart,
                      icon: Icons.refresh,
                      color: Colors.orange,
                      isEnabled: true,
                      onPressed: _restartService,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Information section
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .persistentNotificationInfoTitle,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontFamily: "Amiri",
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          AppLocalizations.of(context)!
                              .persistentNotificationInfo,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue[600],
                            height: 1.3,
                            fontFamily: "Amiri",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 14.sp),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          fontFamily: "Amiri",
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey[300],
        foregroundColor: isEnabled ? Colors.white : Colors.grey[600],
        disabledBackgroundColor: Colors.grey[300],
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        elevation: isEnabled ? 2 : 0,
        shadowColor: color.withValues(alpha: 0.3),
      ),
    );
  }

  Future<void> _startService() async {
    try {
      await _countdownService.startPersistentCountdown();
      setState(() {});
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.persistentCountdownStarted,
            Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.failedToStart(e.toString()),
            Colors.red);
      }
    }
  }

  Future<void> _stopService() async {
    try {
      await _countdownService.stopPersistentCountdown();
      setState(() {});
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.persistentCountdownStopped,
            Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.failedToStop(e.toString()),
            Colors.red);
      }
    }
  }

  Future<void> _restartService() async {
    try {
      await _countdownService.restart();
      setState(() {});
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)!.persistentCountdownRestarted,
            Colors.blue);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)!.failedToRestart(e.toString()),
            Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getSnackBarIcon(color),
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSnackBarTitle(color),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: "Amiri",
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: "Amiri",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 8,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.ok,
            textColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  IconData _getSnackBarIcon(Color color) {
    if (color == Colors.green) {
      return Icons.check_circle;
    } else if (color == Colors.red) {
      return Icons.error;
    } else if (color == Colors.orange) {
      return Icons.warning;
    } else if (color == Colors.blue) {
      return Icons.refresh;
    }
    return Icons.info;
  }

  String _getSnackBarTitle(Color color) {
    if (color == Colors.green) {
      return AppLocalizations.of(context)!.success;
    } else if (color == Colors.red) {
      return AppLocalizations.of(context)!.error;
    } else if (color == Colors.orange) {
      return AppLocalizations.of(context)!.warning;
    } else if (color == Colors.blue) {
      return AppLocalizations.of(context)!.info;
    }
    return AppLocalizations.of(context)!.notification;
  }
}
