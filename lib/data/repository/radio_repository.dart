import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/radio_services.dart';
import 'package:huda/data/models/radio_station_model.dart';

class RadioRepository {
  final RadioServices radioServices;

  RadioRepository({required this.radioServices});

  Future<RadioStationModel> getRadios(String language) async {
    try {
      final response = await radioServices.getRadios(language);
      return RadioStationModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
