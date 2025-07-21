import 'package:bloc/bloc.dart';
import 'package:huda/data/api/athkar_services.dart';
import 'package:huda/data/models/ahtkar_item_model.dart';
import 'package:huda/data/repository/athkar_repository.dart';
import 'package:meta/meta.dart';

part 'athkar_state.dart';

class AthkarCubit extends Cubit<AthkarState> {
  AthkarCubit() : super(AthkarInitial());
  final AthkarRepository athkarRepository = AthkarRepository(AthkarService());

  Future<void> loadAthkar() async {
    emit(AthkarLoading());
    try {
      final athkarList = await athkarRepository.getAthkarList();
      emit(AthkarLoaded(athkarList));
    } catch (e) {
      emit(AthkarError(e.toString()));
    }
  }
}
