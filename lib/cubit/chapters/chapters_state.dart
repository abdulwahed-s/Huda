part of 'chapters_cubit.dart';

@immutable
sealed class ChaptersState {}

final class ChaptersInitial extends ChaptersState {}

final class ChaptersLoading extends ChaptersState {}

final class ChaptersLoaded extends ChaptersState {
  final BookChaptersModel bookChapters;

  ChaptersLoaded(this.bookChapters);
}

final class ChaptersError extends ChaptersState {
  final String message;

  ChaptersError(this.message);
}

