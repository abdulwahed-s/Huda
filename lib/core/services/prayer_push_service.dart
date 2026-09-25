import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:huda/core/services/prayer_push_credential_store.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

abstract interface class PrayerPushSynchronizer {
  Future<PrayerPushSyncResult> syncFallback({
    required DateTime? localCoverageUntil,
    required String timeZoneName,
    required String reason,
    int locationRevision = 0,
    int scheduleRevision = 0,
    String configurationSignature = '',
    PrayerScheduleConfiguration? configuration,
    Set<int> suppressedOccurrenceIds = const <int>{},
  });

  Future<PrayerPushSyncResult> disable({
    required String reason,
    int locationRevision = 0,
    int scheduleRevision = 0,
  });
}

abstract final class PrayerPushErrorCode {
  static const settingsChanged = 'prayer_notification_settings_changed';
  static const busy = 'prayer_notification_sync_busy';
  static const unavailable = 'prayer_notification_sync_unavailable';
  static const verificationFailed =
      'prayer_notification_sync_verification_failed';
}

enum PrayerPushSyncStatus { acknowledged, deferred, unsupported, failed }

class PrayerPushSyncResult {
  const PrayerPushSyncResult(
    this.status, {
    this.acceptedScheduleRevision,
    this.acceptedLocationRevision,
    this.ownershipUntilUtc,
    this.scheduledThroughUtc,
    this.message,
  });

  final PrayerPushSyncStatus status;
  final int? acceptedScheduleRevision;
  final int? acceptedLocationRevision;
  final DateTime? ownershipUntilUtc;
  final DateTime? scheduledThroughUtc;
  final String? message;

  bool get acknowledged => status == PrayerPushSyncStatus.acknowledged;
}

class PrayerPushService implements PrayerPushSynchronizer {
  PrayerPushService({
    required this.cacheHelper,
    PrayerPushCredentialStore? credentialStore,
    DateTime Function()? now,
  }) : credentialStore =
           credentialStore ??
           PrayerPushCredentialStore(cacheHelper: cacheHelper),
       _now = now ?? DateTime.now;

  static const _channel = MethodChannel('com.aw.huda/prayer_push');
  static const _functionName = 'prayer-push-sync';
  static const _remoteHorizon = Duration(days: 370);
  static const _remoteEventLimit = 1900;
  static const _maximumCachedAcknowledgementAge = Duration(hours: 6);

  static const _deviceTokenKey = 'prayer_push_apns_token';
  static const _environmentKey = 'prayer_push_apns_environment';
  static const _lastSyncAcknowledgementKey =
      'prayer_push_last_sync_acknowledgement_v1';
  static const _legacyLastSyncSignatureKey = 'prayer_push_last_sync_signature';
  static const _legacyLastSyncAtKey = 'prayer_push_last_sync_at';

  static PrayerPushService? _channelOwner;

  final CacheHelper cacheHelper;
  final PrayerPushCredentialStore credentialStore;
  final DateTime Function() _now;
  final Lock _lock = Lock();

  _PendingSync? _pendingSync;
  bool _channelInitialized = false;

  bool get _isSupported => !kIsWeb && Platform.isIOS;

