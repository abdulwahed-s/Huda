part of 'audios_cubit.dart';

sealed class AudiosState extends Equatable {
  const AudiosState();

  @override
  List<Object> get props => [];
}

final class AudiosInitial extends AudiosState {}

final class AudiosLoading extends AudiosState {}

final class AudiosLoaded extends AudiosState {
  final AudiosResponse audiosResponse;

  const AudiosLoaded(this.audiosResponse);
}

final class AudiosError extends AudiosState {
  final String message;

  const AudiosError(this.message);
}

final class AudiosOffline extends AudiosState {}

final class AudiosOfflineLoading extends AudiosState {}

final class AudiosOfflineLoaded extends AudiosState {
  final List<OfflineAudiobookModel> offlineAudios;

  const AudiosOfflineLoaded(this.offlineAudios);

  @override
  List<Object> get props => [offlineAudios];
}

final class AudiosOfflineEmpty extends AudiosState {}
