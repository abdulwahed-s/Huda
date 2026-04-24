import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadProgressState {
  final Map<String, double> progress;

  final Map<String, DownloadAllProgress> batchProgress;

  const DownloadProgressState({
    this.progress = const {},
    this.batchProgress = const {},
  });

  DownloadProgressState copyWith({
    Map<String, double>? progress,
    Map<String, DownloadAllProgress>? batchProgress,
  }) {
    return DownloadProgressState(
      progress: progress ?? this.progress,
      batchProgress: batchProgress ?? this.batchProgress,
    );
  }

  double? getSurahProgress(
      dynamic reciterId, dynamic moshafId, String surahNumber) {
    return progress['$reciterId-$moshafId-$surahNumber'];
  }

  DownloadAllProgress? getBatchProgress(dynamic reciterId, dynamic moshafId) {
    return batchProgress['$reciterId-$moshafId'];
  }

  bool isSurahDownloading(
      dynamic reciterId, dynamic moshafId, String surahNumber) {
    final p = progress['$reciterId-$moshafId-$surahNumber'];
    return p != null && p < 1.0;
  }
}

class DownloadAllProgress {
  final int completed;
  final int total;

  const DownloadAllProgress({required this.completed, required this.total});

  double get fraction => total > 0 ? completed / total : 0.0;
  bool get isDone => completed >= total;
}

class DownloadProgressCubit extends Cubit<DownloadProgressState> {
  DownloadProgressCubit() : super(const DownloadProgressState());

  void updateSurahProgress(
      dynamic reciterId, dynamic moshafId, String surahNumber, double value) {
    final key = '$reciterId-$moshafId-$surahNumber';
    final updated = Map<String, double>.from(state.progress);
    updated[key] = value;
    emit(state.copyWith(progress: updated));
  }

  void completeSurahDownload(
      dynamic reciterId, dynamic moshafId, String surahNumber) {
    final key = '$reciterId-$moshafId-$surahNumber';
    final updated = Map<String, double>.from(state.progress);
    updated[key] = 1.0;
    emit(state.copyWith(progress: updated));

    Future.delayed(const Duration(seconds: 1), () {
      if (!isClosed) {
        final cleaned = Map<String, double>.from(state.progress);
        cleaned.remove(key);
        emit(state.copyWith(progress: cleaned));
      }
    });
  }

  void removeSurahProgress(
      dynamic reciterId, dynamic moshafId, String surahNumber) {
    final key = '$reciterId-$moshafId-$surahNumber';
    final updated = Map<String, double>.from(state.progress);
    updated.remove(key);
    emit(state.copyWith(progress: updated));
  }

  void updateBatchProgress(
      dynamic reciterId, dynamic moshafId, int completed, int total) {
    final key = '$reciterId-$moshafId';
    final updated = Map<String, DownloadAllProgress>.from(state.batchProgress);
    updated[key] = DownloadAllProgress(completed: completed, total: total);
    emit(state.copyWith(batchProgress: updated));
  }

  void completeBatch(dynamic reciterId, dynamic moshafId) {
    final key = '$reciterId-$moshafId';
    final updated = Map<String, DownloadAllProgress>.from(state.batchProgress);
    updated.remove(key);
    emit(state.copyWith(batchProgress: updated));
  }
}
