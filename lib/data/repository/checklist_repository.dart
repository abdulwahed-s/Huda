import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import '../models/checklist_item.dart';

class ChecklistRepository {
  static const String _checklistItemsKey = 'checklist_items';
  static const String _dailyChecklistsKey = 'daily_checklists';
  static const String _streakCountKey = 'streak_count';
  static const String _lastStreakDateKey = 'last_streak_date';

  static final Map<String, DailyChecklist> _dailyChecklistCache = {};

  void _clearCache() {
    _dailyChecklistCache.clear();
  }

  static List<ChecklistItem> getLocalizedDefaultItems(
          AppLocalizations localizations) =>
      [
        ChecklistItem(
          id: 'fajr',
          title: localizations.fajrPrayer,
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'dhuhr',
          title: localizations.dhuhrPrayer,
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'asr',
          title: localizations.asrPrayer,
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'maghrib',
          title: localizations.maghribPrayer,
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'isha',
          title: localizations.ishaPrayer,
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'quran',
          title: localizations.readingQuran,
          type: ChecklistItemType.quran,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'athkar_sabah',
          title: localizations.athkarSabah,
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'athkar_masaa',
          title: localizations.athkarMasaa,
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
      ];

  static List<ChecklistItem> get defaultItems => [
        ChecklistItem(
          id: 'fajr',
          title: 'Fajr Prayer',
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'dhuhr',
          title: 'Dhuhr Prayer',
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'asr',
          title: 'Asr Prayer',
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'maghrib',
          title: 'Maghrib Prayer',
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'isha',
          title: 'Isha Prayer',
          type: ChecklistItemType.prayer,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'quran',
          title: 'Reading Quran',
          type: ChecklistItemType.quran,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'athkar_sabah',
          title: 'Athkar Sabah',
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        ChecklistItem(
          id: 'athkar_masaa',
          title: 'Athkar Masaa',
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ),
      ];

  Future<List<ChecklistItem>> getAllChecklistItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_checklistItemsKey);

    if (itemsJson == null) {
      await saveChecklistItems(defaultItems);
      return defaultItems;
    }

    final itemsList = jsonDecode(itemsJson) as List;
    final items =
        itemsList.map((item) => ChecklistItem.fromJson(item)).toList();

    final migratedItems = await _migrateAthkarItems(items);

    return migratedItems;
  }

  Future<void> updateDefaultItemTitles(AppLocalizations localizations) async {
    final items = await getAllChecklistItems();
    bool hasChanges = false;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.isDefault) {
        String? newTitle;

        switch (item.id) {
          case 'fajr':
            newTitle = localizations.fajrPrayer;
            break;
          case 'dhuhr':
            newTitle = localizations.dhuhrPrayer;
            break;
          case 'asr':
            newTitle = localizations.asrPrayer;
            break;
          case 'maghrib':
            newTitle = localizations.maghribPrayer;
            break;
          case 'isha':
            newTitle = localizations.ishaPrayer;
            break;
          case 'quran':
            newTitle = localizations.readingQuran;
            break;
          case 'athkar_sabah':
            newTitle = localizations.athkarSabah;
            break;
          case 'athkar_masaa':
            newTitle = localizations.athkarMasaa;
            break;
        }

        if (newTitle != null && newTitle != item.title) {
          items[i] = item.copyWith(title: newTitle);
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      await saveChecklistItems(items);
      _clearCache();
    }
  }

