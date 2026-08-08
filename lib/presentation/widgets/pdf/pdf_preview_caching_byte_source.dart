import 'dart:async';
import 'dart:typed_data';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';

class PdfPreviewCachingByteSource implements PdfByteSource {
  PdfPreviewCachingByteSource(this._source);

  final PdfByteSource _source;
  final List<_CachedRange> _cachedRanges = [];
  Future<void> _operations = Future<void>.value();
  Future<int?>? _length;
  Future<void>? _closeFuture;
  bool _cacheNewReads = true;
  bool _closed = false;

  @override
  Future<int?> get length =>
      _length ??= _runExclusive(() async => _source.length);

  void finishPreview() {
    _cacheNewReads = false;
  }

  void clearPreviewCache() => _cachedRanges.clear();

  @override
  Future<Uint8List> readRange(int start, int endExclusive) {
    return _runExclusive(() => _readRange(start, endExclusive));
  }

  Future<Uint8List> _readRange(int start, int endExclusive) async {
    if (_closed) throw StateError('PDF byte source has been closed.');

    final safeStart = start < 0 ? 0 : start;
    final safeEnd = endExclusive < safeStart ? safeStart : endExclusive;
    if (safeStart == safeEnd) return Uint8List(0);

    final available = <_CachedRange>[
      for (final range in _cachedRanges)
        if (range.end > safeStart && range.start < safeEnd) range,
    ];

    for (final gap in _missingRanges(safeStart, safeEnd)) {
      final bytes = await _source.readRange(gap.start, gap.end);
      if (bytes.isEmpty) break;

      final boundedBytes = bytes.length <= gap.length
          ? bytes
          : Uint8List.sublistView(bytes, 0, gap.length);
      final fetched = _CachedRange(gap.start, boundedBytes);
      available.add(fetched);
      if (_cacheNewReads) _insertCachedRange(fetched);

      if (boundedBytes.length < gap.length) break;
    }

    return _assembleRange(available, safeStart, safeEnd);
  }

  List<_RequestedRange> _missingRanges(int start, int end) {
    final gaps = <_RequestedRange>[];
    var cursor = start;

    for (final cached in _cachedRanges) {
      if (cached.end <= cursor) continue;
      if (cached.start >= end) break;

      if (cached.start > cursor) {
        gaps.add(
            _RequestedRange(cursor, cached.start < end ? cached.start : end));
      }
      if (cached.end > cursor) {
        cursor = cached.end < end ? cached.end : end;
      }
      if (cursor == end) return gaps;
    }

    if (cursor < end) gaps.add(_RequestedRange(cursor, end));
    return gaps;
  }

  Uint8List _assembleRange(
    List<_CachedRange> available,
    int start,
    int end,
  ) {
    available.sort((left, right) => left.start.compareTo(right.start));
    final chunks = <Uint8List>[];
    var cursor = start;

    for (final range in available) {
      if (range.end <= cursor) continue;
      if (range.start > cursor || cursor >= end) break;

      final chunkEnd = range.end < end ? range.end : end;
      chunks.add(
        Uint8List.sublistView(
            range.bytes, cursor - range.start, chunkEnd - range.start),
      );
      cursor = chunkEnd;
    }

    final result = Uint8List(cursor - start);
    var offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  void _insertCachedRange(_CachedRange range) {
    var index = 0;
    while (index < _cachedRanges.length &&
        _cachedRanges[index].start < range.start) {
      index++;
    }
    _cachedRanges.insert(index, range);
  }

  Future<T> _runExclusive<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) return existing;
    _closed = true;
    return _closeFuture = _runExclusive(() async {
      _cachedRanges.clear();
      await _source.close();
    });
  }
}

class _RequestedRange {
  const _RequestedRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;
}

class _CachedRange {
  const _CachedRange(this.start, this.bytes);

  final int start;
  final Uint8List bytes;

  int get end => start + bytes.length;
}
