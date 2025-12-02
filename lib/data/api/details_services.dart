import 'package:flutter/foundation.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';
import 'package:huda/core/keys/hadith_key.dart';

class DetailsServices {
  late Dio dio;
  DetailsServices() {
    BaseOptions options = BaseOptions(
        baseUrl: EndPoints.hadithBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'X-API-Key': apiKey,
        });
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllDetails(
      String chapterNumber, String bookName, int pageNumber) async {
    try {
      if (kIsWeb) {
        final fullUrl =
            '${EndPoints.hadithBaseUrl}${EndPoints.hadithDetail(bookName, chapterNumber)}?page=$pageNumber';
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

        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('error')) {
          throw Exception('Server Error');
        }
        
        return data;
      } else {
        final Response response = await dio.get(
          EndPoints.hadithDetail(bookName, chapterNumber),
          queryParameters: {
            'page': pageNumber,
          },
        );

        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('error')) {
          throw Exception('Server Error');
        }

        return data;
      }
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
