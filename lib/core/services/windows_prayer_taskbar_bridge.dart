import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_rule_store.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:synchronized/synchronized.dart';
import 'package:just_audio/just_audio.dart';

enum WindowsPrayerTaskbarStyle { iconOnly, iconNameCountdown, iconNameClock }

enum WindowsPrayerTaskbarTextColor { automatic, light, dark, appColor }

enum WindowsPrayerTaskbarTextSize { small, medium, large }

@immutable
class WindowsPrayerTaskbarPreferences {
  const WindowsPrayerTaskbarPreferences({
    this.showTaskbarCountdown = true,
    this.startWithWindows = false,
    this.style = WindowsPrayerTaskbarStyle.iconNameCountdown,
    this.showSeconds = true,
    this.transparentBackground = true,
    this.textColor = WindowsPrayerTaskbarTextColor.automatic,
    this.textSize = WindowsPrayerTaskbarTextSize.medium,
    this.showIcon = true,
  });

  final bool showTaskbarCountdown, startWithWindows;
  final WindowsPrayerTaskbarStyle style;
  final bool showSeconds;
  final bool transparentBackground, showIcon;
  final WindowsPrayerTaskbarTextColor textColor;
  final WindowsPrayerTaskbarTextSize textSize;
  // Keep the schema-1 wire fields for older installations. The tray is now
  // part of Huda's lifecycle and can only be closed through Exit.
  bool get enabled => true;
  bool get showTrayIcon => true;

  WindowsPrayerTaskbarPreferences copyWith({
    bool? showTaskbarCountdown,
    bool? startWithWindows,
    WindowsPrayerTaskbarStyle? style,
    bool? showSeconds,
    bool? transparentBackground,
    WindowsPrayerTaskbarTextColor? textColor,
    WindowsPrayerTaskbarTextSize? textSize,
    bool? showIcon,
  }) => WindowsPrayerTaskbarPreferences(
    showTaskbarCountdown: showTaskbarCountdown ?? this.showTaskbarCountdown,
    startWithWindows: startWithWindows ?? this.startWithWindows,
    style: style ?? this.style,
    showSeconds: showSeconds ?? this.showSeconds,
    transparentBackground: transparentBackground ?? this.transparentBackground,
    textColor: textColor ?? this.textColor,
    textSize: textSize ?? this.textSize,
    showIcon: showIcon ?? this.showIcon,
  );

  Map<String, Object> toMap() => {
    'enabled': enabled,
    'showTaskbarCountdown': showTaskbarCountdown,
    'showTrayIcon': showTrayIcon,
    'startWithWindows': startWithWindows,
    'style': style.name,
    'showSeconds': showSeconds,
    'transparentBackground': transparentBackground,
    'textColor': textColor.name,
    'textSize': textSize.name,
    'showIcon': showIcon,
  };

  factory WindowsPrayerTaskbarPreferences.fromMap(Map<Object?, Object?> map) =>
      WindowsPrayerTaskbarPreferences(
        showTaskbarCountdown: map['showTaskbarCountdown'] != false,
        startWithWindows: map['startWithWindows'] == true,
        style: WindowsPrayerTaskbarStyle.values.firstWhere(
          (style) => style.name == map['style'],
          orElse: () => WindowsPrayerTaskbarStyle.iconNameCountdown,
        ),
        showSeconds: map['showSeconds'] != false,
        transparentBackground: map['transparentBackground'] != false,
        textColor: WindowsPrayerTaskbarTextColor.values.firstWhere(
          (color) => color.name == map['textColor'],
          orElse: () => WindowsPrayerTaskbarTextColor.automatic,
        ),
        textSize: WindowsPrayerTaskbarTextSize.values.firstWhere(
          (size) => size.name == map['textSize'],
          orElse: () => WindowsPrayerTaskbarTextSize.medium,
        ),
        showIcon: map['showIcon'] != false,
      );
}

@immutable
class WindowsPrayerTaskbarStatus {
  const WindowsPrayerTaskbarStatus({
    this.helperAvailable = false,
    this.running = false,
    this.appliedRevision = 0,
    this.taskbarPlacement = 'hidden',
    this.startupState = 'disabled',
    this.error,
    this.prayerAudioPlaying = false,
    this.prayerFocusActive = false,
    this.prayerFocusCanDismiss = true,
    this.prayerSessionId,
    this.prayerAudioSessionId,
    this.prayerAudioError,
    this.prayerQueueError,
    this.prayerToastCoverageUntilUtc,
    this.prayerExperienceVersion = 1,
  });

