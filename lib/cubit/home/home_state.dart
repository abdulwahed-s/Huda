part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  final bool hasLastReadPosition;
  final Map<String, dynamic>? lastReadSummary;
  final bool hasLastQuranAudio;
  final QuranAudioProgress? lastQuranAudio;
  final bool hasLastRadioStation;
  final RadioStationProgress? lastRadioStation;
  final DailyAyah dailyAyah;
  final KhatmaSnapshot khatma;

  HomeLoaded({
    required this.hasLastReadPosition,
    this.lastReadSummary,
    required this.hasLastQuranAudio,
    this.lastQuranAudio,
    required this.hasLastRadioStation,
    this.lastRadioStation,
    required this.dailyAyah,
    required this.khatma,
  });
}

final class HomeError extends HomeState {
  final String message;

  HomeError({required this.message});
}
