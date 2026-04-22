part of 'quran_radio_cubit.dart';

@immutable
sealed class QuranRadioState {}

final class QuranRadioInitial extends QuranRadioState {}

class QuranRadioLoading extends QuranRadioState {}

class QuranRadioLoaded extends QuranRadioState {
  final List<RadioStation> radios;
  final RadioStation? currentlyPlaying;

  QuranRadioLoaded({
    required this.radios,
    this.currentlyPlaying,
  });

  QuranRadioLoaded copyWith({
    List<RadioStation>? radios,
    RadioStation? currentlyPlaying,
    bool clearPlaying = false,
  }) {
    return QuranRadioLoaded(
      radios: radios ?? this.radios,
      currentlyPlaying:
          clearPlaying ? null : (currentlyPlaying ?? this.currentlyPlaying),
    );
  }
}

class QuranRadioError extends QuranRadioState {
  final String message;
  QuranRadioError(this.message);
}
