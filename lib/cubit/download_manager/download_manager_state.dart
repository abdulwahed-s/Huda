part of 'download_manager_cubit.dart';

sealed class DownloadManagerState extends Equatable {
  const DownloadManagerState();

  @override
  List<Object?> get props => [];
}

final class DownloadManagerInitial extends DownloadManagerState {}

final class DownloadStarted extends DownloadManagerState {
  final int bookId;

  const DownloadStarted(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class DownloadInProgress extends DownloadManagerState {
  final DownloadProgress progress;

  const DownloadInProgress(this.progress);

  @override
  List<Object> get props => [progress];
}

final class DownloadCompleted extends DownloadManagerState {
  final int bookId;

  const DownloadCompleted(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class DownloadPaused extends DownloadManagerState {
  final int bookId;

  const DownloadPaused(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class DownloadResumed extends DownloadManagerState {
  final int bookId;

  const DownloadResumed(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class DownloadCancelled extends DownloadManagerState {
  final int bookId;

  const DownloadCancelled(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class DownloadError extends DownloadManagerState {
  final int bookId;
  final String message;

  const DownloadError(this.bookId, this.message);

  @override
  List<Object> get props => [bookId, message];
}

final class BookDeleted extends DownloadManagerState {
  final int bookId;

  const BookDeleted(this.bookId);

  @override
  List<Object> get props => [bookId];
}

final class StorageInfoLoaded extends DownloadManagerState {
  final Map<String, dynamic> storageInfo;

  const StorageInfoLoaded(this.storageInfo);

  @override
  List<Object> get props => [storageInfo];
}
