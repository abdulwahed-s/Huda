enum HomeThemeId { classic, prayerToday, quranJourney }

enum HomeSectionId {
  dateAndPrayer,
  prayerSchedule,
  dailyAyah,
  continueReading,
  khatmaProgress,
  quranTools,
}

enum HomeFeatureId {
  quran,
  quranKit,
  prayerTimes,
  hadith,
  athkar,
  hijriCalendar,
  miqaatLock,
  books,
  audios,
  hudaAI,
  checklist,
  qiblah,
  notifications,
  ramadan,
  zakat,
  tasbih,
  settings,
  widgetManagement,
}

class HomeThemeConfiguration {
  const HomeThemeConfiguration({
    required this.orderedSections,
    required this.hiddenSections,
    required this.primaryFeatures,
    required this.viewMoreFeatures,
    required this.hiddenFeatures,
  });

  final List<HomeSectionId> orderedSections;
  final Set<HomeSectionId> hiddenSections;
  final List<HomeFeatureId> primaryFeatures;
  final List<HomeFeatureId> viewMoreFeatures;
  final Set<HomeFeatureId> hiddenFeatures;

  HomeThemeConfiguration copyWith({
    List<HomeSectionId>? orderedSections,
    Set<HomeSectionId>? hiddenSections,
    List<HomeFeatureId>? primaryFeatures,
    List<HomeFeatureId>? viewMoreFeatures,
    Set<HomeFeatureId>? hiddenFeatures,
  }) {
    return HomeThemeConfiguration(
      orderedSections: orderedSections ?? this.orderedSections,
      hiddenSections: hiddenSections ?? this.hiddenSections,
      primaryFeatures: primaryFeatures ?? this.primaryFeatures,
      viewMoreFeatures: viewMoreFeatures ?? this.viewMoreFeatures,
      hiddenFeatures: hiddenFeatures ?? this.hiddenFeatures,
    );
  }

  Map<String, dynamic> toJson() => {
        'sections': orderedSections.map((item) => item.name).toList(),
        'hiddenSections': hiddenSections.map((item) => item.name).toList(),
        'primaryFeatures': primaryFeatures.map((item) => item.name).toList(),
        'viewMoreFeatures': viewMoreFeatures.map((item) => item.name).toList(),
        'hiddenFeatures': hiddenFeatures.map((item) => item.name).toList(),
      };

  factory HomeThemeConfiguration.fromJson(
    Map<String, dynamic> json,
    HomeThemeConfiguration fallback,
  ) {
    final sections = _enumList(
      json['sections'],
      HomeSectionId.values,
      (value) => value.name,
    );
    for (final section in fallback.orderedSections) {
      if (!sections.contains(section)) sections.add(section);
    }

    final primary = _enumList(
      json['primaryFeatures'],
      HomeFeatureId.values,
      (value) => value.name,
    );
    final viewMore = _enumList(
      json['viewMoreFeatures'],
      HomeFeatureId.values,
      (value) => value.name,
    )..removeWhere(primary.contains);

    for (final feature in [
      ...fallback.primaryFeatures,
      ...fallback.viewMoreFeatures,
    ]) {
      if (!primary.contains(feature) && !viewMore.contains(feature)) {
        if (fallback.primaryFeatures.contains(feature)) {
          primary.add(feature);
        } else {
          viewMore.add(feature);
        }
      }
    }

    return HomeThemeConfiguration(
      orderedSections: sections,
      hiddenSections: _enumList(
        json['hiddenSections'],
        HomeSectionId.values,
        (value) => value.name,
      ).toSet(),
      primaryFeatures: primary,
      viewMoreFeatures: viewMore,
      hiddenFeatures: _enumList(
        json['hiddenFeatures'],
        HomeFeatureId.values,
        (value) => value.name,
      ).toSet(),
    );
  }
}

class HomePreferences {
  const HomePreferences({
    required this.schemaVersion,
    required this.selectedTheme,
    required this.configurations,
  });

