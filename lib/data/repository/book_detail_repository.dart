import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/books_detail_services.dart';
import 'package:huda/data/models/books_detail_model.dart';

class BookDetailRepository {
  final BooksDetailServices booksDetailServices;

  BookDetailRepository({required this.booksDetailServices});

  Future<BookDetailModel> getBookDetail(String lang, int bookId) async {
    try {
      final response = await booksDetailServices.getBookDetail(lang, bookId);
      return BookDetailModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
