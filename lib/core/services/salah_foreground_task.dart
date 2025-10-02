import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalahCountdownTaskHandler extends TaskHandler {
  PrayerTimes? _prayerTimes;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      await _initializePrayerTimes();
    } catch (e) {
       // todo Add error handling here
    }
  }

  Future<void> _initializePrayerTimes() async {
    try {
      
      final prefs = await SharedPreferences.getInstance();

      
      final latStr = prefs.getString('latitude');
      final lonStr = prefs.getString('longitude');

      if (latStr != null && lonStr != null) {
        final lat = double.parse(latStr);
        final lon = double.parse(lonStr);

        final coordinates = Coordinates(lat, lon);
        final params = CalculationMethod.karachi.getParameters();
        params.madhab = Madhab.shafi;

        final date = DateComponents.from(DateTime.now());
        _prayerTimes = PrayerTimes(coordinates, date, params);
      } else {}
    } catch (e) {
       // todo Add error handling here
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    try {
      if (_prayerTimes == null) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Prayer Times',
          notificationText: 'Loading prayer times...',
        );
        return;
      }

      final now = DateTime.now();
      final nextPrayer = _prayerTimes!.nextPrayer();
      final nextTime = _prayerTimes!.timeForPrayer(nextPrayer);

      if (nextTime != null) {
        final diff = nextTime.difference(now);

        if (diff.isNegative) {
          
          _initializePrayerTimes();
          return;
        }

        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        final s = diff.inSeconds.remainder(60);

        String prayerName = _getPrayerDisplayName(nextPrayer);
        String timeText = _formatCountdown(h, m, s);

        FlutterForegroundTask.updateService(
          notificationTitle: 'Next $prayerName in $timeText',
          notificationText: 'At ${_formatTime(nextTime)}',
        );
      } else {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Prayer Times',
          notificationText: 'Error calculating next prayer',
        );
      }
    } catch (e) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Prayer Times',
        notificationText: 'Error updating countdown',
      );
    }
  }

  String _getPrayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }

  String _formatCountdown(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

Future<void> startSalahCountdownService() async {
  
  if (await FlutterForegroundTask.isRunningService) {
    return;
  }

  try {
    
    await FlutterForegroundTask.startService(
      notificationTitle: 'Prayer Times',
      notificationText: 'Initializing countdown...',
      callback: startCallback,
    );
  } catch (e) {
    // todo Add error handling here
  }
}

Future<void> stopSalahCountdownService() async {
  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.stopService();
  }
}

Future<void> startCallback() async {
  FlutterForegroundTask.setTaskHandler(SalahCountdownTaskHandler());
}
