part of 'hadith_details_cubit.dart';

@immutable
sealed class HadithDetailsState {}

final class HadithDetailsInitial extends HadithDetailsState {}

final class HadithDetailsLoading extends HadithDetailsState {}

final class HadithDetailsLoaded extends HadithDetailsState {
  final HadithDetailsModel hadithDetail;

  HadithDetailsLoaded(this.hadithDetail);
}

final class HadithDetailsError extends HadithDetailsState {
  final String message;

  HadithDetailsError(this.message);
}

