import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/data/services/audiobook_download_service.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';

part 'audiobook_download_state.dart';

class AudiobookDownloadCubit extends Cubit<AudiobookDownloadState> {
  final AudiobookDownloadService _downloadService;
  final OfflineAudiobooksService _offlineService;

  AudiobookDownloadCubit({
    required AudiobookDownloadService downloadService,
    required OfflineAudiobooksService offlineService,
  })  : _downloadService = downloadService,
        _offlineService = offlineService,
        super(const AudiobookDownloadState());

  Future<void> checkStatus(int audiobookId) async {
    final isDownloaded =
        await _offlineService.isAudiobookDownloaded(audiobookId);
    final isDownloading = await _downloadService.isDownloading(audiobookId);
    emit(state.copyWith(
      isDownloaded: isDownloaded,
      isDownloading: isDownloading,
    ));
  }

  Future<void> download(AudioDetailModel detail, String language) async {
    if (detail.id == null) return;
    emit(state.copyWith(isDownloading: true, progress: 0.0, error: null));

    _downloadService.onProgressUpdate = (progress) {
      if (isClosed) return;
      switch (progress.status) {
        case DownloadStatus.downloading:
          emit(state.copyWith(
            isDownloading: true,
            progress: progress.progress,
          ));
          break;
        case DownloadStatus.completed:
          emit(state.copyWith(
            isDownloading: false,
            isDownloaded: true,
            progress: 1.0,
          ));
          break;
        case DownloadStatus.failed:
          emit(state.copyWith(
            isDownloading: false,
            error: progress.error,
          ));
          break;
        default:
          break;
      }
    };

    try {
      await _downloadService.downloadAudiobook(detail, language);
      emit(state.copyWith(isDownloading: false, isDownloaded: true));
    } catch (e) {
      emit(state.copyWith(isDownloading: false, error: e.toString()));
    }
  }

  Future<void> cancel(int audiobookId) async {
    await _downloadService.cancelDownload(audiobookId);
    emit(state.copyWith(
        isDownloading: false, isDownloaded: false, progress: 0.0));
  }

  Future<void> delete(int audiobookId) async {
    await _offlineService.deleteAudiobook(audiobookId);
    emit(state.copyWith(isDownloaded: false, progress: 0.0));
  }
}
