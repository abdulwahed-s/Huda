class NextPrayerCountdown {
  final String prayerName;
  final Duration duration;
  final bool isPastPrayer;
  final int secondsPassed;

  const NextPrayerCountdown({
    required this.prayerName,
    required this.duration,
    this.isPastPrayer = false,
    this.secondsPassed = 0,
  });
}
