part of 'athkar_cubit.dart';

@immutable
sealed class AthkarState {}

final class AthkarInitial extends AthkarState {}

final class AthkarLoading extends AthkarState {}

final class AthkarLoaded extends AthkarState {
  final List<AthkarItem> athkar;

  AthkarLoaded(this.athkar);
}

final class AthkarError extends AthkarState {
  final String message;

  AthkarError(this.message);
}

final class AthkarOffline extends AthkarState {}
