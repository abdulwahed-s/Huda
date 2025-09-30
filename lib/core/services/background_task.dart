import 'package:huda/core/services/notification_services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const String dailyTaskKey = "dailyPrayerNotificationTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == dailyTaskKey) {
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Muscat'));

        final cacheHelper = CacheHelper();
        await cacheHelper.init();

        final lat =
            double.tryParse(cacheHelper.getDataString(key: 'latitude') ?? '');
        final lon =
            double.tryParse(cacheHelper.getDataString(key: 'longitude') ?? '');

        if (lat == null || lon == null) return Future.value(true);

        final coordinates = Coordinates(lat, lon);
        final params = CalculationMethod.karachi.getParameters();
        params.madhab = Madhab.shafi;

        final notifications = NotificationServices();
        await notifications.initialize();

        await _schedulePrayersForDate(
            coordinates, params, notifications, DateTime.now(), 1);
        await _schedulePrayersForDate(coordinates, params, notifications,
            DateTime.now().add(const Duration(days: 1)), 100);
      } catch (e) {
        // 
      }
    }

    return Future.value(true);
  });
}

Future<void> _schedulePrayersForDate(
    Coordinates coordinates,
    CalculationParameters params,
    NotificationServices notifications,
    DateTime date,
    int idOffset) async {
  final prayerTimes = PrayerTimes(
    coordinates,
    DateComponents.from(date),
    params,
  );

  final prayers = {
    Prayer.fajr: prayerTimes.fajr,
    Prayer.dhuhr: prayerTimes.dhuhr,
    Prayer.asr: prayerTimes.asr,
    Prayer.maghrib: prayerTimes.maghrib,
    Prayer.isha: prayerTimes.isha,
  };

  int id = idOffset;
  for (final entry in prayers.entries) {
    final name = _getPrayerDisplayName(entry.key);
    final time = entry.value;
    if (time.isAfter(DateTime.now())) {
      await notifications.schedulePrayerNotification(
        id: id++,
        title: '🕌 $name Prayer Time',
        body: 'It\'s time for $name prayer. May Allah accept your prayers.',
        scheduledTime: time,
      );
    }
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

Duration calculateInitialDelay() {
  final now = DateTime.now();
  DateTime next2AM;

  if (now.hour < 2) {
    next2AM = DateTime(now.year, now.month, now.day, 2);
  } else {
    next2AM = DateTime(now.year, now.month, now.day + 1, 2);
  }

  return next2AM.difference(now);
}
