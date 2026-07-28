part of 'islamic_event_cubit.dart';

@immutable
sealed class IslamicEventState {}

final class IslamicEventInitial extends IslamicEventState {
  @override
  bool operator ==(Object other) => other is IslamicEventInitial;

  @override
  int get hashCode => 0;
}

final class IslamicEventLoading extends IslamicEventState {
  @override
  bool operator ==(Object other) => other is IslamicEventLoading;

  @override
  int get hashCode => 1;
}

final class IslamicEventActive extends IslamicEventState {
  final IslamicEventConfig event;

  IslamicEventActive({required this.event});

  @override
  bool operator ==(Object other) =>
      other is IslamicEventActive && other.event == event;

  @override
  int get hashCode => event.hashCode;
}

final class IslamicEventNone extends IslamicEventState {
  @override
  bool operator ==(Object other) => other is IslamicEventNone;

  @override
  int get hashCode => 2;
}
