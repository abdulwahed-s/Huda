import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

class ReadingPositionService {
  static const String _lastReadSurahKey = 'last_read_surah';
  static const String _lastReadAyahKey = 'last_read_ayah';
  static const String _lastReadPositionKey = 'last_read_position';
  static const String _lastReadTimestampKey = 'last_read_timestamp';

  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  Future<void> saveReadingPosition({
    required int surahNumber,
    required int ayahNumber,
    double position = 0.0,
  }) async {
    await _cacheHelper.saveData(key: _lastReadSurahKey, value: surahNumber);
    await _cacheHelper.saveData(key: _lastReadAyahKey, value: ayahNumber);
    await _cacheHelper.saveData(key: _lastReadPositionKey, value: position);
    await _cacheHelper.saveData(
      key: _lastReadTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch,
    );
  }

  int? getLastReadSurah() {
    return _cacheHelper.getData(key: _lastReadSurahKey) as int?;
  }

  int? getLastReadAyah() {
    return _cacheHelper.getData(key: _lastReadAyahKey) as int?;
  }

  double? getLastReadPosition() {
    return _cacheHelper.getData(key: _lastReadPositionKey) as double?;
  }

  DateTime? getLastReadTimestamp() {
    final timestamp = _cacheHelper.getData(key: _lastReadTimestampKey) as int?;
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  bool hasLastReadPosition() {
    return getLastReadSurah() != null;
  }

  Map<String, dynamic>? getLastReadSummary() {
    final surahNumber = getLastReadSurah();
    final ayahNumber = getLastReadAyah();
    final position = getLastReadPosition();
    final timestamp = getLastReadTimestamp();

    if (surahNumber == null) return null;

    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber ?? 1,
      'position': position ?? 0.0,
      'timestamp': timestamp,
    };
  }

  Future<void> clearLastReadPosition() async {
    await _cacheHelper.removeData(key: _lastReadSurahKey);
    await _cacheHelper.removeData(key: _lastReadAyahKey);
    await _cacheHelper.removeData(key: _lastReadPositionKey);
    await _cacheHelper.removeData(key: _lastReadTimestampKey);
  }

  Future<void> updateCurrentPosition({
    required int ayahNumber,
    double position = 0.0,
  }) async {
    final currentSurah = getLastReadSurah();
    if (currentSurah != null) {
      await _cacheHelper.saveData(key: _lastReadAyahKey, value: ayahNumber);
      await _cacheHelper.saveData(key: _lastReadPositionKey, value: position);
      await _cacheHelper.saveData(
        key: _lastReadTimestampKey,
        value: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<void> updatePositionForSurah({
    required int surahNumber,
    required int ayahNumber,
    double position = 0.0,
  }) async {
    await saveReadingPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      position: position,
    );
  }
}
