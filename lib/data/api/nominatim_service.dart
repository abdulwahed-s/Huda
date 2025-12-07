import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/core/constants/end_points.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/data/models/placemark_model.dart';

class NominatimService {
  final Dio dio;

  NominatimService()
      : dio = Dio(BaseOptions(
          baseUrl: EndPoints.googleMapsBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<PlacemarkModel> getPlacemark(double lat, double lon) async {
    try {
      final response = await dio.get(
          EndPoints.googleMapsReverseGeocoding(lat, lon, googleMapsApiKey));
      return PlacemarkModel.fromJson(response.data);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
