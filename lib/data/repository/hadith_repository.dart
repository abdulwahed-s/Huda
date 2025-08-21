import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/hadith_services.dart';
import 'package:huda/data/models/hadith_books_model.dart';

class HadithRepository {
  final HadithServices hadithServices;

  HadithRepository({required this.hadithServices});

  Future<HadithBooksModel> getAllBooks() async {
    try {
      final response = await hadithServices.getAllBooks();
      return HadithBooksModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
