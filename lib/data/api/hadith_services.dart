import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';
import 'package:huda/core/keys/hadith_key.dart';

class HadithServices {
  late Dio dio;
  HadithServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.hadithBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllBooks() async {
    try {
      final Response response = await dio.get(
        EndPoints.hadithBooks,
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
