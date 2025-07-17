import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class TafsirServices {
  late Dio dio;
  TafsirServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.baseUrl,
      connectTimeout:
          const Duration(seconds: 60), 
      receiveTimeout: const Duration(
          seconds: 120), 
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getTafsir() async {
    try {
      final Response response = await dio.get(
        EndPoints.edition,
        queryParameters: {
          'type': 'tafsir',
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

  Future<Map<String, dynamic>> getSuraTafsir(
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
      print(response.data);
      return response.data;
    } on DioException catch (e) {
      print(e);
      throw Exception(getDioErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getFullQuranTafsir(String identifier) async {
    print(
        "🌐 API Service: Starting getFullQuranTafsir for identifier: $identifier");
    print(
        "🔗 API Service: Making request to: ${EndPoints.surahEdition(identifier)}");
    try {
      final Response response = await dio.get(
        EndPoints.surahEdition(identifier),
      );
      print(
          "✅ API Service: Received response with status code: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ API Service: Bad status code: ${response.statusCode}");
        throw DioException(requestOptions: RequestOptions());
      }

      if (response.data['code'] >= 400) {
        print(
            "❌ API Service: API returned error code: ${response.data['code']}");
        throw DioException(requestOptions: RequestOptions());
      }

      print("✅ API Service: Response data received successfully");
      print(
          "📊 API Service: Data size: ${response.data.toString().length} characters");
      return response.data;
    } on DioException catch (e) {
      print("❌ API Service: DioException occurred: $e");
      print("❌ API Service: DioException message: ${e.message}");
      print("❌ API Service: DioException type: ${e.type}");
      throw Exception(getDioErrorMessage(e));
    } catch (e) {
      print("❌ API Service: Unexpected error: $e");
      print("❌ API Service: Error type: ${e.runtimeType}");
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }
}
