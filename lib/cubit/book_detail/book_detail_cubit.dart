import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/books_detail_services.dart';
import 'package:huda/data/models/books_detail_model.dart';
import 'package:huda/data/repository/book_detail_repository.dart';

part 'book_detail_state.dart';

class BookDetailCubit extends Cubit<BookDetailState> {
  BookDetailCubit() : super(BookDetailInitial());
  BookDetailRepository bookDetailRepository =
      BookDetailRepository(booksDetailServices: BooksDetailServices());

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
      emit(BookDetailOffline());
    }
  }
}
