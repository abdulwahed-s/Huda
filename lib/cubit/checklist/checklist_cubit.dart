import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/l10n/app_localizations.dart';
import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';

part 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  final ChecklistRepository _repository;

  ChecklistCubit({ChecklistRepository? repository})
      : _repository = repository ?? ChecklistRepository(),
        super(ChecklistInitial());

  Future<void> loadChecklist([DateTime? date]) async {
    try {
      if (state is ChecklistInitial) {
        emit(ChecklistLoading());
      }

      final targetDate = date ?? DateTime.now();
      final dailyChecklist = await _repository.getDailyChecklist(targetDate);
      final streakCount = await _repository.getStreakCount();

      emit(ChecklistLoaded(
        dailyChecklist: dailyChecklist,
        streakCount: streakCount,
        currentDate: targetDate,
      ));
    } catch (e) {
      emit(ChecklistError(e.toString()));
    }
  }

  Future<void> navigateToDate(DateTime date) async {
    try {
      final dailyChecklist = await _repository.getDailyChecklist(date);
      final streakCount = await _repository.getStreakCount();

      emit(ChecklistLoaded(
        dailyChecklist: dailyChecklist,
        streakCount: streakCount,
        currentDate: date,
      ));

      _preloadAdjacentDays(date);
    } catch (e) {
      emit(ChecklistError(e.toString()));
    }
  }

  void _preloadAdjacentDays(DateTime currentDate) {
    final previousDay = currentDate.subtract(const Duration(days: 1));
    final nextDay = currentDate.add(const Duration(days: 1));

    _repository.getDailyChecklist(previousDay).then((_) {}).catchError((_) {});
    _repository.getDailyChecklist(nextDay).then((_) {}).catchError((_) {});
  }

  Future<void> toggleItemCompletion(String itemId, bool completed) async {
    final currentState = state;
    if (currentState is! ChecklistLoaded) return;

    final today = DateTime.now();
    final currentDate = currentState.currentDate;
    final isToday = currentDate.year == today.year &&
        currentDate.month == today.month &&
        currentDate.day == today.day;

    if (!isToday) {
      emit(const ChecklistError('Can only modify checklist items for today'));

      Future.delayed(const Duration(seconds: 2), () {
        loadChecklist(currentState.currentDate);
      });
      return;
    }

    try {
      final updatedCompletions =
          Map<String, bool>.from(currentState.dailyChecklist.completedItems);
      updatedCompletions[itemId] = completed;

      final updatedDailyChecklist = currentState.dailyChecklist.copyWith(
        completedItems: updatedCompletions,
      );

      emit(ChecklistLoaded(
        dailyChecklist: updatedDailyChecklist,
        streakCount: currentState.streakCount,
        currentDate: currentState.currentDate,
      ));

      await _repository.updateItemCompletion(
        currentState.currentDate,
        itemId,
        completed,
      );

      final updatedStreakCount = await _repository.getStreakCount();
      emit(ChecklistLoaded(
        dailyChecklist: updatedDailyChecklist,
        streakCount: updatedStreakCount,
        currentDate: currentState.currentDate,
      ));
    } catch (e) {
      emit(currentState);
      emit(ChecklistError(e.toString()));
    }
  }

  Future<void> addCustomItem({
    required String title,
    required ChecklistItemType type,
    required RepetitionFrequency frequency,
  }) async {
    final currentState = state;
    if (currentState is! ChecklistLoaded) return;

    final today = DateTime.now();
    final currentDate = currentState.currentDate;
    final isToday = currentDate.year == today.year &&
        currentDate.month == today.month &&
        currentDate.day == today.day;

    if (!isToday) {
      emit(const ChecklistError('Can only add custom items for today'));

      Future.delayed(const Duration(seconds: 2), () {
        loadChecklist(currentState.currentDate);
      });
      return;
    }

    try {
      final item = ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        type: type,
        frequency: frequency,
        createdAt: DateTime.now(),
        isDefault: false,
      );

      await _repository.addChecklistItem(item);

      final updatedDailyChecklist =
          await _repository.getDailyChecklist(currentState.currentDate);
      final streakCount = await _repository.getStreakCount();

      emit(ChecklistLoaded(
        dailyChecklist: updatedDailyChecklist,
        streakCount: streakCount,
        currentDate: currentState.currentDate,
      ));
    } catch (e) {
      emit(ChecklistError(e.toString()));
    }
  }

  Future<void> removeCustomItem(String itemId) async {
    final currentState = state;
    if (currentState is! ChecklistLoaded) return;

    final today = DateTime.now();
    final currentDate = currentState.currentDate;
    final isToday = currentDate.year == today.year &&
        currentDate.month == today.month &&
        currentDate.day == today.day;

    if (!isToday) {
      emit(const ChecklistError('Can only remove custom items for today'));

      Future.delayed(const Duration(seconds: 2), () {
        loadChecklist(currentState.currentDate);
      });
      return;
    }

    try {
      await _repository.removeChecklistItem(itemId);

      final updatedDailyChecklist =
          await _repository.getDailyChecklist(currentState.currentDate);
      final streakCount = await _repository.getStreakCount();

      emit(ChecklistLoaded(
        dailyChecklist: updatedDailyChecklist,
        streakCount: streakCount,
        currentDate: currentState.currentDate,
      ));
    } catch (e) {
      emit(ChecklistError(e.toString()));
    }
  }

  void navigateToPreviousDay() {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final previousDay =
          currentState.currentDate.subtract(const Duration(days: 1));
      navigateToDate(previousDay);
    }
  }

  void navigateToNextDay() {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final nextDay = currentState.currentDate.add(const Duration(days: 1));
      navigateToDate(nextDay);
    }
  }

  void navigateToToday() {
    navigateToDate(DateTime.now());
  }

  Future<void> updateLocalizedTitles(AppLocalizations localizations) async {
    try {
      await _repository.updateDefaultItemTitles(localizations);

      final currentState = state;
      if (currentState is ChecklistLoaded) {
        await loadChecklist(currentState.currentDate);
      }
    } catch (e) {
      // 
    }
  }
}