  @override
  Future<PrayerPushSyncResult> syncFallback({
    required DateTime? localCoverageUntil,
    required String timeZoneName,
    required String reason,
    int locationRevision = 0,
    int scheduleRevision = 0,
    String configurationSignature = '',
    PrayerScheduleConfiguration? configuration,
    Set<int> suppressedOccurrenceIds = const <int>{},
  }) async {
    if (!_isSupported) {
      return const PrayerPushSyncResult(PrayerPushSyncStatus.unsupported);
    }

    _pendingSync = _PendingSync(
      localCoverageUntil: localCoverageUntil,
      timeZoneName: timeZoneName,
      reason: reason,
      locationRevision: locationRevision,
      scheduleRevision: scheduleRevision,
      configurationSignature: configurationSignature,
      configuration: configuration,
      suppressedOccurrenceIds: Set.unmodifiable(suppressedOccurrenceIds),
    );

    await _initializeNativeRegistration();
    try {
      return await _syncPendingIfPossible();
    } on _PrayerPushHttpException catch (error) {
      debugPrint('Unable to synchronize prayer push fallback: $error');
      return PrayerPushSyncResult(
        PrayerPushSyncStatus.failed,
        acceptedScheduleRevision: error.acceptedScheduleRevision,
        acceptedLocationRevision: error.acceptedLocationRevision,
        ownershipUntilUtc: error.acknowledgedLocalCoverageUntil,
        message: error.userMessageCode,
      );
    } catch (error) {
      debugPrint('Unable to synchronize prayer push fallback: $error');
      return const PrayerPushSyncResult(
        PrayerPushSyncStatus.failed,
        message: PrayerPushErrorCode.verificationFailed,
      );
    }
  }

