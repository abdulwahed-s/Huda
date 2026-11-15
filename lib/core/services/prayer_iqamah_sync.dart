import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/prayer_iqamah_settings.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';

abstract final class PrayerIqamahSync {
  static Future<void> publish(PrayerIqamahSettings settings) async {
    await Future.wait([
      PrayerWidgetService.publishIqamah(settings),
      WindowsPrayerTaskbarBridge.publishIqamah(settings),
      LinuxPrayerTrayBridge.publishIqamah(settings),
    ]);
  }
}
