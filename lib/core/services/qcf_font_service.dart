import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/keys/hadith_key.dart';

enum FontPackType {
  qcf4,
  tajweed;

  String get cacheKey {
    switch (this) {
      case FontPackType.qcf4:
        return 'qcf4_fonts_downloaded';
      case FontPackType.tajweed:
        return 'tajweed_fonts_downloaded';
    }
  }

  List<String> get storageParts {
    switch (this) {
      case FontPackType.qcf4:
        return ['qcf4_01.zip', 'qcf4_02.zip'];
      case FontPackType.tajweed:
        return ['tajweed_01.zip', 'tajweed_02.zip'];
    }
  }

  String get fontDirName {
    switch (this) {
      case FontPackType.qcf4:
        return 'qcf4_fonts';
      case FontPackType.tajweed:
        return 'tajweed_fonts';
    }
  }

  String get zipFileName {
    switch (this) {
      case FontPackType.qcf4:
        return 'qcf4.zip';
      case FontPackType.tajweed:
        return 'tajweed.zip';
    }
  }

  String get sizeLabel {
    switch (this) {
      case FontPackType.qcf4:
        return '~50 MB';
      case FontPackType.tajweed:
        return '~65 MB';
    }
  }

  String _supabasePublicUrl(String filename) =>
      '$supabaseUrl/storage/v1/object/public/Quran/$filename';
}

enum QcfFontStatus { idle, downloading, extracting, loading, ready, error }

class QcfFontDownloadState {
  final QcfFontStatus status;
  final double progress;
  final String? errorMessage;

  const QcfFontDownloadState({
    this.status = QcfFontStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });

  const QcfFontDownloadState.idle() : this();

  const QcfFontDownloadState.downloading(double p)
      : this(status: QcfFontStatus.downloading, progress: p);

  const QcfFontDownloadState.extracting()
      : this(status: QcfFontStatus.extracting);

  const QcfFontDownloadState.loading() : this(status: QcfFontStatus.loading);

  const QcfFontDownloadState.ready() : this(status: QcfFontStatus.ready);

  QcfFontDownloadState.error(String message)
      : this(status: QcfFontStatus.error, errorMessage: message);
}

class QcfFontService {
  final FontPackType packType;
  static const int totalFonts = 604;

  final CacheHelper _cache;

  bool _fontsReady = false;
  bool get areFontsReady => _fontsReady;

  bool get wasPreviouslyDownloaded =>
      _cache.getData(key: packType.cacheKey) as bool? ?? false;

  final _stateController = StreamController<QcfFontDownloadState>.broadcast();
  Stream<QcfFontDownloadState> get stateStream => _stateController.stream;

  QcfFontDownloadState _currentState = const QcfFontDownloadState.idle();
  QcfFontDownloadState get currentState => _currentState;

  final Set<int> _loadedPages = {};
  final Set<int> _loadingPages = {};
  final Map<int, String> _pageFileIndex = {};

  final _pageFontLoadedController = StreamController<int>.broadcast();
  Stream<int> get pageFontLoadedStream => _pageFontLoadedController.stream;

  bool isPageFontLoaded(int pageNumber) => _loadedPages.contains(pageNumber);

  QcfFontService(
      {required CacheHelper cache, this.packType = FontPackType.qcf4})
      : _cache = cache;

  Future<void> init() async {
    if (kIsWeb) return;

    final downloaded = _cache.getData(key: packType.cacheKey) as bool? ?? false;
    if (!downloaded) return;

    final fontsDir = await _fontsDirectory();
    if (!fontsDir.existsSync()) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    _buildPageFileIndex(fontsDir);

    if (_pageFileIndex.isEmpty) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    _fontsReady = true;
    _emit(const QcfFontDownloadState.ready());
  }

  Future<void> downloadAndInstall() async {
    if (_fontsReady) return;
    if (_currentState.status == QcfFontStatus.downloading ||
        _currentState.status == QcfFontStatus.extracting ||
        _currentState.status == QcfFontStatus.loading) {
      return;
    }

    try {
      _emit(const QcfFontDownloadState.downloading(0));

      final tempDir = await getTemporaryDirectory();
      final part1File = File('${tempDir.path}/${packType.name}_01.zip');
      final part2File = File('${tempDir.path}/${packType.name}_02.zip');

      final dio = Dio();

      await dio.download(
        packType._supabasePublicUrl(packType.storageParts[0]),
        part1File.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(QcfFontDownloadState.downloading(
                (received / total * 0.5).clamp(0.0, 0.5)));
          }
        },
      );

