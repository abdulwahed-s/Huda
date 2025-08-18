part of 'rating_cubit.dart';

@immutable
abstract class RatingState {}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingReady extends RatingState {
  final bool shouldShow;

  RatingReady({required this.shouldShow});
}

class RatingSubmitting extends RatingState {}

class RatingSubmitted extends RatingState {
  final int rating;
  final String message;

  RatingSubmitted({required this.rating, this.message = ''});
}

class RatingFailure extends RatingState {
  final String message;

  RatingFailure({required this.message});
}

class FeedbackSubmitting extends RatingState {}

class FeedbackSubmitted extends RatingState {}

class FeedbackFailure extends RatingState {
  final String message;

  FeedbackFailure({required this.message});
}