  final bool helperAvailable, running;
  final int appliedRevision;
  final String taskbarPlacement, startupState;
  final String? error;
  final bool prayerAudioPlaying, prayerFocusActive, prayerFocusCanDismiss;
  final String? prayerSessionId,
      prayerAudioSessionId,
      prayerAudioError,
      prayerQueueError;
  final DateTime? prayerToastCoverageUntilUtc;

  /// 3 and later: per-prayer settings and reminders before prayers.
  final int prayerExperienceVersion;
  bool get startupEnabled => startupState == 'enabled';
  bool get startupBlocked =>
      startupState == 'disabledByUser' || startupState == 'disabledByPolicy';

  factory WindowsPrayerTaskbarStatus.fromMap(Map<String, dynamic> map) =>
      WindowsPrayerTaskbarStatus(
        helperAvailable: map['helperAvailable'] == true,
        running: map['running'] == true,
        appliedRevision: (map['appliedRevision'] as num?)?.toInt() ?? 0,
        taskbarPlacement: map['taskbarPlacement'] as String? ?? 'unavailable',
        startupState: map['startupState'] as String? ?? 'unavailable',
        error: map['error'] as String?,
        prayerAudioPlaying: map['prayerAudioPlaying'] == true,
        prayerFocusActive: map['prayerFocusActive'] == true,
        prayerFocusCanDismiss: map['prayerFocusCanDismiss'] != false,
        prayerSessionId: map['prayerSessionId'] as String?,
        prayerAudioSessionId: map['prayerAudioSessionId'] as String?,
        prayerAudioError: map['prayerAudioError'] as String?,
        prayerQueueError: map['prayerQueueError'] as String?,
        prayerToastCoverageUntilUtc: DateTime.tryParse(
          map['prayerToastCoverageUntilUtc'] as String? ?? '',
        ),
        prayerExperienceVersion:
            (map['prayerExperienceVersion'] as num?)?.toInt() ?? 1,
      );
}

abstract final class WindowsPrayerTaskbarBridge {
  static const channel = MethodChannel('com.aw.huda/windows_prayer_taskbar');
  static const preferencesKey = 'windows_prayer_taskbar_preferences_v1';

  /// Set once reminders have turned on "Start with Windows", so it is never
  /// turned on again against the user's choice.
  static const reminderStartupKey = 'windows_reminder_startup_enabled_v1';
  static const experienceApplyJournalKey = 'windows_prayer_experience_apply_v1';
  static final status = ValueNotifier(const WindowsPrayerTaskbarStatus());
  static final _lock = Lock();
  static final _experienceLock = Lock();
  static final experience = ValueNotifier(const WindowsPrayerExperience());
  static DateTime? _experienceActiveFrom;
  static Map<String, Object?>? _notificationContract;
  static Future<void>? _installation;
  static CacheHelper? _cache;
  static PrayerDisplaySnapshot? _display;
  static Map<String, Object?>? _presentation;
  static WindowsPrayerTaskbarPreferences _preferences =
      const WindowsPrayerTaskbarPreferences();
  static int _revision = 0;
  static String? _published;
  static bool _displayLoadFailed = false;

  static Future<void> install({
    required Future<void> Function() openSettings,
    required Future<void> Function() openPrayerPage,
    required Future<void> Function() openQuran,
    required Future<void> Function() openAthkar,
    required Future<void> Function() openHuda,
    CacheHelper? cacheHelper,
    Future<PrayerDisplaySnapshot?> Function()? loadDisplay,
  }) {
    if (!PlatformUtils.isWindows) return Future.value();
    return _installation ??= _install(
      openSettings,
      openPrayerPage,
      openQuran,
      openAthkar,
      openHuda,
      cacheHelper ?? getIt<CacheHelper>(),
      loadDisplay,
    );
  }

