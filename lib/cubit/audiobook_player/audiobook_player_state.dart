import 'package:just_audio/just_audio.dart';
import 'package:huda/data/models/audio_detail_model.dart';

abstract class AudiobookPlayerState {}

class AudiobookPlayerInitial extends AudiobookPlayerState {}

class AudiobookPlayerLoading extends AudiobookPlayerState {
  final int audiobookId;
  final int initialTrackIndex;
  AudiobookPlayerLoading({
    required this.audiobookId,
    required this.initialTrackIndex,
  });
}

class AudiobookPlayerPlaying extends AudiobookPlayerState {
  final int audiobookId;
  final String title;
  final String author;
  final String? artUrl;
  final AudioPlayer audioPlayer;
  final List<AudioTrack> tracks;
  final List<AudioSource> playList;
  final bool isOffline;

  AudiobookPlayerPlaying({
    required this.audiobookId,
    required this.title,
    required this.author,
    required this.artUrl,
    required this.audioPlayer,
    required this.tracks,
    required this.playList,
    required this.isOffline,
  });
}

class AudiobookPlayerError extends AudiobookPlayerState {
  final String message;
  AudiobookPlayerError(this.message);
}
