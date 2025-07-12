part of 'quran_cubit.dart';

@immutable
sealed class QuranState {}

final class QuranInitial extends QuranState {}

class QuranLoading extends QuranState {}

class QuranLoaded extends QuranState {
  final List<QuranModel> surahs;

  QuranLoaded(this.surahs);
}

class QuranError extends QuranState {
  final String message;

  QuranError(this.message);
}