  Future<List<ChecklistItem>> _migrateAthkarItems(
      List<ChecklistItem> items) async {
    final oldAthkarIndex = items.indexWhere((item) => item.id == 'athkar');

    if (oldAthkarIndex != -1) {
      final updatedItems = List<ChecklistItem>.from(items);
      updatedItems.removeAt(oldAthkarIndex);

      final hasAthkarSabah =
          updatedItems.any((item) => item.id == 'athkar_sabah');
      final hasAthkarMasaa =
          updatedItems.any((item) => item.id == 'athkar_masaa');

      if (!hasAthkarSabah) {
        updatedItems.add(ChecklistItem(
          id: 'athkar_sabah',
          title: 'Morning Athkar',
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ));
      }

      if (!hasAthkarMasaa) {
        updatedItems.add(ChecklistItem(
          id: 'athkar_masaa',
          title: 'Evening Athkar',
          type: ChecklistItemType.athkar,
          frequency: RepetitionFrequency.daily,
          createdAt: DateTime.now(),
          isDefault: true,
        ));
      }

      await saveChecklistItems(updatedItems);
      return updatedItems;
    }

    return items;
  }

  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_checklistItemsKey, itemsJson);
  }

  Future<void> addChecklistItem(ChecklistItem item) async {
    final items = await getAllChecklistItems();

    final today = DateTime.now();
    final creationDate = item.createdAt.isAfter(today) ? today : item.createdAt;

    final adjustedItem = item.copyWith(
      createdAt: creationDate,
    );

    items.add(adjustedItem);
    await saveChecklistItems(items);

    _clearCache();
  }

  Future<void> removeChecklistItem(String itemId) async {
    final items = await getAllChecklistItems();

    items.removeWhere((item) => item.id == itemId);
    await saveChecklistItems(items);

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString('removed_item_${itemId}_date', _formatDateKey(today));

    _clearCache();
  }

  Future<DailyChecklist> getDailyChecklist(DateTime date) async {
    final dateKey = _formatDateKey(date);

    if (_dailyChecklistCache.containsKey(dateKey)) {
      return _dailyChecklistCache[dateKey]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final checklistJson = prefs.getString('${_dailyChecklistsKey}_$dateKey');

    if (checklistJson == null) {
      final allItems = await getAllChecklistItems();
      final applicableItems =
          await _getApplicableItemsForDateAsync(allItems, date);

      final dailyChecklist = DailyChecklist(
        date: date,
        items: applicableItems,
        completedItems: {},
      );

      await saveDailyChecklist(dailyChecklist);

      _dailyChecklistCache[dateKey] = dailyChecklist;
      return dailyChecklist;
    }

    final existingChecklist =
        DailyChecklist.fromJson(jsonDecode(checklistJson));

    final migratedChecklist = _migrateAthkarCompletions(existingChecklist);

    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (dateOnly.isBefore(todayOnly)) {
      final allItems = await getAllChecklistItems();
      final shouldHaveItems =
          await _getApplicableItemsForDateAsync(allItems, date);

      final newItems = shouldHaveItems
          .where((item) => !migratedChecklist.items
              .any((existing) => existing.id == item.id))
          .toList();

      if (newItems.isNotEmpty) {
        final updatedItems = [...migratedChecklist.items, ...newItems];
        final updatedChecklist =
            existingChecklist.copyWith(items: updatedItems);
        await saveDailyChecklist(updatedChecklist);

        _dailyChecklistCache[dateKey] = updatedChecklist;
        return updatedChecklist;
      }

      _dailyChecklistCache[dateKey] = migratedChecklist;
      return migratedChecklist;
    }

    final allItems = await getAllChecklistItems();
    final currentApplicableItems =
        await _getApplicableItemsForDateAsync(allItems, date);

    final preservedCompletions = <String, bool>{};
    for (final item in currentApplicableItems) {
      if (migratedChecklist.completedItems.containsKey(item.id)) {
        preservedCompletions[item.id] =
            migratedChecklist.completedItems[item.id]!;
      }
    }

    final updatedChecklist = migratedChecklist.copyWith(
      items: currentApplicableItems,
      completedItems: preservedCompletions,
    );

    await saveDailyChecklist(updatedChecklist);

    _dailyChecklistCache[dateKey] = updatedChecklist;
    return updatedChecklist;
  }

  Future<List<ChecklistItem>> _getApplicableItemsForDateAsync(
      List<ChecklistItem> allItems, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateOnly = DateTime(date.year, date.month, date.day);

    final applicableItems = <ChecklistItem>[];

    for (final item in allItems) {
      if (!item.isDefault) {
        final removalDateStr = prefs.getString('removed_item_${item.id}_date');
        if (removalDateStr != null) {
          final removalDate = DateTime.parse(removalDateStr);
          final removalDateOnly =
              DateTime(removalDate.year, removalDate.month, removalDate.day);

          if (dateOnly.isAtSameMomentAs(removalDateOnly) ||
              dateOnly.isAfter(removalDateOnly)) {
            continue;
          }
        }
      }

      if (item.frequency == RepetitionFrequency.daily) {
        final itemCreationDate = DateTime(
            item.createdAt.year, item.createdAt.month, item.createdAt.day);

        if (!item.isDefault && dateOnly.isBefore(itemCreationDate)) {
          continue;
        }

        applicableItems.add(item);
        continue;
      }

      final itemCreationDate = DateTime(
          item.createdAt.year, item.createdAt.month, item.createdAt.day);

      if (!item.isDefault && dateOnly.isBefore(itemCreationDate)) {
        continue;
      }

      final daysSinceCreation = dateOnly.difference(itemCreationDate).inDays;

      if (daysSinceCreation >= 0 &&
          daysSinceCreation % item.frequency.days == 0) {
        applicableItems.add(item);
      }
    }

    return applicableItems;
  }

  Future<void> saveDailyChecklist(DailyChecklist checklist) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDateKey(checklist.date);
    final checklistJson = jsonEncode(checklist.toJson());
    await prefs.setString('${_dailyChecklistsKey}_$dateKey', checklistJson);

    _dailyChecklistCache[dateKey] = checklist;
  }

  Future<void> updateItemCompletion(
      DateTime date, String itemId, bool completed) async {
    final checklist = await getDailyChecklist(date);
    final updatedCompletedItems =
        Map<String, bool>.from(checklist.completedItems);
    updatedCompletedItems[itemId] = completed;

    final updatedChecklist =
        checklist.copyWith(completedItems: updatedCompletedItems);
    await saveDailyChecklist(updatedChecklist);

    await _updateStreak(date);
  }

  Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();

    await _checkForMissedDays();

    return prefs.getInt(_streakCountKey) ?? 0;
  }

  Future<void> _checkForMissedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStreakDateStr = prefs.getString(_lastStreakDateKey);

    if (lastStreakDateStr == null) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final dateParts = lastStreakDateStr.split('-');
    final lastStreakDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    if (lastStreakDate.isAtSameMomentAs(todayOnly)) return;

    final daysSinceLastStreak = todayOnly.difference(lastStreakDate).inDays;

    if (daysSinceLastStreak > 1) {
      bool foundMissedDay = false;

      for (int i = 1; i < daysSinceLastStreak; i++) {
        final checkDate = lastStreakDate.add(Duration(days: i));
        final checklist = await getDailyChecklist(checkDate);

        if (checklist.items.isNotEmpty && !checklist.isCompleted) {
          foundMissedDay = true;
          break;
        }
      }

      if (foundMissedDay) {
        await prefs.setInt(_streakCountKey, 0);
        await prefs.remove(_lastStreakDateKey);
      }
    }
  }

  Future<void> _updateStreak(DateTime date) async {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (dateOnly.isAfter(todayOnly)) return;

    await _updateStreakWithPersistence(dateOnly);
  }

  Future<void> _updateStreakWithPersistence(DateTime dateOnly) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final checklist = await getDailyChecklist(dateOnly);
    final isDateCompleted = checklist.isCompleted && checklist.items.isNotEmpty;

    if (dateOnly.isAtSameMomentAs(todayOnly)) {
      await _handleTodayStreakUpdate(isDateCompleted);
    } else {
      await _recalculateFullStreak();
    }
  }

  Future<void> _handleTodayStreakUpdate(bool isTodayCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final currentStoredStreak = prefs.getInt(_streakCountKey) ?? 0;
    final lastStreakDateStr = prefs.getString(_lastStreakDateKey);

    int baseStreak = 0;
    DateTime? lastCompletedDate;

    if (lastStreakDateStr != null) {
      final dateParts = lastStreakDateStr.split('-');
      lastCompletedDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      if (lastCompletedDate.isBefore(todayOnly)) {
        baseStreak = await _calculateStreakUpToDate(lastCompletedDate);

        final yesterday = todayOnly.subtract(const Duration(days: 1));
        final daysBetween = yesterday.difference(lastCompletedDate).inDays;

        if (daysBetween > 0) {
          bool gapFound = false;
          for (int i = 1; i <= daysBetween; i++) {
            final checkDate = lastCompletedDate.add(Duration(days: i));
            final checkChecklist = await getDailyChecklist(checkDate);
            if (checkChecklist.items.isNotEmpty &&
                !checkChecklist.isCompleted) {
              gapFound = true;
              break;
            }
          }

          if (gapFound) {
            baseStreak = 0;
            lastCompletedDate = null;
          }
        }
      } else if (lastCompletedDate.isAtSameMomentAs(todayOnly)) {
        baseStreak = currentStoredStreak > 0 ? currentStoredStreak - 1 : 0;

        if (baseStreak > 0) {
          lastCompletedDate = todayOnly.subtract(const Duration(days: 1));
        } else {
          lastCompletedDate = null;
        }
      }
    }

    int newStreak;
    DateTime? newLastCompletedDate;

    if (isTodayCompleted) {
      final yesterday = todayOnly.subtract(const Duration(days: 1));

      if (lastCompletedDate != null &&
          (lastCompletedDate.isAtSameMomentAs(yesterday) || baseStreak > 0)) {
        newStreak = baseStreak + 1;
      } else {
        newStreak = 1;
      }
      newLastCompletedDate = todayOnly;
    } else {
      newStreak = baseStreak;
      newLastCompletedDate = lastCompletedDate;
    }

    await prefs.setInt(_streakCountKey, newStreak);
    if (newLastCompletedDate != null) {
      await prefs.setString(
          _lastStreakDateKey, _formatDateKey(newLastCompletedDate));
    } else {
      await prefs.remove(_lastStreakDateKey);
    }
  }

  Future<int> _calculateStreakUpToDate(DateTime endDate) async {
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = endDate.subtract(Duration(days: i));
      final checklist = await getDailyChecklist(checkDate);

      if (checklist.isCompleted && checklist.items.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> _recalculateFullStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    int streakCount = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = todayOnly.subtract(Duration(days: i));
      final checklist = await getDailyChecklist(checkDate);

      if (checklist.isCompleted && checklist.items.isNotEmpty) {
        streakCount++;
      } else {
        break;
      }
    }

    await prefs.setInt(_streakCountKey, streakCount);
    if (streakCount > 0) {
      final mostRecentCompletedDay =
          todayOnly.subtract(Duration(days: streakCount - 1));
      await prefs.setString(
          _lastStreakDateKey, _formatDateKey(mostRecentCompletedDay));
    } else {
      await prefs.remove(_lastStreakDateKey);
    }
  }

  DailyChecklist _migrateAthkarCompletions(DailyChecklist checklist) {
    final hasOldAthkar = checklist.completedItems.containsKey('athkar');

    if (hasOldAthkar) {
      final oldAthkarCompleted = checklist.completedItems['athkar'] ?? false;
      final updatedCompletions =
          Map<String, bool>.from(checklist.completedItems);

      updatedCompletions.remove('athkar');

      if (oldAthkarCompleted) {
        updatedCompletions['athkar_sabah'] = true;
        updatedCompletions['athkar_masaa'] = true;
      }

      return checklist.copyWith(completedItems: updatedCompletions);
    }

    return checklist;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
