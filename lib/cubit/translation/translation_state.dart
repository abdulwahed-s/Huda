part of 'translation_cubit.dart';

@immutable
sealed class TranslationState {}

final class TranslationInitial extends TranslationState {}

class TranslationLoading extends TranslationState {}

class TranslationOffline extends TranslationState {
  final edition.EditionModel translationModel;
  TranslationOffline(this.translationModel);
}

class TranslationLoaded extends TranslationState {
  final edition.EditionModel translationModel;
  TranslationLoaded(this.translationModel);
}

class TranslationError extends TranslationState {
  final String message;
  TranslationError(this.message);
}

class SurahTranslationLoading extends TranslationState {}

class SurahTranslationLoaded extends TranslationState {
  final translation.TafsirModel translationModel;
  SurahTranslationLoaded(this.translationModel);
}

class TranslationDownloadInProgress extends TranslationState {}

class SurahTranslationDownloadInProgress extends TranslationState {
  final String identifier;
  final int surahNumber;
  SurahTranslationDownloadInProgress(this.identifier, this.surahNumber);
}

class FullQuranTranslationDownloadInProgress extends TranslationState {
  final String identifier;
  FullQuranTranslationDownloadInProgress(this.identifier);
}

class TranslationDownloadCompleted extends TranslationState {}

class TranslationDownloadDeleted extends TranslationState {}

class TranslationCacheCleared extends TranslationState {}
