import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class TranslationServices {
  late Dio dio;
  TranslationServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getTranslation() async {
    try {
      final Response response = await dio.get(
        EndPoints.edition,
        queryParameters: {
          'type': 'translation',
          'format': 'text',
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

  Future<Map<String, dynamic>> getSuraTranslation(
      String identifier, int number) async {
    try {
      final Response response = await dio.get(
        EndPoints.oneSurahEdition(identifier, number),
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

  Future<Map<String, dynamic>> getFullQuranTranslation(
      String identifier) async {
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
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }
}
