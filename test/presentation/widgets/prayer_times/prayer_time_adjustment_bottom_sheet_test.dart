import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrayerTimesCubit prayerTimesCubit;
  late ThemeCubit themeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesCalculator.methodKey: 'other',
      PrayerTimesCalculator.customFajrAngleKey: '18',
      PrayerTimesCalculator.customMaghribAngleKey: '4',
      PrayerTimesCalculator.customIshaAngleKey: '17',
    });
    await getIt.reset();
    final cache = CacheHelper();
    await cache.init();
    getIt.registerSingleton<CacheHelper>(cache);
    prayerTimesCubit = PrayerTimesCubit(cache);
    themeCubit = ThemeCubit();
  });

  tearDown(() async {
    await prayerTimesCubit.close();
    await themeCubit.close();
    await getIt.reset();
  });

  testWidgets('Custom exposes three validated localized angle fields', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 800),
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<PrayerTimesCubit>.value(value: prayerTimesCubit),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PrayerTimeAdjustmentBottomSheet()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.byKey(const ValueKey('custom-prayer-angles')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-fajr-angle')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-maghrib-angle')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-isha-angle')), findsOneWidget);
    expect(find.text(l10n.prayerMaghribZeroMeansSunset), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-fajr-angle')),
      '0',
    );
    await tester.pump();
    expect(find.text(l10n.prayerAngleRangeExclusive), findsOneWidget);
    expect(_applyInkWell(tester, l10n).onTap, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('custom-fajr-angle')),
      '١٨٫٥',
    );
    await tester.pump();
    expect(find.text(l10n.prayerAngleRangeExclusive), findsNothing);
    expect(_applyInkWell(tester, l10n).onTap, isNotNull);
  });
}

InkWell _applyInkWell(WidgetTester tester, AppLocalizations l10n) {
  final finder = find
      .ancestor(
        of: find.text(l10n.prayerSettingsApply),
        matching: find.byType(InkWell),
      )
      .first;
  return tester.widget<InkWell>(finder);
}
