part of 'hijri_calendar_cubit.dart';

class HijriCalendarState extends Equatable {
  final Map<String, List<HijriEvent>> events;

  HijriCalendarState({Map<String, List<HijriEvent>>? events})
      : events = events ?? {};

  HijriCalendarState copyWith({Map<String, List<HijriEvent>>? events}) {
    return HijriCalendarState(events: events ?? this.events);
  }

  @override
  List<Object> get props => [events];
}
