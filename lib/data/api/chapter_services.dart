import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';
import 'package:huda/core/keys/hadith_key.dart';

class ChapterServices {
  late Dio dio;
  ChapterServices() {
    BaseOptions options = BaseOptions(
        baseUrl: EndPoints.hadithBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "X-API-Key": apiKey,
        });
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getChaptersByBook(String bookName) async {
    try {
      final Response response = await dio.get(
        EndPoints.bookChapter(bookName),
        queryParameters: {
          'limit': 100,
        },
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
