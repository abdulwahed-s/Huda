part of 'languages_cubit.dart';

sealed class LanguagesState extends Equatable {
  const LanguagesState();

  @override
  List<Object> get props => [];
}

final class LanguagesInitial extends LanguagesState {}

final class LanguagesLoading extends LanguagesState {}

final class LanguagesLoaded extends LanguagesState {
  final List<BooksLanguagesModel> languages;

  const LanguagesLoaded(this.languages);
}

final class LanguagesError extends LanguagesState {
  final String message;

  const LanguagesError(this.message);
}

final class LanguagesOffline extends LanguagesState {}
