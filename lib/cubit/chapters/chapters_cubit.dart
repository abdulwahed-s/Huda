import 'package:bloc/bloc.dart';
import 'package:huda/data/api/chapter_services.dart';
import 'package:huda/data/models/book_chapters_model.dart';
import 'package:huda/data/repository/chapter_repository.dart';
import 'package:meta/meta.dart';

part 'chapters_state.dart';

class ChaptersCubit extends Cubit<ChaptersState> {
  ChaptersCubit() : super(ChaptersInitial());

  ChapterRepository chapterRepository =
      ChapterRepository(chapterServices: ChapterServices());

  void fetchChaptersByBook(String bookName) async {
    emit(ChaptersLoading());
    try {
      final bookChapters = await chapterRepository.getChaptersByBook(bookName);
      emit(ChaptersLoaded(bookChapters));
    } catch (e) {
      emit(ChaptersError(e.toString()));
    }
  }
}
