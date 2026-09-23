import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart'
    show PrayerCountdownTaskHandler;

class SalahCountdownTaskHandler extends PrayerCountdownTaskHandler {}

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
