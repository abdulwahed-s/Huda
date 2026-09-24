import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/services/app_review_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'rating_state.dart';

enum FeedbackCategory {
  issue('issue'),
  featureRequest('feature_request'),
  general('general_feedback');

  const FeedbackCategory(this.storageValue);

  final String storageValue;
}

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

  Future<void> handleRating(
    int rating, {
    String? comment,
    String? contactEmail,
  }) async {
    emit(RatingSubmitting());

    try {
      if (rating >= 4) {
        await AppReviewService.launchReviewPage();
        await AppReviewService.recordDoNotAskAgain();
        emit(RatingSubmitted(rating: rating, message: 'Redirected to store'));
      } else {
        await _submitRatingFeedback(
          rating,
          comment ?? '',
          contactEmail: contactEmail,
        );
        await AppReviewService.recordRemindLater();
        emit(RatingSubmitted(rating: rating, message: 'Feedback collected'));
      }
    } catch (e) {
      emit(RatingFailure(message: 'Failed to handle rating'));
    }
  }

  Future<void> _submitRatingFeedback(
    int rating,
    String feedback, {
    String? contactEmail,
  }) async {
    try {
      await Supabase.instance.client.from('app_feedback').insert({
        'type': 'rating',
        'rating': rating,
        'text': feedback,
        'device': await _collectDeviceDetails(),
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contact_email': contactEmail,
      });
    } catch (e) {
      throw Exception('Failed to submit feedback');
    }
  }

  Future<void> submitFeedback(
    String feedback, {
    required FeedbackCategory category,
    String? contactEmail,
  }) async {
    emit(FeedbackSubmitting());

    try {
      await Supabase.instance.client.from('app_feedback').insert({
        'type': category.storageValue,
        'text': feedback,
        'device': await _collectDeviceDetails(),
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contact_email': contactEmail,
      });

      emit(FeedbackSubmitted());
    } catch (e) {
      emit(FeedbackFailure(message: 'Failed to submit feedback'));
    }
  }

  Future<Map<String, String>> _collectDeviceDetails() async {
    final details = <String, String>{
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'model': 'Unknown',
      'version': 'Unknown',
      'manufacturer': 'Unknown',
      'app_version': 'Unknown',
    };

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      details['app_version'] =
          '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final info = await deviceInfo.webBrowserInfo;
        details
          ..['model'] = info.platform ?? 'Web browser'
          ..['version'] = info.appVersion ?? 'Unknown'
          ..['manufacturer'] = info.vendor ?? 'Unknown'
          ..['browser'] = info.browserName.name;
        return details;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;
          details
            ..['model'] = info.model
            ..['version'] = info.version.release
            ..['manufacturer'] = info.manufacturer;
          break;
        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;
          details
            ..['model'] = info.modelName
            ..['version'] = info.systemVersion
            ..['manufacturer'] = 'Apple';
          break;
        case TargetPlatform.macOS:
          final info = await deviceInfo.macOsInfo;
          details
            ..['model'] = info.modelName
            ..['version'] = info.osRelease
            ..['manufacturer'] = 'Apple';
          break;
        case TargetPlatform.windows:
          final info = await deviceInfo.windowsInfo;
          details
            ..['model'] = info.productName
            ..['version'] =
                '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}'
            ..['manufacturer'] = 'Microsoft';
          break;
        case TargetPlatform.linux:
          final info = await deviceInfo.linuxInfo;
          details
            ..['model'] = info.prettyName
            ..['version'] = info.version ?? info.versionId ?? 'Unknown'
            ..['manufacturer'] = info.name;
          break;
        case TargetPlatform.fuchsia:
          break;
      }
    } catch (_) {}

    return details;
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
