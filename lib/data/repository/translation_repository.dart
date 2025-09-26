import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/translation_services.dart';
import 'package:huda/data/models/edition_model.dart';
import 'package:huda/data/models/tafsir_model.dart';

class TranslationRepository {
  final TranslationServices translationServices;

  TranslationRepository({required this.translationServices});

  Future<EditionModel> getTranslation() async {
    try {
      final response = await translationServices.getTranslation();
      return EditionModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getSurahTranslation(String identifier, int number) async {
    try {
      final response =
          await translationServices.getSuraTranslation(identifier, number);
      return TafsirModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getFullQuranTranslation(String identifier) async {
    try {
      final response =
          await translationServices.getFullQuranTranslation(identifier);

      final tafsirModel = TafsirModel.fromJson(response);
      return tafsirModel;
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }
}
