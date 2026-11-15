import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// layout.json with one full-page ayah segment per page.
Map<String, Object> testLayout({int pageCount = 604}) => {
  'pack': 'test',
  'width': 1260,
  'height': 2375,
  'pages': {
    for (var p = 1; p <= pageCount; p++)
      '$p': {
        'lines': 15,
        'ayahs': [
          [2, p, 1, 0, 0, 1260, 1000],
          [2, p + 1, 2, 0, 1000, 1260, 2375],
        ],
        'markers': [
          [2, p, 600, 900, 660, 1000],
        ],
        'banners': [
          [3, 4, 100, 1256, 260],
        ],
      },
  },
};

/// Writes a two-part pack and returns its manifest.
Map<String, Object> writePack(
  Directory dir, {
  List<int>? pageBytes,
  int pageCount = 604,
}) {
  final bytes = pageBytes ?? [1, 2, 3];
  final parts = <Map<String, Object>>[];
  final half = pageCount ~/ 2;
  for (final range in [(1, half), (half + 1, pageCount)]) {
    final archive = Archive();
    if (range.$1 == 1) {
      final json = utf8.encode(jsonEncode(testLayout(pageCount: pageCount)));
      archive.add(ArchiveFile('layout.json', json.length, json));
    }
    for (var p = range.$1; p <= range.$2; p++) {
      archive.add(
        ArchiveFile(
          'page${p.toString().padLeft(3, '0')}.webp',
          bytes.length,
          bytes,
        ),
      );
    }
    final zip = ZipEncoder().encode(archive);
    final name = 'test_${parts.length + 1}.zip';
    File('${dir.path}/$name').writeAsBytesSync(zip);
    parts.add({
      'file': name,
      'bytes': zip.length,
      'sha256': sha256.convert(zip).toString(),
    });
  }
  return {'id': 'test', 'parts': parts};
}

