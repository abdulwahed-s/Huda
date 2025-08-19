part of 'checklist_cubit.dart';

sealed class ChecklistState extends Equatable {
  const ChecklistState();

  @override
  List<Object> get props => [];
}

final class ChecklistInitial extends ChecklistState {}

final class ChecklistLoading extends ChecklistState {}

final class ChecklistLoaded extends ChecklistState {
  final DailyChecklist dailyChecklist;
  final int streakCount;
  final DateTime currentDate;

  const ChecklistLoaded({
    required this.dailyChecklist,
    required this.streakCount,
    required this.currentDate,
  });

  ChecklistLoaded copyWith({
    DailyChecklist? dailyChecklist,
    int? streakCount,
    DateTime? currentDate,
  }) {
    return ChecklistLoaded(
      dailyChecklist: dailyChecklist ?? this.dailyChecklist,
      streakCount: streakCount ?? this.streakCount,
      currentDate: currentDate ?? this.currentDate,
    );
  }

  @override
  List<Object> get props => [dailyChecklist, streakCount, currentDate];
}

final class ChecklistError extends ChecklistState {
  final String message;

  const ChecklistError(this.message);

  @override
  List<Object> get props => [message];
}
