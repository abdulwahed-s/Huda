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
      '10:62',
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
      '36:58',
      '37:100',
      '39:53',
      '40:44',
      '44:51',
      '51:50',
      '54:17',
      '55:13',
      '68:4',
      '74:7',
      '85:14',
      '89:27',
      '89:30',
      '93:3',
      '93:4',
      '93:5',
      '93:9',
      '93:10',
      '93:11',
      '94:5',
      '94:8',
      '96:1',
      '99:7',
    };

    expect(catalog.version, 7);
    expect(catalog.verses, hasLength(references.length));
    expect(catalog.sources.keys.toSet(), languages);
    expect(catalog.verses.map((verse) => verse.id).toSet(), references);
    for (final verse in catalog.verses) {
      expect(verse.arabic.trim(), isNotEmpty);
      expect(verse.widgetSizes, isNotEmpty);
      expect(verse.translations.keys.toSet(), languages);
      expect(verse.translations.values, everyElement(isNot(isEmpty)));
      final surah = catalog.surahs[verse.surah];
      expect(surah, isNotNull, reason: 'Missing Surah ${verse.surah}');
      expect(surah!.displayNames.keys.toSet(), {
        'en',
        'ar',
        'tr',
        'fr',
        'de',
        'es',
        'ur',
        'ru',
        'ms',
        'bn',
      });
    }
  });

  test(
    'every verse has the expected monotonic widget-size eligibility',
    () async {
      final catalog = await QuranWidgetCatalog.load();
      const small = {
        '36:58',
        '37:100',
        '44:51',
        '68:4',
        '74:7',
        '85:14',
        '89:30',
        '93:9',
        '93:10',
        '93:11',
        '94:5',
        '94:8',
        '96:1',
      };
      const medium = {
        ...small,
        '2:152',
        '10:62',
        '15:49',
        '16:128',
        '26:62',
        '33:3',
        '51:50',
        '54:17',
        '55:13',
        '93:3',
        '93:4',
        '93:5',
        '99:7',
      };
      final all = catalog.verses.map((verse) => verse.id).toSet();

      expect(
        catalog.verses
            .where((verse) => verse.widgetSizes.contains(QuranWidgetSize.small))
            .map((verse) => verse.id)
            .toSet(),
        small,
      );
      expect(
        catalog.verses
            .where(
              (verse) => verse.widgetSizes.contains(QuranWidgetSize.medium),
            )
            .map((verse) => verse.id)
            .toSet(),
        medium,
      );
      expect(
        catalog.verses
            .where((verse) => verse.widgetSizes.contains(QuranWidgetSize.large))
            .map((verse) => verse.id)
            .toSet(),
        all,
      );

      for (final verse in catalog.verses) {
        if (verse.widgetSizes.contains(QuranWidgetSize.small)) {
          expect(verse.widgetSizes, contains(QuranWidgetSize.medium));
        }
        if (verse.widgetSizes.contains(QuranWidgetSize.medium)) {
          expect(verse.widgetSizes, contains(QuranWidgetSize.large));
        }
      }
    },
  );

  test(
    'references follow app locale and fall back to canonical names',
    () async {
      final catalog = await QuranWidgetCatalog.load();
      final verse = catalog.verses.firstWhere((item) => item.id == '29:69');

      expect(catalog.displayReference(verse, 'en'), "Al-'Ankabut • 69");
      expect(catalog.displayReference(verse, 'tr-TR'), 'Ankebût • 69');
      expect(catalog.displayReference(verse, 'ar'), 'العنكبوت • 69');
      expect(catalog.displayReference(verse, 'ja'), "Al-'Ankabut • 69");
    },
  );

  test(
    'rotation advances once per UTC hour and honors the manual offset',
    () async {
      final catalog = await QuranWidgetCatalog.load();
      final start = DateTime.utc(2026, 8, 27, 10, 20);

      expect(
        catalog.verseFor(start, size: QuranWidgetSize.small),
        catalog.verseFor(
          start.add(const Duration(minutes: 39)),
          size: QuranWidgetSize.small,
        ),
      );
      expect(
        catalog.verseFor(
          start.add(const Duration(hours: 1)),
          size: QuranWidgetSize.medium,
        ),
        catalog.verseFor(start, size: QuranWidgetSize.medium, offset: 1),
      );

      for (final size in QuranWidgetSize.values) {
        for (var offset = 0; offset < catalog.verses.length; offset++) {
          expect(
            catalog.verseFor(start, size: size, offset: offset).widgetSizes,
            contains(size),
          );
        }
      }
    },
  );

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
      customized.copyWith(translationBold: false).translationBold,
      isFalse,
    );
  });
}
