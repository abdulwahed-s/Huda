import 'package:bloc/bloc.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:huda/data/api/hadith_services.dart';
import 'package:huda/data/models/hadith_books_model.dart';
import 'package:huda/data/repository/hadith_repository.dart';
import 'package:meta/meta.dart';

part 'hadith_state.dart';

class HadithCubit extends Cubit<HadithState> {
  HadithCubit() : super(HadithInitial());

  HadithRepository hadithRepository =
      HadithRepository(hadithServices: HadithServices());

  Future<void> fetchHadithBooks() async {
    if (await NetworkInfo.checkInternetConnectivity()) {
      emit(HadithLoading());
      try {
        final hadithBooks = await hadithRepository.getAllBooks();
        emit(HadithLoaded(hadithBooks: hadithBooks));
      } catch (e) {
        emit(HadithError(message: e.toString()));
      }
    } else {
      emit(HadithOffline());
    }
  }
}
