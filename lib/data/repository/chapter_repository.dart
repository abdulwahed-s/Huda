import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/chapter_services.dart';
import 'package:huda/data/models/book_chapters_model.dart';

class ChapterRepository {
  final ChapterServices chapterServices;

  ChapterRepository({required this.chapterServices});

  Future<BookChaptersModel> getChaptersByBook(String bookId) async {
    try {
      final response = await chapterServices.getChaptersByBook(bookId);
      return BookChaptersModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