  static const currentSchemaVersion = 2;

  final int schemaVersion;
  final HomeThemeId selectedTheme;
  final Map<HomeThemeId, HomeThemeConfiguration> configurations;

  HomeThemeConfiguration configurationFor(HomeThemeId theme) {
    final fallback = HomeThemeDefaults.configuration(theme);
    return HomeThemePolicy.normalize(
      theme,
      configurations[theme] ?? fallback,
      fallback,
    );
  }

  HomePreferences copyWith({
    HomeThemeId? selectedTheme,
    Map<HomeThemeId, HomeThemeConfiguration>? configurations,
  }) {
    return HomePreferences(
      schemaVersion: currentSchemaVersion,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      configurations: configurations ?? this.configurations,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'selectedTheme': selectedTheme.name,
        'configurations': {
          for (final entry in configurations.entries)
            entry.key.name: entry.value.toJson(),
        },
      };

  factory HomePreferences.defaults() => HomePreferences(
        schemaVersion: currentSchemaVersion,
        selectedTheme: HomeThemeId.classic,
        configurations: {
          for (final theme in HomeThemeId.values)
            theme: HomeThemeDefaults.configuration(theme),
        },
      );

  factory HomePreferences.fromJson(Map<String, dynamic> json) {
    final defaults = HomePreferences.defaults();
    final storedSchemaVersion = switch (json['schemaVersion']) {
      final num value => value.toInt(),
      _ => 1,
    };
    final selectedName = json['selectedTheme'];
    final selected = HomeThemeId.values.firstWhere(
      (theme) => theme.name == selectedName,
      orElse: () => HomeThemeId.classic,
    );
    final rawConfigurations = json['configurations'];
    final configurations = <HomeThemeId, HomeThemeConfiguration>{};

    for (final theme in HomeThemeId.values) {
      final fallback = defaults.configurationFor(theme);
      final raw =
          rawConfigurations is Map ? rawConfigurations[theme.name] : null;
      final resetFocusedMode = storedSchemaVersion < currentSchemaVersion &&
          theme != HomeThemeId.classic;
      final parsed = !resetFocusedMode && raw is Map
          ? HomeThemeConfiguration.fromJson(
              Map<String, dynamic>.from(raw),
              fallback,
            )
          : fallback;
      configurations[theme] =
          HomeThemePolicy.normalize(theme, parsed, fallback);
    }

    return HomePreferences(
      schemaVersion: currentSchemaVersion,
      selectedTheme: selected,
      configurations: configurations,
    );
  }
}

class HomeThemeDefaults {
  const HomeThemeDefaults._();

  static const _allFeatures = HomeFeatureId.values;

  static HomeThemeConfiguration configuration(HomeThemeId theme) {
    return switch (theme) {
      HomeThemeId.classic => const HomeThemeConfiguration(
          orderedSections: [],
          hiddenSections: {},
          primaryFeatures: [
            HomeFeatureId.quranKit,
            HomeFeatureId.prayerTimes,
            HomeFeatureId.hadith,
            HomeFeatureId.athkar,
            HomeFeatureId.hijriCalendar,
            HomeFeatureId.miqaatLock,
            HomeFeatureId.books,
            HomeFeatureId.audios,
            HomeFeatureId.hudaAI,
            HomeFeatureId.checklist,
            HomeFeatureId.qiblah,
            HomeFeatureId.notifications,
            HomeFeatureId.ramadan,
            HomeFeatureId.zakat,
            HomeFeatureId.tasbih,
            HomeFeatureId.settings,
            HomeFeatureId.widgetManagement,
          ],
          viewMoreFeatures: [],
          hiddenFeatures: {},
        ),
      HomeThemeId.prayerToday => _withPrimary(
          sections: const [],
          primary: const [
            HomeFeatureId.prayerTimes,
            HomeFeatureId.quranKit,
            HomeFeatureId.athkar,
            HomeFeatureId.hadith,
            HomeFeatureId.tasbih,
          ],
          reserved: const {
            HomeFeatureId.quran,
          },
        ),
      HomeThemeId.quranJourney => _withPrimary(
          sections: const [
            HomeSectionId.dailyAyah,
            HomeSectionId.khatmaProgress,
          ],
          primary: const [
            HomeFeatureId.athkar,
            HomeFeatureId.hadith,
            HomeFeatureId.books,
            HomeFeatureId.audios,
          ],
          reserved: const {
            HomeFeatureId.quran,
            HomeFeatureId.quranKit,
          },
        ),
    };
  }

