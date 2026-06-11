part of 'audiobook_download_cubit.dart';

class AudiobookDownloadState extends Equatable {
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final String? error;

  const AudiobookDownloadState({
    this.isDownloaded = false,
    this.isDownloading = false,
    this.progress = 0.0,
    this.error,
  });

  AudiobookDownloadState copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    double? progress,
    String? error,
  }) {
    return AudiobookDownloadState(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isDownloaded, isDownloading, progress, error];
}
