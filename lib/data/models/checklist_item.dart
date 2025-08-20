import 'package:equatable/equatable.dart';

enum ChecklistItemType {
  prayer,
  quran,
  athkar,
  custom,
}

enum RepetitionFrequency {
  daily(1),
  every2Days(2),
  every3Days(3),
  every4Days(4),
  every5Days(5),
  every6Days(6),
  weekly(7);

  const RepetitionFrequency(this.days);
  final int days;
}

class ChecklistItem extends Equatable {
  final String id;
  final String title;
  final ChecklistItemType type;
  final RepetitionFrequency frequency;
  final DateTime createdAt;
  final bool isDefault;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.type,
    required this.frequency,
    required this.createdAt,
    this.isDefault = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    ChecklistItemType? type,
    RepetitionFrequency? frequency,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'frequency': frequency.name,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      title: json['title'],
      type: ChecklistItemType.values.firstWhere((e) => e.name == json['type']),
      frequency: RepetitionFrequency.values
          .firstWhere((e) => e.name == json['frequency']),
      createdAt: DateTime.parse(json['createdAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, type, frequency, createdAt, isDefault];
}

class DailyChecklist extends Equatable {
  final DateTime date;
  final List<ChecklistItem> items;
  final Map<String, bool> completedItems;

  const DailyChecklist({
    required this.date,
    required this.items,
    required this.completedItems,
  });

  DailyChecklist copyWith({
    DateTime? date,
    List<ChecklistItem>? items,
    Map<String, bool>? completedItems,
  }) {
    return DailyChecklist(
      date: date ?? this.date,
      items: items ?? this.items,
      completedItems: completedItems ?? this.completedItems,
    );
  }

  bool get isCompleted =>
      items.isNotEmpty &&
      items.every((item) => completedItems[item.id] == true);

  int get completedCount =>
      completedItems.values.where((completed) => completed).length;

  double get progressPercentage =>
      items.isEmpty ? 0.0 : (completedCount / items.length);

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'completedItems': completedItems,
    };
  }

  factory DailyChecklist.fromJson(Map<String, dynamic> json) {
    return DailyChecklist(
      date: DateTime.parse(json['date']),
      items: (json['items'] as List)
          .map((item) => ChecklistItem.fromJson(item))
          .toList(),
      completedItems: Map<String, bool>.from(json['completedItems']),
    );
  }

  @override
  List<Object?> get props => [date, items, completedItems];
}
