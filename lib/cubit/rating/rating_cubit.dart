import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appStoreIdentifier: '6757343816',
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

  static const String _microsoftStoreProductId = '9p68h8m1g92b';

  Future<void> handleRating(int rating, {String? comment, String? contactEmail}) async {
    emit(RatingSubmitting());

    try {
      if (rating >= 4) {
        await _launchStoreForRating();
        await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
        emit(RatingSubmitted(rating: rating, message: 'Redirected to store'));
      } else {
        await _submitFeedback(rating, comment ?? '', contactEmail: contactEmail);
        await _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
        emit(RatingSubmitted(rating: rating, message: 'Feedback collected'));
      }
    } catch (e) {
      emit(RatingFailure(message: 'Failed to handle rating'));
    }
  }

  Future<void> _launchStoreForRating() async {
    if (Platform.isWindows) {
      final storeUrl = Uri.parse(
        'ms-windows-store://review/?ProductId=$_microsoftStoreProductId',
      );
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl);
      } else {
        final webUrl = Uri.parse(
          'https://apps.microsoft.com/detail/$_microsoftStoreProductId',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      await _rateMyApp.launchStore();
    }
  }

  Future<void> _submitFeedback(int rating, String feedback, {String? contactEmail}) async {
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

  Future<void> submitDetailedFeedback(String feedback, {String? contactEmail}) async {
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
    await _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
    emit(RatingReady(shouldShow: false));
  }

  Future<void> callNever() async {
    await _rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
    emit(RatingReady(shouldShow: false));
  }

  RateMyApp get rateMyApp => _rateMyApp;
}
