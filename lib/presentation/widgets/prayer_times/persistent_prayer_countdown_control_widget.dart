import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = PrayerPalette.of(context);
    final running = _countdownService.isRunning;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 10.w, 8.h),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: colors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.persistentPrayerCountdown,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      running
                          ? l10n.persistentPrayerCountdownRunning
                          : l10n.persistentPrayerCountdownStopped,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: running ? colors.primary : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                excludeSemantics: true,
                toggled: running,
                label:
                    '${l10n.persistentPrayerCountdown}: '
                    '${running ? l10n.active : l10n.stopped}',
                child: Switch.adaptive(
                  value: running,
                  onChanged: (enable) =>
                      enable ? _startService() : _stopService(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.persistentNotificationInfo,
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.35,
              color: palette.muted,
            ),
          ),
          if (running)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _restartService,
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
                label: Text(l10n.restart),
              ),
            )
          else
            SizedBox(height: 6.h),
        ],
      ),
    );
  }

  Future<void> _startService() async {
    try {
      if (!await PermissionHandlers.requestNotificationPermission(context)) {
        return;
      }
      await _countdownService.startPersistentCountdown();
      setState(() {});
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.persistentCountdownStarted,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.failedToStart(e.toString()),
          HudaSnackBarKind.error,
        );
      }
    }
  }

  Future<void> _stopService() async {
    try {
      await _countdownService.stopPersistentCountdown();
      setState(() {});
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.persistentCountdownStopped,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.failedToStop(e.toString()),
          HudaSnackBarKind.error,
        );
      }
    }
  }

  Future<void> _restartService() async {
    try {
      if (!await PermissionHandlers.requestNotificationPermission(context)) {
        return;
      }
      await _countdownService.restart();
      setState(() {});
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.persistentCountdownRestarted,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.failedToRestart(e.toString()),
          HudaSnackBarKind.error,
        );
      }
    }
  }

  void _showSnackBar(String message, HudaSnackBarKind kind) {
    if (mounted) {
      HudaSnackBar.show(
        context,
        message: message,
        kind: kind,
        dismissible: kind == HudaSnackBarKind.error,
      );
    }
  }
}
