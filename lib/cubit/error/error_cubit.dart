// error_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

part 'error_state.dart';

class ErrorCubit extends Cubit<ErrorState> {
  ErrorCubit() : super(ErrorInitial());

  Future<void> sendError(String error) async {
    emit(ErrorLoading());

    try {
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown';
      String version = 'Unknown';
      String manufacturer = 'Unknown';

      try {
        final androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
        version = androidInfo.version.release;
        manufacturer = androidInfo.manufacturer;
      } catch (_) {}

      final docId = const Uuid().v4();

      await FirebaseFirestore.instance.collection('app_errors').doc(docId).set({
        'error': error,
        'userMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
        'device': {
          'model': model,
          'version': version,
          'manufacturer': manufacturer,
        },
      });

      emit(ErrorLoaded(docId: docId));
    } catch (e) {
      emit(ErrorFailure(message: 'Failed to send error'));
    }
  }

  Future<void> submitFeedback(String message) async {
    final currentState = state;
    if (currentState is ErrorLoaded) {
      emit(ErrorSubmitting());
      try {
        await FirebaseFirestore.instance
            .collection('app_errors')
            .doc(currentState.docId)
            .update({
          'userMessage': message,
          'userMessageTimestamp': FieldValue.serverTimestamp(),
        });
        emit(ErrorSubmitted());
      } catch (e) {
        emit(ErrorFailure(message: 'Failed to submit feedback'));
      }
    }
  }
}
