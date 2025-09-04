import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:huda/l10n/app_localizations.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/services/prayer_countdown_service.dart';

class PrayerCountdownControlWidget extends StatefulWidget {
  const PrayerCountdownControlWidget({super.key});

  @override
  State<PrayerCountdownControlWidget> createState() =>
      _PrayerCountdownControlWidgetState();
}

class _PrayerCountdownControlWidgetState
    extends State<PrayerCountdownControlWidget> {
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prayer Countdown Notification (Foreground Service)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_isServiceRunning ? "Running" : "Stopped"}',
              style: TextStyle(
                color: _isServiceRunning ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isServiceRunning ? null : _startService,
                    child: Text(AppLocalizations.of(context)!.start),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isServiceRunning ? null : _stopService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.stop),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _restartService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.restart),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startService() async {
    try {
      await getIt<PrayerCountdownService>().startCountdownNotification();
      await _checkServiceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.prayerCountdownStarted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedStartService(e.toString()))),
        );
      }
    }
  }

  Future<void> _stopService() async {
    try {
      await getIt<PrayerCountdownService>().stopCountdownNotification();
      await _checkServiceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.prayerCountdownStopped)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedStopService(e.toString()))),
        );
      }
    }
  }

  Future<void> _restartService() async {
    try {
      await getIt<PrayerCountdownService>().stopCountdownNotification();
      await Future.delayed(const Duration(milliseconds: 500));
      await getIt<PrayerCountdownService>().startCountdownNotification();
      await _checkServiceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.prayerCountdownRestarted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedRestartService(e.toString()))),
        );
      }
    }
  }
}
