import 'package:huda/core/class/dio_errors.dart';
import 'package:dio/dio.dart';

class RadioServices {
  late Dio dio;
  RadioServices() {
    BaseOptions options = BaseOptions(
      baseUrl: 'https://mp3quran.net/api/v3',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getRadios(String language) async {
    try {
      final Response response = await dio.get(
        '/radios',
        queryParameters: {
          'language': language,
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
