import 'package:just_audio/just_audio.dart';
import 'package:huda/data/models/reciter_model.dart';

abstract class QuranPlayerState {}

class QuranPlayerInitial extends QuranPlayerState {}

class QuranPlayerLoading extends QuranPlayerState {
  final int? reciterId;
  final int? moshafId;
  final int? initialIndex;
  QuranPlayerLoading({this.reciterId, this.moshafId, this.initialIndex});
}

class QuranPlayerPlaying extends QuranPlayerState {
  final Moshaf moshaf;
  final Reciter reciter;
  final int suraNumber;
  final List jsonData;
  final AudioPlayer audioPlayer;
  final List<String> surahNumbers;
  final List<AudioSource> playList;

  QuranPlayerPlaying({
    required this.moshaf,
    required this.reciter,
    required this.suraNumber,
    required this.jsonData,
    required this.audioPlayer,
    required this.surahNumbers,
    required this.playList,
  });
}

class QuranPlayerPaused extends QuranPlayerState {}

class QuranPlayerError extends QuranPlayerState {
  final String message;
  QuranPlayerError(this.message);
}

class QuranPlayerDownloading extends QuranPlayerState {
  final String surahName;
  QuranPlayerDownloading(this.surahName);
}

class QuranPlayerDownloadComplete extends QuranPlayerState {
  final String surahName;
  QuranPlayerDownloadComplete(this.surahName);
}
