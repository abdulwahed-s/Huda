import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
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

enum QcfFontPriority { visible, prepared, speculative }

/// A reader moved away or released speculative work before registration.
class QcfFontRequestCancelled implements Exception {
  const QcfFontRequestCancelled();
}

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

class QcfFontService with WidgetsBindingObserver {
  final FontPackType packType;
  static const int totalFonts = 604;
  static const int preloadRadius = 3;
  static const int maxConcurrentReads = 3;
  static const int maxPendingFonts = 8;
  static const int maxPendingBytes = 4 * 1024 * 1024;
  static const speculativeIdleDelay = Duration(milliseconds: 150);

  final CacheHelper _cache;
  final Future<Directory> Function()? _fontsDirectoryProvider;
  final Future<Uint8List> Function(File) _readFont;
  final Future<void> Function(Uint8List, String) _registerFont;
  Future<void>? _initialization;
  Future<void>? _installation;
  bool _disposed = false;

  bool _fontsReady = false;
  bool get areFontsReady => _fontsReady;

  bool get wasPreviouslyDownloaded =>
      _cache.getData(key: packType.cacheKey) as bool? ?? false;

  final _stateController = StreamController<QcfFontDownloadState>.broadcast();
  Stream<QcfFontDownloadState> get stateStream => _stateController.stream;

  QcfFontDownloadState _currentState = const QcfFontDownloadState.idle();
  QcfFontDownloadState get currentState => _currentState;

  final Set<int> _loadedPages = {};
  final Map<int, Future<void>> _loadingPages = {};
  final Map<int, _FontRequest> _requests = {};
  final Map<int, String> _pageFileIndex = {};
  Set<int>? _bufferedPages;
  Set<int> _visiblePages = {};
  Set<int> _preparedPages = {};
  int _windowGeneration = 0;
  int _activeReads = 0;
  bool _readerScrolling = false;
  bool _speculativeWorkEnabled = true;
  bool _speculativeRegistrationAllowed = false;
  Timer? _idleTimer;

  final _pageFontLoadedController = StreamController<int>.broadcast();
  Stream<int> get pageFontLoadedStream => _pageFontLoadedController.stream;

  bool isPageFontLoaded(int pageNumber) => _loadedPages.contains(pageNumber);

  QcfFontService({
    required CacheHelper cache,
    this.packType = FontPackType.qcf4,
    Future<Directory> Function()? fontsDirectory,
    Future<Uint8List> Function(File)? readFont,
    Future<void> Function(Uint8List, String)? registerFont,
  }) : _cache = cache,
       _fontsDirectoryProvider = fontsDirectory,
       _readFont = readFont ?? ((file) => file.readAsBytes()),
       _registerFont =
           registerFont ??
           ((bytes, family) => ui.loadFontFromList(bytes, fontFamily: family)) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() {
    if (_disposed) return Future.error(const QcfFontRequestCancelled());
    final existing = _initialization;
    if (existing != null) return existing;
    final completer = Completer<void>();
    _initialization = completer.future;
    _initialize().then(
      completer.complete,
      onError: (Object error, StackTrace stack) {
        _initialization = null;
        _emit(QcfFontDownloadState.error(error.toString()));
        completer.completeError(error, stack);
      },
    );
    return completer.future;
  }

  Future<void> _initialize() async {
    if (kIsWeb) return;

    final downloaded = _cache.getData(key: packType.cacheKey) as bool? ?? false;
    if (!downloaded) return;

    final fontsDir = await _fontsDirectory();
    if (!await fontsDir.exists()) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    await _buildPageFileIndex(fontsDir);

    if (_pageFileIndex.isEmpty) {
      await _cache.saveData(key: packType.cacheKey, value: false);
      _emit(const QcfFontDownloadState.idle());
      return;
    }

    _fontsReady = true;
    _emit(const QcfFontDownloadState.ready());
  }

  Future<void> downloadAndInstall() => _installation ??= _downloadAndInstall();

