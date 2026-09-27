import 'package:huda/data/models/surah_audio_model.dart' as audio;
import 'package:huda/data/models/surah_model.dart';

class QuranAudioCatalog {
  static const bitrates = <String, int>{
    'ar.abdulbasitmurattal': 64,
    'ar.abdulbasitmurattal-2': 64,
    'ar.abdullahbasfar': 64,
    'ar.abdullahbasfar-2': 64,
    'ar.abdulsamad': 64,
    'ar.abdurrahmaansudais': 64,
    'ar.abdurrahmaansudais-2': 64,
    'ar.ahmedajamy': 128,
    'ar.alafasy': 128,
    'ar.alafasy-2': 128,
    'ar.aymanswoaid': 64,
    'ar.aymanswoaid-2': 64,
    'ar.hanirifai': 64,
    'ar.hanirifai-2': 64,
    'ar.hudhaify': 128,
    'ar.hudhaify-2': 128,
    'ar.husary': 64,
    'ar.husary-2': 64,
    'ar.husarymujawwad': 128,
    'ar.husarymujawwad-2': 128,
    'ar.ibrahimakhbar': 32,
    'ar.mahermuaiqly': 128,
    'ar.mahermuaiqly-2': 128,
    'ar.minshawimujawwad': 64,
    'ar.minshawimujawwad-2': 64,
    'ar.muhammadayyoub': 128,
    'ar.muhammadayyoub-2': 128,
    'ar.muhammadjibreel': 128,
    'ar.muhammadjibreel-2': 128,
    'ar.parhizgar': 48,
    'ar.saoodshuraym': 64,
    'ar.saoodshuraym-2': 64,
    'ar.shaatree': 128,
    'ar.shaatree-2': 128,
    'en.walk': 192,
    'fa.hedayatfarfooladvand': 40,
    'fr.leclerc': 128,
    'ru.kuliev-audio': 128,
    'ru.kuliev-audio-2': 320,
    'ur.khan': 64,
    'zh.chinese': 128,
  };

  static String? ayahUrl(String identifier, int? globalAyahNumber) {
    final bitrate = bitrates[identifier];
    if (bitrate == null ||
        globalAyahNumber == null ||
        globalAyahNumber < 1 ||
        globalAyahNumber > 6236) {
      return null;
    }
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$identifier/$globalAyahNumber.mp3';
  }

  static audio.SurahAudioModel? forSurah(String identifier, SurahModel surah) {
    if (!bitrates.containsKey(identifier) ||
        surah.ayahs == null ||
        surah.ayahs!.isEmpty ||
        surah.ayahs!.any((ayah) => ayahUrl(identifier, ayah.number) == null)) {
      return null;
    }
    return audio.SurahAudioModel(
      code: 200,
      status: 'OK',
      data: audio.Data(
        edition: audio.Edition(identifier: identifier, format: 'audio'),
        surahs: [
          audio.Surahs(
            number: surah.number,
            name: surah.name,
            englishName: surah.englishName,
            ayahs: surah.ayahs!
                .map(
                  (ayah) => audio.Ayahs(
                    number: ayah.number,
                    numberInSurah: ayah.numberInSurah,
                    audio: ayahUrl(identifier, ayah.number),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
