import 'dart:async';
import 'dart:math';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:quran/quran.dart' as quran;

class KhatmaService {
  final CacheHelper _cache;

  KhatmaService({required CacheHelper cache}) : _cache = cache;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  Stream<void> get khatmaChanges => _changesController.stream;

  void dispose() => _changesController.close();

  static const String _kEnabled = 'khatma_enabled';
  static const String _kPlanDays = 'khatma_plan_days';
  static const String _kCurrentDayIndex = 'khatma_current_day_index';
  static const String _kStartedAt = 'khatma_started_at';
  static const String _kReminderEnabled = 'khatma_reminder_enabled';
  static const String _kReminderHour = 'khatma_reminder_hour';
  static const String _kReminderMinute = 'khatma_reminder_minute';

  static const int totalPages = 604;

  bool get enabled => _cache.getData(key: _kEnabled) == true;

  int get planDays => (_cache.getData(key: _kPlanDays) as int?) ?? 30;

  int get currentDayIndex =>
      (_cache.getData(key: _kCurrentDayIndex) as int?) ?? 0;

  bool get isCompleted => enabled && currentDayIndex >= planDays;

  String? get startedAtIso => _cache.getDataString(key: _kStartedAt);

  DateTime? get startedAt {
    final iso = startedAtIso;
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  bool get reminderEnabled => _cache.getData(key: _kReminderEnabled) == true;
  int get reminderHour => (_cache.getData(key: _kReminderHour) as int?) ?? 19;
  int get reminderMinute =>
      (_cache.getData(key: _kReminderMinute) as int?) ?? 0;

  Future<void> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _cache.saveData(key: _kReminderEnabled, value: enabled);
    await _cache.saveData(key: _kReminderHour, value: hour);
    await _cache.saveData(key: _kReminderMinute, value: minute);
  }

  int pagesPerDay(int days) => days > 0 ? (totalPages / days).round() : 0;

  ({int startPage, int endPage}) rangeForDay(int dayIndex, int days) {
    if (days <= 0) return (startPage: 1, endPage: 1);
    final safeDayIndex = dayIndex.clamp(0, days - 1);
    final start = (safeDayIndex * totalPages) ~/ days + 1;
    final end = ((safeDayIndex + 1) * totalPages) ~/ days;
    return (
      startPage: start.clamp(1, totalPages),
      endPage: end.clamp(1, totalPages)
    );
  }

  double get percentTotal =>
      enabled ? (currentDayIndex / planDays).clamp(0.0, 1.0) : 0.0;

  int get totalPagesRead => planDays > 0
      ? (currentDayIndex.clamp(0, planDays) * totalPages) ~/ planDays
      : 0;

  int get pagesRemaining => max(0, totalPages - totalPagesRead);

  int get daysRemaining => max(0, planDays - currentDayIndex);

  double get percentDaily {
    final st = startedAt;
    if (st == null) return 0.1;
    final daysPassed = DateTime.now().difference(st).inDays;
    if (currentDayIndex > daysPassed) return 1.0;
    if (currentDayIndex == daysPassed) return 0.1;
    return 0.0;
  }

  double get percentPacing {
    final st = startedAt;
    if (st == null) return 1.0;
    final daysPassed = DateTime.now().difference(st).inDays;
    if (daysPassed == 0) return 1.0;
    return (currentDayIndex / daysPassed).clamp(0.0, 1.0);
  }

  ({
    int startPage,
    int endPage,
    int startSurah,
    int startVerse,
    String startSurahName,
    int endSurah,
    int endVerse,
    String endSurahName,
  }) rangeDetailsForDay(int dayIndex, int days) {
    final r = rangeForDay(dayIndex, days);

    final startPageData = quran.getPageData(r.startPage);
    final startSurah =
        startPageData.isNotEmpty ? startPageData.first['surah'] as int : 1;
    final startVerse =
        startPageData.isNotEmpty ? startPageData.first['start'] as int : 1;

    final endPageData = quran.getPageData(r.endPage);
    final endSurah =
        endPageData.isNotEmpty ? endPageData.last['surah'] as int : 114;
    final endVerse =
        endPageData.isNotEmpty ? endPageData.last['end'] as int : 6;

    final startSurahName = quran.getSurahNameArabic(startSurah);
    final endSurahName = quran.getSurahNameArabic(endSurah);

    return (
      startPage: r.startPage,
      endPage: r.endPage,
      startSurah: startSurah,
      startVerse: startVerse,
      startSurahName: startSurahName,
      endSurah: endSurah,
      endVerse: endVerse,
      endSurahName: endSurahName,
    );
  }

  String rangeLabelForDay(int dayIndex, int days) {
    final details = rangeDetailsForDay(dayIndex, days);
    return 'من ${details.startSurahName}: ${details.startVerse}\nإلى ${details.endSurahName}: ${details.endVerse}';
  }

  Future<void> startPlan(int days) async {
    final now = DateTime.now().toIso8601String();
    await _cache.saveData(key: _kEnabled, value: true);
    await _cache.saveData(key: _kPlanDays, value: days);
    await _cache.saveData(key: _kCurrentDayIndex, value: 0);
    await _cache.saveData(key: _kStartedAt, value: now);
    _changesController.add(null);
  }

  Future<void> startPlanFromDay(int days, int dayIndex) async {
    await startPlan(days);
    await _cache.saveData(key: _kCurrentDayIndex, value: dayIndex);
  }

  Future<void> markTodayDone() async {
    if (!enabled) return;
    final next = min(planDays, currentDayIndex + 1);
    await _cache.saveData(key: _kCurrentDayIndex, value: next);
    _changesController.add(null);
  }

  Future<void> resetPlan() async {
    await _cache.saveData(key: _kEnabled, value: false);
    await _cache.removeData(key: _kPlanDays);
    await _cache.removeData(key: _kCurrentDayIndex);
    await _cache.removeData(key: _kStartedAt);
    _changesController.add(null);
  }
}
