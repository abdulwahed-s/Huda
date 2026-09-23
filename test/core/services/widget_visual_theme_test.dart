import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/quran_widget_service.dart';

void main() {
  test('Quran widget offers every prayer widget visual theme', () {
    final prayerThemes = PrayerWidgetVisualTheme.values
        .map((theme) => theme.storage)
        .toList();
    final quranThemes = QuranWidgetVisualTheme.values
        .map((theme) => theme.storage)
        .toList();

    expect(quranThemes, prayerThemes);
  });

  test('prayer widget time format migrates and persists stable tokens', () {
    expect(
      PrayerWidgetTimeFormat.fromStorage(null),
      PrayerWidgetTimeFormat.system,
    );
    expect(
      PrayerWidgetTimeFormat.fromStorage('12h'),
      PrayerWidgetTimeFormat.twelveHour,
    );
    expect(
      PrayerWidgetTimeFormat.fromStorage('24h'),
      PrayerWidgetTimeFormat.twentyFourHour,
    );
    expect(PrayerWidgetTimeFormat.twelveHour.storage, '12h');
    expect(PrayerWidgetTimeFormat.twentyFourHour.storage, '24h');
  });

  test(
    'failed native widget operations propagate instead of succeeding',
    () async {
      await expectLater(
        PrayerWidgetService.requireSuccessfulPlatformOperation(
          Future<bool?>.value(false),
          operation: 'write settings',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'structured Android widget result retains failures and renderer paths',
    () {
      final report = PrayerWidgetUpdateReport.fromMap({
        'revision': 42,
        'widgetCount': 2,
        'successfulUpdates': 1,
        'failedUpdates': 1,
        'rendererPath': {'canvas_live': 1, 'failed': 1},
        'alarmScheduled': true,
        'alarmPrecision': 'inexact_idle',
        'error': 'widget 9: launcher rejected update',
      });
      expect(report.revision, 42);
      expect(report.failedUpdates, 1);
      expect(report.rendererPaths['canvas_live'], 1);
      expect(report.alarmPrecision, 'inexact_idle');
      expect(report.error, contains('launcher rejected'));
    },
  );
}
