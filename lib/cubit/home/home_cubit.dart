import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ReadingPositionService _readingPositionService =
      getIt<ReadingPositionService>();

  HomeCubit() : super(HomeInitial()) {
    loadHomeData();
  }

  void loadHomeData() {
    try {
      emit(HomeLoading());

      final hasLastRead = _readingPositionService.hasLastReadPosition();
      final lastReadSummary = _readingPositionService.getLastReadSummary();

      emit(HomeLoaded(
        hasLastReadPosition: hasLastRead,
        lastReadSummary: lastReadSummary,
      ));
    } catch (e) {
      emit(HomeError(message: 'Failed to load home data: $e'));
    }
  }

  Map<String, dynamic>? getLastReadPosition() {
    return _readingPositionService.getLastReadSummary();
  }

  Future<void> clearLastReadPosition() async {
    try {
      await _readingPositionService.clearLastReadPosition();
      loadHomeData();
    } catch (e) {
      emit(HomeError(message: 'Failed to clear last read position: $e'));
    }
  }

  void refresh() {
    loadHomeData();
  }
}
