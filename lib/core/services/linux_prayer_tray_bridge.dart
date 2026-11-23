import 'dart:async';
import 'dart:convert';

import 'package:huda/core/services/prayer_iqamah_settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_rule_store.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/theme/app_theme.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_method_label.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:synchronized/synchronized.dart';

enum LinuxPrayerTrayStyle { iconOnly, iconNameCountdown, iconNameClock }

class LinuxPrayerTrayPreferences {
  const LinuxPrayerTrayPreferences({
    this.iqamahMinutes = PrayerIqamahSettings.defaults,
    this.enabled = true,
    this.startAtLogin = false,
    this.style = LinuxPrayerTrayStyle.iconNameCountdown,
  });
  final Map<String, int> iqamahMinutes;
  final bool enabled, startAtLogin;
  final LinuxPrayerTrayStyle style;
  LinuxPrayerTrayPreferences copyWith({
    Map<String, int>? iqamahMinutes,
    bool? enabled,
    bool? startAtLogin,
    LinuxPrayerTrayStyle? style,
  }) => LinuxPrayerTrayPreferences(
    iqamahMinutes: iqamahMinutes ?? this.iqamahMinutes,
    enabled: enabled ?? this.enabled,
    startAtLogin: startAtLogin ?? this.startAtLogin,
    style: style ?? this.style,
  );
  Map<String, Object> toMap() => {
    'iqamahMinutes': iqamahMinutes,
    'enabled': enabled,
    'startAtLogin': startAtLogin,
    'style': style.name,
  };
  factory LinuxPrayerTrayPreferences.fromMap(Map<dynamic, dynamic>? map) =>
      LinuxPrayerTrayPreferences(
        iqamahMinutes: PrayerIqamahSettings.sanitize(map?['iqamahMinutes']).toMap(),
        enabled: map?['enabled'] != false,
        startAtLogin: map?['startAtLogin'] == true,
        style: LinuxPrayerTrayStyle.values.firstWhere(
          (style) => style.name == map?['style'],
          orElse: () => LinuxPrayerTrayStyle.iconNameCountdown,
        ),
      );
}

class LinuxPrayerTrayStatus {
  const LinuxPrayerTrayStatus({
    this.serviceAvailable = false,
    this.extensionState = 'missing',
    this.startupEnabled = false,
    this.startupKnown = false,
    this.appliedRevision = 0,
    this.state = 'unavailable',
    this.error,
  });
  final bool serviceAvailable, startupEnabled, startupKnown;
  final String extensionState, state;
  final int appliedRevision;
  final String? error;
  factory LinuxPrayerTrayStatus.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['snapshot'];
    final snapshot = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : const <String, dynamic>{};
    return LinuxPrayerTrayStatus(
      serviceAvailable: map['serviceAvailable'] == true,
      extensionState: map['extensionState'] as String? ?? 'missing',
      startupEnabled: map['startupEnabled'] == true,
      startupKnown:
          map['startupKnown'] as bool? ?? map.containsKey('startupEnabled'),
      appliedRevision:
          (snapshot['appliedRevision'] as num?)?.toInt() ??
          (map['appliedRevision'] as num?)?.toInt() ??
          0,
      state:
          snapshot['state'] as String? ??
          map['state'] as String? ??
          'unavailable',
      error: map['error'] as String? ?? snapshot['error'] as String?,
    );
  }
}

abstract final class LinuxPrayerTrayBridge {
  static const channel = MethodChannel('com.aw.huda/linux_prayer_tray');
  /// Set once reminders or the prayer handover have turned on "Start at
  /// login", so it is never turned on again against the user's choice.
  static const reminderStartupKey = 'linux_reminder_startup_enabled_v1';
  static const preferencesKey = 'linux_prayer_tray_preferences_v1';
  static final preferences = ValueNotifier(const LinuxPrayerTrayPreferences());
  static final status = ValueNotifier(const LinuxPrayerTrayStatus());
  static final experience = ValueNotifier(const LinuxPrayerExperience());
  static Map<String, Object?>? _notificationContract;
  static final _lock = Lock();
  static CacheHelper? _cache;
  static Future<void>? _installation;
  static PrayerDisplaySnapshot? _display;
  static Map<String, Object?>? _presentation;
  static AppLocalizations? _l10n;
  static String? _published;
  static int _revision = 0;
  static bool _displayLoadFailed = false;

