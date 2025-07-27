part of 'athkar_details_cubit.dart';

@immutable
sealed class AthkarDetailsState {}

final class AthkarDetailsInitial extends AthkarDetailsState {}

final class AthkarDetailsLoading extends AthkarDetailsState {}

final class AthkarDetailsLoaded extends AthkarDetailsState {
  final AthkarCategory athkarCategory;

  AthkarDetailsLoaded(this.athkarCategory);
}

final class AthkarDetailsError extends AthkarDetailsState {
  final String message;

  AthkarDetailsError(this.message);
}

final class AthkarDetailsOffline extends AthkarDetailsState {}