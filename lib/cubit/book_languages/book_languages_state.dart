part of 'book_languages_cubit.dart';

sealed class BookLanguagesState extends Equatable {
  const BookLanguagesState();

  @override
  List<Object> get props => [];
}

final class BookLanguagesInitial extends BookLanguagesState {}

final class BookTranslationsLoaded extends BookLanguagesState {
  final List<BookLanguagesModel> translations;

  const BookTranslationsLoaded(this.translations);
}

final class BookTranslationsError extends BookLanguagesState {
  final String error;

  const BookTranslationsError(this.error);
}

final class BookTranslationsLoading extends BookLanguagesState {}

final class BookTranslationsOffline extends BookLanguagesState {}
