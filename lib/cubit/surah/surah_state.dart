part of 'surah_cubit.dart';

@immutable
sealed class SurahState {}

final class SurahInitial extends SurahState {}

class SurahLoading extends SurahState {}

class SurahLoaded extends SurahState {
  final SurahModel surah;
  SurahLoaded(this.surah);
}

class SurahError extends SurahState {
  final String message;
  SurahError(this.message);
}