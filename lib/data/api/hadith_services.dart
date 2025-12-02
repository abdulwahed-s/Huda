import 'package:flutter/foundation.dart';
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
        headers: {"X-API-Key": apiKey});
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllBooks() async {
    try {
      if (kIsWeb) {
        final fullUrl = '${EndPoints.hadithBaseUrl}${EndPoints.hadithBooks}';
        final proxyUrl =
            'https://corsproxy.io/?${Uri.encodeComponent(fullUrl)}';

        final Response response = await dio.get(
          proxyUrl,
          options: Options(
            headers: {
              "X-API-Key": apiKey,
              "Origin": "http://localhost:8080",
            },
            extra: {'baseUrl': ''},
          ),
        );

        if (response.statusCode != 200) {
          throw DioException(requestOptions: RequestOptions());
        }

        return response.data;
      } else {
        final Response response = await dio.get(EndPoints.hadithBooks);

        if (response.statusCode != 200) {
          throw DioException(requestOptions: RequestOptions());
        }

        return response.data;
      }
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
