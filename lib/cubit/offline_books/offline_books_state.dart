part of 'offline_books_cubit.dart';

sealed class OfflineBooksState extends Equatable {
  const OfflineBooksState();

  @override
  List<Object?> get props => [];
}

final class OfflineBooksInitial extends OfflineBooksState {}

final class OfflineBooksLoading extends OfflineBooksState {}

final class OfflineBooksLoaded extends OfflineBooksState {
  final List<OfflineBookModel> books;

  const OfflineBooksLoaded(this.books);

  @override
  List<Object> get props => [books];
}

final class OfflineBooksEmpty extends OfflineBooksState {}

final class OfflineBooksError extends OfflineBooksState {
  final String message;

  const OfflineBooksError(this.message);

  @override
  List<Object> get props => [message];
}

final class OfflineBookLoading extends OfflineBooksState {}

final class OfflineBookLoaded extends OfflineBooksState {
  final OfflineBookModel book;

  const OfflineBookLoaded(this.book);

  @override
  List<Object> get props => [book];
}

final class OfflineBookNotFound extends OfflineBooksState {}

final class OfflineStorageInfoLoaded extends OfflineBooksState {
  final Map<String, dynamic> storageInfo;

  const OfflineStorageInfoLoaded(this.storageInfo);

  @override
  List<Object> get props => [storageInfo];
}
