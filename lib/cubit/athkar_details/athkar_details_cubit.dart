import 'package:bloc/bloc.dart';
import 'package:huda/data/api/athkar_services.dart';
import 'package:huda/data/models/athkar_detail_model.dart';
import 'package:huda/data/repository/athkar_repository.dart';
import 'package:meta/meta.dart';

part 'athkar_details_state.dart';

class AthkarDetailsCubit extends Cubit<AthkarDetailsState> {
  AthkarDetailsCubit() : super(AthkarDetailsInitial());

  AthkarRepository athkarRepository = AthkarRepository(AthkarService());

  Future<void> loadAthkarDetail(String id) async {
    emit(AthkarDetailsLoading());
    try {
      final athkarDetail = await athkarRepository.getAthkarDetail(id);
      emit(AthkarDetailsLoaded(athkarDetail));
    } catch (e) {
      emit(AthkarDetailsError(e.toString()));
    }
  }
}
