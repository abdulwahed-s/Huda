import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class AudioServices {
  late Dio dio;
  AudioServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllAudio() async {
    try {
      final Response response = await dio.get(
        EndPoints.edition,
        queryParameters: {
          'format': 'audio',
        },
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }

      if (response.data['code'] >= 400) {
        throw DioException(requestOptions: RequestOptions());
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSuraAudio(String identifier) async {
    try {
      final Response response = await dio.get(
        EndPoints.surahEdition(identifier),
      );

      if (response.statusCode != 200) {
        throw DioException(requestOptions: RequestOptions());
      }

      if (response.data['code'] >= 400) {
        throw DioException(requestOptions: RequestOptions());
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
