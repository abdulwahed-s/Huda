part of 'audio_detail_cubit.dart';

sealed class AudioDetailState extends Equatable {
  const AudioDetailState();

  @override
  List<Object> get props => [];
}

final class AudioDetailInitial extends AudioDetailState {}

final class AudioDetailLoading extends AudioDetailState {}

final class AudioDetailLoaded extends AudioDetailState {
  final AudioDetailModel audioDetail;

  const AudioDetailLoaded(this.audioDetail);
}

final class AudioDetailOfflineLoaded extends AudioDetailState {
  final OfflineAudiobookModel offlineAudio;

  const AudioDetailOfflineLoaded(this.offlineAudio);

  @override
  List<Object> get props => [offlineAudio];
}

final class AudioDetailError extends AudioDetailState {
  final String error;

  const AudioDetailError(this.error);
}

final class AudioDetailOffline extends AudioDetailState {}
