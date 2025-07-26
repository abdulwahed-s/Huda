import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/books_services.dart';
import 'package:huda/data/models/books_response.dart';

class BooksRepository {
  final BooksServices booksServices;

  BooksRepository({required this.booksServices});

  Future<BooksResponse> getAllBooks(String lang, int page) async {
    try {
      final response = await booksServices.getAllBooks(lang, page);
      return BooksResponse.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
