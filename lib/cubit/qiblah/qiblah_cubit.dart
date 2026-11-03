import 'package:meta/meta.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/geolocator.dart';

part 'qiblah_state.dart';

class QiblahCubit extends Cubit<QiblahState> {
  QiblahCubit() : super(QiblahInitial());

  /// Set once Qiblah has shown the system's location prompt.
  static const askedKey = 'qiblah_location_asked';

  /// Checks location and loads the compass. The system prompt shows on the
  /// first visit only; after that, only when the person taps "Allow
  /// location" ([ask]), so opening Qiblah never nags.
  Future<void> loadQiblah({bool ask = false}) async {
    emit(QiblahLoading());

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(QiblahLocationServiceOff("Location service is disabled"));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final prefs = CacheHelper.sharedPreferences;
        if (ask || !(prefs.getBool(askedKey) ?? false)) {
          await prefs.setBool(askedKey, true);
          permission = await Geolocator.requestPermission();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(QiblahPermissionDeniedForever(
            "Location permission permanently denied. Please enable it from app settings."));
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        emit(QiblahPermissionDenied("Location permission denied"));
        return;
      }

      emit(QiblahReady());
    } catch (e) {
      emit(QiblahError(e.toString()));
    }
  }
}
