import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/home_preferences_service.dart';
import 'package:huda/data/models/home/home_preferences.dart';

import 'home_customization_state.dart';

class HomeCustomizationCubit extends Cubit<HomeCustomizationState> {
  HomeCustomizationCubit(this._service)
      : super(const HomeCustomizationLoading()) {
    load();
  }

  final HomePreferencesService _service;

  void load() {
    try {
      final preferences = _service.load();
      emit(
        HomeCustomizationReady(
          preferences,
          draft: _copy(preferences),
        ),
      );
    } catch (error) {
      emit(HomeCustomizationError(error.toString()));
    }
  }

  void beginEditing() {
    final current = state;
    if (current is! HomeCustomizationReady || current.isSaving) return;
    emit(
      current.copyWith(
        draft: _copy(current.preferences),
        isEditing: true,
        hasChanges: false,
        clearSaveError: true,
      ),
    );
  }

  void cancelEditing() {
    final current = state;
    if (current is! HomeCustomizationReady || current.isSaving) return;
    emit(
      current.copyWith(
        draft: _copy(current.preferences),
        isEditing: false,
        hasChanges: false,
        clearSaveError: true,
      ),
    );
  }

  void selectTheme(HomeThemeId theme) {
    final current = _editingState;
    if (current == null || current.draft.selectedTheme == theme) return;
    _emitDraft(current.draft.copyWith(selectedTheme: theme));
  }

  void reorderSections(HomeSectionId dragged, HomeSectionId target) {
    final current = _editingState;
    if (current == null || dragged == target) return;
    final configuration = _configuration(current);
    final sections = List<HomeSectionId>.from(configuration.orderedSections);
    final oldIndex = sections.indexOf(dragged);
    final targetIndex = sections.indexOf(target);
    if (oldIndex < 0 || targetIndex < 0) return;
    sections
      ..removeAt(oldIndex)
      ..insert(targetIndex.clamp(0, sections.length), dragged);
    _updateConfiguration(
      current,
      configuration.copyWith(orderedSections: sections),
    );
  }

  void setSectionVisibility(HomeSectionId section, {required bool visible}) {
    final current = _editingState;
    if (current == null) return;
    final configuration = _configuration(current);
    final hidden = Set<HomeSectionId>.from(configuration.hiddenSections);
    visible ? hidden.remove(section) : hidden.add(section);
    _updateConfiguration(
      current,
      configuration.copyWith(hiddenSections: hidden),
    );
  }

  void reorderFeature({
    required bool primary,
    required HomeFeatureId dragged,
    required HomeFeatureId target,
  }) {
    final current = _editingState;
    if (current == null || dragged == target) return;
    final configuration = _configuration(current);
    final features = List<HomeFeatureId>.from(
      primary ? configuration.primaryFeatures : configuration.viewMoreFeatures,
    );
    final oldIndex = features.indexOf(dragged);
    final targetIndex = features.indexOf(target);
    if (oldIndex < 0 || targetIndex < 0) return;
    features
      ..removeAt(oldIndex)
      ..insert(targetIndex.clamp(0, features.length), dragged);
    _updateConfiguration(
      current,
      primary
          ? configuration.copyWith(primaryFeatures: features)
          : configuration.copyWith(viewMoreFeatures: features),
    );
  }

  void setFeatureVisibility(HomeFeatureId feature, {required bool visible}) {
    final current = _editingState;
    if (current == null) return;
    final configuration = _configuration(current);
    final hidden = Set<HomeFeatureId>.from(configuration.hiddenFeatures);
    visible ? hidden.remove(feature) : hidden.add(feature);
    _updateConfiguration(
      current,
      configuration.copyWith(hiddenFeatures: hidden),
    );
  }

  void moveFeature(HomeFeatureId feature, {required bool toPrimary}) {
    final current = _editingState;
    if (current == null) return;
    final configuration = _configuration(current);
    final primary = List<HomeFeatureId>.from(configuration.primaryFeatures)
      ..remove(feature);
    final more = List<HomeFeatureId>.from(configuration.viewMoreFeatures)
      ..remove(feature);
    (toPrimary ? primary : more).add(feature);
    _updateConfiguration(
      current,
      configuration.copyWith(
        primaryFeatures: primary,
        viewMoreFeatures: more,
      ),
    );
  }

  void resetCurrentTheme() {
    final current = _editingState;
    if (current == null) return;
    _updateConfiguration(
      current,
      HomeThemeDefaults.configuration(current.draft.selectedTheme),
    );
  }

  Future<bool> applyDraft() async {
    final current = state;
    if (current is! HomeCustomizationReady || current.isSaving) return false;
    if (!current.hasChanges) {
      emit(current.copyWith(isEditing: false, clearSaveError: true));
      return true;
    }
    return apply(current.draft);
  }

  Future<bool> apply(HomePreferences preferences) async {
    final previous = state;
    if (previous is HomeCustomizationReady && previous.isSaving) return false;
    final committed =
        previous is HomeCustomizationReady ? previous.preferences : preferences;
    emit(
      HomeCustomizationReady(
        committed,
        draft: preferences,
        isEditing: true,
        hasChanges: !_same(committed, preferences),
        isSaving: true,
      ),
    );
    try {
      await _service.save(preferences);
      emit(
        HomeCustomizationReady(
          preferences,
          draft: _copy(preferences),
        ),
      );
      return true;
    } catch (error) {
      emit(
        HomeCustomizationReady(
          committed,
          draft: preferences,
          isEditing: true,
          hasChanges: !_same(committed, preferences),
          saveError: error.toString(),
        ),
      );
      return false;
    }
  }

  HomeCustomizationReady? get _editingState {
    final current = state;
    if (current is! HomeCustomizationReady || current.isSaving) return null;
    if (!current.isEditing) beginEditing();
    final refreshed = state;
    return refreshed is HomeCustomizationReady ? refreshed : null;
  }

  HomeThemeConfiguration _configuration(HomeCustomizationReady current) {
    return current.draft.configurationFor(current.draft.selectedTheme);
  }

  void _updateConfiguration(
    HomeCustomizationReady current,
    HomeThemeConfiguration configuration,
  ) {
    final configurations = Map<HomeThemeId, HomeThemeConfiguration>.from(
      current.draft.configurations,
    );
    configurations[current.draft.selectedTheme] = configuration;
    _emitDraft(current.draft.copyWith(configurations: configurations));
  }

  void _emitDraft(HomePreferences draft) {
    final current = state;
    if (current is! HomeCustomizationReady || current.isSaving) return;
    emit(
      current.copyWith(
        draft: draft,
        isEditing: true,
        hasChanges: !_same(current.preferences, draft),
        clearSaveError: true,
      ),
    );
  }

  static HomePreferences _copy(HomePreferences preferences) =>
      HomePreferences.fromJson(preferences.toJson());

  static bool _same(HomePreferences a, HomePreferences b) =>
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());
}
