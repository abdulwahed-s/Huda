import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/services/sahur_alarm_gateway.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sahur implements SahurAlarmGateway {
  final settings = <SahurAlarmSettings>[];
  final permissionRequests = <bool>[];
  bool reject = false;
  @override
  Future<SahurAlarmReceipt> configure(
    SahurAlarmSettings value, {
    bool requestPermission = false,
  }) async {
    settings.add(value);
    permissionRequests.add(requestPermission);
    return SahurAlarmReceipt(
      accepted: !value.enabled || !reject,
      notificationOnly: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sahur gateway;
  late NotificationsCubit cubit;
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final cache = CacheHelper();
    await cache.init();
    getIt.registerSingleton<CacheHelper>(cache);
    gateway = _Sahur();
    cubit = NotificationsCubit(sahur: gateway);
    await cubit.loadPreferences();
  });
  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });
  NotificationPreferencesLoaded state() =>
      cubit.state as NotificationPreferencesLoaded;

  test(
    'enable asks the shared permission; disable cancels through the gateway',
    () async {
      await cubit.togglePreference('sahurAlarmEnabled', true);
      expect(state().sahurAlarmEnabled, isTrue);
      expect(state().sahurNotificationOnly, isTrue);
      expect(state().loadingKeys, isEmpty);
      expect(gateway.permissionRequests, [true]);
      await cubit.togglePreference('sahurAlarmEnabled', false);
      expect(gateway.settings.last.enabled, isFalse);
      expect(state().sahurAlarmEnabled, isFalse);
      expect(gateway.permissionRequests, [true, false]);
    },
  );

  test(
    'failed enable rolls back the switch and removes partial native alarms',
    () async {
      gateway.reject = true;
      await expectLater(
        cubit.togglePreference('sahurAlarmEnabled', true),
        throwsA(isA<NotificationNotScheduledException>()),
      );
      expect(state().sahurAlarmEnabled, isFalse);
      expect(state().loadingKeys, isEmpty);
      expect(gateway.settings.map((s) => s.enabled), [true, false]);
    },
  );

  test(
    'disabled edits are saved, enabled edits reschedule both modes',
    () async {
      await cubit.setSahurExactTime('03:15');
      await cubit.setSahurMinutesBeforeFajr(75);
      expect(gateway.settings, isEmpty);
      await cubit.togglePreference('sahurAlarmEnabled', true);
      expect(
        (gateway.settings.last.hour, gateway.settings.last.minute),
        (3, 15),
      );
      await cubit.setSahurAlarmType(1);
      expect(gateway.settings.last.type, 1);
      expect(gateway.settings.last.minutesBeforeFajr, 75);
      await cubit.setSahurMinutesBeforeFajr(90);
      expect(gateway.settings.last.minutesBeforeFajr, 90);
    },
  );
}
