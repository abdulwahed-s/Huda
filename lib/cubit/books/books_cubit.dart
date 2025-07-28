import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/books_services.dart';
import 'package:huda/data/models/books_response.dart';
import 'package:huda/data/repository/books_repository.dart';

part 'books_state.dart';

class BooksCubit extends Cubit<BooksState> {
  BooksCubit() : super(BooksInitial());

  BooksRepository booksRepository =
      BooksRepository(booksServices: BooksServices());

  Future<void> fetchBooks(String lang, int pageNumber) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(BooksLoading());
      try {
        final booksResponse =
            await booksRepository.getAllBooks(lang, pageNumber);
        emit(BooksLoaded(booksResponse));
      } catch (e) {
        emit(BooksError(e.toString()));
      }
    } else {
      emit(BooksOffline());
    }
  }
}
