import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/cache/cache_helper.dart';

enum HijriAdjustmentChoice {
  automatic,
  plusTwo,
  plusOne,
  none,
  minusOne,
  minusTwo;

  bool get isAutomatic => this == HijriAdjustmentChoice.automatic;

  DayAdjustment get dayAdjustment => switch (this) {
        HijriAdjustmentChoice.automatic => DayAdjustment.none,
        HijriAdjustmentChoice.plusTwo => DayAdjustment.plusTwo,
        HijriAdjustmentChoice.plusOne => DayAdjustment.plusOne,
        HijriAdjustmentChoice.none => DayAdjustment.none,
        HijriAdjustmentChoice.minusOne => DayAdjustment.minusOne,
        HijriAdjustmentChoice.minusTwo => DayAdjustment.minusTwo,
      };

  String get label => switch (this) {
        HijriAdjustmentChoice.automatic => 'auto',
        HijriAdjustmentChoice.plusTwo => '+2',
        HijriAdjustmentChoice.plusOne => '+1',
        HijriAdjustmentChoice.none => '0',
        HijriAdjustmentChoice.minusOne => '-1',
        HijriAdjustmentChoice.minusTwo => '-2',
      };

  static HijriAdjustmentChoice? fromStorage(String? value) {
    for (final choice in values) {
      if (choice.name == value) return choice;
    }
    return null;
  }
}

class HijriCalendarService extends ChangeNotifier {
  HijriCalendarService({
    required CacheHelper cache,
    VerifiedMonthStartProvider? automaticProvider,
    DateTime Function()? now,
  })  : _cache = cache,
        _automaticProvider =
            automaticProvider ?? OfficialUmmAlQuraTodayProvider(),
        _now = now ?? DateTime.now {
    _calendar = UmmAlQuraCalendar();
  }

  static const automaticRefreshInterval = Duration(days: 7);
  static const _adjustmentKey = 'hijri_calendar_adjustment_v1';
  static const _verificationCacheKey = 'hijri_calendar_verification_v1';

  final CacheHelper _cache;
  final VerifiedMonthStartProvider _automaticProvider;
  final DateTime Function() _now;
  late UmmAlQuraCalendar _calendar;
  HijriAdjustmentChoice? _choice;
  Future<void>? _initialization;
  Future<VerificationRefreshResult>? _refresh;

  UmmAlQuraCalendar get calendar => _calendar;
  HijriAdjustmentChoice? get adjustmentChoice => _choice;
  bool get hasAdjustmentChoice => _choice != null;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    _choice = HijriAdjustmentChoice.fromStorage(
      _cache.getDataString(key: _adjustmentKey),
    );
    await _rebuildCalendar(loadAutomaticCache: _choice?.isAutomatic ?? false);
  }

  Future<void> setAdjustmentChoice(HijriAdjustmentChoice choice) async {
    await initialize();
    await _cache.saveData(key: _adjustmentKey, value: choice.name);
    _choice = choice;
    await _rebuildCalendar(loadAutomaticCache: choice.isAutomatic);
    notifyListeners();

    if (choice.isAutomatic) {
      await refreshAutomaticAdjustmentIfDue();
    }
  }

  Future<VerificationRefreshResult> refreshAutomaticAdjustmentIfDue() async {
    await initialize();
    if (_choice?.isAutomatic != true) {
      return const VerificationRefreshResult(
        status: VerificationRefreshStatus.disabled,
      );
    }

    final activeRefresh = _refresh;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _calendar.refreshIfDue(_now().toUtc());
    _refresh = refresh;
    try {
      final result = await refresh;
      if (result.status == VerificationRefreshStatus.refreshed) {
        notifyListeners();
      }
      return result;
    } finally {
      _refresh = null;
    }
  }

  HijriDate toHijri(DateTime date) => _calendar.toHijriDateTime(date).date;

  DateTime toGregorian(HijriDate date) {
    final gregorian = _calendar.toGregorian(date).date;
    return DateTime(gregorian.year, gregorian.month, gregorian.day);
  }

  int daysInMonth(int year, int month) => _calendar.daysInMonth(year, month);

  static String eventKey(HijriDate date) =>
      '${date.day}/${date.month}/${date.year}';

  Future<void> _rebuildCalendar({required bool loadAutomaticCache}) async {
    final automatic = _choice?.isAutomatic ?? false;
    _calendar = UmmAlQuraCalendar(
      dayAdjustment: _choice?.dayAdjustment ?? DayAdjustment.none,
      verificationSettings: VerificationSettings(
        enabled: automatic,
        refreshInterval: automatic ? automaticRefreshInterval : null,
      ),
      verifiedMonthStartProvider: automatic ? _automaticProvider : null,
      verifiedCalendarStore: _SharedPreferencesVerifiedCalendarStore(
        cache: _cache,
        cacheKey: _verificationCacheKey,
      ),
    );

    if (loadAutomaticCache) {
      await _calendar.loadCachedVerification();
    }
  }

  @override
  void dispose() {
    final provider = _automaticProvider;
    if (provider is OfficialUmmAlQuraTodayProvider) {
      provider.close();
    }
    super.dispose();
  }
}

class _SharedPreferencesVerifiedCalendarStore implements VerifiedCalendarStore {
  const _SharedPreferencesVerifiedCalendarStore({
    required CacheHelper cache,
    required String cacheKey,
  })  : _cache = cache,
        _cacheKey = cacheKey;

  final CacheHelper _cache;
  final String _cacheKey;

  @override
  Future<VerifiedCalendarCache?> read() async {
    final raw = _cache.getDataString(key: _cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final rawStarts = json['monthStarts'];
      if (rawStarts is! List) return null;

      return VerifiedCalendarCache(
        lastCheckedAt: _parseDateTime(json['lastCheckedAt']),
        monthStarts: rawStarts.map((entry) {
          final value = Map<String, dynamic>.from(entry as Map);
          return VerifiedMonthStart(
            month: HijriMonth(
              value['hijriYear'] as int,
              value['hijriMonth'] as int,
            ),
            startsOn: GregorianDate(
              value['gregorianYear'] as int,
              value['gregorianMonth'] as int,
              value['gregorianDay'] as int,
            ),
            authority: value['authority'] as String,
            verifiedAt: DateTime.parse(value['verifiedAt'] as String),
          );
        }),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(VerifiedCalendarCache cache) async {
    final encoded = jsonEncode(<String, Object?>{
      'lastCheckedAt': cache.lastCheckedAt?.toIso8601String(),
      'monthStarts': cache.monthStarts
          .map(
            (start) => <String, Object>{
              'hijriYear': start.month.year,
              'hijriMonth': start.month.month,
              'gregorianYear': start.startsOn.year,
              'gregorianMonth': start.startsOn.month,
              'gregorianDay': start.startsOn.day,
              'authority': start.authority,
              'verifiedAt': start.verifiedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    });
    await _cache.saveData(key: _cacheKey, value: encoded);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
