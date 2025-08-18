import 'package:bloc/bloc.dart';
import 'package:huda/data/api/details_services.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/data/repository/details_repository.dart';
import 'package:meta/meta.dart';

part 'hadith_details_state.dart';

class HadithDetailsCubit extends Cubit<HadithDetailsState> {
  HadithDetailsCubit() : super(HadithDetailsInitial());

  final DetailsRepository detailsRepository =
      DetailsRepository(detailsServices: DetailsServices());

  Future<void> fetchHadithDetails(String chapterId, String bookId,int pageNumber) async {
    emit(HadithDetailsLoading());
    try {
      final hadithDetail =
          await detailsRepository.getHadithDetails(chapterId, bookId,pageNumber);
      emit(HadithDetailsLoaded(hadithDetail));
    } catch (e) {
      emit(HadithDetailsError(e.toString()));
    }
  }
}
