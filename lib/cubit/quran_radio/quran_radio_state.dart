part of 'quran_radio_cubit.dart';

@immutable
sealed class QuranRadioState {}

final class QuranRadioInitial extends QuranRadioState {}

class QuranRadioLoading extends QuranRadioState {}

class QuranRadioLoaded extends QuranRadioState {
  final List<RadioStation> radios;
  final RadioStation? currentlyPlaying;
  final bool isPlaying;
  final bool isBuffering;

  QuranRadioLoaded({
    required this.radios,
    this.currentlyPlaying,
    this.isPlaying = false,
    this.isBuffering = false,
  });

  QuranRadioLoaded copyWith({
    List<RadioStation>? radios,
    RadioStation? currentlyPlaying,
    bool clearPlaying = false,
    bool? isPlaying,
    bool? isBuffering,
  }) {
    return QuranRadioLoaded(
      radios: radios ?? this.radios,
      currentlyPlaying:
          clearPlaying ? null : (currentlyPlaying ?? this.currentlyPlaying),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}

class QuranRadioError extends QuranRadioState {
  final String message;
  QuranRadioError(this.message);
}
