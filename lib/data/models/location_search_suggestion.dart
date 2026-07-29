class LocationSearchSuggestion {
  const LocationSearchSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;

  factory LocationSearchSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSearchSuggestion(
      placeId: json['placeId'] as String? ?? '',
      primaryText: json['primaryText'] as String? ?? '',
      secondaryText: json['secondaryText'] as String? ?? '',
    );
  }

  String get displayName =>
      secondaryText.isEmpty ? primaryText : '$primaryText, $secondaryText';

  bool get isValid => placeId.isNotEmpty && primaryText.isNotEmpty;
}
