part of 'audio_cubit.dart';

@immutable
sealed class AudioState {}

final class AudioInitial extends AudioState {}

class AudioOffline extends AudioState {}

class AudioLoading extends AudioState {}

class SurahAudioLoading extends AudioState {}

class ReaderOffline extends AudioState {}

class ReaderLoading extends AudioState {}

class ReaderError extends AudioState {
  final String message;
  ReaderError(this.message);
}

class AudioLoaded extends AudioState {
  final edition.EditionModel surahAudioModel;
  final SurahAudioModel? currentSurahAudio;

  AudioLoaded({
    required this.surahAudioModel,
    this.currentSurahAudio,
  });

  AudioLoaded copyWith({
    edition.EditionModel? surahAudioModel,
    SurahAudioModel? currentSurahAudio,
    bool clearAudio = false,
  }) {
    return AudioLoaded(
      surahAudioModel: surahAudioModel ?? this.surahAudioModel,
      currentSurahAudio:
          clearAudio ? null : (currentSurahAudio ?? this.currentSurahAudio),
    );
  }
}

class SurahAudioLoaded extends AudioState {
  final SurahAudioModel audioModel;
  SurahAudioLoaded({required this.audioModel});
}

class AudioError extends AudioState {
  final String message;
  AudioError(this.message);
}

// Download states
class DownloadInProgress extends AudioState {
  final String ayahId;
  final double progress;
  final String fileName;

  DownloadInProgress({
    required this.ayahId,
    required this.progress,
    required this.fileName,
  });
}

class DownloadCompleted extends AudioState {
  final String ayahId;
  final String filePath;
  final String fileName;

  DownloadCompleted({
    required this.ayahId,
    required this.filePath,
    required this.fileName,
  });
}

class DownloadError extends AudioState {
  final String ayahId;
  final String error;

  DownloadError({
    required this.ayahId,
    required this.error,
  });
}

class SurahDownloadInProgress extends AudioState {
  final int totalAyahs;
  final int downloadedAyahs;
  final double overallProgress;
  final String currentAyahFileName;

  SurahDownloadInProgress({
    required this.totalAyahs,
    required this.downloadedAyahs,
    required this.overallProgress,
    required this.currentAyahFileName,
  });
}

class SurahDownloadCompleted extends AudioState {
  final int totalAyahs;
  final String surahNumber;

  SurahDownloadCompleted({
    required this.totalAyahs,
    required this.surahNumber,
  });
}

class AudioOfflineWithDownloads extends AudioState {
  final edition.EditionModel surahAudioModel;
  final List<String> downloadedReaderIds;
  final String surahNumber;

  AudioOfflineWithDownloads({
    required this.surahAudioModel,
    required this.downloadedReaderIds,
    required this.surahNumber,
  });
}
