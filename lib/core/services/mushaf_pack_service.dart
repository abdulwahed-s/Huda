import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/painting.dart' show Offset, Rect;
import 'package:path_provider/path_provider.dart';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/keys/hadith_key.dart';

/// Downloadable Mushaf page-image packs, rendered from the KFGQPC V4 fonts
/// (see tool/mushaf_pack). Page images replace live QCF font text, which
/// janked on every frame while swiping.
enum MushafPack {
  hafs(
    id: 'hafs_v4_1260',
    sizeLabel: '~87 MB',
    tinted: true,
    pageCount: 604,
    legacyFontDir: 'qcf4_fonts',
    legacyCacheKey: 'qcf4_fonts_downloaded',
    legacyZipPrefix: 'qcf4',
  ),
  tajweed(
    id: 'tajweed_v4_1260',
    sizeLabel: '~80 MB',
    tinted: false,
    pageCount: 604,
    legacyFontDir: 'tajweed_fonts',
    legacyCacheKey: 'tajweed_fonts_downloaded',
    legacyZipPrefix: 'tajweed',
  ),

  /// IndoPak 15 lines (Qudratullah), from QUL's layout, script and font.
  indopak(
    id: 'indopak_15_1260',
    sizeLabel: '~60 MB',
    tinted: true,
    pageCount: 610,
  );

  final String id;
  final String sizeLabel;

  /// Black ink mask tinted with the theme text color (Hafs), or Tajweed
  /// colors baked into the image.
  final bool tinted;
  final int pageCount;

  /// Page fonts that versions before page images downloaded for this layout.
  final String? legacyFontDir;
  final String? legacyCacheKey;
  final String? legacyZipPrefix;

  const MushafPack({
    required this.id,
    required this.sizeLabel,
    required this.tinted,
    required this.pageCount,
    this.legacyFontDir,
    this.legacyCacheKey,
    this.legacyZipPrefix,
  });

  String get cacheKey => 'mushaf_pack_${id}_installed';

  String get baseUrl =>
      '$supabaseUrl/storage/v1/object/public/Quran/mushaf/v1/$id';
}

enum MushafPackStatus { idle, downloading, extracting, loading, ready, error }

class MushafPackState {
  final MushafPackStatus status;
  final double progress;
  final String? errorMessage;

  const MushafPackState({
    this.status = MushafPackStatus.idle,
    this.progress = 0,
    this.errorMessage,
  });

  const MushafPackState.idle() : this();
  const MushafPackState.downloading(double p)
    : this(status: MushafPackStatus.downloading, progress: p);
  const MushafPackState.extracting()
    : this(status: MushafPackStatus.extracting, progress: 1);
  const MushafPackState.loading() : this(status: MushafPackStatus.loading);
  const MushafPackState.ready() : this(status: MushafPackStatus.ready);
  MushafPackState.error(String message)
    : this(status: MushafPackStatus.error, errorMessage: message);
}

/// One ayah's run on one line, in image pixels.
class MushafAyahSegment {
  final int surah;
  final int ayah;
  final int line;
  final Rect rect;

  const MushafAyahSegment(this.surah, this.ayah, this.line, this.rect);
}

/// An ayah-number glyph or an empty surah-banner slot, in image pixels.
class MushafPageBox {
  final int surah;
  final int ayah;
  final Rect rect;

  const MushafPageBox(this.surah, this.ayah, this.rect);
}

class MushafPageLayout {
  final List<MushafAyahSegment> ayahs;
  final List<MushafPageBox> markers;

  /// `ayah` is 0: banners belong to a surah, not an ayah.
  final List<MushafPageBox> banners;

  const MushafPageLayout({
    required this.ayahs,
    required this.markers,
    required this.banners,
  });

