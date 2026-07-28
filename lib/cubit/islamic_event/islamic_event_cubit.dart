import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:huda/core/services/islamic_event_service.dart';
import 'package:huda/data/models/islamic_event_config.dart';

part 'islamic_event_state.dart';

class IslamicEventCubit extends Cubit<IslamicEventState> {
  final IslamicEventService _service;
  Timer? _refreshTimer;
  Future<void>? _activeLoad;

  IslamicEventCubit({
    required IslamicEventService service,
    bool loadOnCreate = true,
  })  : _service = service,
        super(IslamicEventInitial()) {
    if (loadOnCreate) loadActiveEvent();
  }

  Future<void> loadActiveEvent() {
    final activeLoad = _activeLoad;
    if (activeLoad != null) return activeLoad;

    final load = _loadActiveEvent();
    _activeLoad = load;
    return load;
  }

  Future<void> _loadActiveEvent() async {
    if (state is IslamicEventInitial) emit(IslamicEventLoading());
    try {
      final event = await _service.getActiveEvent();
      if (event != null) {
        final current = state;
        if (current is! IslamicEventActive || current.event != event) {
          emit(IslamicEventActive(event: event));
        }
      } else {
        if (state is! IslamicEventNone) emit(IslamicEventNone());
      }
    } catch (_) {
      if (state is! IslamicEventNone) emit(IslamicEventNone());
    } finally {
      _activeLoad = null;
      if (!isClosed) _scheduleNextRefresh();
    }
  }

  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();
    try {
      final refreshAt = _service.nextRefreshAt();
      if (refreshAt == null) return;
      final delay = refreshAt.difference(DateTime.now());
      _refreshTimer = Timer(
        delay <= Duration.zero ? const Duration(seconds: 1) : delay,
        () {
          if (!isClosed) loadActiveEvent();
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
