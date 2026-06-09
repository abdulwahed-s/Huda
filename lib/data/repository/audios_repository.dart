import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/audios_services.dart';
import 'package:huda/data/models/audios_response.dart';

class AudiosRepository {
  final AudiosServices audiosServices;

  AudiosRepository({required this.audiosServices});

  Future<AudiosResponse> getAllAudios(
      String lang, int page, String respLang) async {
    try {
      final response = await audiosServices.getAllAudios(lang, page, respLang);
      return AudiosResponse.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
