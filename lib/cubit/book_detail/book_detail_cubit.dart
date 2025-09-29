import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/books_detail_services.dart';
import 'package:huda/data/models/books_detail_model.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/repository/book_detail_repository.dart';
import 'package:huda/data/services/offline_books_service.dart';

part 'book_detail_state.dart';

class BookDetailCubit extends Cubit<BookDetailState> {
  BookDetailCubit() : super(BookDetailInitial());
  BookDetailRepository bookDetailRepository =
      BookDetailRepository(booksDetailServices: BooksDetailServices());
  OfflineBooksService offlineBooksService = OfflineBooksService();

  Future<void> fetchBookDetail(int bookId, String language) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(BookDetailLoading());
      try {
        final bookDetail =
            await bookDetailRepository.getBookDetail(language, bookId);
        emit(BookDetailLoaded(bookDetail));
      } catch (e) {
        emit(BookDetailError(e.toString()));
      }
    } else {
      // When offline, try to get the book from local storage
      await fetchOfflineBookDetail(bookId);
    }
  }

  Future<void> fetchOfflineBookDetail(int bookId) async {
    emit(BookDetailLoading());
    try {
      final offlineBook = await offlineBooksService.getBook(bookId);
      if (offlineBook != null) {
        emit(BookDetailOfflineLoaded(offlineBook));
      } else {
        emit(BookDetailOffline());
      }
    } catch (e) {
      emit(BookDetailOffline());
    }
  }
}