      await dio.download(
        packType._supabasePublicUrl(packType.storageParts[1]),
        part2File.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(QcfFontDownloadState.downloading(
                (0.5 + received / total * 0.5).clamp(0.5, 1.0)));
          }
        },
      );

      _emit(const QcfFontDownloadState.downloading(1.0));

      _emit(const QcfFontDownloadState.extracting());
      final fontsDir = await _fontsDirectory();
      if (fontsDir.existsSync()) {
        fontsDir.deleteSync(recursive: true);
      }
      fontsDir.createSync(recursive: true);

      await compute(_extractZip, _ExtractArgs(part1File.path, fontsDir.path));
      if (part1File.existsSync()) part1File.deleteSync();

      await compute(_extractZip, _ExtractArgs(part2File.path, fontsDir.path));
      if (part2File.existsSync()) part2File.deleteSync();

      _buildPageFileIndex(fontsDir);

      await _cache.saveData(key: packType.cacheKey, value: true);
      _fontsReady = true;
      _emit(const QcfFontDownloadState.ready());
    } catch (e) {
      debugPrint('QcfFontService(${packType.name}): download error: $e');
      _emit(QcfFontDownloadState.error(e.toString()));
    }
  }

  Future<Directory> _fontsDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    return Directory('${appSupport.path}/${packType.fontDirName}');
  }

  Future<void> ensurePagesLoaded(List<int> pageNumbers) async {
    final toLoad = pageNumbers
        .where((p) =>
            !_loadedPages.contains(p) &&
            !_loadingPages.contains(p) &&
            _pageFileIndex.containsKey(p))
        .toList();

    if (toLoad.isEmpty) return;

    const batchSize = 5;
    for (int i = 0; i < toLoad.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, toLoad.length);
      await Future.wait(toLoad.sublist(i, end).map(_loadSingleFont));
    }
  }

  Future<void> _loadSingleFont(int pageNumber) async {
    if (_loadedPages.contains(pageNumber) ||
        _loadingPages.contains(pageNumber)) {
      return;
    }
    _loadingPages.add(pageNumber);

    final filePath = _pageFileIndex[pageNumber];
    if (filePath == null) {
      _loadingPages.remove(pageNumber);
      return;
    }

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final byteData = ByteData.view(bytes.buffer);
      final loader = FontLoader(_familyNameForPage(pageNumber));
      loader.addFont(Future.value(byteData));
      await loader.load();

      _loadingPages.remove(pageNumber);
      _loadedPages.add(pageNumber);
      _pageFontLoadedController.add(pageNumber);
    } catch (e) {
      _loadingPages.remove(pageNumber);
      debugPrint(
          'QcfFontService(${packType.name}): failed to load font for page $pageNumber: $e');
    }
  }

  void _buildPageFileIndex(Directory fontsDir) {
    _pageFileIndex.clear();
    final fontFiles = fontsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .toList();

    for (final file in fontFiles) {
      final familyName = _familyNameFromFile(file);
      if (familyName == null) continue;
      final pageNum = int.tryParse(familyName.substring(5));
      if (pageNum == null) continue;
      _pageFileIndex[pageNum] = file.path;
    }
  }

  String _familyNameForPage(int pageNumber) {
    final padded = pageNumber.toString().padLeft(3, '0');
    return packType == FontPackType.qcf4 ? 'QCF_P$padded' : 'QCF_T$padded';
  }

  String? _familyNameFromFile(File file) {
    final name = file.uri.pathSegments.last;

    switch (packType) {
      case FontPackType.qcf4:
        final match = RegExp(r'QCF4(\d{3})').firstMatch(name);
        if (match == null) return null;
        return 'QCF_P${match.group(1)}';

      case FontPackType.tajweed:
        final match =
            RegExp(r'^p(\d+)\.ttf$', caseSensitive: false).firstMatch(name);
        if (match == null) return null;
        final num = int.tryParse(match.group(1)!);
        if (num == null) return null;
        return 'QCF_T${num.toString().padLeft(3, '0')}';
    }
  }

  void _emit(QcfFontDownloadState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    _stateController.close();
    _pageFontLoadedController.close();
  }
}

class _ExtractArgs {
  final String zipPath;
  final String destPath;
  _ExtractArgs(this.zipPath, this.destPath);
}

void _extractZip(_ExtractArgs args) {
  final bytes = File(args.zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final entry in archive) {
    if (entry.isFile) {
      final fileName = entry.name.split('/').last;
      if (fileName.endsWith('.ttf')) {
        final outFile = File('${args.destPath}/$fileName');
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(entry.content as List<int>);
      }
    }
  }
}
