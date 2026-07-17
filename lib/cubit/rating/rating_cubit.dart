import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/services/app_review_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

part 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  RatingCubit() : super(RatingInitial());

  Future<void> checkIfShouldShowDialog() async {
    emit(RatingLoading());

    try {
      final shouldShow = await AppReviewService.recordLaunchAndEvaluate();
      emit(RatingReady(shouldShow: shouldShow));
    } catch (e) {
      emit(RatingFailure(message: 'Failed to check rating status'));
    }
  }

  Future<void> handleRating(int rating,
      {String? comment, String? contactEmail}) async {
    emit(RatingSubmitting());

    try {
      if (rating >= 4) {
        await AppReviewService.launchReviewPage();
        await AppReviewService.recordDoNotAskAgain();
        emit(RatingSubmitted(rating: rating, message: 'Redirected to store'));
      } else {
        await _submitFeedback(rating, comment ?? '',
            contactEmail: contactEmail);
        await AppReviewService.recordRemindLater();
        emit(RatingSubmitted(rating: rating, message: 'Feedback collected'));
      }
    } catch (e) {
      emit(RatingFailure(message: 'Failed to handle rating'));
    }
  }

  Future<void> _submitFeedback(int rating, String feedback,
      {String? contactEmail}) async {
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

      await Supabase.instance.client.from('app_feedback').insert({
        'type': 'rating',
        'rating': rating,
        'text': feedback,
        'device': {
          'model': model,
          'version': version,
          'manufacturer': manufacturer,
        },
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contact_email': contactEmail,
      });
    } catch (e) {
      throw Exception('Failed to submit feedback');
    }
  }

  Future<void> submitDetailedFeedback(String feedback,
      {String? contactEmail}) async {
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

      await Supabase.instance.client.from('app_feedback').insert({
        'type': 'detailed',
        'text': feedback,
        'device': {
          'model': model,
          'version': version,
          'manufacturer': manufacturer,
        },
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contact_email': contactEmail,
      });

      emit(FeedbackSubmitted());
    } catch (e) {
      emit(FeedbackFailure(message: 'Failed to submit feedback'));
    }
  }

  Future<void> callLater() async {
    await AppReviewService.recordRemindLater();
    emit(RatingReady(shouldShow: false));
  }

  Future<void> callNever() async {
    await AppReviewService.recordDoNotAskAgain();
    emit(RatingReady(shouldShow: false));
  }
}
