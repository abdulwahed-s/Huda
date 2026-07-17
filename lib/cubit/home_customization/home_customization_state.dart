import 'package:huda/data/models/home/home_preferences.dart';

sealed class HomeCustomizationState {
  const HomeCustomizationState();
}

class HomeCustomizationLoading extends HomeCustomizationState {
  const HomeCustomizationLoading();
}

class HomeCustomizationReady extends HomeCustomizationState {
  const HomeCustomizationReady(
    this.preferences, {
    HomePreferences? draft,
    this.isEditing = false,
    this.hasChanges = false,
    this.isSaving = false,
    this.saveError,
  }) : draft = draft ?? preferences;

  final HomePreferences preferences;

  final HomePreferences draft;
  final bool isEditing;
  final bool hasChanges;
  final bool isSaving;
  final String? saveError;

  HomeCustomizationReady copyWith({
    HomePreferences? preferences,
    HomePreferences? draft,
    bool? isEditing,
    bool? hasChanges,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return HomeCustomizationReady(
      preferences ?? this.preferences,
      draft: draft ?? this.draft,
      isEditing: isEditing ?? this.isEditing,
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : saveError ?? this.saveError,
    );
  }
}

class HomeCustomizationError extends HomeCustomizationState {
  const HomeCustomizationError(this.message);

  final String message;
}
