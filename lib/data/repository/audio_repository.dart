import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/audio_services.dart';
import 'package:huda/data/models/edition_model.dart';
import 'package:huda/data/models/surah_audio_model.dart';

class AudioRepository {
  final AudioServices audioServices;

  AudioRepository({required this.audioServices});

  Future<EditionModel> getAudio() async {
    try {
      final response = await audioServices.getAllAudio();
      print(response);
      return EditionModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<SurahAudioModel> getSurahAudio(String identifier) async {
    try {
      final response = await audioServices.getSuraAudio(identifier);
      print(response);
      return SurahAudioModel.fromJson(response);
    } on DioException catch (e) {
      print(e);
      throw getDioErrorMessage(e);
    }
  }
}
