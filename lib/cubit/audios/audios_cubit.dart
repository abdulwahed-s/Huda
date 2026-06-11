import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/audios_services.dart';
import 'package:huda/data/models/audios_response.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/data/repository/audios_repository.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';

part 'audios_state.dart';

class AudiosCubit extends Cubit<AudiosState> {
  AudiosCubit() : super(AudiosInitial());

  AudiosRepository audiosRepository =
      AudiosRepository(audiosServices: AudiosServices());
  OfflineAudiobooksService offlineAudiobooksService =
      OfflineAudiobooksService();

  Future<void> fetchAudios(String lang, int pageNumber, String respLang) async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(AudiosLoading());
      try {
        final AudiosResponse audiosResponse =
            await audiosRepository.getAllAudios(lang, pageNumber, respLang);
        emit(AudiosLoaded(audiosResponse));
      } catch (e) {
        emit(AudiosError(e.toString()));
      }
    } else {
      await fetchOfflineAudios(lang);
    }
  }

  Future<void> fetchOfflineAudios(String lang) async {
    emit(AudiosOfflineLoading());
    try {
      List<OfflineAudiobookModel> offlineAudios;

      if (lang == 'showall') {
        offlineAudios = await offlineAudiobooksService.getAllAudiobooks();
      } else {
        offlineAudios =
            await offlineAudiobooksService.getAudiobooksByLanguage(lang);
      }

      if (offlineAudios.isEmpty) {
        emit(AudiosOfflineEmpty());
      } else {
        emit(AudiosOfflineLoaded(offlineAudios));
      }
    } catch (e) {
      emit(AudiosOffline());
    }
  }
}
