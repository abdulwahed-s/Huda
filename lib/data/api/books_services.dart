import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class BooksServices {
  late Dio dio;
  BooksServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.islamhouseBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllBooks(String lang, int page) async {
    try {
      final Response response = await dio.get(
        EndPoints.books(lang, page),
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
