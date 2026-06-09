import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

class AudiobookProgress {
  final int audiobookId;
  final int trackIndex;
  final Duration position;
  final DateTime updatedAt;
  final String? title;
  final String? author;
  final int? trackCount;

  AudiobookProgress({
    required this.audiobookId,
    required this.trackIndex,
    required this.position,
    required this.updatedAt,
    this.title,
    this.author,
    this.trackCount,
  });

  factory AudiobookProgress.fromJson(Map<String, dynamic> json) {
    return AudiobookProgress(
      audiobookId: json['audiobookId'],
      trackIndex: json['trackIndex'] ?? 0,
      position: Duration(milliseconds: json['positionMs'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      title: json['title'],
      author: json['author'],
      trackCount: json['trackCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audiobookId': audiobookId,
      'trackIndex': trackIndex,
      'positionMs': position.inMilliseconds,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'title': title,
      'author': author,
      'trackCount': trackCount,
    };
  }
}

class AudioProgressService {
  static const String _progressKey = 'audiobook_progress';
  static const String _lastPlayedIdKey = 'audiobook_last_played_id';

  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  Map<String, dynamic> _readAll() {
    try {
      final data = _cacheHelper.getDataString(key: _progressKey);
      if (data == null) return {};
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  Future<void> savePosition(
    int audiobookId,
    int trackIndex,
    Duration position, {
    String? title,
    String? author,
    int? trackCount,
  }) async {
    final all = _readAll();
    final existing = all[audiobookId.toString()];
    final progress = AudiobookProgress(
      audiobookId: audiobookId,
      trackIndex: trackIndex,
      position: position,
      updatedAt: DateTime.now(),
      title: title ?? (existing != null ? existing['title'] : null),
      author: author ?? (existing != null ? existing['author'] : null),
      trackCount: trackCount ?? (existing != null ? existing['trackCount'] : null),
    );
    all[audiobookId.toString()] = progress.toJson();
    await _cacheHelper.saveData(key: _progressKey, value: jsonEncode(all));
    await _cacheHelper.saveData(key: _lastPlayedIdKey, value: audiobookId);
  }

  AudiobookProgress? getProgress(int audiobookId) {
    final all = _readAll();
    final data = all[audiobookId.toString()];
    if (data == null) return null;
    try {
      return AudiobookProgress.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  AudiobookProgress? getLastPlayed() {
    final id = _cacheHelper.getData(key: _lastPlayedIdKey) as int?;
    if (id == null) return null;
    return getProgress(id);
  }

  bool hasProgress(int audiobookId) => getProgress(audiobookId) != null;

  Future<void> clear(int audiobookId) async {
    final all = _readAll();
    all.remove(audiobookId.toString());
    await _cacheHelper.saveData(key: _progressKey, value: jsonEncode(all));
    final lastId = _cacheHelper.getData(key: _lastPlayedIdKey) as int?;
    if (lastId == audiobookId) {
      await _cacheHelper.removeData(key: _lastPlayedIdKey);
    }
  }
}
