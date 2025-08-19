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
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getChaptersByBook(String bookId) async {
    try {
      final Response response = await dio.get(
        EndPoints.bookChapter(bookId),
        queryParameters: {
          'apiKey': apiKey,
        },
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }

      if (response.data['status'] >= 400) {
        throw DioException(requestOptions: RequestOptions());
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
