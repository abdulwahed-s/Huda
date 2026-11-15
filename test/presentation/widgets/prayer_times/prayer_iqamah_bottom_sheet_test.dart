import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/prayer_iqamah_settings.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_iqamah_bottom_sheet.dart';

void main() {
  testWidgets(
    'steppers clamp, off is shown, reset stages defaults and save publishes once',
    (tester) async {
      PrayerIqamahSettings? saved;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PrayerIqamahBottomSheet(
              settings: PrayerIqamahSettings.sanitize({
                'fajr': 60,
                'maghrib': 0,
              }),
              onSave: (settings) async => saved = settings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('fajr-plus')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('maghrib-minus')))
            .onPressed,
        isNull,
      );
      expect(find.text('Off'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('maghrib-plus')));
      await tester.pump();
      expect(saved, isNull);
      await tester.tap(find.text('Reset to defaults'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved!.toMap(), PrayerIqamahSettings.defaults);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} sheet supports RTL and large text on a narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: PrayerIqamahBottomSheet(
                settings: const PrayerIqamahSettings(),
                onSave: (_) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
