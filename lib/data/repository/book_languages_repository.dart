import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/books_languages_services.dart';
import 'package:huda/data/models/book_languages_model.dart';

class BookLanguagesRepository {
  final BooksLanguagesServices booksLanguagesServices;

  BookLanguagesRepository({required this.booksLanguagesServices});

  Future<List<BookLanguagesModel>> getBookLanguages(int bookId) async {
    try {
      final response = await booksLanguagesServices.getBookLanguages(bookId);
      return response.map((item) => BookLanguagesModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
