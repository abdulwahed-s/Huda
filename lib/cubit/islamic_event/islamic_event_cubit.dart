import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:huda/core/services/islamic_event_service.dart';
import 'package:huda/data/models/islamic_event_config.dart';

part 'islamic_event_state.dart';

class IslamicEventCubit extends Cubit<IslamicEventState> {
  final IslamicEventService _service;

  IslamicEventCubit({
    required IslamicEventService service,
    bool loadOnCreate = true,
  })  : _service = service,
        super(IslamicEventInitial()) {
    if (loadOnCreate) loadActiveEvent();
  }

  Future<void> loadActiveEvent() async {
    emit(IslamicEventLoading());
    try {
      final event = await _service.getActiveEvent();
      if (event != null) {
        emit(IslamicEventActive(event: event));
      } else {
        emit(IslamicEventNone());
      }
    } catch (_) {
      emit(IslamicEventNone());
    }
  }
}