  Future<void> _downloadAndInstall() async {
    try {
      await init();
      if (kIsWeb || _fontsReady) return;
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
            _emit(
              QcfFontDownloadState.downloading(
                (received / total * 0.5).clamp(0.0, 0.5),
              ),
            );
          }
        },
      );

      await dio.download(
        packType._supabasePublicUrl(packType.storageParts[1]),
        part2File.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(
              QcfFontDownloadState.downloading(
                (0.5 + received / total * 0.5).clamp(0.5, 1.0),
              ),
            );
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

      await _buildPageFileIndex(fontsDir);
      if (_pageFileIndex.isEmpty) {
        throw const FileSystemException('No page fonts found in the font pack');
      }

      await _cache.saveData(key: packType.cacheKey, value: true);
      _fontsReady = true;
      _emit(const QcfFontDownloadState.ready());
    } catch (e) {
      debugPrint('QcfFontService(${packType.name}): download error: $e');
      _emit(QcfFontDownloadState.error(e.toString()));
    } finally {
      _installation = null;
    }
  }

  Future<Directory> _fontsDirectory() async {
    if (_fontsDirectoryProvider != null) return _fontsDirectoryProvider();
    final appSupport = await getApplicationSupportDirectory();
    return Directory('${appSupport.path}/${packType.fontDirName}');
  }

  Future<void> _awaitPackReady() async {
    await init();
    final installation = _installation;
    if (installation != null) await installation;
    if (_disposed) throw const QcfFontRequestCancelled();
    if (!_fontsReady) {
      throw StateError('The ${packType.name} font pack is not installed');
    }
  }

  /// Completes only after every requested font is registered, including an
  /// operation already in progress. Failed operations are removed for retry.
  Future<void> ensurePagesLoaded(
    Iterable<int> pageNumbers, {
    QcfFontPriority priority = QcfFontPriority.visible,
  }) async {
    if (kIsWeb) return;
    final generation = _windowGeneration;
    await _awaitPackReady();
    if (_bufferedPages != null && generation != _windowGeneration) {
      throw const QcfFontRequestCancelled();
    }
    await _queuePages(pageNumbers, priority);
  }

  Future<void> _queuePages(
    Iterable<int> pageNumbers,
    QcfFontPriority priority,
  ) async {
    final futures = pageNumbers
        .where((page) => page >= 1 && page <= totalFonts)
        .toSet()
        .map((page) => _requestPage(page, priority))
        .toList();
    _pumpReads();
    _flushSpeculativeFonts();
    await Future.wait(futures);
  }

  /// Refresh the disk index on an explicit retry, without forgetting fonts
  /// already registered in the engine. This also recovers restored files that
  /// were absent during the original initialization.
  Future<void> retryPagesLoaded(
    Iterable<int> pageNumbers, {
    QcfFontPriority priority = QcfFontPriority.visible,
  }) async {
    if (kIsWeb) return;
    final generation = _windowGeneration;
    await _awaitPackReady();
    await _buildPageFileIndex(await _fontsDirectory());
    if (_disposed || generation != _windowGeneration) {
      throw const QcfFontRequestCancelled();
    }
    await _queuePages(pageNumbers, priority);
  }

  /// Visible dependencies finish independently of the neighboring buffer.
  Future<void> loadPageWindow(int pageNumber, {bool doublePage = false}) async {
    final generation = ++_windowGeneration;
    final page = pageNumber.clamp(1, totalFonts);
    final rightPage = doublePage ? ((page - 1) ~/ 2) * 2 + 1 : page;
    final timing = TimelineTask()
      ..start(
        'Quran visible fonts',
        arguments: {
          'pack': packType.name,
          'page': rightPage,
          'doublePage': doublePage,
        },
      );
    _visiblePages = {1, rightPage, if (doublePage) rightPage + 1};
    _preparedPages = {
      if (doublePage) ...[
        rightPage - 2,
        rightPage - 1,
        rightPage + 2,
        rightPage + 3,
      ] else ...[
        rightPage - 1,
        rightPage + 1,
      ],
    }..removeWhere((page) => page < 1 || page > totalFonts);
    _bufferedPages = {
      ..._visiblePages,
      for (var offset = -preloadRadius; offset <= preloadRadius; offset++)
        if (rightPage + offset >= 1 && rightPage + offset <= totalFonts)
          rightPage + offset,
    };
    _speculativeWorkEnabled = true;
    for (final request in _requests.values.toList()) {
      if (!_bufferedPages!.contains(request.page) && !request.registering) {
        _cancelRequest(request);
      }
    }
    _updateRequestPriorities();
    _scheduleIdleRegistration();
    try {
      await _awaitPackReady();
      if (generation != _windowGeneration || _disposed) return;
      final visible = _queuePages(_visiblePages, QcfFontPriority.visible);
      _ignoreSpeculativeResult(
        _queuePages(_preparedPages, QcfFontPriority.prepared),
      );
      _ignoreSpeculativeResult(
        _queuePages(
          _bufferedPages!.difference(_visiblePages).difference(_preparedPages),
          QcfFontPriority.speculative,
        ),
      );
      await visible;
    } finally {
      timing.finish();
    }
  }

  /// Promote a page as soon as it starts entering the viewport, including
  /// before PageView's midpoint-based onPageChanged callback.
  void updateVisiblePages(Iterable<int> pages) {
    final visible = {
      1,
      ...pages.where((page) => page >= 1 && page <= totalFonts),
    };
    if (visible.length == _visiblePages.length &&
        visible.every(_visiblePages.contains)) {
      return;
    }
    _visiblePages = visible;
    _updateRequestPriorities();
    _ignoreSpeculativeResult(ensurePagesLoaded(visible));
  }

  void setReaderScrolling(bool scrolling) {
    _readerScrolling = scrolling;
    _scheduleIdleRegistration();
  }

  void _scheduleIdleRegistration() {
    _idleTimer?.cancel();
    _speculativeRegistrationAllowed = false;
    if (_disposed || _readerScrolling || !_speculativeWorkEnabled) return;
    _idleTimer = Timer(speculativeIdleDelay, () {
      _speculativeRegistrationAllowed = true;
      _pumpReads();
      _flushSpeculativeFonts();
    });
  }

  void _ignoreSpeculativeResult(Future<void> future) {
    unawaited(
      future.catchError((Object error) {
        if (error is! QcfFontRequestCancelled) {
          debugPrint('QcfFontService(${packType.name}): preload error: $error');
        }
      }),
    );
  }

  QcfFontPriority _windowPriority(int page) => _visiblePages.contains(page)
      ? QcfFontPriority.visible
      : _preparedPages.contains(page)
      ? QcfFontPriority.prepared
      : QcfFontPriority.speculative;

  Future<void> _requestPage(int page, QcfFontPriority priority) {
    if (_loadedPages.contains(page)) return Future.value();
    if (_visiblePages.contains(page)) priority = QcfFontPriority.visible;
    if (priority != QcfFontPriority.visible &&
        (!_speculativeWorkEnabled ||
            (_bufferedPages != null && !_bufferedPages!.contains(page)))) {
      return Future.error(const QcfFontRequestCancelled());
    }
    final existing = _requests[page];
    if (existing != null) {
      final future = _loadingPages[page]!;
      if (priority.index < existing.priority.index) {
        existing.priority = priority;
      }
      if (existing.priority == QcfFontPriority.visible &&
          existing.bytes != null) {
        _registerRequest(existing);
      }
      return future;
    }
    final path = _pageFileIndex[page];
    if (path == null) {
      return Future.error(FileSystemException('Missing font for page $page'));
    }
    final request = _FontRequest(page, path, priority);
    _requests[page] = request;
    _loadingPages[page] = request.completer.future;
    if (priority != QcfFontPriority.visible && _idleTimer == null) {
      _scheduleIdleRegistration();
    }
    return request.completer.future;
  }

  void _updateRequestPriorities() {
    for (final request in _requests.values.toList()) {
      request.priority = _windowPriority(request.page);
      if (request.priority == QcfFontPriority.visible &&
          request.bytes != null) {
        _registerRequest(request);
      }
    }
  }

  int get _pendingByteCount => _requests.values.fold(
    0,
    (total, request) => total + (request.bytes?.length ?? 0),
  );

  bool get _canReadSpeculative =>
      _speculativeWorkEnabled &&
      _requests.values
              .where(
                (request) =>
                    request.priority != QcfFontPriority.visible &&
                    (request.bytes != null || request.reading),
              )
              .length <
          maxPendingFonts &&
      _pendingByteCount < maxPendingBytes;

  void _pumpReads() {
    if (_disposed) return;
    while (_activeReads < maxConcurrentReads) {
      _FontRequest? next;
      for (final request in _requests.values) {
        if (request.reading || request.registering || request.bytes != null) {
          continue;
        }
        if (request.priority != QcfFontPriority.visible &&
            !_canReadSpeculative) {
          continue;
        }
        if (next == null || request.priority.index < next.priority.index) {
          next = request;
        }
      }
      if (next == null) break;
      unawaited(_readRequest(next));
    }
  }

  Future<void> _readRequest(_FontRequest request) async {
    request.reading = true;
    _activeReads++;
    final timing = TimelineTask()
      ..start(
        'Quran font read',
        arguments: {'pack': packType.name, 'page': request.page},
      );
    try {
      final Uint8List bytes;
      try {
        bytes = await _readFont(File(request.path));
      } finally {
        timing.finish();
      }
      if (request.cancelled || _disposed) return;
      if (request.priority != QcfFontPriority.visible &&
          _pendingByteCount + bytes.length > maxPendingBytes) {
        _cancelRequest(request);
        return;
      }
      request.bytes = bytes;
      if (request.priority == QcfFontPriority.visible) {
        _registerRequest(request);
      }
    } catch (error, stack) {
      _completeRequest(request, error: error, stack: stack);
    } finally {
      request.reading = false;
      _activeReads--;
      _pumpReads();
      _flushSpeculativeFonts();
    }
  }

  void _flushSpeculativeFonts() {
    if (_disposed ||
        !_speculativeRegistrationAllowed ||
        _readerScrolling ||
        !_speculativeWorkEnabled) {
      return;
    }
    // Wait for the current buffer's reads so staggered disk completions do not
    // produce one full text relayout per completion. Flush earlier at the cap.
    if (_requests.values.any(
      (request) =>
          request.priority != QcfFontPriority.visible && request.reading,
    )) {
      return;
    }
    if (_canReadSpeculative &&
        _requests.values.any(
          (request) =>
              request.priority != QcfFontPriority.visible &&
              !request.registering &&
              request.bytes == null,
        )) {
      return;
    }
    final pending = _requests.values
        .where((request) => request.bytes != null)
        .toList();
    if (pending.isEmpty) return;
    Timeline.timeSync(
      'Quran speculative font batch',
      () {
        // No await here: native registration and fontsChange notifications for
        // this batch occur within the same event-loop turn.
        for (final request in pending) {
          _registerRequest(request);
        }
      },
      arguments: {'pack': packType.name, 'count': pending.length},
    );
    _pumpReads();
  }

  void _registerRequest(_FontRequest request) {
    final bytes = request.bytes;
    if (bytes == null ||
        request.registering ||
        request.cancelled ||
        _disposed) {
      return;
    }
    request.bytes = null;
    request.registering = true;
    try {
      final registration = Timeline.timeSync(
        'Quran font register',
        () => _registerFont(bytes, _familyNameForPage(request.page)),
        arguments: {
          'pack': packType.name,
          'page': request.page,
          'bytes': bytes.length,
        },
      );
      registration.then(
        (_) {
          if (!_disposed) {
            _loadedPages.add(request.page);
            _pageFontLoadedController.add(request.page);
          }
          _completeRequest(request);
        },
        onError: (Object error, StackTrace stack) {
          _completeRequest(request, error: error, stack: stack);
        },
      );
    } catch (error, stack) {
      _completeRequest(request, error: error, stack: stack);
    }
  }

  void _completeRequest(
    _FontRequest request, {
    Object? error,
    StackTrace? stack,
  }) {
    if (_requests[request.page] != request) return;
    _requests.remove(request.page);
    _loadingPages.remove(request.page);
    request.bytes = null;
    if (error == null) {
      request.completer.complete();
    } else {
      request.completer.completeError(error, stack);
    }
  }

  void _cancelRequest(_FontRequest request) {
    request.cancelled = true;
    _completeRequest(request, error: const QcfFontRequestCancelled());
  }

  @override
  void didHaveMemoryPressure() {
    _speculativeWorkEnabled = false;
    _idleTimer?.cancel();
    _idleTimer = null;
    _speculativeRegistrationAllowed = false;
    for (final request in _requests.values.toList()) {
      if (request.priority != QcfFontPriority.visible && !request.registering) {
        _cancelRequest(request);
      }
    }
  }

  void clearPreloadWindow() {
    _windowGeneration++;
    _visiblePages = {};
    _preparedPages = {};
    _bufferedPages = {};
    _readerScrolling = false;
    _updateRequestPriorities();
    didHaveMemoryPressure();
  }

  Future<void> _buildPageFileIndex(Directory fontsDir) async {
    final index = <int, String>{};
    await for (final file in fontsDir.list()) {
      if (file is! File || !file.path.toLowerCase().endsWith('.ttf')) continue;
      final familyName = _familyNameFromFile(file);
      if (familyName == null) continue;
      final pageNum = int.tryParse(familyName.substring(5));
      if (pageNum == null || pageNum < 1 || pageNum > totalFonts) continue;
      index[pageNum] = file.path;
    }
    _pageFileIndex
      ..clear()
      ..addAll(index);
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
        final match = RegExp(
          r'^p(\d+)\.ttf$',
          caseSensitive: false,
        ).firstMatch(name);
        if (match == null) return null;
        final num = int.tryParse(match.group(1)!);
        if (num == null) return null;
        return 'QCF_T${num.toString().padLeft(3, '0')}';
    }
  }

  void _emit(QcfFontDownloadState state) {
    if (_disposed) return;
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    for (final request in _requests.values.toList()) {
      _cancelRequest(request);
    }
    _stateController.close();
    _pageFontLoadedController.close();
  }
}

class _FontRequest {
  final int page;
  final String path;
  final completer = Completer<void>();
  QcfFontPriority priority;
  Uint8List? bytes;
  bool reading = false;
  bool registering = false;
  bool cancelled = false;

  _FontRequest(this.page, this.path, this.priority);
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
