import 'package:meta/meta.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/geolocator.dart';

part 'qiblah_state.dart';

class QiblahCubit extends Cubit<QiblahState> {
  QiblahCubit() : super(QiblahInitial());

  Future<void> loadQiblah() async {
    emit(QiblahLoading());

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(QiblahPermissionDenied("Location service is disabled"));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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
