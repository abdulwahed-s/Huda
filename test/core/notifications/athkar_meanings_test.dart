import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/notifications/reminder_planner.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/reminder_notification_content.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  final now = tz.TZDateTime(tz.getLocation('UTC'), 2026, 10, 28, 12);
  final english = ReminderNotificationContent.of(
    lookupAppLocalizations(const Locale('en')),
  );
  ReminderPlanner planner(
    ReminderNotificationContent content, {
    bool apple = false,
    tz.TZDateTime? at,
  }) => ReminderPlanner(
    policy: NotificationCapacityPolicy.forPlatform(
      apple ? HudaNotificationPlatform.ios : HudaNotificationPlatform.android,
    ),
    scheduleMode: 'native',
    content: content,
    now: at ?? now,
    repeatsAthkar: apple,
  );

  test('all ten languages have twenty meanings; Arabic has no second line', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final content = ReminderNotificationContent.of(
        lookupAppLocalizations(locale),
      );
      expect(content.randomAthkarTexts, hasLength(20));
      expect(content.randomAthkarTexts.toSet(), hasLength(20));
      for (var i = 0; i < 20; i++) {
        final text = content.randomAthkarTexts[i];
        if (locale.languageCode == 'ar') {
          expect(text, ReminderNotificationContent.arabicAthkarTexts[i]);
          expect(text, isNot(contains('\n')));
        } else {
          final lines = text.split('\n');
          expect(lines, hasLength(2));
          expect(
            lines.first,
            '\u2067${ReminderNotificationContent.arabicAthkarTexts[i]}\u2069',
          );
          expect(lines.last, startsWith('\u2068'));
          expect(lines.last.length, greaterThan(5));
        }
      }
    }
  });

  test('background content reloads the saved app language', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
    final first = await ReminderNotificationContent.load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', 'de');
    final second = await ReminderNotificationContent.load();
    expect(first.randomAthkarTexts.first, contains('Gloire'));
    expect(second.randomAthkarTexts.first, contains('Gepriesen'));
  });

  test('live rules carry the meanings without changing their title', () {
    final rule = planner(english)
        .plan(const ReminderSettings(randomAthkarMinutes: 60), [])
        .changes
        .schedule
        .single;
    expect(rule.title, english.randomAthkarTitle);
    expect(rule.texts, english.randomAthkarTexts);
    expect(rule.texts.first, contains('\n\u2068Glory be to Allah'));
  });

  test(
    'upgrade replaces an Arabic-only live catalog even with the same title',
    () {
      const settings = ReminderSettings(randomAthkarMinutes: 60);
      final first = planner(english).plan(settings, []).changes.schedule.single;
      final old = QueuedNotification(
        id: first.id,
        title: first.title,
        body: '',
        payload: jsonEncode([ReminderPlanner.liveAthkarPayloadVersion, 60]),
      );
      final replacement = planner(
        english,
      ).plan(settings, [old]).changes.schedule.single;
      expect(replacement.texts, english.randomAthkarTexts);
      final current = QueuedNotification(
        id: replacement.id,
        title: replacement.title,
        body: replacement.body,
        payload: replacement.payload,
      );
      expect(
        planner(english).plan(settings, [current]).changes.schedule,
        isEmpty,
      );
    },
  );

  test(
    'Apple repeating slots preserve bilingual pairs and keep reshuffling',
    () {
      const settings = ReminderSettings(randomAthkarMinutes: 15);
      final first = planner(
        english,
        apple: true,
      ).plan(settings, []).changes.schedule;
      final later = planner(
        english,
        apple: true,
        at: now.add(const Duration(hours: 1)),
      ).plan(settings, []).changes.schedule;
      expect(first, isNotEmpty);
      expect(
        first.every((e) => english.randomAthkarTexts.contains(e.body)),
        isTrue,
      );
      expect(
        first.map((e) => e.body).toList(),
        isNot(later.map((e) => e.body).toList()),
      );
    },
  );
}
