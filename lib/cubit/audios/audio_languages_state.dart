part of 'audio_languages_cubit.dart';

sealed class AudioLanguagesState extends Equatable {
  const AudioLanguagesState();

  @override
  List<Object> get props => [];
}

final class AudioLanguagesInitial extends AudioLanguagesState {}

final class AudioLanguagesLoading extends AudioLanguagesState {}

final class AudioLanguagesLoaded extends AudioLanguagesState {
  final List<AudioLanguageModel> languages;

  const AudioLanguagesLoaded(this.languages);
}

final class AudioLanguagesError extends AudioLanguagesState {
  final String message;

  const AudioLanguagesError(this.message);
}

final class AudioLanguagesOffline extends AudioLanguagesState {}
