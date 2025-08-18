part of 'tafsir_cubit.dart';

@immutable
sealed class TafsirState {}

final class TafsirInitial extends TafsirState {}

class TafsirLoading extends TafsirState {}

class TafsirOffline extends TafsirState {
  final edition.EditionModel tafsirModel;
  TafsirOffline(this.tafsirModel);
}

class TafsirLoaded extends TafsirState {
  final edition.EditionModel tafsirModel;
  TafsirLoaded(this.tafsirModel);
}

class TafsirError extends TafsirState {
  final String message;
  TafsirError(this.message);
}

class SurahTafsirLoading extends TafsirState {}

class SurahTafsirLoaded extends TafsirState {
  final tafsir.TafsirModel tafsirModel;
  SurahTafsirLoaded(this.tafsirModel);
}

class TafsirDownloadInProgress extends TafsirState {}

class SurahTafsirDownloadInProgress extends TafsirState {
  final String identifier;
  final int surahNumber;
  SurahTafsirDownloadInProgress(this.identifier, this.surahNumber);
}

class FullQuranTafsirDownloadInProgress extends TafsirState {
  final String identifier;
  FullQuranTafsirDownloadInProgress(this.identifier);
}

class TafsirDownloadCompleted extends TafsirState {}

class TafsirDownloadDeleted extends TafsirState {}

class TafsirCacheCleared extends TafsirState {}
