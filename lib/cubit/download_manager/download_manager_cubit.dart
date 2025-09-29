import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/models/books_detail_model.dart';
import 'package:huda/data/services/book_download_service.dart';
import 'package:huda/data/services/offline_books_service.dart';

part 'download_manager_state.dart';

class DownloadManagerCubit extends Cubit<DownloadManagerState> {
  DownloadManagerCubit() : super(DownloadManagerInitial());

  final BookDownloadService _downloadService = BookDownloadService();
  final OfflineBooksService _offlineBooksService = OfflineBooksService();

  Future<void> downloadBook(BookDetailModel bookDetail, String language) async {
    try {
      emit(DownloadStarted(bookDetail.id!));

      _downloadService.onProgressUpdate = (progress) {
        emit(DownloadInProgress(progress));
      };

      await _downloadService.downloadBook(bookDetail, language);
      emit(DownloadCompleted(bookDetail.id!));
    } catch (e) {
      emit(DownloadError(bookDetail.id!, e.toString()));
    }
  }

  Future<void> cancelDownload(int bookId) async {
    try {
      await _downloadService.cancelDownload(bookId);
      emit(DownloadCancelled(bookId));
    } catch (e) {
      emit(DownloadError(bookId, 'Failed to cancel download: $e'));
    }
  }

  Future<void> pauseDownload(int bookId) async {
    try {
      await _downloadService.pauseDownload(bookId);
      emit(DownloadPaused(bookId));
    } catch (e) {
      emit(DownloadError(bookId, 'Failed to pause download: $e'));
    }
  }

  Future<void> resumeDownload(int bookId) async {
    try {
      await _downloadService.resumeDownload(bookId);
      emit(DownloadResumed(bookId));
    } catch (e) {
      emit(DownloadError(bookId, 'Failed to resume download: $e'));
    }
  }

  Future<void> getDownloadProgress(int bookId) async {
    try {
      final progress = await _downloadService.getDownloadProgress(bookId);
      if (progress != null) {
        emit(DownloadInProgress(progress));
      } else {
        emit(DownloadManagerInitial());
      }
    } catch (e) {
      emit(DownloadError(bookId, 'Failed to get download progress: $e'));
    }
  }

  Future<bool> isBookDownloaded(int bookId) async {
    return await _offlineBooksService.isBookDownloaded(bookId);
  }

  Future<void> deleteDownloadedBook(int bookId) async {
    try {
      await _offlineBooksService.deleteBook(bookId);
      emit(BookDeleted(bookId));
    } catch (e) {
      emit(DownloadError(bookId, 'Failed to delete book: $e'));
    }
  }

  Future<void> getStorageInfo() async {
    try {
      final storageInfo = await _offlineBooksService.getStorageInfo();
      emit(StorageInfoLoaded(storageInfo));
    } catch (e) {
      emit(DownloadError(0, 'Failed to get storage info: $e'));
    }
  }

  void reset() {
    emit(DownloadManagerInitial());
  }
}
