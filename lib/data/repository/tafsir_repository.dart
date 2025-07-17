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
      print(response);
      return EditionModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getSurahTafsir(String identifier, int number) async {
    try {
      final response = await tafsirServices.getSuraTafsir(identifier, number);
      print(response);
      return TafsirModel.fromJson(response);
    } on DioException catch (e) {
      print(e);
      throw getDioErrorMessage(e);
    }
  }

  Future<TafsirModel> getFullQuranTafsir(String identifier) async {
    print(
        "🔄 Repository: Starting getFullQuranTafsir for identifier: $identifier");
    try {
      final response = await tafsirServices.getFullQuranTafsir(identifier);
      print("✅ Repository: Received response from API service");
      print(
          "📊 Repository: Response data size: ${response.toString().length} characters");
      final tafsirModel = TafsirModel.fromJson(response);
      print("✅ Repository: Successfully parsed TafsirModel");
      return tafsirModel;
    } on DioException catch (e) {
      print("❌ Repository: DioException occurred: $e");
      print("❌ Repository: DioException details: ${e.message}");
      print("❌ Repository: DioException type: ${e.type}");
      throw getDioErrorMessage(e);
    } catch (e) {
      print("❌ Repository: Unexpected error: $e");
      print("❌ Repository: Error type: ${e.runtimeType}");
      rethrow;
    }
  }
}