  static Future<void> _install(
    Future<void> Function() openSettings,
    Future<void> Function() openPrayerPage,
    Future<void> Function() openQuran,
    Future<void> Function() openAthkar,
    Future<void> Function() openHuda,
    CacheHelper cache,
    Future<PrayerDisplaySnapshot?> Function()? loadDisplay,
  ) async {
    _cache = cache;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'prayerAudioStarted':
          if (getIt.isRegistered<AudioPlayer>()) {
            await getIt<AudioPlayer>().pause();
          }
        case 'openPrayerSettings':
          await openSettings();
        case 'openPrayerPage':
          await openPrayerPage();
        case 'openQuran':
          await openQuran();
        case 'openAthkar':
          await openAthkar();
        case 'openHuda':
          await openHuda();
      }
    });
    Map<String, dynamic>? persisted;
    try {
      final bootstrap = await channel.invokeMapMethod<String, dynamic>(
        'initialize',
      );
      final raw = bootstrap?['configuration'] as String?;
      status.value = WindowsPrayerTaskbarStatus(
        helperAvailable: bootstrap?['helperAvailable'] == true,
      );
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            persisted = decoded;
            final revision = decoded['revision'];
            if (revision is int &&
                revision > 0 &&
                revision <= 9007199254740991) {
              _revision = revision;
            }
          }
        } on FormatException {
          /* Publish a complete revision to repair the file. */
        }
      }
    } catch (error) {
      _recordError(error);
    }
    try {
      var loadedExperience = WindowsPrayerExperience.read(cache);
      final journalRaw = cache.getDataString(key: experienceApplyJournalKey);
      if (journalRaw != null) {
        Map? journal;
        try {
          journal = jsonDecode(journalRaw) as Map;
        } catch (_) {}
        final previous = WindowsPrayerExperience.tryParse(journal?['previous']);
        final intended = WindowsPrayerExperience.tryParse(journal?['intended']);
        final native = WindowsPrayerExperience.tryParse(
          persisted?['prayerExperience'],
        );
        // The exchange may have committed just before the process terminated.
        loadedExperience =
            native != null &&
                intended != null &&
                jsonEncode(native.toMap()) == jsonEncode(intended.toMap())
            ? native
            : previous ?? native ?? const WindowsPrayerExperience();
        if (!await cache.saveData(
          key: WindowsPrayerExperience.preferencesKey,
          value: jsonEncode(loadedExperience.toMap()),
        )) {
          throw StateError(
            'Interrupted prayer settings could not be recovered.',
          );
        }
        await cache.removeData(key: experienceApplyJournalKey);
      }
      if (!loadedExperience.configured &&
          persisted?['prayerExperience'] != null) {
        loadedExperience =
            WindowsPrayerExperience.tryParse(persisted!['prayerExperience']) ??
            loadedExperience;
        await cache.saveData(
          key: WindowsPrayerExperience.preferencesKey,
          value: jsonEncode(loadedExperience.toMap()),
        );
      }
      experience.value = loadedExperience;
      _experienceActiveFrom = DateTime.tryParse(
        persisted?['prayerExperienceActiveFromUtc'] as String? ?? '',
      );
      if (persisted?['notificationContract'] is Map) {
        _notificationContract = Map<String, Object?>.from(
          persisted!['notificationContract'] as Map,
        );
      }
      final cached = cache.getDataString(key: preferencesKey);
      Map? preferences;
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is Map) preferences = decoded;
        } on FormatException {
          /* Recover preferences from the shared exchange. */
        }
      }
      if (preferences == null &&
          persisted?['schemaVersion'] == 1 &&
          persisted?['preferences'] is Map) {
        // Migrate between MSIX and Inno installations through Huda's exchange.
        preferences = persisted!['preferences'] as Map;
      }
      if (preferences != null) {
        _preferences = WindowsPrayerTaskbarPreferences.fromMap(preferences);
        await cache.saveData(
          key: preferencesKey,
          value: jsonEncode(_preferences.toMap()),
        );
      }
    } catch (error) {
      _recordError(error);
    }
    // Navigation remains available even if one persisted input needs repair.
    try {
      await channel.invokeMethod<void>('ready');
    } catch (error) {
      _recordError(error);
    }
    try {
      _display = loadDisplay != null
          ? await loadDisplay()
          : await PrayerLocationRepository(
              cacheHelper: cache,
            ).readCommittedDisplay();
    } catch (error) {
      _displayLoadFailed = true;
      _recordError(error);
    }
  }

  static Future<WindowsPrayerTaskbarPreferences> getPreferences() async {
    await _installation;
    return _preferences;
  }

  static Future<void> setPreferences(
    WindowsPrayerTaskbarPreferences next,
  ) async {
    await _installation;
    await _lock.synchronized(() async {
      final saved = await (_cache ?? getIt<CacheHelper>()).saveData(
        key: preferencesKey,
        value: jsonEncode(next.toMap()),
      );
      if (!saved) {
        throw StateError('Windows prayer preferences could not be saved.');
      }
      _preferences = next;
      try {
        await _publish(force: true, updateStartup: true);
      } catch (error) {
        _recordError(error);
        rethrow;
      }
    });
  }

  static Future<void> publishDisplay(PrayerDisplaySnapshot display) async {
    if (!PlatformUtils.isWindows) return;
    await _installation;
    await _lock.synchronized(() async {
      if (_display != null &&
          (_display!.location.revision > display.location.revision ||
              (_display!.location.revision == display.location.revision &&
                  _display!.revision > display.revision))) {
        return;
      }
      _display = display;
      _displayLoadFailed = false;
      try {
        await _publish();
      } catch (error) {
        _recordError(error);
      }
    });
  }

  /// Publishes the reminder rules saved in [ReminderRuleStore] so the
  /// companion renews their toasts while Huda is closed. Huda schedules the
  /// toasts itself too, so false only means renewal waits for a later publish.
  ///
  /// The first time repeating reminders exist, "Start with Windows" is turned
  /// on so renewal survives restarts. This happens once: a user who turns it
  /// off afterwards, or blocks it in Windows settings, keeps that choice.
  static Future<bool> publishReminderRules() async {
    if (!PlatformUtils.isWindows || _installation == null) return false;
    await _installation;
    return _lock.synchronized(() async {
      try {
        final cache = _cache ?? getIt<CacheHelper>();
        final repeating = ReminderRuleStore.read(
          cache,
        ).any((rule) => rule['kind'] != 'once');
        var startup = false;
        if (repeating && cache.getData(key: reminderStartupKey) != true) {
          if (!_preferences.startWithWindows) {
            final next = _preferences.copyWith(startWithWindows: true);
            startup = await cache.saveData(
              key: preferencesKey,
              value: jsonEncode(next.toMap()),
            );
            if (startup) _preferences = next;
          }
          await cache.saveData(key: reminderStartupKey, value: true);
        }
        await _publish(force: startup, updateStartup: startup);
        return true;
      } catch (error) {
        _recordError(error);
        return false;
      }
    });
  }

  static Future<void> publishNotificationContract({
    required int locationRevision,
    required int scheduleRevision,
    required String configurationSignature,
  }) async {
    if (!PlatformUtils.isWindows) return;
    await _installation;
    await _lock.synchronized(() async {
      _notificationContract = {
        'locationRevision': locationRevision,
        'scheduleRevision': scheduleRevision,
        'configurationSignature': configurationSignature,
      };
      try {
        await _publish();
      } catch (error) {
        _recordError(error);
      }
    });
  }

  static Future<void> applyExperience(
    WindowsPrayerExperience next, {
    required Future<PrayerScheduleResult> Function() reconcile,
  }) => _experienceLock.synchronized(() async {
    await _installation;
    next.validate();
    final cache = _cache ?? getIt<CacheHelper>();
    final previous = experience.value;
    final previousCutover = _experienceActiveFrom;
    final hasCompanion = status.value.helperAvailable;
    if (!hasCompanion &&
        next.enabled &&
        next.mode != WindowsPrayerReminderMode.silent) {
      throw StateError('The Windows prayer companion is unavailable.');
    }
    if (hasCompanion) await experienceCommand('suspendRenewal');
    try {
      if (!await cache.saveData(
        key: experienceApplyJournalKey,
        value: jsonEncode({
          'previous': previous.toMap(),
          'intended': next.toMap(),
        }),
      )) {
        throw StateError('Prayer settings recovery state could not be saved.');
      }
      if (!await cache.saveData(
        key: WindowsPrayerExperience.preferencesKey,
        value: jsonEncode(next.toMap()),
      )) {
        throw StateError('Prayer reminder settings could not be saved.');
      }
      final result = await reconcile();
      if (!result.isSuccess) {
        throw StateError(
          result.message ?? 'Prayer reminders could not be reconciled.',
        );
      }
      await _lock.synchronized(() async {
        experience.value = next;
        _experienceActiveFrom = DateTime.now().toUtc().add(
          const Duration(seconds: 31),
        );
        if (hasCompanion) await _publish(force: true);
      });
      await cache.removeData(key: experienceApplyJournalKey);
    } catch (_) {
      experience.value = previous;
      _experienceActiveFrom = previousCutover;
      await cache.saveData(
        key: WindowsPrayerExperience.preferencesKey,
        value: jsonEncode(previous.toMap()),
      );
      // Recover any partial toast replacement before allowing companion renewal.
      await reconcile();
      if (hasCompanion) {
        try {
          await _lock.synchronized(() => _publish(force: true));
          await cache.removeData(key: experienceApplyJournalKey);
        } catch (error) {
          _recordError(error);
        }
      } else {
        await cache.removeData(key: experienceApplyJournalKey);
      }
      rethrow;
    } finally {
      if (hasCompanion) {
        try {
          await experienceCommand('resumeRenewal');
        } catch (error) {
          _recordError(error);
        }
      }
    }
  });

  static Future<WindowsPrayerTaskbarStatus> experienceCommand(
    String command, {
    String? sessionId,
    WindowsPrayerExperience? settings,
    double? volume,
  }) async {
    final raw = await channel
        .invokeMethod<String>('experienceCommand', {
          'json': jsonEncode({
            'command': command,
            if (sessionId != null) 'sessionId': sessionId,
            if (settings != null) 'settings': settings.toMap(),
            if (volume != null) 'volume': volume,
          }),
        })
        .timeout(const Duration(seconds: 10));
    final map = jsonDecode(raw!) as Map<String, dynamic>;
    if (map['error'] != null && map['helperAvailable'] != true) {
      throw StateError(map['error'] as String);
    }
    final updated = WindowsPrayerTaskbarStatus.fromMap(map);
    status.value = updated;
    return updated;
  }

  static Future<void> syncPresentation(
    AppLocalizations l10n, {
    required Color primaryColor,
    required ThemeMode themeMode,
    required bool use24HourClock,
    String fontFamily = AppFonts.amiri,
  }) async {
    if (!PlatformUtils.isWindows) return;
    await _installation;
    await _lock.synchronized(() async {
      final numerals = _cache?.getDataString(key: 'prayerWidgetNumerals');
      _presentation = presentationPayload(
        l10n,
        primaryColor: primaryColor,
        themeMode: themeMode,
        use24HourClock: use24HourClock,
        fontFamily: fontFamily,
        numerals:
            numerals == 'arabic' ||
                (numerals == 'auto' && l10n.localeName.startsWith('ar'))
            ? 'arabic'
            : 'western',
      );
      try {
        await _publish();
      } catch (error) {
        _recordError(error);
      }
    });
  }

  static Map<String, Object?> presentationPayload(
    AppLocalizations l10n, {
    required Color primaryColor,
    required ThemeMode themeMode,
    required bool use24HourClock,
    String numerals = 'western',
    String fontFamily = AppFonts.amiri,
  }) => {
    'locale': l10n.localeName,
    'rtl': const ['ar', 'ur'].contains(l10n.localeName.split('_').first),
    'themeMode': themeMode.name,
    'primaryColor': primaryColor.toARGB32(),
    'numerals': numerals,
    'use24HourClock': use24HourClock,
    'fontFamily': AppFonts.sanitize(fontFamily),
    'strings': {
      'prayerTimes': l10n.prayerTimes,
      'prayerSettings': l10n.macPrayerMenuSettings,
      'openHuda': l10n.windowsPrayerOpenHuda,
      'quran': l10n.quran,
      'athkar': l10n.athkar,
      'quitHuda': l10n.exitDialog,
      'needsSetup': l10n.macPrayerMenuNeedsSetup,
      'verifyLocation': l10n.macPrayerMenuVerifyLocation,
      'calendarUnavailable': l10n.windowsPrayerCalendarUnavailable,
      'noNextPrayer': l10n.windowsPrayerNoNextPrayer,
      'fajr': l10n.fajr,
      'sunrise': l10n.prayerSunriseLabel,
      'dhuhr': l10n.dhuhr,
      'asr': l10n.asr,
      'maghrib': l10n.maghrib,
      'isha': l10n.isha,
      'prayerStopAdhan': l10n.windowsPrayerStopAdhan,
      'prayerDismissFocus': l10n.windowsPrayerDismissFocus,
      'prayerFocusMessage': l10n.windowsPrayerFocusMessage,
      'prayerFocusMode': l10n.windowsPrayerFocusMode,
      'prayerFocusVerseReference': l10n.windowsPrayerFocusVerseReference,
      'prayerFocusTimeRemaining': l10n.windowsPrayerFocusTimeRemaining,
      'prayerFocusExitHint': l10n.windowsPrayerFocusExitHint,
      'prayerFocusLockedHint': l10n.windowsPrayerFocusLockedHint,
      'prayerNotificationTitle': l10n.notificationPrayerTimeTitle('{prayer}'),
      'prayerNotificationBody': l10n.notificationPrayerTimeBody('{prayer}'),
      'prayerAdvanceBody': l10n.iosPrayerAdvanceBody('{prayer}', '{minutes}'),
      'prayerNextNotification': l10n.windowsPrayerNextNotification(
        '{prayer}',
        '{duration}',
      ),
    },
  };

  static Map<String, Object?> configurationPayload({
    required int revision,
    required WindowsPrayerTaskbarPreferences preferences,
    required Map<String, Object?> presentation,
    PrayerDisplaySnapshot? display,
    DateTime? publishedAtUtc,
    WindowsPrayerExperience? prayerExperience,
    DateTime? prayerExperienceActiveFromUtc,
    Map<String, Object?>? notificationContract,
  }) {
    final location = display?.location;
    final params = display == null
        ? null
        : PrayerTimesCalculator.buildParameters(
            methodToken: display.method,
            countryCode: location!.countryCode ?? '',
            madhab: PrayerTimesCalculator.madhabFromToken(display.madhab),
            highLatitudeRule: PrayerTimesCalculator.highLatitudeRuleFromToken(
              display.highLatitude,
            ),
            customAngles: display.angles,
          );
    // Explicit keys are the wire contract; enum names are local implementation details.
    final highLatitude = switch (display?.highLatitude) {
      'middleOfTheNight' => 'middle_of_night',
      'seventhOfTheNight' => 'seventh_of_night',
      'twilightAngle' => 'twilight_angle',
      'none' => 'none',
      _ => 'automatic',
    };
    final locale = presentation['locale'] as String;
    return {
      'schemaVersion': 1,
      'revision': revision,
      'publishedAtUtc': (publishedAtUtc ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      'preferences': preferences.toMap(),
      'presentation': presentation,
      if (prayerExperience != null)
        'prayerExperience': prayerExperience.toMap(),
      if (prayerExperienceActiveFromUtc != null)
        'prayerExperienceActiveFromUtc': prayerExperienceActiveFromUtc
            .toUtc()
            .toIso8601String(),
      if (notificationContract != null)
        'notificationContract': notificationContract,
      'location': location == null
          ? null
          : {
              'revision': location.revision,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'altitude': 0,
              'timeZoneId': location.timeZoneId,
              'countryCode': location.countryCode ?? '',
              'mode': location.mode.name,
              'verified': !display!.provisional,
              'verificationReasons': location.verificationReasons,
              'locality': location.locality,
              'countryName':
                  PrayerCountryNames.localized(location.countryCode, locale) ??
                  location.countryName,
            },
      'calculation': display == null
          ? null
          : {
              'methodChoice': display.method,
              'methodKey': PrayerTimesCalculator.resolveMethod(
                display.method,
                location!.countryCode ?? '',
              ).key,
              'madhab': display.madhab == 'hanafi' ? 'hanafi' : 'shafi',
              'highLatitudeRule': highLatitude,
              'fajrAngle': params!.fajrAngle,
              'maghribIsInterval': params.maghribIsInterval,
              'maghribValue': params.maghribValue,
              'ishaIsInterval': params.ishaIsInterval,
              'ishaValue': params.ishaValue,
              'manualOffsets': PrayerTimesCalculator.sanitizeOffsets(
                display.offsets,
              ),
            },
    };
  }

  static Future<void> _publish({
    bool force = false,
    bool updateStartup = false,
  }) async {
    final presentation = _presentation;
    if (presentation == null) return;
    if (_displayLoadFailed && _display == null) {
      throw StateError('The saved prayer configuration could not be loaded.');
    }
    final content = configurationPayload(
      revision: 1,
      preferences: _preferences,
      presentation: presentation,
      display: _display,
      publishedAtUtc: DateTime.utc(2000),
      prayerExperience: experience.value,
      prayerExperienceActiveFromUtc: _experienceActiveFrom,
      notificationContract: _notificationContract,
    );
    // Repeating reminders whose toasts the companion keeps topped up.
    content['reminderRules'] = [
      for (final rule
          in _cache == null
              ? const <Map<String, Object?>>[]
              : ReminderRuleStore.read(_cache!))
        if (rule['kind'] != 'once') rule,
    ];
    final fingerprint = jsonEncode(content);
    if (!force && _published == fingerprint) return;
    _revision = PrayerDisplaySnapshot.nextRevision(_revision);
    content['revision'] = _revision;
    content['publishedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    final raw = await channel.invokeMethod<String>('publishConfiguration', {
      'json': jsonEncode(content),
      'revision': _revision,
      'enabled': _preferences.enabled,
      'startWithWindows': _preferences.enabled && _preferences.startWithWindows,
      'updateStartup': updateStartup || _published == null,
    });
    final applied = WindowsPrayerTaskbarStatus.fromMap(
      jsonDecode(raw!) as Map<String, dynamic>,
    );
    status.value = applied;
    if (applied.error != null ||
        (_preferences.enabled &&
            (!applied.running || applied.appliedRevision != _revision))) {
      throw StateError(
        applied.error ?? 'The countdown has not applied the saved revision.',
      );
    }
    _published = fingerprint;
  }

  static Future<void> refreshStatus() async {
    if (!PlatformUtils.isWindows) return;
    await _installation;
    try {
      final raw = await channel.invokeMethod<String>('getStatus');
      final refreshed = WindowsPrayerTaskbarStatus.fromMap(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      status.value = refreshed;
      if (_preferences.enabled &&
          (!refreshed.running || refreshed.appliedRevision < _revision)) {
        _recordError(
          StateError('The countdown has not applied the saved revision.'),
        );
      }
    } catch (error) {
      _recordError(error);
    }
  }

  static Future<void> openStartupSettings() =>
      channel.invokeMethod<void>('openStartupSettings');

  static void _recordError(Object error) {
    final current = status.value;
    status.value = WindowsPrayerTaskbarStatus(
      helperAvailable: current.helperAvailable,
      running: current.running,
      appliedRevision: current.appliedRevision,
      taskbarPlacement: current.taskbarPlacement,
      startupState: current.startupState,
      error: error.toString(),
      prayerAudioPlaying: current.prayerAudioPlaying,
      prayerFocusActive: current.prayerFocusActive,
      prayerFocusCanDismiss: current.prayerFocusCanDismiss,
      prayerSessionId: current.prayerSessionId,
      prayerAudioSessionId: current.prayerAudioSessionId,
      prayerAudioError: current.prayerAudioError,
      prayerQueueError: current.prayerQueueError,
      prayerToastCoverageUntilUtc: current.prayerToastCoverageUntilUtc,
    );
  }

  @visibleForTesting
  static void resetForTesting({CacheHelper? cacheHelper}) {
    _installation = null;
    _cache = cacheHelper;
    _display = null;
    _presentation = null;
    _revision = 0;
    _published = null;
    _displayLoadFailed = false;
    experience.value = const WindowsPrayerExperience();
    _experienceActiveFrom = null;
    _notificationContract = null;
    _preferences = const WindowsPrayerTaskbarPreferences();
    status.value = const WindowsPrayerTaskbarStatus();
    channel.setMethodCallHandler(null);
  }
}
