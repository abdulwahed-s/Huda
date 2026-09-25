import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/continue_activity_dock.dart';
import 'package:huda/presentation/widgets/home/feature_grid.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeCubit homeCubit;
  late ThemeCubit themeCubit;
  late KhatmaService khatmaService;

  Widget buildSubject({bool disableAnimations = false}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>.value(value: homeCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1200, 900),
        builder: (context, child) => MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disableAnimations),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: FeatureGrid(
                      isDarkMode: false,
                      features: [],
                      quranStackCard: QuranFeatureStackCard(
                        isDarkMode: false,
                        index: 0,
                        stackLabel: 'Quran Kit',
                        quranLabel: 'Quran',
                        audioLabel: 'Quran Audio',
                        radioLabel: 'Quran Radio',
                        bookmarkLabel: 'Bookmarks',
                        onQuranTap: _noop,
                        onAudioTap: _noop,
                        onRadioTap: _noop,
                        onBookmarkTap: _noop,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    final cache = CacheHelper();
    await cache.init();
    getIt.registerSingleton<CacheHelper>(cache);

    khatmaService = KhatmaService(cache: cache);
    homeCubit = HomeCubit(
      readingPositionService: ReadingPositionService(),
      quranAudioProgressService: QuranAudioProgressService(),
      quranRadioProgressService: QuranRadioProgressService(),
      khatmaService: khatmaService,
    );
    themeCubit = ThemeCubit();
  });

  tearDown(() async {
    await homeCubit.close();
    await themeCubit.close();
    khatmaService.dispose();
    await getIt.reset();
  });

  testWidgets('Quran tools unfold from the selected Quran Kit card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final anchor = find.byKey(const ValueKey('quran-kit-anchor'));
    final revealedQuran = find.byKey(const ValueKey('quran-kit-reveal-1'));
    final anchorCenter = tester.getCenter(anchor);
    final collapsedCenter = tester.getCenter(revealedQuran);
    expect((collapsedCenter - anchorCenter).distance, lessThan(20));

    await tester.tap(find.text('Quran Kit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final inFlightCenter = tester.getCenter(revealedQuran);

    await tester.pumpAndSettle();
    final expandedCenter = tester.getCenter(revealedQuran);
    final fullDistance = (expandedCenter - anchorCenter).distance;
    final inFlightDistance = (inFlightCenter - anchorCenter).distance;
    final activityRect = tester.getRect(find.byType(ContinueActivityDock));
    final quranCardRect = tester.getRect(revealedQuran);

    expect(fullDistance, greaterThan(100));
    expect(inFlightDistance, greaterThan(0));
    expect(inFlightDistance, lessThan(fullDistance));
    expect(activityRect.bottom, lessThan(quranCardRect.top));
    expect(activityRect.width, greaterThan(quranCardRect.width * 3));

    await tester.tap(find.text('Quran Kit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final returningDistance =
        (tester.getCenter(revealedQuran) - anchorCenter).distance;
    expect(returningDistance, greaterThan(0));
    expect(returningDistance, lessThan(fullDistance));

    await tester.pumpAndSettle();
    final returnedCenter = tester.getCenter(revealedQuran);
    expect((returnedCenter - anchorCenter).distance, lessThan(20));
  });

  testWidgets('Quran Kit reveal is immediate when animations are disabled', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject(disableAnimations: true));
    await tester.pumpAndSettle();

    final anchor = find.byKey(const ValueKey('quran-kit-anchor'));
    final revealedQuran = find.byKey(const ValueKey('quran-kit-reveal-1'));
    final anchorCenter = tester.getCenter(anchor);
    expect(
      (tester.getCenter(revealedQuran) - anchorCenter).distance,
      lessThan(20),
    );

    await tester.tap(find.text('Quran Kit'));
    await tester.pump();

    expect(
      (tester.getCenter(revealedQuran) - anchorCenter).distance,
      greaterThan(100),
    );
  });
}

void _noop() {}
