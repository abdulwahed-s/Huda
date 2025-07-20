import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class AthkarService {
  final Dio dio;

  AthkarService()
      : dio = Dio(BaseOptions(
          baseUrl: EndPoints.baseUrlAthkar,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<Map<String, dynamic>> getArabicAthkar() async {
    try {
      final response = await dio.get(EndPoints.arAthkar);
      return response.data;
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> getEnglishAthkar() async {
    try {
      final response = await dio.get(EndPoints.enAthkar);
      return response.data;
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> getAthkarDetail(String id) async {
    try {
      final response = await dio.get(EndPoints.athkarDetail(id));
      return response.data;
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
