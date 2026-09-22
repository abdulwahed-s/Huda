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
}
