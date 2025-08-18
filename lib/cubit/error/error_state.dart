part of 'error_cubit.dart';

@immutable
sealed class ErrorState {}

final class ErrorInitial extends ErrorState {}

class ErrorLoading extends ErrorState {}

class ErrorLoaded extends ErrorState {
  final String docId;

  ErrorLoaded({required this.docId});
}

class ErrorSubmitting extends ErrorState {}

class ErrorSubmitted extends ErrorState {}

class ErrorFailure extends ErrorState {
  final String message;

  ErrorFailure({required this.message});
}
