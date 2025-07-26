import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class BooksLanguagesServices {
  late Dio dio;
  BooksLanguagesServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.islamhouseBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<List<dynamic>> getBookLanguages(int bookId) async {
    try {
      final Response response = await dio.get(
        EndPoints.bookLanguages(bookId),
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }

      if (response.data is Map<String, dynamic> &&
          response.data['code'] == 204) {
        return [];
      }
      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
