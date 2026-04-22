import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:huda/core/cache/cache_helper.dart';

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

  String get storagePath {
    switch (this) {
      case FontPackType.qcf4:
        return 'fonts/qcf4.zip';
      case FontPackType.tajweed:
        return 'fonts/tajweed.zip';
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

  QcfFontService(
      {required CacheHelper cache, this.packType = FontPackType.qcf4})
      : _cache = cache;

  Future<void> init() async {
    if (kIsWeb) return;

    final downloaded = _cache.getData(key: packType.cacheKey) as bool? ?? false;
    if (!downloaded) return;

    _emit(const QcfFontDownloadState.loading());

    final fontsDir = await _fontsDirectory();
    if (!fontsDir.existsSync()) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    final fontFiles = fontsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .toList();

    if (fontFiles.isEmpty) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    await _loadFontsFromDisk(fontsDir);
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
      final zipFile = File('${tempDir.path}/${packType.zipFileName}');

      final ref = FirebaseStorage.instance.ref(packType.storagePath);
      final downloadTask = ref.writeToFile(zipFile);

      downloadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          _emit(QcfFontDownloadState.downloading(progress.clamp(0.0, 1.0)));
        }
      });

      await downloadTask;
      _emit(const QcfFontDownloadState.downloading(1.0));

      _emit(const QcfFontDownloadState.extracting());
      final fontsDir = await _fontsDirectory();
      if (fontsDir.existsSync()) {
        fontsDir.deleteSync(recursive: true);
      }
      fontsDir.createSync(recursive: true);

      await compute(_extractZip, _ExtractArgs(zipFile.path, fontsDir.path));

      if (zipFile.existsSync()) zipFile.deleteSync();

      _emit(const QcfFontDownloadState.loading());
      await _loadFontsFromDisk(fontsDir);

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

  Future<void> _loadFontsFromDisk(Directory fontsDir) async {
    final fontFiles = fontsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in fontFiles) {
      final familyName = _familyNameFromFile(file);
      if (familyName == null) continue;

      try {
        final bytes = await file.readAsBytes();
        final byteData = ByteData.view(bytes.buffer);
        final loader = FontLoader(familyName);
        loader.addFont(Future.value(byteData));
        await loader.load();
      } catch (e) {
        debugPrint(
            'QcfFontService(${packType.name}): failed to load font $familyName: $e');
      }
    }
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
