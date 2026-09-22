import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/quran_widget_catalog.dart';
import 'package:huda/core/services/quran_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog contains the curated verses and every translation', () async {
    final catalog = await QuranWidgetCatalog.load();
    const languages = {'en', 'tr', 'fr', 'de', 'es', 'ur', 'ru', 'ms', 'bn'};
    const references = {
      '2:152',
      '2:153',
      '3:139',
      '3:160',
      '10:107',
      '13:28',
      '15:49',
      '16:128',
      '20:25',
      '20:46',
      '21:83',
      '21:87',
      '26:62',
      '29:69',
      '33:3',
      '39:53',
      '40:44',
      '51:50',
      '53:42',
      '89:27',
      '93:3',
      '93:4',
      '94:5',
      '94:6',
    };

    expect(catalog.version, 2);
    expect(catalog.verses, hasLength(references.length));
    expect(catalog.sources.keys.toSet(), languages);
    expect(catalog.verses.map((verse) => verse.id).toSet(), references);
    for (final verse in catalog.verses) {
      expect(verse.arabic.trim(), isNotEmpty);
      expect(verse.translations.keys.toSet(), languages);
      expect(verse.translations.values, everyElement(isNot(isEmpty)));
      final surah = catalog.surahs[verse.surah];
      expect(surah, isNotNull, reason: 'Missing Surah ${verse.surah}');
      expect(
        surah!.displayNames.keys.toSet(),
        {'en', 'ar', 'tr', 'fr', 'de', 'es', 'ur', 'ru', 'ms', 'bn'},
      );
    }
  });

  test('references follow app locale and fall back to canonical names',
      () async {
    final catalog = await QuranWidgetCatalog.load();
    final verse = catalog.verses.firstWhere((item) => item.id == '29:69');

    expect(catalog.displayReference(verse, 'en'), "Al-'Ankabut • 69");
    expect(catalog.displayReference(verse, 'tr-TR'), 'Ankebût • 69');
    expect(catalog.displayReference(verse, 'ar'), 'العنكبوت • 69');
    expect(catalog.displayReference(verse, 'ja'), "Al-'Ankabut • 69");
  });

  test('rotation advances once per UTC hour and honors the manual offset',
      () async {
    final catalog = await QuranWidgetCatalog.load();
    final start = DateTime.utc(2026, 8, 27, 10, 20);

    expect(catalog.verseFor(start),
        catalog.verseFor(start.add(const Duration(minutes: 39))));
    expect(
      catalog.verseFor(start.add(const Duration(hours: 1))),
      catalog.verseFor(start, offset: 1),
    );
  });

  test('automatic translation follows locale and hides for Arabic', () {
    const automatic = QuranWidgetSettings();
    expect(automatic.effectiveLanguage('ar'), isNull);
    expect(automatic.effectiveLanguage('tr'), 'tr');
    expect(automatic.effectiveLanguage('ja'), 'en');

    const explicitEnglish = QuranWidgetSettings(
      language: QuranWidgetTranslationLanguage.en,
    );
    expect(explicitEnglish.effectiveLanguage('ar'), 'en');
  });

  test('widget typography defaults and customization are preserved', () {
    const defaults = QuranWidgetSettings();
    expect(defaults.ayahTextSize, 100);
    expect(defaults.translationTextSize, 100);
    expect(defaults.ayahAutoFit, isTrue);
    expect(defaults.translationAutoFit, isTrue);
    expect(defaults.ayahBold, isFalse);
    expect(defaults.translationBold, isFalse);

    final customized = defaults.copyWith(
      ayahTextSize: 85,
      translationTextSize: 130,
      ayahAutoFit: false,
      translationAutoFit: false,
      ayahBold: true,
      translationBold: true,
    );
    expect(customized.ayahTextSize, 85);
    expect(customized.translationTextSize, 130);
    expect(customized.ayahAutoFit, isFalse);
    expect(customized.translationAutoFit, isFalse);
    expect(customized.ayahBold, isTrue);
    expect(customized.translationBold, isTrue);
    expect(customized.copyWith(ayahBold: false).ayahBold, isFalse);
    expect(customized.copyWith(ayahAutoFit: true).ayahAutoFit, isTrue);
    expect(
      customized.copyWith(translationAutoFit: true).translationAutoFit,
      isTrue,
    );
    expect(
        customized.copyWith(translationBold: false).translationBold, isFalse);
  });
}
