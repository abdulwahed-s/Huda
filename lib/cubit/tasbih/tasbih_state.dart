part of 'tasbih_cubit.dart';

@immutable
sealed class TasbihState {}

final class TasbihInitial extends TasbihState {}

final class TasbihLoading extends TasbihState {}

final class TasbihLoaded extends TasbihState {
  final List<TasbihNote> notes;
  final int selectedNoteIndex;
  final bool mode;

  TasbihLoaded({
    required this.notes,
    required this.selectedNoteIndex,
    required this.mode,
  });

  int get currentCount {
    if (notes.isEmpty) return 0;
    final index = selectedNoteIndex.clamp(0, notes.length - 1);
    return notes[index].count;
  }
}

final class TasbihError extends TasbihState {
  final String message;

  TasbihError(this.message);
}
