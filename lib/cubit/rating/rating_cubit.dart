import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

part 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  late RateMyApp _rateMyApp;

  RatingCubit() : super(RatingInitial()) {
    _initializeRateMyApp();
  }

  void _initializeRateMyApp() {
    _rateMyApp = RateMyApp(
      preferencesPrefix: 'rateMyApp_',
      minDays: 3,
      minLaunches: 7,
      remindDays: 5,
      remindLaunches: 10,
      googlePlayIdentifier: 'com.aw.huda',
      appStoreIdentifier: '1234567890',
    );
  }

  Future<void> checkIfShouldShowDialog() async {
    emit(RatingLoading());

    try {
      await _rateMyApp.init();

      if (_rateMyApp.shouldOpenDialog) {
        emit(RatingReady(shouldShow: true));
      } else {
        emit(RatingReady(shouldShow: false));
      }
    } catch (e) {
      emit(RatingFailure(message: 'Failed to check rating status'));
    }
  }

  Future<void> handleRating(int rating, {String? comment}) async {
    emit(RatingSubmitting());

    try {
      if (rating >= 4) {
        await _rateMyApp.launchStore();
        await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
        emit(RatingSubmitted(rating: rating, message: 'Redirected to store'));
      } else {
        await _submitFeedback(rating, comment ?? '');
        await _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
        emit(RatingSubmitted(rating: rating, message: 'Feedback collected'));
      }
    } catch (e) {
      emit(RatingFailure(message: 'Failed to handle rating'));
    }
  }

  Future<void> _submitFeedback(int rating, String feedback) async {
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

      await FirebaseFirestore.instance
          .collection('app_feedback')
          .doc(docId)
          .set({
        'rating': rating,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'app_rating',
        'device': {
          'model': model,
          'version': version,
          'manufacturer': manufacturer,
        },
      });
    } catch (e) {
      throw Exception('Failed to submit feedback');
    }
  }

  Future<void> submitDetailedFeedback(String feedback) async {
    emit(FeedbackSubmitting());

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

      await FirebaseFirestore.instance
          .collection('app_feedback')
          .doc(docId)
          .set({
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'detailed_feedback',
        'device': {
          'model': model,
          'version': version,
          'manufacturer': manufacturer,
        },
      });

      emit(FeedbackSubmitted());
    } catch (e) {
      emit(FeedbackFailure(message: 'Failed to submit feedback'));
    }
  }

  Future<void> callLater() async {
    await _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
    emit(RatingReady(shouldShow: false));
  }

  Future<void> callNever() async {
    await _rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
    emit(RatingReady(shouldShow: false));
  }

  RateMyApp get rateMyApp => _rateMyApp;
}