  /// The ayah under [point] (image pixels): its text or its number glyph.
  ({int surah, int ayah})? ayahAt(Offset point) {
    for (final marker in markers) {
      if (marker.rect.contains(point)) {
        return (surah: marker.surah, ayah: marker.ayah);
      }
    }
    for (final segment in ayahs) {
      if (segment.rect.contains(point)) {
        return (surah: segment.surah, ayah: segment.ayah);
      }
    }
    return null;
  }

  factory MushafPageLayout.fromJson(Map<String, dynamic> json) {
    Rect rect(List<dynamic> r, int from) => Rect.fromLTRB(
      (r[from] as num).toDouble(),
      (r[from + 1] as num).toDouble(),
      (r[from + 2] as num).toDouble(),
      (r[from + 3] as num).toDouble(),
    );
    return MushafPageLayout(
      ayahs: [
        for (final r in json['ayahs'] as List<dynamic>)
          MushafAyahSegment(
            (r as List<dynamic>)[0] as int,
            r[1] as int,
            r[2] as int,
            rect(r, 3),
          ),
      ],
      markers: [
        for (final r in json['markers'] as List<dynamic>)
          MushafPageBox(
            (r as List<dynamic>)[0] as int,
            r[1] as int,
            rect(r, 2),
          ),
      ],
      banners: [
        for (final r in json['banners'] as List<dynamic>)
          MushafPageBox((r as List<dynamic>)[0] as int, 0, rect(r, 1)),
      ],
    );
  }
}

class MushafPackLayout {
  final int imageWidth;
  final int imageHeight;
  final Map<int, MushafPageLayout> pages;

  const MushafPackLayout({
    required this.imageWidth,
    required this.imageHeight,
    required this.pages,
  });

  double get aspectRatio => imageWidth / imageHeight;