  @override
  Future<PrayerPushSyncResult> disable({
    required String reason,
    int locationRevision = 0,
    int scheduleRevision = 0,
  }) async {
    if (!_isSupported) {
      return const PrayerPushSyncResult(PrayerPushSyncStatus.unsupported);
    }

    final identity = await credentialStore.read();
    if (identity == null) {
      return const PrayerPushSyncResult(PrayerPushSyncStatus.deferred);
    }

    try {
      await _clearCachedAcknowledgement();
      final response = await _post({
        'action': 'disable',
        'installationId': identity.id,
        'installationSecret': identity.secret,
        'reason': reason,
        'locationRevision': locationRevision,
        'scheduleRevision': scheduleRevision,
      });
      final acceptedScheduleRevision = _validRevision(
        response['acceptedScheduleRevision'],
      );
      final acceptedLocationRevision = _validRevision(
        response['acceptedLocationRevision'],
      );
      if (response['ok'] != true ||
          response['enabled'] != false ||
          acceptedScheduleRevision == null ||
          acceptedLocationRevision == null) {
        throw const FormatException(
          'Prayer push disable acknowledgement is incomplete.',
        );
      }
      return PrayerPushSyncResult(
        PrayerPushSyncStatus.acknowledged,
        acceptedScheduleRevision: acceptedScheduleRevision,
        acceptedLocationRevision: acceptedLocationRevision,
      );
    } on _PrayerPushHttpException catch (error) {
      debugPrint('Unable to disable prayer push fallback: $error');
      return PrayerPushSyncResult(
        PrayerPushSyncStatus.failed,
        acceptedScheduleRevision: error.acceptedScheduleRevision,
        acceptedLocationRevision: error.acceptedLocationRevision,
        message: error.userMessageCode,
      );
    } catch (error) {
      debugPrint('Unable to disable prayer push fallback: $error');
      return const PrayerPushSyncResult(
        PrayerPushSyncStatus.failed,
        message: PrayerPushErrorCode.verificationFailed,
      );
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
        await _clearCachedAcknowledgement();
      }
    }
    if (environment == 'development' || environment == 'production') {
      final previous = cacheHelper.getDataString(key: _environmentKey);
      await cacheHelper.saveData(key: _environmentKey, value: environment);
      if (previous != environment) {
        await _clearCachedAcknowledgement();
      }
    }
  }

  Future<PrayerPushSyncResult> _syncPendingIfPossible() {
    return _lock.synchronized(() async {
      final pending = _pendingSync;
      if (pending == null) {
        return const PrayerPushSyncResult(PrayerPushSyncStatus.deferred);
      }

      final token = cacheHelper.getDataString(key: _deviceTokenKey);
      final environment = cacheHelper.getDataString(key: _environmentKey);
      if (token == null || token.isEmpty || environment == null) {
        return const PrayerPushSyncResult(
          PrayerPushSyncStatus.deferred,
          message: 'APNs registration is unavailable.',
        );
      }

      final identity = await _installationIdentity();
      final planner = PrayerNotificationPlanner(cacheHelper);
      final plan = pending.configuration == null
          ? planner.build(
              now: _now(),
              maxEvents: _remoteEventLimit,
              horizon: _remoteHorizon,
              timeZoneName: pending.timeZoneName,
            )
          : planner.buildFromConfiguration(
              now: _now(),
              maxEvents: _remoteEventLimit,
              horizon: _remoteHorizon,
              configuration: pending.configuration!,
              scheduleRevision: pending.scheduleRevision,
            );
      if (plan == null || plan.events.isEmpty) {
        return const PrayerPushSyncResult(
          PrayerPushSyncStatus.deferred,
          message: 'No immutable remote prayer plan is available.',
        );
      }

      final remoteEvents = plan.events
          .where(
            (event) =>
                !pending.suppressedOccurrenceIds.contains(event.id) &&
                (pending.localCoverageUntil == null ||
                    event.scheduledInstantUtc.isAfter(
                      pending.localCoverageUntil!.toUtc(),
                    )),
          )
          .toList(growable: false);
      if (remoteEvents.isEmpty) {
        return const PrayerPushSyncResult(
          PrayerPushSyncStatus.deferred,
          message: 'No remotely owned prayer occurrences are available.',
        );
      }
      final content = <String, Map<String, String>>{};
      for (final event in remoteEvents) {
        content.putIfAbsent(
          event.prayer.name,
          () => {'title': event.title, 'body': event.body},
        );
      }
      final events = encodeScheduleEvents(remoteEvents);
      final eventDigest = sha256
          .convert(utf8.encode(jsonEncode(events)))
          .toString();

      final first = events.first;
      final last = events.last;
      final opaqueConfigurationSignature = sha256
          .convert(utf8.encode(plan.configurationSignature))
          .toString();
      final localCoverageEpoch =
          pending.localCoverageUntil
              ?.toUtc()
              .millisecondsSinceEpoch
              .toString() ??
          'none';
      final syncSignature = [
        opaqueConfigurationSignature,
        token,
        environment,
        pending.locationRevision,
        pending.scheduleRevision,
        localCoverageEpoch,
        eventDigest,
        first[0],
        last[0],
      ].join('|');
      final cachedAcknowledgement = decodeCachedAcknowledgement(
        cacheHelper.getData(key: _lastSyncAcknowledgementKey),
        expectedSignature: syncSignature,
        now: _now(),
      );
      if (cachedAcknowledgement != null) {
        if (identical(_pendingSync, pending)) _pendingSync = null;
        return cachedAcknowledgement;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final locale =
          cacheHelper.getDataString(key: 'app_locale') ??
          cacheHelper.getDataString(key: 'locale') ??
          'en';
      final response = await _post({
        'action': 'sync',
        'installationId': identity.id,
        'installationSecret': identity.secret,
        'deviceToken': token,
        'environment': environment,
        'bundleId': 'com.aw.huda',
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        'locale': locale,
        'timeZone': pending.timeZoneName,
        'configurationSignature': opaqueConfigurationSignature,
        'locationRevision': pending.locationRevision,
        'scheduleRevision': pending.scheduleRevision,
        'localCoverageUntil': pending.localCoverageUntil
            ?.toUtc()
            .toIso8601String(),
        'scheduleThrough': plan.coverageUntilInstant?.toIso8601String(),
        'content': content,
        'events': events,
        'reason': pending.reason,
      });

      final acceptedScheduleRevision = _validRevision(
        response['acceptedScheduleRevision'],
      );
      final acceptedLocationRevision = _validRevision(
        response['acceptedLocationRevision'],
      );
      if (response['ok'] != true ||
          response['enabled'] != true ||
          acceptedScheduleRevision == null ||
          acceptedLocationRevision == null ||
          !response.containsKey('acknowledgedLocalCoverageUntil')) {
        throw const FormatException(
          'Prayer push ownership acknowledgement is incomplete.',
        );
      }
      final rawAcknowledgedBoundary =
          response['acknowledgedLocalCoverageUntil'];
      final acknowledgedBoundary = rawAcknowledgedBoundary == null
          ? null
          : _strictUtcDate(rawAcknowledgedBoundary);
      if (rawAcknowledgedBoundary != null && acknowledgedBoundary == null) {
        throw const FormatException(
          'Prayer push ownership boundary is invalid.',
        );
      }
      final scheduledThrough = _strictUtcDate(response['scheduleThrough']);
      if (scheduledThrough == null) {
        throw const FormatException(
          'Prayer push schedule coverage is invalid.',
        );
      }

      final result = PrayerPushSyncResult(
        PrayerPushSyncStatus.acknowledged,
        acceptedScheduleRevision: acceptedScheduleRevision,
        acceptedLocationRevision: acceptedLocationRevision,
        ownershipUntilUtc: acknowledgedBoundary,
        scheduledThroughUtc: scheduledThrough,
      );
      final exactAcknowledgement =
          acceptedScheduleRevision == pending.scheduleRevision &&
          acceptedLocationRevision == pending.locationRevision &&
          _sameUtcInstant(acknowledgedBoundary, pending.localCoverageUntil);
      if (exactAcknowledgement) {
        await cacheHelper.saveData(
          key: _lastSyncAcknowledgementKey,
          value: jsonEncode({
            'schemaVersion': 2,
            'signature': syncSignature,
            'synchronizedAtUtc': _now().toUtc().toIso8601String(),
            'acceptedScheduleRevision': acceptedScheduleRevision,
            'acceptedLocationRevision': acceptedLocationRevision,
            'acknowledgedLocalCoverageUntil': acknowledgedBoundary
                ?.toUtc()
                .toIso8601String(),
            'scheduledThroughUtc': scheduledThrough.toIso8601String(),
          }),
        );
        if (identical(_pendingSync, pending)) _pendingSync = null;
      }
      return result;
    });
  }

  Future<void> _clearCachedAcknowledgement() async {
    await cacheHelper.removeData(key: _lastSyncAcknowledgementKey);
    await cacheHelper.removeData(key: _legacyLastSyncSignatureKey);
    await cacheHelper.removeData(key: _legacyLastSyncAtKey);
  }

  @visibleForTesting
  static PrayerPushSyncResult? decodeCachedAcknowledgement(
    Object? encoded, {
    required String expectedSignature,
    required DateTime now,
  }) {
    if (encoded is! String) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map ||
          decoded['schemaVersion'] != 2 ||
          decoded['signature'] != expectedSignature ||
          !decoded.containsKey('acknowledgedLocalCoverageUntil')) {
        return null;
      }
      final synchronizedAt = _strictUtcDate(decoded['synchronizedAtUtc']);
      final acceptedScheduleRevision = _validRevision(
        decoded['acceptedScheduleRevision'],
      );
      final acceptedLocationRevision = _validRevision(
        decoded['acceptedLocationRevision'],
      );
      final rawBoundary = decoded['acknowledgedLocalCoverageUntil'];
      final boundary = rawBoundary == null ? null : _strictUtcDate(rawBoundary);
      final scheduledThrough = _strictUtcDate(decoded['scheduledThroughUtc']);
      if (synchronizedAt == null ||
          acceptedScheduleRevision == null ||
          acceptedLocationRevision == null ||
          scheduledThrough == null ||
          (rawBoundary != null && boundary == null)) {
        return null;
      }
      final utcNow = now.toUtc();
      if (utcNow.isBefore(synchronizedAt) ||
          utcNow.difference(synchronizedAt) >
              _maximumCachedAcknowledgementAge) {
        return null;
      }
      return PrayerPushSyncResult(
        PrayerPushSyncStatus.acknowledged,
        acceptedScheduleRevision: acceptedScheduleRevision,
        acceptedLocationRevision: acceptedLocationRevision,
        ownershipUntilUtc: boundary,
        scheduledThroughUtc: scheduledThrough,
      );
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static List<List<Object>> encodeScheduleEvents(
    Iterable<PrayerNotificationEvent> events,
  ) {
    return events
        .map(
          (event) => <Object>[
            event.scheduledInstantUtc.millisecondsSinceEpoch ~/ 1000,
            event.id,
            event.prayer.name,
          ],
        )
        .toList(growable: false);
  }

  Future<PrayerPushInstallationIdentity> _installationIdentity() async {
    final existing = await credentialStore.read();
    if (existing != null) {
      return existing;
    }

    final id = const Uuid().v4();
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final secret = base64UrlEncode(bytes).replaceAll('=', '');
    final identity = PrayerPushInstallationIdentity(id, secret);
    await credentialStore.write(identity);
    return identity;
  }

  Future<Map<String, Object?>> _post(Map<String, Object?> body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse('$supabaseUrl/functions/v1/$_functionName');
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 10));
      Map<String, Object?> decoded = const <String, Object?>{};
      if (responseBody.isNotEmpty) {
        try {
          final value = jsonDecode(responseBody);
          if (value is Map) decoded = Map<String, Object?>.from(value);
        } catch (_) {}
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _PrayerPushHttpException(
          statusCode: response.statusCode,
          response: decoded,
          responseBody: responseBody,
          uri: uri,
        );
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}

