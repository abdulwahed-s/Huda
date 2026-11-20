import 'package:flutter/foundation.dart';
import 'package:huda/data/models/islamic_event_config.dart';

class HomeActions {
  const HomeActions({
    required this.openQuran,
    required this.openPrayerTimes,
    required this.openAudio,
    required this.openRadio,
    required this.openBookmarks,
    required this.openSurah,
    required this.openLastRead,
    required this.openLastReciter,
    required this.openLastStation,
    required this.retry,
  });

  final VoidCallback openQuran;
  final VoidCallback openPrayerTimes;
  final VoidCallback openAudio;
  final VoidCallback openRadio;
  final VoidCallback openBookmarks;
  final void Function(int surah, int ayah) openSurah;

  final void Function(Map<String, dynamic> summary) openLastRead;
  final void Function(Object progress) openLastReciter;
  final void Function(Object progress) openLastStation;

  final VoidCallback retry;
}

abstract final class HomeClock {
  @visibleForTesting
  static DateTime Function() debugNow = DateTime.now;

  static DateTime now() => debugNow();
}

abstract final class HomeSpecialEventPreview {
  static const bool enabled = bool.fromEnvironment(
    'HUDA_SPECIAL_EVENT_PREVIEW',
    defaultValue: false,
  );

  static const String environmentEventKey = String.fromEnvironment(
    'HUDA_SPECIAL_EVENT_PREVIEW_KEY',
    defaultValue: '',
  );

  static bool testingOverride = false;
  static String? _testingEventKeyOverride;

  static const IslamicEventConfig ramadanFixture = IslamicEventConfig(
    id: 'testing-ramadan',
    eventKey: 'ramadan',
    hijriMonth: 9,
    hijriDayStart: 1,
    hijriDayEnd: 30,
    actionRoute: '',
    iconName: 'nightlight_round',
    priority: 0,
  );

  static const Map<String, IslamicEventConfig> fixtures = {
    'ramadan': ramadanFixture,
    'last_ten_ramadan': IslamicEventConfig(
      id: 'testing-last_ten_ramadan',
      eventKey: 'last_ten_ramadan',
      hijriMonth: 9,
      hijriDayStart: 21,
      hijriDayEnd: 30,
      actionRoute: '',
      iconName: 'nights_stay',
      priority: 0,
    ),
    'eid_al_fitr': IslamicEventConfig(
      id: 'testing-eid_al_fitr',
      eventKey: 'eid_al_fitr',
      hijriMonth: 10,
      hijriDayStart: 1,
      hijriDayEnd: 1,
      actionRoute: '',
      iconName: 'auto_awesome',
      priority: 0,
    ),
    'eid_al_adha': IslamicEventConfig(
      id: 'testing-eid_al_adha',
      eventKey: 'eid_al_adha',
      hijriMonth: 12,
      hijriDayStart: 10,
      hijriDayEnd: 10,
      actionRoute: '',
      iconName: 'mosque',
      priority: 0,
    ),
    'day_of_arafah': IslamicEventConfig(
      id: 'testing-day_of_arafah',
      eventKey: 'day_of_arafah',
      hijriMonth: 12,
      hijriDayStart: 9,
      hijriDayEnd: 9,
      actionRoute: '',
      iconName: 'terrain',
      priority: 0,
    ),
    'first_ten_dhul_hijjah': IslamicEventConfig(
      id: 'testing-first_ten_dhul_hijjah',
      eventKey: 'first_ten_dhul_hijjah',
      hijriMonth: 12,
      hijriDayStart: 1,
      hijriDayEnd: 10,
      actionRoute: '',
      iconName: 'wb_sunny_outlined',
      priority: 0,
    ),
    'ashura': IslamicEventConfig(
      id: 'testing-ashura',
      eventKey: 'ashura',
      hijriMonth: 1,
      hijriDayStart: 10,
      hijriDayEnd: 10,
      actionRoute: '',
      iconName: 'brightness_7',
      priority: 0,
    ),
    'days_of_tashreeq': IslamicEventConfig(
      id: 'testing-days_of_tashreeq',
      eventKey: 'days_of_tashreeq',
      hijriMonth: 12,
      hijriDayStart: 11,
      hijriDayEnd: 13,
      actionRoute: '',
      iconName: 'celebration',
      priority: 0,
    ),
    'white_days_fasting': IslamicEventConfig(
      id: 'testing-white_days_fasting',
      eventKey: 'white_days_fasting',
      hijriMonth: 8,
      hijriDayStart: 13,
      hijriDayEnd: 15,
      actionRoute: '',
      iconName: 'brightness_5_outlined',
      priority: 0,
      source: IslamicEventSource.localRecurring,
    ),
    'monday_thursday_fasting': IslamicEventConfig(
      id: 'testing-monday_thursday_fasting',
      eventKey: 'monday_thursday_fasting',
      hijriMonth: 8,
      hijriDayStart: 8,
      hijriDayEnd: 8,
      actionRoute: '',
      iconName: 'wb_twilight_outlined',
      priority: 0,
      source: IslamicEventSource.localRecurring,
    ),
    'white_days_monday_thursday_fasting': IslamicEventConfig(
      id: 'testing-white_days_monday_thursday_fasting',
      eventKey: 'white_days_monday_thursday_fasting',
      hijriMonth: 8,
      hijriDayStart: 13,
      hijriDayEnd: 13,
      actionRoute: '',
      iconName: 'brightness_5_outlined',
      priority: 0,
      source: IslamicEventSource.localRecurring,
    ),
  };

  static Iterable<String> get supportedEventKeys => fixtures.keys;

  static IslamicEventConfig? fixtureForKey(String? eventKey) {
    if (eventKey == null) return null;
    return fixtures[eventKey.trim()];
  }

  static IslamicEventConfig? get selectedFixture {
    final testingFixture = fixtureForKey(_testingEventKeyOverride);
    if (testingFixture != null) return testingFixture;

    final environmentFixture = fixtureForKey(environmentEventKey);
    if (environmentFixture != null) return environmentFixture;

    return enabled || testingOverride ? ramadanFixture : null;
  }

  static bool get fixtureEnabled => selectedFixture != null;

  static void selectFixtureForTesting(String? eventKey) {
    if (eventKey == null) {
      _testingEventKeyOverride = null;
      return;
    }
    final fixture = fixtureForKey(eventKey);
    if (fixture == null) {
      throw ArgumentError.value(
        eventKey,
        'eventKey',
        'Unsupported special-event preview key',
      );
    }
    _testingEventKeyOverride = fixture.eventKey;
  }

  static void resetTestingOverrides() {
    testingOverride = false;
    _testingEventKeyOverride = null;
  }
}