  factory MushafPackLayout.fromJson(Map<String, dynamic> json) {
    final pages = json['pages'] as Map<String, dynamic>;
    return MushafPackLayout(
      imageWidth: json['width'] as int,
      imageHeight: json['height'] as int,
      pages: {
        for (final entry in pages.entries)
          int.parse(entry.key): MushafPageLayout.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }
}

class MushafPackPart {
  final String file;
  final int bytes;
  final String sha256;

  const MushafPackPart(this.file, this.bytes, this.sha256);
}

typedef MushafPackDownloader =
    Future<void> Function(
      String url,
      String savePath,
      void Function(int received, int total) onProgress,
    );

/// Installs one [MushafPack] and serves its page files and ayah layout.
///
/// Packs live in `<app support>/mushaf_packs/<id>`. Installation downloads
/// every part, checks its size and SHA-256 from manifest.json, extracts into
/// a staging directory, and only then replaces the installed pack.
class MushafPackService {
  static const _layoutFile = 'layout.json';

  final MushafPack pack;
  final CacheHelper _cache;
  final Future<Directory> Function() _rootDirectory;
  final Future<Directory> Function() _tempDirectory;
  final Future<Map<String, dynamic>> Function(String url) _fetchJson;
  final MushafPackDownloader _download;

  Future<void>? _initialization;
  Future<void>? _installation;
  Directory? _packDir;
  MushafPackLayout? _layout;

  final _stateController = StreamController<MushafPackState>.broadcast();
  MushafPackState _currentState = const MushafPackState.idle();

  MushafPackService({
    required CacheHelper cache,
    required this.pack,
    Future<Directory> Function()? rootDirectory,
    Future<Directory> Function()? tempDirectory,
    Future<Map<String, dynamic>> Function(String url)? fetchJson,
    MushafPackDownloader? download,
  }) : _cache = cache,
       _rootDirectory = rootDirectory ?? getApplicationSupportDirectory,
       _tempDirectory = tempDirectory ?? getTemporaryDirectory,
       _fetchJson = fetchJson ?? _dioFetchJson,
       _download = download ?? _dioDownload;

  Stream<MushafPackState> get stateStream => _stateController.stream;
  MushafPackState get currentState => _currentState;

  /// Installed and its layout loaded: pages can be shown.
  bool get isReady => _layout != null;

  bool get wasPreviouslyInstalled =>
      _cache.getData(key: pack.cacheKey) as bool? ?? false;

  MushafPackLayout? get layout => _layout;

  File pageFile(int page) =>
      File('${_packDir!.path}/page${page.toString().padLeft(3, '0')}.webp');

  /// Removes the legacy page fonts and loads an installed pack. Safe to call
  /// repeatedly; concurrent callers share one run.
  Future<void> init() =>
      _initialization ??= _initialize().catchError((Object error) {
        _initialization = null;
        debugPrint('MushafPackService(${pack.id}): init error: $error');
        _emit(MushafPackState.error(error.toString()));
      });

  Future<void> _initialize() async {
    if (kIsWeb) return;
    final root = await _rootDirectory();
    await _removeLegacyFonts(root);
    _packDir = Directory('${root.path}/mushaf_packs/${pack.id}');
    await _removeInterruptedInstall();
    if (!wasPreviouslyInstalled) return;
    if (!await File('${_packDir!.path}/$_layoutFile').exists()) {
      await _cache.saveData(key: pack.cacheKey, value: false);
      return;
    }
    _emit(const MushafPackState.loading());
    await _loadLayout();
    _emit(const MushafPackState.ready());
  }

  /// Page fonts from versions before page images; the reader no longer uses
  /// them.
  Future<void> _removeLegacyFonts(Directory root) async {
    final fontDir = pack.legacyFontDir;
    if (fontDir == null) return;
    final fonts = Directory('${root.path}/$fontDir');
    if (await fonts.exists()) {
      try {
        await fonts.delete(recursive: true);
      } catch (error) {
        debugPrint('MushafPackService: could not remove legacy fonts: $error');
      }
    }
    final legacyKey = pack.legacyCacheKey;
    if (legacyKey != null && _cache.getData(key: legacyKey) != null) {
      await _cache.removeData(key: legacyKey);
    }
    try {
      final temp = await _tempDirectory();
      for (final part in ['01', '02']) {
        final zip = File('${temp.path}/${pack.legacyZipPrefix}_$part.zip');
        if (await zip.exists()) await zip.delete();
      }
    } catch (_) {}
  }

  /// Staging and part zips left by an install the app was killed during.
  Future<void> _removeInterruptedInstall() async {
    try {
      final staging = Directory('${_packDir!.path}.partial');
      if (await staging.exists()) await staging.delete(recursive: true);
      final temp = await _tempDirectory();
      for (final part in ['01', '02']) {
        final zip = File('${temp.path}/${pack.id}_$part.zip');
        if (await zip.exists()) await zip.delete();
      }
    } catch (error) {
      debugPrint('MushafPackService(${pack.id}): cleanup error: $error');
    }
  }

  Future<void> _loadLayout() async {
    final json = await _readJsonInIsolate('${_packDir!.path}/$_layoutFile');
    _layout = MushafPackLayout.fromJson(json);
  }

  Future<void> downloadAndInstall() =>
      _installation ??= _install().whenComplete(() => _installation = null);

  Future<void> _install() async {
    try {
      await init();
      if (kIsWeb || isReady) return;
      _emit(const MushafPackState.downloading(0));

      final manifest = await _fetchJson('${pack.baseUrl}/manifest.json');
      final parts = [
        for (final p in manifest['parts'] as List<dynamic>)
          MushafPackPart(
            (p as Map<String, dynamic>)['file'] as String,
            p['bytes'] as int,
            p['sha256'] as String,
          ),
      ];
      final totalBytes = parts.fold<int>(0, (sum, p) => sum + p.bytes);

      final temp = await _tempDirectory();
      final staging = Directory('${_packDir!.path}.partial');
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);

      final zips = <File>[];
      try {
        var completedBytes = 0;
        for (final part in parts) {
          final zip = File('${temp.path}/${part.file}');
          zips.add(zip);
          await _download('${pack.baseUrl}/${part.file}', zip.path, (
            received,
            _,
          ) {
            _emit(
              MushafPackState.downloading(
                ((completedBytes + received) / totalBytes).clamp(0.0, 1.0),
              ),
            );
          });
          await _verify(zip, part);
          completedBytes += part.bytes;
        }

        _emit(const MushafPackState.extracting());
        for (final zip in zips) {
          await _extractInIsolate(zip.path, staging.path);
        }
        await _validateStaging(staging);

        await _cache.saveData(key: pack.cacheKey, value: false);
        final installed = _packDir!;
        if (await installed.exists()) await installed.delete(recursive: true);
        await staging.rename(installed.path);
      } catch (_) {
        if (await staging.exists()) await staging.delete(recursive: true);
        rethrow;
      } finally {
        for (final zip in zips) {
          if (await zip.exists()) await zip.delete();
        }
      }

      _emit(const MushafPackState.loading());
      await _loadLayout();
      await _cache.saveData(key: pack.cacheKey, value: true);
      _emit(const MushafPackState.ready());
    } catch (error) {
      debugPrint('MushafPackService(${pack.id}): install error: $error');
      _emit(MushafPackState.error(error.toString()));
    }
  }

  Future<void> _verify(File zip, MushafPackPart part) async {
    final length = await zip.length();
    if (length != part.bytes) {
      throw FileSystemException(
        'Size mismatch: $length of ${part.bytes} bytes',
        zip.path,
      );
    }
    final digest = await sha256.bind(zip.openRead()).first;
    if (digest.toString() != part.sha256) {
      throw FileSystemException('Checksum mismatch', zip.path);
    }
  }

  Future<void> _validateStaging(Directory staging) async {
    if (!await File('${staging.path}/$_layoutFile').exists()) {
      throw const FileSystemException('Pack has no layout.json');
    }
    for (var page = 1; page <= pack.pageCount; page++) {
      final name = 'page${page.toString().padLeft(3, '0')}.webp';
      if (!await File('${staging.path}/$name').exists()) {
        throw FileSystemException('Pack is missing $name');
      }
    }
  }

  /// Called when an installed page file is missing or unreadable, so the
  /// reader offers a fresh download.
  Future<void> markBroken() async {
    _layout = null;
    await _cache.saveData(key: pack.cacheKey, value: false);
    _emit(const MushafPackState.idle());
  }

  void _emit(MushafPackState state) {
    if (_stateController.isClosed) return;
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() => _stateController.close();
}

// Top-level so the isolate closures capture only their arguments, not a
// service (whose pending futures cannot be sent between isolates).
Future<Map<String, dynamic>> _readJsonInIsolate(String path) => Isolate.run(
  () => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
);

Future<void> _extractInIsolate(String zipPath, String destPath) =>
    Isolate.run(() => _extractZip(zipPath, destPath));

/// Streams entries to disk; unlike archive's extractArchiveToDisk, write
/// errors propagate. Entries are flat file names.
void _extractZip(String zipPath, String destPath) {
  final input = InputFileStream(zipPath);
  try {
    final archive = ZipDecoder().decodeStream(input, verify: true);
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.split('/').last;
      if (name.isEmpty || name.startsWith('.')) continue;
      final output = OutputFileStream('$destPath/$name');
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
    }
  } finally {
    input.closeSync();
  }
}

Future<Map<String, dynamic>> _dioFetchJson(String url) async {
  final response = await Dio().get<String>(
    url,
    options: Options(responseType: ResponseType.plain),
  );
  return jsonDecode(response.data!) as Map<String, dynamic>;
}

Future<void> _dioDownload(
  String url,
  String savePath,
  void Function(int received, int total) onProgress,
) => Dio().download(url, savePath, onReceiveProgress: onProgress);
