import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/quran_content_store.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ReciterCatalog {
  const ReciterCatalog({
    required this.reciters,
    required this.riwayat,
    required this.suwar,
  });

  final List<Reciter> reciters;
  final List<Moshaf> riwayat;

  final List suwar;
}

class ReciterCatalogSource {
  const ReciterCatalogSource();

  Future<bool> isOnline() => NetworkInfo.checkInternetConnectivity();

  Future<String> downloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/huda_audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return audioDir.path;
  }

  Future<ReciterCatalog?> load(String lang, {required bool online}) async {
    final prefs = await SharedPreferences.getInstance();
    final contentStore = getIt<QuranContentStore>();
    var recitersJson = await contentStore.readReciterCatalog(lang);
    if (recitersJson == null) {
      if (!online) return null;
      await _fetchAndStore(lang, prefs);
      recitersJson = await contentStore.readReciterCatalog(lang);
    }
    if (recitersJson == null) return null;

    final moshafJson = prefs.getString('huda_moshaf_$lang');
    final suwarJson = prefs.getString('huda_suwar_$lang');
    final data = json.decode(recitersJson) as List<dynamic>;
    final data2 = json.decode(moshafJson!)['riwayat'] as List<dynamic>;
    final data3 = json.decode(suwarJson!) as List<dynamic>;

    final reciters = data.map((r) => Reciter.fromJson(r)).toList()
      ..sort((a, b) => a.letter.toString().compareTo(b.letter.toString()));
    return ReciterCatalog(
      reciters: reciters,
      riwayat: data2.map((r) => Moshaf.fromJson(r)).toList(),
      suwar: data3,
    );
  }

  Future<void> _fetchAndStore(String lang, SharedPreferences prefs) async {
    try {
      final responses = await Future.wait([
        Dio().get('http://mp3quran.net/api/v3/reciters?language=$lang'),
        Dio().get('http://mp3quran.net/api/v3/moshaf?language=$lang'),
        Dio().get('http://mp3quran.net/api/v3/suwar?language=$lang'),
      ]);

      if (responses[0].data != null) {
        await getIt<QuranContentStore>().saveReciterCatalog(
          lang,
          json.encode(responses[0].data['reciters']),
        );
      }
      if (responses[1].data != null) {
        prefs.setString('huda_moshaf_$lang', json.encode(responses[1].data));
      }
      if (responses[2].data != null) {
        prefs.setString(
          'huda_suwar_$lang',
          json.encode(responses[2].data['suwar']),
        );
      }
    } catch (e) {
      debugPrint('Error storing reciters data: $e');
    }
  }
}
