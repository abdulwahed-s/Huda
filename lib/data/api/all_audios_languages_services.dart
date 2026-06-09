import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:dio/dio.dart';

class AllAudiosLanguagesServices {
  late Dio dio;
  AllAudiosLanguagesServices() {
    BaseOptions options = BaseOptions(
      baseUrl: EndPoints.islamhouseBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    dio = Dio(options);
  }

  Future<List<dynamic>> getAudiosLanguages(String lang) async {
    try {
      final Response response = await dio.get(
        EndPoints.allAudiosLanguages(lang),
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
