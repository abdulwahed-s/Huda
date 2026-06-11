import 'package:flutter_bloc/flutter_bloc.dart';

enum AudiobookBarVisibility { hidden, visible }

class AudiobookBarCubit extends Cubit<AudiobookBarVisibility> {
  AudiobookBarCubit() : super(AudiobookBarVisibility.hidden);

  void show() => emit(AudiobookBarVisibility.visible);
  void hide() => emit(AudiobookBarVisibility.hidden);
}
