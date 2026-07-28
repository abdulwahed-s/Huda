import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

abstract interface class PrayerPushSynchronizer {
  Future<void> syncFallback({
    required DateTime? localCoverageUntil,
    required String timeZoneName,
    required String reason,
  });

  Future<void> disable({required String reason});
}

class PrayerPushService implements PrayerPushSynchronizer {
  PrayerPushService({
    required this.cacheHelper,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _channel = MethodChannel('com.aw.huda/prayer_push');
  static const _functionName = 'prayer-push-sync';
  static const _remoteHorizon = Duration(days: 370);
  static const _remoteEventLimit = 1900;

  static const _installationIdKey = 'prayer_push_installation_id';
  static const _installationSecretKey = 'prayer_push_installation_secret';
  static const _deviceTokenKey = 'prayer_push_apns_token';
  static const _environmentKey = 'prayer_push_apns_environment';
  static const _lastSyncSignatureKey = 'prayer_push_last_sync_signature';
  static const _lastSyncAtKey = 'prayer_push_last_sync_at';

  static PrayerPushService? _channelOwner;

  final CacheHelper cacheHelper;
  final DateTime Function() _now;
  final Lock _lock = Lock();

  _PendingSync? _pendingSync;
  bool _channelInitialized = false;

  bool get _isSupported => !kIsWeb && Platform.isIOS;

  @override
  Future<void> syncFallback({
    required DateTime? localCoverageUntil,
    required String timeZoneName,
    required String reason,
  }) async {
    if (!_isSupported) return;

    _pendingSync = _PendingSync(
      localCoverageUntil: localCoverageUntil,
      timeZoneName: timeZoneName,
      reason: reason,
    );

    await _initializeNativeRegistration();
    await _syncPendingIfPossible();
  }

  @override
  Future<void> disable({required String reason}) async {
    if (!_isSupported) return;

    final installationId = cacheHelper.getDataString(key: _installationIdKey);
    final installationSecret =
        cacheHelper.getDataString(key: _installationSecretKey);
    if (installationId == null || installationSecret == null) return;

    try {
      await _post({
        'action': 'disable',
        'installationId': installationId,
        'installationSecret': installationSecret,
        'reason': reason,
      });
      await cacheHelper.removeData(key: _lastSyncSignatureKey);
    } catch (error) {
      debugPrint('Unable to disable prayer push fallback: $error');
    }
  }

  Future<void> _initializeNativeRegistration() async {
    if (_channelInitialized) return;
    _channelInitialized = true;
    _channelOwner = this;
    _channel.setMethodCallHandler((call) async {
      final owner = _channelOwner;
      if (owner == null) return;
      if (call.method == 'tokenUpdated') {
        await owner._acceptRegistration(call.arguments);
        unawaited(owner._syncPendingIfPossible());
      } else if (call.method == 'registrationFailed') {
        debugPrint('APNs registration failed: ${call.arguments}');
      }
    });

    try {
      final registration = await _channel.invokeMethod<Object?>('register');
      await _acceptRegistration(registration);
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      debugPrint('Unable to request APNs registration: ${error.message}');
    }
  }

  Future<void> _acceptRegistration(Object? arguments) async {
    if (arguments is! Map) return;
    final token = arguments['token']?.toString().trim().toLowerCase();
    final environment = arguments['environment']?.toString().trim();
    if (token != null && token.isNotEmpty) {
      final previous = cacheHelper.getDataString(key: _deviceTokenKey);
      await cacheHelper.saveData(key: _deviceTokenKey, value: token);
      if (previous != token) {
        await cacheHelper.removeData(key: _lastSyncSignatureKey);
      }
    }
    if (environment == 'development' || environment == 'production') {
      final previous = cacheHelper.getDataString(key: _environmentKey);
      await cacheHelper.saveData(key: _environmentKey, value: environment);
      if (previous != environment) {
        await cacheHelper.removeData(key: _lastSyncSignatureKey);
      }
    }
  }

  Future<void> _syncPendingIfPossible() {
    return _lock.synchronized(() async {
      final pending = _pendingSync;
      if (pending == null) return;

      final token = cacheHelper.getDataString(key: _deviceTokenKey);
      final environment = cacheHelper.getDataString(key: _environmentKey);
      if (token == null || token.isEmpty || environment == null) return;

      final identity = await _installationIdentity();
      final plan = PrayerNotificationPlanner(cacheHelper).build(
        now: _now(),
        maxEvents: _remoteEventLimit,
        horizon: _remoteHorizon,
        timeZoneName: pending.timeZoneName,
      );
      if (plan == null || plan.events.isEmpty) return;

      final content = <String, Map<String, String>>{};
      final events = <List<Object>>[];
      for (final event in plan.events) {
        content.putIfAbsent(
          event.prayer.name,
          () => {'title': event.title, 'body': event.body},
        );
        events.add([
          event.scheduledTime.toUtc().millisecondsSinceEpoch ~/ 1000,
          event.id,
          event.prayer.name,
        ]);
      }

      final first = events.first;
      final last = events.last;
      final opaqueConfigurationSignature =
          sha256.convert(utf8.encode(plan.configurationSignature)).toString();
      final localCoverageEpoch = pending.localCoverageUntil
              ?.toUtc()
              .millisecondsSinceEpoch
              .toString() ??
          'none';
      final syncSignature = [
        opaqueConfigurationSignature,
        token,
        environment,
        localCoverageEpoch,
        first[0],
        first[1],
        last[0],
        last[1],
      ].join('|');
      if (cacheHelper.getDataString(key: _lastSyncSignatureKey) ==
          syncSignature) {
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      await _post({
        'action': 'sync',
        'installationId': identity.id,
        'installationSecret': identity.secret,
        'deviceToken': token,
        'environment': environment,
        'bundleId': 'com.aw.huda',
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        'timeZone': pending.timeZoneName,
        'configurationSignature': opaqueConfigurationSignature,
        'localCoverageUntil':
            pending.localCoverageUntil?.toUtc().toIso8601String(),
        'scheduleThrough': plan.coverageUntil?.toUtc().toIso8601String(),
        'content': content,
        'events': events,
        'reason': pending.reason,
      });

      await cacheHelper.saveData(
        key: _lastSyncSignatureKey,
        value: syncSignature,
      );
      await cacheHelper.saveData(
        key: _lastSyncAtKey,
        value: _now().toUtc().toIso8601String(),
      );
    });
  }

  Future<_InstallationIdentity> _installationIdentity() async {
    var id = cacheHelper.getDataString(key: _installationIdKey);
    var secret = cacheHelper.getDataString(key: _installationSecretKey);
    if (id != null && secret != null) {
      return _InstallationIdentity(id, secret);
    }

    id = const Uuid().v4();
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    secret = base64UrlEncode(bytes).replaceAll('=', '');
    await cacheHelper.saveData(key: _installationIdKey, value: id);
    await cacheHelper.saveData(key: _installationSecretKey, value: secret);
    return _InstallationIdentity(id, secret);
  }

  Future<void> _post(Map<String, Object?> body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse('$supabaseUrl/functions/v1/$_functionName');
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      request.write(jsonEncode(body));
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Prayer push sync returned ${response.statusCode}: '
          '${responseBody.length > 240 ? responseBody.substring(0, 240) : responseBody}',
          uri: uri,
        );
      }
    } finally {
      client.close(force: true);
    }
  }
}

class _PendingSync {
  const _PendingSync({
    required this.localCoverageUntil,
    required this.timeZoneName,
    required this.reason,
  });

  final DateTime? localCoverageUntil;
  final String timeZoneName;
  final String reason;
}

class _InstallationIdentity {
  const _InstallationIdentity(this.id, this.secret);

  final String id;
  final String secret;
}
