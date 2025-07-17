import 'package:flutter/material.dart';

enum BookmarkType { bookmark, note, star }

class BookmarkModel {
  final String id;
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;
  final String surahName;
  final BookmarkType type;
  final Color? color; // For bookmark type
  final String? note; // For note type
  final double? ayahPosition; // For accurate scrolling to the ayah
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookmarkModel({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
    required this.surahName,
    required this.type,
    this.color,
    this.note,
    this.ayahPosition,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'ayahText': ayahText,
      'surahName': surahName,
      'type': type.name,
      'color': color?.value,
      'note': note,
      'ayahPosition': ayahPosition,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      ayahText: json['ayahText'] as String,
      surahName: json['surahName'] as String,
      type: BookmarkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BookmarkType.bookmark,
      ),
      color: json['color'] != null ? Color(json['color'] as int) : null,
      note: json['note'] as String?,
      ayahPosition: json['ayahPosition'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Copy with method for updates
  BookmarkModel copyWith({
    String? id,
    int? surahNumber,
    int? ayahNumber,
    String? ayahText,
    String? surahName,
    BookmarkType? type,
    Color? color,
    String? note,
    double? ayahPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      ayahText: ayahText ?? this.ayahText,
      surahName: surahName ?? this.surahName,
      type: type ?? this.type,
      color: color ?? this.color,
      note: note ?? this.note,
      ayahPosition: ayahPosition ?? this.ayahPosition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkModel &&
        other.id == id &&
        other.surahNumber == surahNumber &&
        other.ayahNumber == ayahNumber &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        surahNumber.hashCode ^
        ayahNumber.hashCode ^
        type.hashCode;
  }

  @override
  String toString() {
    return 'BookmarkModel(id: $id, surah: $surahNumber, ayah: $ayahNumber, type: $type)';
  }
}

// Predefined bookmark colors
class BookmarkColors {
  static const List<Color> availableColors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
    Color(0xFFE67E22), // Dark Orange
    Color(0xFF1ABC9C), // Turquoise
    Color(0xFFF1C40F), // Yellow
    Color(0xFF34495E), // Dark Blue-Gray
    Color(0xFFE91E63), // Pink
  ];

  static Color getDefaultColor() => availableColors.first;

  static String getColorName(Color color) {
    const colorNames = {
      0xFFE74C3C: 'Red',
      0xFF3498DB: 'Blue',
      0xFF2ECC71: 'Green',
      0xFFF39C12: 'Orange',
      0xFF9B59B6: 'Purple',
      0xFFE67E22: 'Dark Orange',
      0xFF1ABC9C: 'Turquoise',
      0xFFF1C40F: 'Yellow',
      0xFF34495E: 'Dark Blue-Gray',
      0xFFE91E63: 'Pink',
    };

    return colorNames[color.value] ?? 'Custom';
  }
}

/// Represents a bookmark change event
class BookmarkChange {
  final int surahNumber;
  final int ayahNumber;
  final BookmarkType type;
  final BookmarkChangeAction action;

  BookmarkChange({
    required this.surahNumber,
    required this.ayahNumber,
    required this.type,
    required this.action,
  });
}

/// Types of bookmark change actions
enum BookmarkChangeAction {
  added,
  removed,
  updated,
}
