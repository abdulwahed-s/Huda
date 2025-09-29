part of 'books_cubit.dart';

sealed class BooksState extends Equatable {
  const BooksState();

  @override
  List<Object> get props => [];
}

final class BooksInitial extends BooksState {}

final class BooksLoading extends BooksState {}

final class BooksLoaded extends BooksState {
  final BooksResponse booksResponse;

  const BooksLoaded(this.booksResponse);
}

final class BooksError extends BooksState {
  final String message;

  const BooksError(this.message);
}

final class BooksOffline extends BooksState {}

final class BooksOfflineLoading extends BooksState {}

final class BooksOfflineLoaded extends BooksState {
  final List<OfflineBookModel> offlineBooks;

  const BooksOfflineLoaded(this.offlineBooks);

  @override
  List<Object> get props => [offlineBooks];
}

final class BooksOfflineEmpty extends BooksState {}
