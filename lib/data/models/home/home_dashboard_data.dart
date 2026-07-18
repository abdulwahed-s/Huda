class DailyAyah {
  const DailyAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });

  final int surahNumber;
  final int ayahNumber;
  final String text;
}

class KhatmaSnapshot {
  const KhatmaSnapshot({
    required this.isActive,
    required this.isCompleted,
    required this.currentDay,
    required this.totalDays,
    required this.progress,
    required this.startSurah,
    required this.startAyah,
  });

  final bool isActive;
  final bool isCompleted;
  final int currentDay;
  final int totalDays;
  final double progress;
  final int? startSurah;
  final int? startAyah;
}
