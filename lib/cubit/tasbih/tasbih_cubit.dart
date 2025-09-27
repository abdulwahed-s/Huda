import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:vibration/vibration.dart';

part 'tasbih_state.dart';

class TasbihCubit extends Cubit<TasbihState> {
  TasbihCubit() : super(TasbihInitial());
  CacheHelper cacheHelper = getIt<CacheHelper>();
  int count = 0;
  bool mode = true;
  String? note;
  TextEditingController noteController = TextEditingController();

  void increment() async {
    count++;

    if (count % 5 == 0) {
      saveTasbih();
    }

    if (mode) {
      Future.microtask(() async {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 50);
        }
      });
    }

    emit(TasbihLoaded(count, mode, note));
  }

  @override
  Future<void> close() {
    saveTasbih();
    return super.close();
  }

  void reset() {
    count = 0;
    saveTasbih();
    emit(TasbihLoaded(count, mode, note));
  }

  void changeMode(bool newMode) {
    mode = newMode;
    emit(TasbihLoaded(count, mode, note));
  }

  void loadTasbih() {
    emit(TasbihLoading());
    try {
      count = cacheHelper.getData(key: 'tasbih_count') ?? 0;
      mode = cacheHelper.getData(key: 'tasbih_mode') ?? true;
      note = cacheHelper.getData(key: 'tasbih_note');
      noteController.text = note ?? '';
      emit(TasbihLoaded(count, mode, note));
    } catch (e) {
      emit(TasbihError(e.toString()));
    }
  }

  void saveTasbih() {
    cacheHelper.saveData(key: 'tasbih_count', value: count);
    cacheHelper.saveData(key: 'tasbih_mode', value: mode);
    cacheHelper.saveData(key: 'tasbih_note', value: note);
  }

  void toggleVibration() async {
    if (mode) {
      if (await Vibration.hasVibrator()) {
        if (await Vibration.hasCustomVibrationsSupport()) {
          if (await Vibration.hasAmplitudeControl()) {
            Vibration.vibrate(duration: 50, amplitude: 128);
          } else {
            Vibration.vibrate(duration: 50);
          }
        } else {
          Vibration.vibrate();
        }
      }
    }
  }

  void setNote() {
    note = noteController.text;
    saveTasbih();
    emit(TasbihLoaded(count, mode, note));
  }

  void clearNote() {
    note = null;
    noteController.clear();
    saveTasbih();
    emit(TasbihLoaded(count, mode, note));
  }
}