  static Future<void> install({
    required Future<void> Function() openSettings,
    CacheHelper? cacheHelper,
    Future<PrayerDisplaySnapshot?> Function()? loadDisplay,
  }) {
    if (!PlatformUtils.isLinux) return Future.value();
    return _installation ??= _install(
      openSettings,
      cacheHelper ?? getIt<CacheHelper>(),
      loadDisplay,
    );
  }

  static Future<void> _install(
    Future<void> Function() openSettings,
    CacheHelper cache,
    Future<PrayerDisplaySnapshot?> Function()? loadDisplay,
  ) async {
    _cache = cache;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openPrayerSettings') {
        debugPrint('Linux prayer tray: opening Prayer Settings');
        await openSettings();
      }
      if (call.method == 'notificationTapped' && call.arguments is String) {
        _tap(call.arguments as String);
      }
    });
    try {
      final bootstrap = await channel.invokeMapMethod<String, dynamic>(
        'initialize',
      );
      var restored = false;
      for (final key in ['configuration', 'configurationBackup']) {
        final raw = bootstrap?[key] as String?;
        if (raw == null || raw.isEmpty) continue;
        try {
          final saved = jsonDecode(raw) as Map<String, dynamic>;
          final revision = saved['revision'];
          if (saved['schemaVersion'] != 1 ||
              revision is! int ||
              revision <= 0 ||
              revision > 9007199254740991 ||
              saved['preferences'] is! Map) {
            continue;
          }
          _revision = revision;
          preferences.value = LinuxPrayerTrayPreferences.fromMap(
            saved['preferences'] as Map,
          );
          experience.value =
              LinuxPrayerExperience.tryParse(saved['experience']) ??
              const LinuxPrayerExperience();
          _notificationContract = saved['notificationContract'] is Map
              ? Map<String, Object?>.from(saved['notificationContract'] as Map)
              : null;
          restored = true;
          break;
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      if (!restored) {
        final local = cache.getDataString(key: preferencesKey);
        if (local != null) {
          preferences.value = LinuxPrayerTrayPreferences.fromMap(
            jsonDecode(local) as Map,
          );
        }
      }
      if (cache.getDataString(key: PrayerIqamahSettings.cacheKey) == null) {
        await PrayerIqamahSettings.sanitize(
          preferences.value.iqamahMinutes,
        ).save(cache);
      }
      preferences.value = preferences.value.copyWith(
        iqamahMinutes: PrayerIqamahSettings.fromCache(cache).toMap(),
      );
      try {
        _display =
            await (loadDisplay?.call() ??
                PrayerLocationRepository(
                  cacheHelper: cache,
                ).readCommittedDisplay());
      } catch (_) {
        _displayLoadFailed = true;
      }
      if (bootstrap != null) {
        status.value = LinuxPrayerTrayStatus.fromMap(bootstrap);
      }
    } catch (error) {
      _recordError(error);
    } finally {
      // Navigation readiness does not depend on configuration or service availability.
      try {
        await channel.invokeMethod<void>('ready');
      } catch (error) {
        _recordError(error);
      }
    }
  }

  static void Function(String payload)? _tapHandler;
  static String? _pendingTap;

  /// Opens the page of a clicked companion notification. A tap that arrives
  /// before [onNotificationTap] is set (the one that launched Huda) waits.
  static void onNotificationTap(void Function(String payload) handler) {
    _tapHandler = handler;
    final pending = _pendingTap;
    _pendingTap = null;
    if (pending != null) handler(pending);
  }

  static void _tap(String payload) {
    final handler = _tapHandler;
    if (handler == null) {
      _pendingTap = payload;
    } else {
      handler(payload);
    }
  }

  /// Starts the companion if it isn't running (the Snap: D-Bus activation).
  static Future<void> ensureService() async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    final raw = await channel.invokeMapMethod<String, dynamic>('ensureService');
    if (raw != null) status.value = LinuxPrayerTrayStatus.fromMap(raw);
    if (raw?['error'] != null) throw StateError(raw!['error'] as String);
  }

  /// The first time reminders or prayers need the companion, "Start at login"
  /// is turned on so they keep arriving after a restart, as on Windows
  /// (README decision 3). This happens once: a user who turns it off keeps
  /// that choice. Returns whether the preference changed.
  static Future<bool> enableStartupOnce() async {
    final cache = _cache;
    if (cache == null || cache.getData(key: reminderStartupKey) == true) {
      return false;
    }
    var changed = false;
    if (!preferences.value.startAtLogin) {
      final next = preferences.value.copyWith(startAtLogin: true);
      changed = await cache.saveData(
        key: preferencesKey,
        value: jsonEncode(next.toMap()),
      );
      if (changed) preferences.value = next;
    }
    await cache.saveData(key: reminderStartupKey, value: true);
    return changed;
  }

  static Future<void> refreshStatus() async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>('getStatus');
      if (raw != null) status.value = LinuxPrayerTrayStatus.fromMap(raw);
    } catch (error) {
      _recordError(error);
    }
  }

  /// The host runs this bundled installer; the Snap never writes Shell files.
  static Future<String?> installationCommand() async {
    if (!PlatformUtils.isLinux) return null;
    try {
      final info = await channel.invokeMapMethod<String, dynamic>(
        'getSetupInfo',
      );
      final command = info?['installCommand'];
      return command is String && command.isNotEmpty ? command : null;
    } catch (_) {
      return null; // Older/incomplete bundles can use the release ZIP instructions.
    }
  }

  static Future<void> setPreferences(LinuxPrayerTrayPreferences next) async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    next = next.copyWith(
      iqamahMinutes: PrayerIqamahSettings.fromCache(_cache ?? getIt<CacheHelper>()).toMap(),
    );
    if (next.startAtLogin &&
        experience.value.configured &&
        !experience.value.backgroundEnabled) {
      await applyExperience(
        experience.value.copyWith(backgroundEnabled: true),
        startAtLogin: true,
      );
    }
    await _lock.synchronized(() async {
      final old = preferences.value;
      preferences.value = next;
      try {
        await _publish(force: true, updateStartup: true);
        await _cache?.saveData(
          key: preferencesKey,
          value: jsonEncode(next.toMap()),
        );
      } catch (error) {
        preferences.value = old;
        try {
          await _publish(force: true, updateStartup: true);
        } catch (_) {
          // A repeated native failure is still reported; the old choice is republished durably.
        }
        _recordError(error);
        rethrow;
      }
    });
  }

  /// Reminders, random Athkar and calendar events the companion delivers.
  static List<Map<String, Object?>> _reminderRules() =>
      _cache == null ? const [] : ReminderRuleStore.read(_cache!);

  /// Publishes the reminder rules saved in [ReminderRuleStore]. Rules are
  /// published with every later configuration too, so false only means the
  /// companion has not accepted them yet.
  static Future<bool> publishReminderRules() async {
    if (!PlatformUtils.isLinux || _installation == null) return false;
    await _installation;
    return _lock.synchronized(() async {
      try {
        final startup =
            _reminderRules().isNotEmpty && await enableStartupOnce();
        await _publish(force: startup, updateStartup: startup);
        return true;
      } catch (error) {
        _recordError(error);
        return false;
      }
    });
  }

  static Future<void> publishIqamah(PrayerIqamahSettings settings) async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    await _lock.synchronized(() async {
      preferences.value = preferences.value.copyWith(iqamahMinutes: settings.toMap());
      await _publish(force: true);
    });
  }

  static Future<void> publishDisplay(PrayerDisplaySnapshot display) async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    await _lock.synchronized(() async {
      final previous = _display;
      if (previous != null &&
          (display.location.revision < previous.location.revision ||
              (display.location.revision == previous.location.revision &&
                  display.revision < previous.revision))) {
        return;
      }
      _display = display;
      _displayLoadFailed = false;
      await _publish();
    });
  }

  static Future<void> syncPresentation(
    AppLocalizations l10n, {
    required ThemeMode themeMode,
    required AppColorTheme colorTheme,
    required String fontFamily,
    required double textScale,
    required bool use24HourClock,
    required String numerals,
  }) async {
    if (!PlatformUtils.isLinux) return;
    await _installation;
    await _lock.synchronized(() async {
      _l10n = l10n;
      _presentation = presentationPayload(
        l10n,
        themeMode: themeMode,
        colorTheme: colorTheme,
        fontFamily: fontFamily,
        textScale: textScale,
        use24HourClock: use24HourClock,
        numerals: numerals,
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
    required ThemeMode themeMode,
    required AppColorTheme colorTheme,
    required String fontFamily,
    required double textScale,
    required bool use24HourClock,
    required String numerals,
  }) {
    Map<String, String> tokens(ThemeData theme) {
      final palette = PrayerPalette.fromTheme(theme);
      String css(Color color) {
        final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
        return '#${argb.substring(2)}${argb.substring(0, 2)}';
      }

      return {
        'surface': css(palette.page),
        'card': css(palette.card),
        'primary': css(palette.primary),
        'ink': css(palette.ink),
        'muted': css(palette.muted),
        'faint': css(palette.faint),
        'border': css(palette.border),
        'divider': css(palette.divider),
        'highlight': css(palette.tintStrong),
        'warning': css(palette.warning),
        'error': css(palette.error),
        'success': css(palette.success),
      };
    }

    return {
      'locale': l10n.localeName.split('_').first,
      'rtl': ['ar', 'ur'].contains(l10n.localeName.split('_').first),
      'themeMode': themeMode.name,
      'fontFamily': AppFonts.sanitize(fontFamily),
      'textScale': textScale.isFinite ? textScale.clamp(0.5, 2.0) : 1.0,
      'use24HourClock': use24HourClock,
      'numerals': numerals,
      'tokens': {
        'light': tokens(AppThemeHelper.getLightTheme(colorTheme, fontFamily)),
        'dark': tokens(AppThemeHelper.getDarkTheme(colorTheme, fontFamily)),
      },
      'strings': {
        'fajr': l10n.fajr,
        'sunrise': l10n.prayerSunriseLabel,
        'dhuhr': l10n.dhuhr,
        'asr': l10n.asr,
        'maghrib': l10n.maghrib,
        'isha': l10n.isha,
        'prayerTimes': l10n.prayerTimes,
        'prayerSettings': l10n.macPrayerMenuSettings,
        'openHuda': l10n.windowsPrayerOpenHuda,
        'quitHuda': l10n.macPrayerMenuQuit,
        'quitExplanation': l10n.linuxPrayerTrayQuitExplanation,
        'needsSetup': l10n.macPrayerMenuNeedsSetup,
        'verifyLocation': l10n.macPrayerMenuVerifyLocation,
        'calendarUnavailable': l10n.windowsPrayerCalendarUnavailable,
        'noNextPrayer': l10n.windowsPrayerNoNextPrayer,
        'serviceUnavailable': l10n.linuxPrayerTrayServiceUnavailable,
        'calculationUnavailable': l10n.linuxPrayerTrayCalculationUnavailable,
        'nameCountdown': l10n.macPrayerMenuNameCountdown('{prayer}', '{time}'),
        'nameElapsed': l10n.macPrayerMenuNameElapsed('{prayer}', '{time}'),
        'current': l10n.prayerHeroStarted,
        'nextPrayer': l10n.nextPrayer,
        'prayerAdvanceBody': l10n.iosPrayerAdvanceBody('{prayer}', '{minutes}'),
        'hourUnit': l10n.macPrayerMenuHourShort,
        'minuteUnit': l10n.macPrayerMenuMinuteShort,
        'stop': l10n.windowsPrayerStopAdhan,
        'dismiss': l10n.windowsPrayerDismissFocus,
        'emergencyExit': l10n.macPrayerEmergencyExit,
        'focusMessage': l10n.windowsPrayerFocusMessage,
        'verse': l10n.macPrayerVerse,
        'verseReference': l10n.windowsPrayerFocusVerseReference,
        'remaining': l10n.windowsPrayerFocusTimeRemaining,
        'lockedHint': l10n.linuxPrayerExperienceCommitmentInfo,
        'nativeQuitExplanation': l10n.linuxPrayerExperienceQuitInfo,
        for (final entry in {
          'fajr': l10n.fajr,
          'dhuhr': l10n.dhuhr,
          'asr': l10n.asr,
          'maghrib': l10n.maghrib,
          'isha': l10n.isha,
        }.entries) ...{
          '${entry.key}Title': l10n.notificationPrayerTimeTitle(entry.value),
          '${entry.key}Body': l10n.notificationPrayerTimeBody(entry.value),
        },
      },
    };
  }

  static Map<String, Object?> configurationPayload({
    required int revision,
    required LinuxPrayerTrayPreferences preferences,
    required Map<String, Object?> presentation,
    PrayerDisplaySnapshot? display,
    DateTime? publishedAtUtc,
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
    return {
      'schemaVersion': 1,
      'revision': revision,
      'publishedAtUtc': (publishedAtUtc ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      'preferences': preferences.toMap(),
      'presentation': presentation,
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
                  PrayerCountryNames.localized(
                    location.countryCode,
                    presentation['locale'] as String,
                  ) ??
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
              'highLatitudeRule': switch (display.highLatitude) {
                'middleOfTheNight' => 'middle_of_night',
                'seventhOfTheNight' => 'seventh_of_night',
                'twilightAngle' => 'twilight_angle',
                'none' => 'none',
                _ => 'automatic',
              },
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
    if (_presentation == null) return;
    if (_displayLoadFailed && _display == null) {
      throw StateError('Saved location unavailable');
    }
    final presentation = {
      ..._presentation!,
      'methodLabel': _display == null || _l10n == null
          ? ''
          : prayerCalendarMethodLabel(_l10n!, _display!.method),
    };
    final content = configurationPayload(
      revision: 1,
      preferences: preferences.value,
      presentation: presentation,
      display: _display,
      publishedAtUtc: DateTime.utc(2000),
    );
    if (experience.value.configured) {
      content['experience'] = experience.value.toMap();
      content['notificationContract'] = _notificationContract;
    }
    content['reminderRules'] = _reminderRules();
    final fingerprint = jsonEncode(content);
    if (!force && fingerprint == _published) return;
    _revision = PrayerDisplaySnapshot.nextRevision(_revision);
    content['revision'] = _revision;
    content['publishedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    final raw = await channel
        .invokeMapMethod<String, dynamic>('publishConfiguration', {
          'json': jsonEncode(content),
          // Reminders need the companion even with the panel hidden.
          'enabled':
              preferences.value.enabled ||
              (content['reminderRules']! as List).isNotEmpty,
          'startAtLogin': preferences.value.startAtLogin,
          'updateStartup': updateStartup || _published == null,
        });
    if (raw == null) throw StateError('Tray did not acknowledge configuration');
    status.value = LinuxPrayerTrayStatus.fromMap(raw);
    if (raw['error'] != null) throw StateError(raw['error'] as String);
    // A companion that was just started reads the file a moment later.
    for (var attempt = 0;
        attempt < 10 &&
            preferences.value.enabled &&
            status.value.serviceAvailable &&
            status.value.appliedRevision < _revision;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final latest = await channel.invokeMapMethod<String, dynamic>(
        'getStatus',
      );
      if (latest != null) status.value = LinuxPrayerTrayStatus.fromMap(latest);
    }
    if (preferences.value.enabled &&
        (!status.value.serviceAvailable ||
            status.value.appliedRevision != _revision)) {
      throw StateError('Prayer display did not apply the published revision');
    }
    _published = fingerprint;
  }

  /// Prepare/activate happens in the native bridge. Only a matching native receipt
  /// may change these applied settings; ordinary display publication retains them.
  static Future<Map<String, dynamic>> applyExperience(
    LinuxPrayerExperience next, {
    required bool startAtLogin,
    PrayerScheduleConfiguration? schedule,
    int? scheduleRevision,
    DateTime? cutover,
    Iterable<int> handledOccurrences = const [],
  }) async {
    await _installation;
    return _lock.synchronized(() async {
      if (_presentation == null || _display == null && schedule == null) {
        throw StateError('Committed location and presentation are required.');
      }
      final display = schedule == null
          ? _display!
          : PrayerDisplaySnapshot(
              location: schedule.location,
              method: schedule.methodToken,
              madhab: schedule.madhabToken,
              highLatitude: schedule.highLatitudeRuleToken,
              angles: schedule.customAngles,
              offsets: schedule.offsets,
              revision: scheduleRevision!,
            );
      final configuration =
          schedule ??
          PrayerScheduleConfiguration.fromDisplay(
            display,
            deviceTimeZoneId: display.location.timeZoneId,
            localeCode: _presentation!['locale'] as String,
          );
      _revision = PrayerDisplaySnapshot.nextRevision(_revision);
      final contract = <String, Object?>{
        'locationRevision': display.location.revision,
        'scheduleRevision':
            scheduleRevision ??
            _notificationContract?['scheduleRevision'] ??
            _revision,
        'configurationSignature': configuration
            .withLinuxExperience(next)
            .signature,
      };
      final prefs = preferences.value.copyWith(startAtLogin: startAtLogin);
      final presentation = {
        ..._presentation!,
        'methodLabel': _l10n == null
            ? ''
            : prayerCalendarMethodLabel(_l10n!, display.method),
      };
      final content =
          configurationPayload(
              revision: _revision,
              preferences: prefs,
              presentation: presentation,
              display: display,
            )
            ..['experience'] = next.toMap()
            ..['notificationContract'] = contract
            ..['handledOccurrenceIds'] = handledOccurrences
                .toSet()
                .take(2048)
                .toList()
            ..['cutoverInstantUtc'] = (cutover ?? DateTime.now())
                .toUtc()
                .toIso8601String()
            ..['reminderRules'] = _reminderRules();
      final raw = await channel
          .invokeMapMethod<String, dynamic>('applyExperience', {
            'json': jsonEncode(content),
            'enabled': prefs.enabled || _reminderRules().isNotEmpty,
            'startAtLogin': startAtLogin,
            'updateStartup':
                startAtLogin !=
                (status.value.startupKnown
                    ? status.value.startupEnabled
                    : preferences.value.startAtLogin),
          })
          .timeout(const Duration(seconds: 45));
      if (raw == null ||
          raw['error'] != null ||
          raw['experienceStatus'] is! String) {
        throw StateError(
          raw?['error'] as String? ?? 'Native reminder receipt unavailable.',
        );
      }
      final receipt =
          jsonDecode(raw['experienceStatus'] as String) as Map<String, dynamic>;
      if (receipt['appliedRevision'] != _revision ||
          receipt['deliveryOwner'] != 'native' ||
          receipt['locationRevision'] != contract['locationRevision'] ||
          receipt['scheduleRevision'] != contract['scheduleRevision'] ||
          receipt['configurationSignature'] !=
              contract['configurationSignature']) {
        throw StateError(
          'Native receipt does not match the requested prayer policy.',
        );
      }
      experience.value = LinuxPrayerExperience.fromMap(
        receipt['experience'] as Map,
      );
      status.value = LinuxPrayerTrayStatus.fromMap(raw);
      preferences.value = prefs;
      _notificationContract = contract;
      _display = display;
      _published = null;
      await _cache?.saveData(
        key: LinuxPrayerExperience.preferencesKey,
        value: jsonEncode(experience.value.toMap()),
      );
      await _cache?.saveData(
        key: preferencesKey,
        value: jsonEncode(prefs.toMap()),
      );
      return receipt;
    });
  }

  static Future<void> acceptExperienceReadback(
    Map<String, dynamic> receipt,
  ) async {
    if (receipt['deliveryOwner'] != 'native' || receipt['experience'] is! Map) {
      return;
    }
    final revision = (receipt['appliedRevision'] as num).toInt();
    if (revision < _revision) return;
    final accepted = LinuxPrayerExperience.fromMap(
      receipt['experience'] as Map,
    );
    final changed =
        jsonEncode(accepted.toMap()) != jsonEncode(experience.value.toMap());
    if (changed) experience.value = accepted;
    _revision = revision;
    _notificationContract = {
      'locationRevision': receipt['locationRevision'],
      'scheduleRevision': receipt['scheduleRevision'],
      'configurationSignature': receipt['configurationSignature'],
    };
    if (changed) {
      await _cache?.saveData(
        key: LinuxPrayerExperience.preferencesKey,
        value: jsonEncode(accepted.toMap()),
      );
    }
  }

  static void _recordError(Object error) {
    debugPrint('Linux prayer tray: $error');
    final previous = status.value;
    status.value = LinuxPrayerTrayStatus(
      serviceAvailable: previous.serviceAvailable,
      extensionState: previous.extensionState,
      startupEnabled: previous.startupEnabled,
      startupKnown: previous.startupKnown,
      appliedRevision: previous.appliedRevision,
      state: previous.state,
      error: error.toString(),
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _installation = null;
    _cache = null;
    _display = null;
    _presentation = null;
    _l10n = null;
    _published = null;
    _revision = 0;
    _displayLoadFailed = false;
    _notificationContract = null;
    experience.value = const LinuxPrayerExperience();
    preferences.value = const LinuxPrayerTrayPreferences();
    status.value = const LinuxPrayerTrayStatus();
    _tapHandler = null;
    _pendingTap = null;
    channel.setMethodCallHandler(null);
  }
}
