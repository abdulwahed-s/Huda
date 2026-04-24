import 'package:flutter_bloc/flutter_bloc.dart';

enum PlayerBarVisibility { hidden, minimized, expanded }

class PlayerBarCubit extends Cubit<PlayerBarVisibility> {
  PlayerBarCubit() : super(PlayerBarVisibility.hidden);

  void show() => emit(PlayerBarVisibility.minimized);
  void hide() => emit(PlayerBarVisibility.hidden);
  void expand() => emit(PlayerBarVisibility.expanded);
  void minimize() => emit(PlayerBarVisibility.minimized);
}
