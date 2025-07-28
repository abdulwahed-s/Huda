part of 'book_detail_cubit.dart';

sealed class BookDetailState extends Equatable {
  const BookDetailState();

  @override
  List<Object> get props => [];
}

final class BookDetailInitial extends BookDetailState {}

final class BookDetailLoading extends BookDetailState {}

final class BookDetailLoaded extends BookDetailState {
  final BookDetailModel bookDetail;

  const BookDetailLoaded(this.bookDetail);
}

final class BookDetailError extends BookDetailState {
  final String error;

  const BookDetailError(this.error);
}

final class BookDetailOffline extends BookDetailState {}