void main() {
  late Directory root;
  late Directory temp;
  late Directory server;
  late CacheHelper cache;
  late Map<String, Object> manifest;
  late List<String> downloads;

  MushafPackService service({MushafPack pack = MushafPack.hafs}) =>
      MushafPackService(
        cache: cache,
        pack: pack,
        rootDirectory: () async => root,
        tempDirectory: () async => temp,
        fetchJson: (url) async {
          expect(url, '${pack.baseUrl}/manifest.json');
          return jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
        },
        download: (url, savePath, onProgress) async {
          downloads.add(url);
          final source = File('${server.path}/${url.split('/').last}');
          await source.copy(savePath);
          final length = await source.length();
          onProgress(length, length);
        },
      );

  setUp(() async {
    final base = await Directory.systemTemp.createTemp('mushaf_pack_test');
    root = await Directory('${base.path}/support').create();
    temp = await Directory('${base.path}/tmp').create();
    server = await Directory('${base.path}/server').create();
    SharedPreferences.setMockInitialValues({});
    cache = CacheHelper();
    await cache.init();
    manifest = writePack(server);
    downloads = [];
  });

  test('init removes the page fonts from earlier versions', () async {
    final fonts = await Directory('${root.path}/qcf4_fonts').create();
    File('${fonts.path}/QCF4001_X-Regular.ttf').writeAsBytesSync([0]);
    File('${temp.path}/qcf4_01.zip').writeAsBytesSync([0]);
    await cache.saveData(key: 'qcf4_fonts_downloaded', value: true);
    final tajweedFonts = await Directory('${root.path}/tajweed_fonts').create();

    final hafs = service();
    await hafs.init();

    expect(fonts.existsSync(), isFalse);
    expect(File('${temp.path}/qcf4_01.zip').existsSync(), isFalse);
    expect(cache.getData(key: 'qcf4_fonts_downloaded'), isNull);
    expect(hafs.isReady, isFalse);
    // Each pack only removes its own legacy fonts.
    expect(tajweedFonts.existsSync(), isTrue);
    await service(pack: MushafPack.tajweed).init();
    expect(tajweedFonts.existsSync(), isFalse);
  });

  test('init removes what an interrupted install left behind', () async {
    final staging = await Directory(
      '${root.path}/mushaf_packs/hafs_v4_1260.partial',
    ).create(recursive: true);
    File('${staging.path}/page001.webp').writeAsBytesSync([0]);
    File('${temp.path}/hafs_v4_1260_01.zip').writeAsBytesSync([0]);
    File('${temp.path}/tajweed_v4_1260_01.zip').writeAsBytesSync([0]);

    await service().init();

    expect(staging.existsSync(), isFalse);
    expect(File('${temp.path}/hafs_v4_1260_01.zip').existsSync(), isFalse);
    // A download of another pack may still be running.
    expect(File('${temp.path}/tajweed_v4_1260_01.zip').existsSync(), isTrue);
  });

  test('installs every part, verifies it and loads the layout', () async {
    final hafs = service();
    final states = <MushafPackStatus>[];
    hafs.stateStream.listen((s) => states.add(s.status));

    await hafs.downloadAndInstall();
    await Future<void>.delayed(Duration.zero); // deliver broadcast events

    expect(hafs.isReady, isTrue);
    expect(hafs.wasPreviouslyInstalled, isTrue);
    expect(downloads, hasLength(2));
    expect(hafs.pageFile(604).readAsBytesSync(), [1, 2, 3]);
    expect(hafs.layout!.imageWidth, 1260);
    expect(hafs.layout!.pages, hasLength(604));
    expect(hafs.layout!.pages[50]!.banners.single.surah, 3);
    expect(states.first, MushafPackStatus.downloading);
    expect(states.last, MushafPackStatus.ready);
    expect(states, contains(MushafPackStatus.extracting));
    expect(temp.listSync(), isEmpty, reason: 'downloaded parts are removed');
    expect(
      Directory('${root.path}/mushaf_packs/hafs_v4_1260.partial').existsSync(),
      isFalse,
    );
  });

  test('an installed pack is ready again after a restart', () async {
    await service().downloadAndInstall();
    downloads.clear();

    final restarted = service();
    await restarted.init();

    expect(restarted.isReady, isTrue);
    expect(downloads, isEmpty);
  });

  test(
    'a corrupted part fails the install and leaves nothing behind',
    () async {
      final parts = manifest['parts']! as List<Map<String, Object>>;
      parts[1]['sha256'] = '0' * 64;
      final hafs = service();

      await hafs.downloadAndInstall();

      expect(hafs.isReady, isFalse);
      expect(hafs.wasPreviouslyInstalled, isFalse);
      expect(hafs.currentState.status, MushafPackStatus.error);
      expect(
        Directory('${root.path}/mushaf_packs/hafs_v4_1260').existsSync(),
        isFalse,
      );
      expect(
        Directory(
          '${root.path}/mushaf_packs/hafs_v4_1260.partial',
        ).existsSync(),
        isFalse,
      );
      expect(temp.listSync(), isEmpty);

      // Retrying with a good manifest succeeds.
      manifest = writePack(server);
      await hafs.downloadAndInstall();
      expect(hafs.isReady, isTrue);
    },
  );

  test('a pack missing its files is offered for download again', () async {
    await cache.saveData(key: MushafPack.hafs.cacheKey, value: true);
    final hafs = service();
    await hafs.init();
    expect(hafs.isReady, isFalse);
    expect(hafs.wasPreviouslyInstalled, isFalse);

    await hafs.downloadAndInstall();
    expect(hafs.isReady, isTrue);
    await hafs.markBroken();
    expect(hafs.isReady, isFalse);
    expect(hafs.wasPreviouslyInstalled, isFalse);
    expect(hafs.currentState.status, MushafPackStatus.idle);
  });

  test('concurrent install requests share one download', () async {
    final hafs = service();
    await Future.wait([hafs.downloadAndInstall(), hafs.downloadAndInstall()]);
    expect(downloads, hasLength(2));
    expect(hafs.isReady, isTrue);
  });

  test('the IndoPak pack installs its 610 pages', () async {
    manifest = writePack(server, pageCount: 610);
    final indopak = service(pack: MushafPack.indopak);

    await indopak.downloadAndInstall();

    expect(indopak.isReady, isTrue);
    expect(indopak.layout!.pages, hasLength(610));
    expect(indopak.pageFile(610).existsSync(), isTrue);
  });

  test('a pack missing pages is rejected', () async {
    // A 604-page archive is incomplete for the 610-page IndoPak pack.
    final indopak = service(pack: MushafPack.indopak);
    await indopak.downloadAndInstall();
    expect(indopak.isReady, isFalse);
    expect(indopak.currentState.errorMessage, contains('page605.webp'));
  });

  test('hit testing prefers the ayah-number glyph over the text', () {
    final page = MushafPageLayout.fromJson(
      (testLayout()['pages']! as Map<String, Object>)['10']!
          as Map<String, dynamic>,
    );
    expect(page.ayahAt(const Offset(630, 950)), (surah: 2, ayah: 10));
    expect(page.ayahAt(const Offset(100, 1500)), (surah: 2, ayah: 11));
    expect(page.ayahAt(const Offset(100, 500)), (surah: 2, ayah: 10));
    expect(page.ayahAt(const Offset(100, 3000)), isNull);
  });
}
