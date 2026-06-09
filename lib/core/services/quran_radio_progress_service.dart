import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

class RadioStationProgress {
  final dynamic stationId;
  final String stationName;
  final String stationUrl;
  final DateTime updatedAt;

  RadioStationProgress({
    required this.stationId,
    required this.stationName,
    required this.stationUrl,
    required this.updatedAt,
  });

  factory RadioStationProgress.fromJson(Map<String, dynamic> json) {
    return RadioStationProgress(
      stationId: json['stationId'],
      stationName: json['stationName'] ?? '',
      stationUrl: json['stationUrl'] ?? '',
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'stationUrl': stationUrl,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class QuranRadioProgressService {
  static const String _progressKey = 'quran_radio_station';

  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  Future<void> saveStation({
    required dynamic stationId,
    required String stationName,
    required String stationUrl,
  }) async {
    final progress = RadioStationProgress(
      stationId: stationId,
      stationName: stationName,
      stationUrl: stationUrl,
      updatedAt: DateTime.now(),
    );
    await _cacheHelper.saveData(
        key: _progressKey, value: jsonEncode(progress.toJson()));
  }

  RadioStationProgress? getLastStation() {
    try {
      final data = _cacheHelper.getDataString(key: _progressKey);
      if (data == null) return null;
      return RadioStationProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(data)));
    } catch (e) {
      return null;
    }
  }

  bool hasLastStation() => getLastStation() != null;

  Future<void> clear() async {
    await _cacheHelper.removeData(key: _progressKey);
  }
}
