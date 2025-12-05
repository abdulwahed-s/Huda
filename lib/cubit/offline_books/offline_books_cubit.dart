import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/services/offline_books_service.dart';

part 'offline_books_state.dart';

class OfflineBooksCubit extends Cubit<OfflineBooksState> {
  OfflineBooksCubit() : super(OfflineBooksInitial());

  final OfflineBooksService _offlineBooksService = OfflineBooksService();

  Future<void> fetchOfflineBooks() async {
    // Offline books not supported on web
    if (kIsWeb) {
      emit(OfflineBooksEmpty());
      return;
    }
    try {
      emit(OfflineBooksLoading());
      final books = await _offlineBooksService.getAllBooks();

      if (books.isEmpty) {
        emit(OfflineBooksEmpty());
      } else {
        emit(OfflineBooksLoaded(books));
      }
    } catch (e) {
      emit(OfflineBooksError(e.toString()));
    }
  }

  Future<void> fetchOfflineBooksByLanguage(String language) async {
    try {
      emit(OfflineBooksLoading());
      final books = await _offlineBooksService.getBooksByLanguage(language);

      if (books.isEmpty) {
        emit(OfflineBooksEmpty());
      } else {
        emit(OfflineBooksLoaded(books));
      }
    } catch (e) {
      emit(OfflineBooksError(e.toString()));
    }
  }

  Future<void> searchOfflineBooks(String query) async {
    try {
      emit(OfflineBooksLoading());
      final books = await _offlineBooksService.searchBooks(query);

      if (books.isEmpty) {
        emit(OfflineBooksEmpty());
      } else {
        emit(OfflineBooksLoaded(books));
      }
    } catch (e) {
      emit(OfflineBooksError(e.toString()));
    }
  }

  Future<void> getOfflineBook(int bookId) async {
    try {
      emit(OfflineBookLoading());
      final book = await _offlineBooksService.getBook(bookId);

      if (book != null) {
        emit(OfflineBookLoaded(book));
      } else {
        emit(OfflineBookNotFound());
      }
    } catch (e) {
      emit(OfflineBooksError(e.toString()));
    }
  }

  Future<bool> isBookDownloaded(int bookId) async {
    return await _offlineBooksService.isBookDownloaded(bookId);
  }

  Future<void> deleteOfflineBook(int bookId) async {
    try {
      await _offlineBooksService.deleteBook(bookId);

      await fetchOfflineBooks();
    } catch (e) {
      emit(OfflineBooksError('Failed to delete book: $e'));
    }
  }

  Future<void> getStorageInfo() async {
    try {
      final storageInfo = await _offlineBooksService.getStorageInfo();
      emit(OfflineStorageInfoLoaded(storageInfo));
    } catch (e) {
      emit(OfflineBooksError('Failed to get storage info: $e'));
    }
  }

  Future<void> cleanupOrphanedFiles() async {
    try {
      await _offlineBooksService.cleanupOrphanedFiles();

      await fetchOfflineBooks();
    } catch (e) {
      emit(OfflineBooksError('Failed to cleanup files: $e'));
    }
  }

  void reset() {
    emit(OfflineBooksInitial());
  }
}
