import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/books_languages_services.dart';
import 'package:huda/data/models/book_languages_model.dart';
import 'package:huda/data/repository/book_languages_repository.dart';

part 'book_languages_state.dart';

class BookLanguagesCubit extends Cubit<BookLanguagesState> {
  BookLanguagesCubit() : super(BookLanguagesInitial());
  BookLanguagesRepository bookLanguagesRepository =
      BookLanguagesRepository(booksLanguagesServices: BooksLanguagesServices());

  Future<void> fetchBookLanguages(int bookId) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(BookTranslationsLoading());
      try {
        final translations =
            await bookLanguagesRepository.getBookLanguages(bookId);
        emit(BookTranslationsLoaded(translations));
      } catch (e) {
        emit(BookTranslationsError(e.toString()));
      }
    } else {
      emit(BookTranslationsOffline());
    }
  }
}