class _PrayerPushHttpException implements Exception {
  const _PrayerPushHttpException({
    required this.statusCode,
    required this.response,
    required this.responseBody,
    required this.uri,
  });

  final int statusCode;
  final Map<String, Object?> response;
  final String responseBody;
  final Uri uri;

  int? get acceptedScheduleRevision =>
      _validRevision(response['acceptedScheduleRevision']);

  int? get acceptedLocationRevision =>
      _validRevision(response['acceptedLocationRevision']);

  DateTime? get acknowledgedLocalCoverageUntil =>
      _strictUtcDate(response['acknowledgedLocalCoverageUntil']);

  String get userMessageCode {
    switch (response['error']) {
      case 'revision_conflict':
      case 'stale_revision':
        return PrayerPushErrorCode.settingsChanged;
      case 'rate_limited':
        return PrayerPushErrorCode.busy;
      default:
        return PrayerPushErrorCode.unavailable;
    }
  }

  @override
  String toString() {
    final boundedBody = responseBody.length > 240
        ? responseBody.substring(0, 240)
        : responseBody;
    return 'Prayer push sync returned $statusCode: $boundedBody ($uri)';
  }
}

class _PendingSync {
  const _PendingSync({
    required this.localCoverageUntil,
    required this.timeZoneName,
    required this.reason,
    required this.locationRevision,
    required this.scheduleRevision,
    required this.configurationSignature,
    required this.configuration,
    required this.suppressedOccurrenceIds,
  });

  final DateTime? localCoverageUntil;
  final String timeZoneName;
  final String reason;
  final int locationRevision;
  final int scheduleRevision;
  final String configurationSignature;
  final PrayerScheduleConfiguration? configuration;
  final Set<int> suppressedOccurrenceIds;
}

int? _validRevision(Object? value) {
  if (value is! num || !value.isFinite || value != value.roundToDouble()) {
    return null;
  }
  final revision = value.toInt();
  return revision >= 0 && revision <= PrayerLocationGeneration.maxSafeRevision
      ? revision
      : null;
}

DateTime? _strictUtcDate(Object? value) {
  if (value is! String || !RegExp(r'(?:Z|\+00(?::?00)?)$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  return parsed != null && parsed.isUtc ? parsed : null;
}

bool _sameUtcInstant(DateTime? left, DateTime? right) {
  if (left == null || right == null) return left == null && right == null;
  return left.toUtc().isAtSameMomentAs(right.toUtc());
}