  static HomeThemeConfiguration _withPrimary({
    required List<HomeSectionId> sections,
    required List<HomeFeatureId> primary,
    Set<HomeFeatureId> reserved = const {},
  }) {
    final available =
        _allFeatures.where((feature) => !reserved.contains(feature));
    return HomeThemeConfiguration(
      orderedSections: sections,
      hiddenSections: const {},
      primaryFeatures: primary,
      viewMoreFeatures:
          available.where((feature) => !primary.contains(feature)).toList(),
      hiddenFeatures: const {},
    );
  }
}

class HomeThemePolicy {
  const HomeThemePolicy._();

  static Set<HomeSectionId> configurableSections(HomeThemeId theme) =>
      switch (theme) {
        HomeThemeId.classic || HomeThemeId.prayerToday => const {},
        HomeThemeId.quranJourney => const {
            HomeSectionId.dailyAyah,
            HomeSectionId.khatmaProgress,
          },
      };

  static Set<HomeFeatureId> reservedFeatures(HomeThemeId theme) =>
      switch (theme) {
        HomeThemeId.classic => const {},
        HomeThemeId.prayerToday => const {
            HomeFeatureId.quran,
          },
        HomeThemeId.quranJourney => const {
            HomeFeatureId.quran,
            HomeFeatureId.quranKit,
          },
      };

  static HomeThemeConfiguration normalize(
    HomeThemeId theme,
    HomeThemeConfiguration configuration,
    HomeThemeConfiguration fallback,
  ) {
    final allowedSections = configurableSections(theme);
    final reserved = reservedFeatures(theme);
    final sections =
        configuration.orderedSections.where(allowedSections.contains).toList();
    for (final section in fallback.orderedSections) {
      if (!sections.contains(section)) sections.add(section);
    }

    final primary = <HomeFeatureId>[];
    for (final feature in configuration.primaryFeatures) {
      if (!reserved.contains(feature) && !primary.contains(feature)) {
        primary.add(feature);
      }
    }
    final more = <HomeFeatureId>[];
    for (final feature in configuration.viewMoreFeatures) {
      if (!reserved.contains(feature) &&
          !primary.contains(feature) &&
          !more.contains(feature)) {
        more.add(feature);
      }
    }
    for (final feature in [
      ...fallback.primaryFeatures,
      ...fallback.viewMoreFeatures,
    ]) {
      if (!primary.contains(feature) && !more.contains(feature)) {
        (fallback.primaryFeatures.contains(feature) ? primary : more)
            .add(feature);
      }
    }

    return HomeThemeConfiguration(
      orderedSections: sections,
      hiddenSections:
          configuration.hiddenSections.where(allowedSections.contains).toSet(),
      primaryFeatures: primary,
      viewMoreFeatures: more,
      hiddenFeatures: configuration.hiddenFeatures
          .where((feature) => !reserved.contains(feature))
          .toSet(),
    );
  }
}

List<T> _enumList<T>(
  Object? raw,
  List<T> values,
  String Function(T value) nameOf,
) {
  if (raw is! List) return <T>[];
  final result = <T>[];
  for (final item in raw) {
    for (final value in values) {
      if (nameOf(value) == item && !result.contains(value)) {
        result.add(value);
        break;
      }
    }
  }
  return result;
}
