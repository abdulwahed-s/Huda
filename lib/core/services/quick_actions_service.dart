import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/app.dart';

class QuickActionsService {
  static const QuickActions _quickActions = QuickActions();

  static const String _quranAction = 'action_quran';
  static const String _prayerTimeAction = 'action_prayer_time';
  static const String _athkarAction = 'action_athkar';

  static void initialize() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _quickActions.initialize((String shortcutType) {
      _handleQuickAction(shortcutType);
    });
  }

  static void updateLocalizedLabels(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    _quickActions.setShortcutItems(<ShortcutItem>[
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
    ]);
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
