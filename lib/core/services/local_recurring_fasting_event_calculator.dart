import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/data/models/islamic_event_config.dart';

typedef HijriDateResolver = HijriDate Function(DateTime localDate);
typedef FastingReminderWindowResolver = FastingReminderWindow? Function(
  DateTime targetLocalDate,
);

class FastingReminderWindow {
  const FastingReminderWindow({
    required this.startsAt,
    required this.endsAt,
  });

  final DateTime startsAt;
  final DateTime endsAt;

  bool contains(DateTime instant) =>
      !instant.isBefore(startsAt) && instant.isBefore(endsAt);
}

class LocalRecurringFastingEventCalculator {
  LocalRecurringFastingEventCalculator({
    required HijriDateResolver toHijri,
    required FastingReminderWindowResolver reminderWindowFor,
  })  : _toHijri = toHijri,
        _reminderWindowFor = reminderWindowFor;

  static const whiteDaysFastingKey = 'white_days_fasting';
  static const mondayThursdayFastingKey = 'monday_thursday_fasting';
  static const whiteDaysMondayThursdayFastingKey =
      'white_days_monday_thursday_fasting';

  static const whiteDaysStart = 13;
  static const whiteDaysEnd = 15;

  final HijriDateResolver _toHijri;
  final FastingReminderWindowResolver _reminderWindowFor;

  IslamicEventConfig? eventFor(DateTime instant) {
    final now = instant.isUtc ? instant.toLocal() : instant;
    final localDay = _dateOnly(now);
    final whiteDays = _whiteDaysEvent(now, localDay);
    final mondayThursday = _mondayThursdayEvent(now, localDay);

    if (whiteDays != null &&
        mondayThursday != null &&
        _isSameFastingTarget(whiteDays, mondayThursday)) {
      return _whiteDaysMondayThursdayConfig(
        displayDay: localDay,
        hijriMonth: whiteDays.hijriMonth,
        hijriDay: whiteDays.hijriDayStart,
      );
    }

    return whiteDays ?? mondayThursday;
  }

  DateTime? nextRefreshAt(DateTime instant) {
    final now = instant.isUtc ? instant.toLocal() : instant;
    final today = _dateOnly(now);
    final candidates = <DateTime>[];

    for (var offset = -1; offset <= 3; offset++) {
      final target = DateTime(today.year, today.month, today.day + offset);
      final window = _reminderWindowFor(target);
      if (window == null) continue;
      if (window.startsAt.isAfter(now)) candidates.add(window.startsAt);
      if (window.endsAt.isAfter(now)) candidates.add(window.endsAt);
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  IslamicEventConfig? _mondayThursdayEvent(
    DateTime now,
    DateTime localDay,
  ) {
    for (final targetDay in _todayAndTomorrow(localDay)) {
      if (targetDay.weekday != DateTime.monday &&
          targetDay.weekday != DateTime.thursday) {
        continue;
      }

      final targetHijri = _toHijri(targetDay);
      if (!_isVoluntaryFastingAllowed(targetHijri) ||
          !_isWithinReminderWindow(now, targetDay)) {
        continue;
      }

      return IslamicEventConfig(
        id: 'local-$mondayThursdayFastingKey-${_localDayId(localDay)}',
        eventKey: mondayThursdayFastingKey,
        hijriMonth: targetHijri.month,
        hijriDayStart: targetHijri.day,
        hijriDayEnd: targetHijri.day,
        actionRoute: '',
        iconName: 'wb_twilight_outlined',
        priority: 1,
        source: IslamicEventSource.localRecurring,
      );
    }
    return null;
  }

  IslamicEventConfig? _whiteDaysEvent(
    DateTime now,
    DateTime localDay,
  ) {
    for (final targetDay in _todayAndTomorrow(localDay)) {
      final targetHijri = _toHijri(targetDay);
      if (_isWhiteDay(targetHijri) &&
          _isVoluntaryFastingAllowed(targetHijri) &&
          _isWithinReminderWindow(now, targetDay)) {
        return _whiteDaysConfig(
          displayDay: localDay,
          hijri: targetHijri,
        );
      }
    }
    return null;
  }

  IslamicEventConfig _whiteDaysConfig({
    required DateTime displayDay,
    required HijriDate hijri,
  }) {
    return IslamicEventConfig(
      id: 'local-$whiteDaysFastingKey-${_localDayId(displayDay)}',
      eventKey: whiteDaysFastingKey,
      hijriMonth: hijri.month,
      hijriDayStart: hijri.day,
      hijriDayEnd: hijri.day,
      actionRoute: '',
      iconName: 'brightness_5_outlined',
      priority: 2,
      source: IslamicEventSource.localRecurring,
    );
  }

  IslamicEventConfig _whiteDaysMondayThursdayConfig({
    required DateTime displayDay,
    required int hijriMonth,
    required int hijriDay,
  }) {
    return IslamicEventConfig(
      id: 'local-$whiteDaysMondayThursdayFastingKey-${_localDayId(displayDay)}',
      eventKey: whiteDaysMondayThursdayFastingKey,
      hijriMonth: hijriMonth,
      hijriDayStart: hijriDay,
      hijriDayEnd: hijriDay,
      actionRoute: '',
      iconName: 'brightness_5_outlined',
      priority: 2,
      source: IslamicEventSource.localRecurring,
    );
  }

  bool _isWithinReminderWindow(DateTime now, DateTime targetDay) {
    final window = _reminderWindowFor(targetDay);
    return window?.contains(now) ?? false;
  }

  bool _isWhiteDay(HijriDate date) =>
      date.day >= whiteDaysStart && date.day <= whiteDaysEnd;

  bool _isSameFastingTarget(
    IslamicEventConfig first,
    IslamicEventConfig second,
  ) =>
      first.hijriMonth == second.hijriMonth &&
      first.hijriDayStart == second.hijriDayStart;

  bool _isVoluntaryFastingAllowed(HijriDate date) {
    if (date.month == 9) return false;
    if (date.month == 10 && date.day == 1) return false;
    if (date.month == 12 && date.day >= 10 && date.day <= 13) return false;
    return true;
  }

  Iterable<DateTime> _todayAndTomorrow(DateTime localDay) sync* {
    yield localDay;
    yield DateTime(localDay.year, localDay.month, localDay.day + 1);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _localDayId(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
