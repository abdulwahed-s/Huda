part of 'ramadan_cubit.dart';

class RamadanDayInfo {
  final int dayNumber;
  final DateTime gregorianDate;
  final String dayOfWeek;
  final String status; 

  RamadanDayInfo({
    required this.dayNumber,
    required this.gregorianDate,
    required this.dayOfWeek,
    required this.status,
  });

  RamadanDayInfo copyWith({String? status}) {
    return RamadanDayInfo(
      dayNumber: dayNumber,
      gregorianDate: gregorianDate,
      dayOfWeek: dayOfWeek,
      status: status ?? this.status,
    );
  }
}

abstract class RamadanState {}

class RamadanInitial extends RamadanState {}

class RamadanLoading extends RamadanState {}

class RamadanLoaded extends RamadanState {
  final bool isRamadan;
  final int currentDay;
  final int daysUntilRamadan;
  final int hijriYear;
  final DateTime fajrTime;
  final DateTime maghribTime;
  final Map<int, String> qadhaaStatus;
  final List<RamadanDayInfo> ramadanDays;
  final int fastedCount;
  final int missedCount;

  RamadanLoaded({
    required this.isRamadan,
    required this.currentDay,
    required this.daysUntilRamadan,
    required this.hijriYear,
    required this.fajrTime,
    required this.maghribTime,
    required this.qadhaaStatus,
    required this.ramadanDays,
    required this.fastedCount,
    required this.missedCount,
  });

  RamadanLoaded copyWith({
    bool? isRamadan,
    int? currentDay,
    int? daysUntilRamadan,
    int? hijriYear,
    DateTime? fajrTime,
    DateTime? maghribTime,
    Map<int, String>? qadhaaStatus,
    List<RamadanDayInfo>? ramadanDays,
    int? fastedCount,
    int? missedCount,
  }) {
    return RamadanLoaded(
      isRamadan: isRamadan ?? this.isRamadan,
      currentDay: currentDay ?? this.currentDay,
      daysUntilRamadan: daysUntilRamadan ?? this.daysUntilRamadan,
      hijriYear: hijriYear ?? this.hijriYear,
      fajrTime: fajrTime ?? this.fajrTime,
      maghribTime: maghribTime ?? this.maghribTime,
      qadhaaStatus: qadhaaStatus ?? this.qadhaaStatus,
      ramadanDays: ramadanDays ?? this.ramadanDays,
      fastedCount: fastedCount ?? this.fastedCount,
      missedCount: missedCount ?? this.missedCount,
    );
  }
}

class RamadanError extends RamadanState {
  final String message;
  RamadanError(this.message);
}
