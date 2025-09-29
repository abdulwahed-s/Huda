import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/books_services.dart';
import 'package:huda/data/models/books_response.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/repository/books_repository.dart';
import 'package:huda/data/services/offline_books_service.dart';

part 'books_state.dart';

class BooksCubit extends Cubit<BooksState> {
  BooksCubit() : super(BooksInitial());

  BooksRepository booksRepository =
      BooksRepository(booksServices: BooksServices());
  OfflineBooksService offlineBooksService = OfflineBooksService();

  Future<void> fetchBooks(String lang, int pageNumber, String respLang) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(BooksLoading());
      try {
        final BooksResponse booksResponse =
            await booksRepository.getAllBooks(lang, pageNumber, respLang);
        emit(BooksLoaded(booksResponse));
      } catch (e) {
        emit(BooksError(e.toString()));
      }
    } else {
      await fetchOfflineBooks(lang);
    }
  }

  Future<void> fetchOfflineBooks(String lang) async {
    emit(BooksOfflineLoading());
    try {
      List<OfflineBookModel> offlineBooks;

      if (lang == 'showall') {
        offlineBooks = await offlineBooksService.getAllBooks();
      } else {
        offlineBooks = await offlineBooksService.getBooksByLanguage(lang);
      }

      if (offlineBooks.isEmpty) {
        emit(BooksOfflineEmpty());
      } else {
        emit(BooksOfflineLoaded(offlineBooks));
      }
    } catch (e) {
      emit(BooksOffline());
    }
  }
}
