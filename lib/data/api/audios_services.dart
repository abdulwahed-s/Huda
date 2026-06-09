import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class AudiosServices {
  late Dio dio;
  AudiosServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.islamhouseBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> getAllAudios(
      String lang, int page, String respLang) async {
    try {
      final Response response = await dio.get(
        EndPoints.audios(lang, page, respLang),
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
