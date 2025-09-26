import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/tafsir_services.dart';
import 'package:huda/data/models/edition_model.dart';
import 'package:huda/data/models/tafsir_model.dart';

class TafsirRepository {
  final TafsirServices tafsirServices;

  TafsirRepository({required this.tafsirServices});

  Future<EditionModel> getTafsir() async {
    try {
      final response = await tafsirServices.getTafsir();
      return EditionModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getSurahTafsir(String identifier, int number) async {
    try {
      final response = await tafsirServices.getSuraTafsir(identifier, number);
      return TafsirModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getFullQuranTafsir(String identifier) async {
    try {
      final response = await tafsirServices.getFullQuranTafsir(identifier);
      final tafsirModel = TafsirModel.fromJson(response);
      return tafsirModel;
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }
}
