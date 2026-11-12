import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/windows_notification_registration.dart';
import 'package:huda/core/notifications/pending_notification.dart';

class WindowsPendingPrayerNotification extends PendingNotification {
  WindowsPendingPrayerNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required this.deliveryInstantUtc,
    required this.ambiguous,
    this.silent = false,
  }) : super(id, title, body, payload);

  final DateTime deliveryInstantUtc;
  final bool ambiguous;
  final bool silent;
}

/// The root isolate initializes the existing notification plugin for activation.
/// This adapter owns only asynchronous scheduling commands and snapshot tokens.
class WindowsPrayerNotificationGateway
    implements PrayerNotificationGateway, VerifiedPrayerNotificationGateway {
  WindowsPrayerNotificationGateway({
    this.appId = defaultAppId,
    this.deviceTimeZone = 'UTC',
    this.protectNearDue = true,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(channelName);

  static const defaultAppId = WindowsNotificationRegistration.appId;
  static const channelName = WindowsNotificationRegistration.channelName;
  static const commandTimeout = Duration(seconds: 30);

  final String appId;
  final String deviceTimeZone;
  final bool protectNearDue;
  final MethodChannel _channel;
  int _snapshot = 0;
  bool _initialized = false;
  int additions = 0;
  int cancellations = 0;
  int pendingQueries = 0;

  @override
  bool get supportsSafeReplacement => true;

  Future<T?> _call<T>(String method, [Map<String, Object?> extra = const {}]) =>
      _channel
          .invokeMethod<T>(method, {
            'appId': appId,
            'snapshot': _snapshot,
            'protectNearDue': protectNearDue,
            ...extra,
          })
          .timeout(commandTimeout);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _call<bool>('initialize');
    _initialized = true;
  }

  @override
  String get timeZoneName => deviceTimeZone;

  @override
  Future<String> refreshTimeZone() async =>
      PrayerTimeZoneService.configureLocalTimeZone(deviceTimeZone);

  @override
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    return await _call<int>('settings') == 0;
  }

  @override
  Future<bool> canScheduleExactNotifications() async => true;
  @override
  Future<String> schedulingCapabilitySignature() async => 'default';

  static int? _numericId(Map<Object?, Object?> item) {
    if (item['group'] != '') return null;
    final tag = item['tag']! as String;
    final id = int.tryParse(tag);
    // Native IDs use canonical decimal int32 tags. Keep foreign tag spellings
    // and out-of-range values as unrelated capacity, never cancellation IDs.
    return id != null && id >= 0 && id <= 0x7fffffff && '$id' == tag
        ? id
        : null;
  }

  @override
  Future<List<PendingNotification>> pendingNotificationRequests() async {
    await initialize();
    final response = (await _call<Map<Object?, Object?>>('pending'))!;
    _snapshot = response['snapshot']! as int;
    pendingQueries++;
    final items = (response['items']! as List).cast<Map<Object?, Object?>>();
    final ids = <int, int>{};
    for (final item in items) {
      final id = _numericId(item);
      if (id != null) {
        ids.update(id, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return [
      for (var index = 0; index < items.length; index++)
        WindowsPendingPrayerNotification(
          // Count non-numeric/grouped toasts as unrelated capacity. Never
          // interpret their tags as an instruction to cancel them.
          id: _numericId(items[index]) ?? -1 - index,
          title: items[index]['title']! as String,
          body: items[index]['body']! as String,
          payload: items[index]['payload']! as String,
          deliveryInstantUtc: DateTime.fromMillisecondsSinceEpoch(
            (items[index]['seconds']! as int) * 1000,
            isUtc: true,
          ),
          ambiguous: (ids[_numericId(items[index])] ?? 0) > 1,
          silent: items[index]['silent'] == true,
        ),
    ];
  }

  @override
  bool matchesPendingEvent(
    PrayerNotificationEvent event,
    PendingNotification? pending,
  ) =>
      pending is WindowsPendingPrayerNotification &&
      !pending.ambiguous &&
      pending.id == event.id &&
      pending.title == event.title &&
      pending.body == event.body &&
      pending.silent == (event.windowsSilent == true) &&
      event.matchesPendingPayload(pending.payload) &&
      pending.deliveryInstantUtc.millisecondsSinceEpoch ~/ 1000 ==
          event.scheduledInstantUtc.millisecondsSinceEpoch ~/ 1000;

  Future<void> _ensureSnapshot() async {
    if (_snapshot == 0) await pendingNotificationRequests();
  }

  void _recordMutation(Map<Object?, Object?> response) {
    additions += response['added']! as int;
    cancellations += response['removed']! as int;
  }

  @override
  Future<bool> schedulePrayerEvent(
    PrayerNotificationEvent event, {
    bool? allowExact,
  }) async {
    if (!event.scheduledInstantUtc.isAfter(DateTime.now().toUtc())) {
      return false;
    }
    // Errors propagate: a lost acknowledgement must be journaled as uncertain,
    // rather than converted to a definite "not scheduled" outcome.
    await scheduleToast(
      id: event.id,
      instantUtc: event.scheduledInstantUtc,
      title: event.title,
      body: event.body,
      payload: event.payload,
      silent: event.windowsSilent == true,
    );
    return true;
  }

  /// Adds a toast, replacing every queued toast with the same tag. An
  /// identical queued toast is kept without a new addition.
  Future<void> scheduleToast({
    required int id,
    required DateTime instantUtc,
    required String title,
    required String body,
    required String payload,
    bool silent = false,
    bool shortDuration = false,
  }) async {
    await _ensureSnapshot();
    _recordMutation(
      (await _call<Map<Object?, Object?>>('schedule', {
        'id': id,
        'seconds': instantUtc.millisecondsSinceEpoch ~/ 1000,
        'title': title,
        'body': body,
        'payload': payload,
        'silent': silent,
        if (shortDuration) 'shortDuration': true,
      }))!,
    );
  }

  @override
  Future<void> cancelNotifications(Iterable<int> ids) async {
    final uniqueIds = ids.toSet();
    if (uniqueIds.isEmpty) return;
    await _ensureSnapshot();
    for (final id in uniqueIds) {
      Map<Object?, Object?> response;
      try {
        response = (await _call<Map<Object?, Object?>>('cancel', {'id': id}))!;
      } on PlatformException catch (error) {
        // A toast may have expired since the snapshot. Re-read Windows once;
        // missing IDs are acknowledged without replaying an addition.
        if (error.details is! Map ||
            !(error.details as Map).containsKey('hresult')) {
          rethrow;
        }
        await pendingNotificationRequests();
        response = (await _call<Map<Object?, Object?>>('cancel', {'id': id}))!;
      }
      _recordMutation(response);
    }
  }

  @override
  Future<void> releasePendingSnapshot() async {
    if (_snapshot == 0) return;
    await _call<void>('release');
    _snapshot = 0;
  }
}
