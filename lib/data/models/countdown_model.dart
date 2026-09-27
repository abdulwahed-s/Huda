import 'package:prayer_time_plus/prayer_time_plus.dart';

class NextPrayerCountdown {
  final String prayerName;
  final Duration duration;
  final bool isPastPrayer;
  final int secondsPassed;

  final Prayer? prayer;

  final DateTime? instant;

  const NextPrayerCountdown({
    required this.prayerName,
    required this.duration,
    this.isPastPrayer = false,
    this.secondsPassed = 0,
    this.prayer,
    this.instant,
  });
}
