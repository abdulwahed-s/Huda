import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/all_audios_languages_services.dart';
import 'package:huda/data/models/audio_languages_model.dart';
import 'package:huda/data/repository/all_audio_languages_repository.dart';

part 'audio_languages_state.dart';

class AudioLanguagesCubit extends Cubit<AudioLanguagesState> {
  AudioLanguagesCubit() : super(AudioLanguagesInitial());

  AllAudioLanguagesRepository allAudioLanguagesRepository =
      AllAudioLanguagesRepository(
          allAudiosLanguagesServices: AllAudiosLanguagesServices());

  Future<void> fetchLanguages(String lang) async {
    emit(AudioLanguagesLoading());
    if (await NetworkInfo.checkInternetConnectivity()) {
      try {
        final languages =
            await allAudioLanguagesRepository.getAllAudioLanguages(lang);
        emit(AudioLanguagesLoaded(languages));
      } catch (e) {
        emit(AudioLanguagesError(e.toString()));
      }
    } else {
      emit(AudioLanguagesOffline());
    }
  }
}
