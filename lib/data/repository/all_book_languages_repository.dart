import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/all_books_languages_services.dart';
import 'package:huda/data/models/books_languages_model.dart';

class AllBookLanguagesRepository {
  final AllBooksLanguagesServices allBooksLanguagesServices;

  AllBookLanguagesRepository({required this.allBooksLanguagesServices});

  Future<List<BooksLanguagesModel>> getAllBookLanguages(String lang) async {
    try {
      final response = await allBooksLanguagesServices.getBooksLanguages(lang);
      return response
          .map((item) => BooksLanguagesModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
