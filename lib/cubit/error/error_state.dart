part of 'error_cubit.dart';

@immutable
sealed class ErrorState {}

final class ErrorInitial extends ErrorState {}

class ErrorLoading extends ErrorState {}

class ErrorLoaded extends ErrorState {
  final String docId;

  ErrorLoaded({required this.docId});
}

/// Sending the person's note failed; the report is still there, so the
/// note can be sent again.
class ErrorFeedbackFailure extends ErrorLoaded {
  ErrorFeedbackFailure({required super.docId});
}

class ErrorSubmitting extends ErrorState {}

class ErrorSubmitted extends ErrorState {}

class ErrorFailure extends ErrorState {
  final String message;

  ErrorFailure({required this.message});
}

class ErrorReportingDisabled extends ErrorState {}
