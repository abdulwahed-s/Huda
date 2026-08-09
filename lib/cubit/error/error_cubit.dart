// error_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/services/crash_reporting_consent.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'error_state.dart';

class ErrorCubit extends Cubit<ErrorState> {
  ErrorCubit() : super(ErrorInitial());

  Future<void> sendFlutterError(FlutterErrorDetails details) async {
    if (details.silent) return;

    await sendError(details.exceptionAsString());
  }

  Future<void> sendError(String error) async {
    if (kDebugMode) return;
    if (!await CrashReportingConsent.canReport()) {
      emit(ErrorReportingDisabled());
      return;
    }

    emit(ErrorLoading());

    try {
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown';
      String version = 'Unknown';
      String manufacturer = 'Unknown';
      String appVersion = 'Unknown';

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (_) {}

      try {
        final androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
        version = androidInfo.version.release;
        manufacturer = androidInfo.manufacturer;
      } catch (_) {}

      final result = await Supabase.instance.client
          .from('error_reports')
          .insert({
            'error': error,
            'user_message': '',
            'device': {
              'model': model,
              'version': version,
              'manufacturer': manufacturer,
            },
            'app_version': appVersion,
          })
          .select('id')
          .single();

      final docId = result['id'] as String;
      emit(ErrorLoaded(docId: docId));
    } catch (e) {
      emit(ErrorFailure(message: 'Failed to send error'));
    }
  }

  Future<void> submitFeedback(String message, {String? contactEmail}) async {
    final currentState = state;
    if (currentState is ErrorLoaded) {
      emit(ErrorSubmitting());
      try {
        await Supabase.instance.client.from('error_reports').update({
          'user_message': message,
          if (contactEmail != null && contactEmail.isNotEmpty)
            'contact_email': contactEmail,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentState.docId);
        emit(ErrorSubmitted());
      } catch (e) {
        emit(ErrorFailure(message: 'Failed to submit feedback'));
      }
    }
  }
}
