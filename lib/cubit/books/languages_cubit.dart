import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/all_books_languages_services.dart';
import 'package:huda/data/models/books_languages_model.dart';
import 'package:huda/data/repository/all_book_languages_repository.dart';

part 'languages_state.dart';

class LanguagesCubit extends Cubit<LanguagesState> {
  LanguagesCubit() : super(LanguagesInitial());

  AllBookLanguagesRepository allBookLanguagesRepository =
      AllBookLanguagesRepository(
          allBooksLanguagesServices: AllBooksLanguagesServices());

  Future<void> fetchLanguages(String lang) async {
    emit(LanguagesLoading());
    if (await NetworkInfo.checkInternetConnectivity()) {
      try {
        final languages =
            await allBookLanguagesRepository.getAllBookLanguages(lang);
        emit(LanguagesLoaded(languages));
      } catch (e) {
        emit(LanguagesError(e.toString()));
      }
    } else {
      emit(LanguagesOffline());
    }
  }
}
