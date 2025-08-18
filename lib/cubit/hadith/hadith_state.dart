part of 'hadith_cubit.dart';

@immutable
sealed class HadithState {}

final class HadithInitial extends HadithState {}

final class HadithLoading extends HadithState {}

final class HadithLoaded extends HadithState {
  final HadithBooksModel hadithBooks;

  HadithLoaded({required this.hadithBooks});
}

final class HadithError extends HadithState {
  final String message;

  HadithError({required this.message});
}

final class HadithOffline extends HadithState {}
