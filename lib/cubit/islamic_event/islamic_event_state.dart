part of 'islamic_event_cubit.dart';

@immutable
sealed class IslamicEventState {}

final class IslamicEventInitial extends IslamicEventState {}

final class IslamicEventLoading extends IslamicEventState {}

final class IslamicEventActive extends IslamicEventState {
  final IslamicEventConfig event;

  IslamicEventActive({required this.event});
}

final class IslamicEventNone extends IslamicEventState {}
