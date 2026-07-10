import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/app.dart';

class QuickActionsService {
  static const QuickActions _quickActions = QuickActions();

  static const String _quranAction = 'action_quran';
  static const String _prayerTimeAction = 'action_prayer_time';
  static const String _athkarAction = 'action_athkar';
  static const String _androidNoActivityError =
      'quick_action_getlaunchaction_no_activity';

  static Future<void>? _initializing;
  static bool _initialized = false;
  static Locale? _lastShortcutLocale;

  static void initialize() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _initializing ??= _initialize();
    unawaited(_initializing);
  }

  static Future<void> _initialize() async {
    try {
      await _quickActions.initialize((String shortcutType) {
        _handleQuickAction(shortcutType);
      });
      _initialized = true;
    } on PlatformException catch (e) {
      if (_isAndroidNoActivityError(e)) {
        debugPrint('QuickActions initialize skipped: ${e.code}');
      } else {
        debugPrint('QuickActions initialize failed: $e');
      }
    } catch (e) {
      debugPrint('QuickActions initialize failed: $e');
    } finally {
      if (!_initialized) {
        _initializing = null;
      }
    }
  }

  static void updateLocalizedLabels(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final locale = Localizations.localeOf(context);
    if (_lastShortcutLocale == locale) return;

    initialize();

    unawaited(_setShortcutItems(locale, <ShortcutItem>[
      ShortcutItem(
        type: _quranAction,
        localizedTitle: localizations.quran,
        icon: Platform.isAndroid ? 'quranicon' : 'QuranIcon',
      ),
      ShortcutItem(
        type: _prayerTimeAction,
        localizedTitle: localizations.prayerTimes,
        icon: Platform.isAndroid ? 'prayertimeicon' : 'PrayerTimeIcon',
      ),
      ShortcutItem(
        type: _athkarAction,
        localizedTitle: localizations.athkar,
        icon: Platform.isAndroid ? 'athkaricon' : 'AthkarIcon',
      ),
    ]));
  }

  static Future<void> _setShortcutItems(
    Locale locale,
    List<ShortcutItem> items,
  ) async {
    try {
      await _quickActions.setShortcutItems(items);
      _lastShortcutLocale = locale;
    } catch (e) {
      debugPrint('QuickActions setShortcutItems skipped: $e');
    }
  }

  static bool _isAndroidNoActivityError(PlatformException error) {
    return Platform.isAndroid && error.code == _androidNoActivityError;
  }

  static void _handleQuickAction(String shortcutType) {
    final navigator = App.navigatorKey.currentState;
    if (navigator == null) return;

    switch (shortcutType) {
      case _quranAction:
        navigator.pushNamed(AppRoute.homeQuran);
        break;
      case _prayerTimeAction:
        navigator.pushNamed(AppRoute.prayerTimes);
        break;
      case _athkarAction:
        navigator.pushNamed(AppRoute.athkar);
        break;
    }
  }
}
