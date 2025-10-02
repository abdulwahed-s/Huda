import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:huda/core/services/salah_foreground_task.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';

class PrayerCountdownService {
  static final PrayerCountdownService _instance =
      PrayerCountdownService._internal();
  factory PrayerCountdownService() => _instance;
  PrayerCountdownService._internal();

  StreamSubscription<NextPrayerCountdown>? _countdownSubscription;
  PrayerTimesCubit? _prayerTimesCubit;
  bool _isRunning = false;

  void initialize(PrayerTimesCubit prayerTimesCubit) {
    _prayerTimesCubit = prayerTimesCubit;
  }

  Future<void> startCountdownNotification() async {
    if (_isRunning) {
      debugPrint('Prayer countdown notification is already running');
      return;
    }

    if (_prayerTimesCubit == null) {
      debugPrint('Prayer times cubit not initialized');
      return;
    }

    try {
      await startSalahCountdownService();

      _countdownSubscription = _prayerTimesCubit!
          .getNextPrayerCountdown()
          .listen(_updateNotification);

      _isRunning = true;
      debugPrint('Prayer countdown notification started');
    } catch (e) {
      debugPrint('Error starting prayer countdown notification: $e');
    }
  }

  Future<void> stopCountdownNotification() async {
    if (!_isRunning) return;

    try {
      await _countdownSubscription?.cancel();
      await stopSalahCountdownService();
      _isRunning = false;
      debugPrint('Prayer countdown notification stopped');
    } catch (e) {
      debugPrint('Error stopping prayer countdown notification: $e');
    }
  }

  void _updateNotification(NextPrayerCountdown countdown) {
    if (!_isRunning) return;

    try {
      final h = countdown.duration.inHours;
      final m = countdown.duration.inMinutes.remainder(60);
      final s = countdown.duration.inSeconds.remainder(60);

      String timeText;
      if (h > 0) {
        timeText = '${h}h ${m}m ${s}s';
      } else if (m > 0) {
        timeText = '${m}m ${s}s';
      } else {
        timeText = '${s}s';
      }

      String title = 'Next ${countdown.prayerName} in $timeText';
      String body = 'Stay prepared for prayer time';

      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } catch (e) {
      debugPrint('Error updating notification: $e');
    }
  }

  bool get isRunning => _isRunning;

  Future<void> restart() async {
    if (_isRunning) {
      await stopCountdownNotification();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await startCountdownNotification();
  }

  void dispose() {
    stopCountdownNotification();
  }
}
