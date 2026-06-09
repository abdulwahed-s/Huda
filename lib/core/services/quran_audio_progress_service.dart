import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/reciter_model.dart';

class QuranAudioProgress {
  final dynamic reciterId;
  final String reciterName;
  final dynamic reciterLetter;
  final dynamic moshafId;
  final String moshafName;
  final String moshafServer;
  final dynamic moshafSurahTotal;
  final dynamic moshafType;
  final dynamic moshafSurahList;
  final int surahIndex;
  final int positionMs;
  final String jsonData;
  final DateTime updatedAt;

  QuranAudioProgress({
    required this.reciterId,
    required this.reciterName,
    required this.reciterLetter,
    required this.moshafId,
    required this.moshafName,
    required this.moshafServer,
    required this.moshafSurahTotal,
    required this.moshafType,
    required this.moshafSurahList,
    required this.surahIndex,
    this.positionMs = 0,
    required this.jsonData,
    required this.updatedAt,
  });

  factory QuranAudioProgress.fromJson(Map<String, dynamic> json) {
    return QuranAudioProgress(
      reciterId: json['reciterId'],
      reciterName: json['reciterName'] ?? '',
      reciterLetter: json['reciterLetter'],
      moshafId: json['moshafId'],
      moshafName: json['moshafName'] ?? '',
      moshafServer: json['moshafServer'] ?? '',
      moshafSurahTotal: json['moshafSurahTotal'],
      moshafType: json['moshafType'],
      moshafSurahList: json['moshafSurahList'],
      surahIndex: json['surahIndex'] ?? 0,
      positionMs: json['positionMs'] ?? 0,
      jsonData: json['jsonData'] ?? '[]',
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterLetter': reciterLetter,
      'moshafId': moshafId,
      'moshafName': moshafName,
      'moshafServer': moshafServer,
      'moshafSurahTotal': moshafSurahTotal,
      'moshafType': moshafType,
      'moshafSurahList': moshafSurahList,
      'surahIndex': surahIndex,
      'positionMs': positionMs,
      'jsonData': jsonData,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class QuranAudioProgressService {
  static const String _progressKey = 'quran_audio_progress';

  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  Future<void> savePosition({
    required Reciter reciter,
    required Moshaf moshaf,
    required List jsonData,
    required int surahIndex,
    int positionMs = 0,
  }) async {
    final progress = QuranAudioProgress(
      reciterId: reciter.id,
      reciterName: reciter.name?.toString() ?? '',
      reciterLetter: reciter.letter,
      moshafId: moshaf.id,
      moshafName: moshaf.name?.toString() ?? '',
      moshafServer: moshaf.server?.toString() ?? '',
      moshafSurahTotal: moshaf.surahTotal,
      moshafType: moshaf.moshafType,
      moshafSurahList: moshaf.surahList,
      surahIndex: surahIndex,
      positionMs: positionMs,
      jsonData: jsonEncode(jsonData),
      updatedAt: DateTime.now(),
    );
    await _cacheHelper.saveData(
        key: _progressKey, value: jsonEncode(progress.toJson()));
  }

  QuranAudioProgress? getLastPlayed() {
    try {
      final data = _cacheHelper.getDataString(key: _progressKey);
      if (data == null) return null;
      return QuranAudioProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(data)));
    } catch (e) {
      return null;
    }
  }

  bool hasLastPlayed() => getLastPlayed() != null;

  Future<void> clear() async {
    await _cacheHelper.removeData(key: _progressKey);
  }
}
