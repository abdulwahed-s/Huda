part of 'tasbih_cubit.dart';

@immutable
sealed class TasbihState {}

final class TasbihInitial extends TasbihState {}

final class TasbihLoading extends TasbihState {}

final class TasbihLoaded extends TasbihState {
  final int count;
  final bool mode;
  final String? note;

  TasbihLoaded(this.count, this.mode, this.note);
}

final class TasbihError extends TasbihState {
  final String message;

  TasbihError(this.message);
}
