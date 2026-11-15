import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/mushaf_pack_service_test.dart' show writePack;

class _TestThemeCubit extends Fake implements ThemeCubit {
  @override
  Stream<ThemeState> get stream => const Stream.empty();
  @override
  ThemeState get state => ThemeState(
    themeMode: ThemeMode.light,
    textScaleFactor: 1,
    colorTheme: AppColors.defaultTheme,
    fontFamily: 'Amiri',
  );
}

/// A decodable 1x1 PNG; the decoder sniffs content, not the .webp name.
final _pagePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Widget app({
  int page = 200,
  QuranReadingMode mode = QuranReadingMode.horizontalPages,
  void Function(int surah, int ayah)? onLongPress,
}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BlocProvider<ThemeCubit>.value(
    value: _TestThemeCubit(),
    child: Scaffold(
      body: QuranMushafPageView(
        initialPageNumber: page,
        mode: mode,
        onAyahLongPress: onLongPress,
      ),
    ),
  ),
);

void main() {
  late Directory base;
  late MushafPackService hafs;
  late KhatmaService khatma;

  setUp(() async {
    await getIt.reset();
    base = Directory.systemTemp.createTempSync('mushaf_view_test');
    final root = Directory('${base.path}/support')..createSync();
    final temp = Directory('${base.path}/tmp')..createSync();
    final server = Directory('${base.path}/server')..createSync();
    final manifest = writePack(server, pageBytes: _pagePng);
    SharedPreferences.setMockInitialValues({});
    final cache = CacheHelper();
    await cache.init();
    hafs = MushafPackService(
      cache: cache,
      pack: MushafPack.hafs,
      rootDirectory: () async => root,
      tempDirectory: () async => temp,
      fetchJson: (_) async =>
          jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>,
      download: (url, savePath, onProgress) async {
        await File('${server.path}/${url.split('/').last}').copy(savePath);
        onProgress(1, 1);
      },
    );
    khatma = KhatmaService(cache: cache);
    getIt.registerSingleton<MushafPackService>(hafs, instanceName: 'hafs');
    getIt.registerSingleton<KhatmaService>(khatma);
  });

  tearDown(() async {
    hafs.dispose();
    khatma.dispose();
    await getIt.reset();
  });

  /// Real file IO, isolates and image decoding complete on the real event
  /// loop; their callbacks land in the test zone and need pumps.
  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 300 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      done(),
      isTrue,
      reason: 'not reached; pack state ${hafs.currentState.status}',
    );
  }

  /// Banners are only laid over a decoded page image.
  bool pageShown() => find.text('surah003').evaluate().isNotEmpty;

  testWidgets('a missing pack offers a download instead of pages', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpUntil(
      tester,
      () => find.text('Mushaf pages').evaluate().isNotEmpty,
    );

    expect(find.text('Mushaf pages'), findsOneWidget);
    expect(find.text('Download (~87 MB)'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    // Installing itself is covered by mushaf_pack_service_test; isolates
    // started inside the test zone do not report back.
    await tester.tap(find.text('Download (~87 MB)'));
    await pumpUntil(
      tester,
      () => hafs.currentState.status != MushafPackStatus.idle,
    );
    await tester.pump();
    expect(find.text('Download (~87 MB)'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an installed pack shows the page instead of the download', (
    tester,
  ) async {
    await tester.runAsync(hafs.downloadAndInstall);
    await tester.pumpWidget(app());
    await pumpUntil(tester, pageShown);

    expect(find.text('Mushaf pages'), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('long-pressing the page reports the ayah under the finger', (
    tester,
  ) async {
    await tester.runAsync(hafs.downloadAndInstall);
    final pressed = <(int, int)>[];
    await tester.pumpWidget(app(onLongPress: (s, a) => pressed.add((s, a))));
    await pumpUntil(tester, pageShown);

    final page = find.byType(CustomPaint).last;
    final box = tester.getRect(page);
    // Upper part of the image is ayah 2:200, lower part 2:201 (testLayout).
    await tester.longPressAt(Offset(box.left + 10, box.top + box.height * 0.2));
    await tester.longPressAt(Offset(box.left + 10, box.top + box.height * 0.8));
    expect(pressed, [(2, 200), (2, 201)]);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a page whose file vanished asks for the pack again', (
    tester,
  ) async {
    await tester.runAsync(hafs.downloadAndInstall);
    await tester.runAsync(() => hafs.pageFile(200).delete());
    await tester.pumpWidget(app());
    await pumpUntil(
      tester,
      () => find.text('Mushaf pages').evaluate().isNotEmpty,
    );

    expect(hafs.isReady, isFalse);
    expect(find.text('Mushaf pages'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the IndoPak mode reads its own 610-page pack', (tester) async {
    final server = Directory('${base.path}/indopak_server')..createSync();
    final manifest = writePack(server, pageBytes: _pagePng, pageCount: 610);
    final indopak = MushafPackService(
      cache: CacheHelper(),
      pack: MushafPack.indopak,
      rootDirectory: () async => Directory('${base.path}/support'),
      tempDirectory: () async => Directory('${base.path}/tmp'),
      fetchJson: (_) async =>
          jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>,
      download: (url, savePath, onProgress) async {
        await File('${server.path}/${url.split('/').last}').copy(savePath);
        onProgress(1, 1);
      },
    );
    getIt.registerSingleton<MushafPackService>(
      indopak,
      instanceName: 'indopak',
    );
    addTearDown(indopak.dispose);
    await tester.runAsync(indopak.downloadAndInstall);

    await tester.pumpWidget(app(page: 610, mode: QuranReadingMode.indopak));
    await pumpUntil(tester, pageShown);

    // 610 pages: the last page exists and is the one shown.
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      609,
    );
    expect(hafs.isReady, isFalse, reason: 'other packs are untouched');
    await tester.pumpWidget(const SizedBox());
  });
}
