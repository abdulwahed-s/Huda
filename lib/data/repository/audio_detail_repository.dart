import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/audio_detail_services.dart';
import 'package:huda/data/models/audio_detail_model.dart';

class AudioDetailRepository {
  final AudioDetailServices audioDetailServices;

  AudioDetailRepository({required this.audioDetailServices});

  Future<AudioDetailModel> getAudioDetail(String lang, int audioId) async {
    try {
      final response = await audioDetailServices.getAudioDetail(lang, audioId);
      return AudioDetailModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
