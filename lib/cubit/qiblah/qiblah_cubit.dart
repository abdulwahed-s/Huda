import 'package:meta/meta.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';

part 'qiblah_state.dart';

class QiblahCubit extends Cubit<QiblahState> {
  QiblahCubit() : super(QiblahInitial());

  Future<void> loadQiblah() async {
    emit(QiblahLoading());

    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          emit(QiblahPermissionDenied("Location service is disabled"));

          return;
        }
      }
      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission == PermissionStatus.deniedForever) {
        emit(QiblahPermissionDeniedForever(
            "Location permission permanently denied. Please enable it from app settings."));
        return;
      }
      if (permission != PermissionStatus.granted) {
        emit(QiblahPermissionDenied("Location permission denied"));
        return;
      }

      emit(QiblahReady());
    } catch (e) {
      emit(QiblahError(e.toString()));
    }
  }
}
