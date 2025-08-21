import 'package:dio/dio.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/details_services.dart';
import 'package:huda/data/models/hadith_details_model.dart';

class DetailsRepository {
  final DetailsServices detailsServices;

  DetailsRepository({required this.detailsServices});

  Future<HadithDetailsModel> getHadithDetails(
      String chapterId, String bookId,int pageNumber) async {
    try {
      final response = await detailsServices.getAllDetails(chapterId, bookId,pageNumber);
      return HadithDetailsModel.fromJson(response);
    } on DioException catch (e) {
      throw getDioErrorMessage(e);
    }
  }
}
