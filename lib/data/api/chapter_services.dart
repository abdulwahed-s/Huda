import 'package:flutter/foundation.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';
import 'package:huda/core/keys/hadith_key.dart';

class ChapterServices {
  late Dio dio;
  ChapterServices() {
    BaseOptions options = BaseOptions(
        baseUrl: EndPoints.hadithBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "X-API-Key": apiKey,
        });
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getChaptersByBook(String bookName) async {
    try {
      if (kIsWeb) {
        final fullUrl =
            '${EndPoints.hadithBaseUrl}${EndPoints.bookChapter(bookName)}?limit=100';
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
        final Response response = await dio.get(
          EndPoints.bookChapter(bookName),
          queryParameters: {
            'limit': 100,
          },
        );

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
