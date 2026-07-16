import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/audio_detail_services.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/data/repository/audio_detail_repository.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';

part 'audio_detail_state.dart';

class AudioDetailCubit extends Cubit<AudioDetailState> {
  AudioDetailCubit() : super(AudioDetailInitial());

  AudioDetailRepository audioDetailRepository =
      AudioDetailRepository(audioDetailServices: AudioDetailServices());
  OfflineAudiobooksService offlineAudiobooksService =
      OfflineAudiobooksService();

  Future<void> fetchAudioDetail(int audioId, String language) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(AudioDetailLoading());
      try {
        final audioDetail =
            await audioDetailRepository.getAudioDetail(language, audioId);
        emit(AudioDetailLoaded(audioDetail));
      } catch (e) {
        emit(AudioDetailError(e.toString()));
      }
    } else {
      await fetchOfflineAudioDetail(audioId);
    }
  }

  Future<void> fetchOfflineAudioDetail(int audioId) async {
    emit(AudioDetailLoading());
    try {
      final offlineAudio = await offlineAudiobooksService.getAudiobook(audioId);
      if (offlineAudio != null) {
        emit(AudioDetailOfflineLoaded(offlineAudio));
      } else {
        emit(AudioDetailOffline());
      }
    } catch (e) {
      emit(AudioDetailOffline());
    }
  }
}
