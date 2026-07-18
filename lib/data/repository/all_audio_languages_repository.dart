import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/all_audios_languages_services.dart';
import 'package:huda/data/models/audio_languages_model.dart';

class AllAudioLanguagesRepository {
  final AllAudiosLanguagesServices allAudiosLanguagesServices;

  AllAudioLanguagesRepository({required this.allAudiosLanguagesServices});

  Future<List<AudioLanguageModel>> getAllAudioLanguages(String lang) async {
    try {
      final response =
          await allAudiosLanguagesServices.getAudiosLanguages(lang);
      return response.map((item) => AudioLanguageModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
