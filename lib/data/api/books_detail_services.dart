import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class BooksDetailServices {
  late Dio dio;
  BooksDetailServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.islamhouseBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getBookDetail(String lang, int bookId) async {
    try {
      final Response response = await dio.get(
        EndPoints.bookDetail(lang, bookId),
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }
      if (response.data is Map<String, dynamic> &&
          response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
