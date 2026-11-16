import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:huda/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localized reminder text. [load] works in any isolate, so startup restore
/// and background renewal schedule the same text as the settings page.
class ReminderNotificationContent {
  const ReminderNotificationContent({
    required this.kahfTitle,
    required this.kahfBody,
    required this.morningTitle,
    required this.morningBody,
    required this.eveningTitle,
    required this.eveningBody,
    required this.quranTitle,
    required this.quranBody,
    required this.checklistTitle,
    required this.checklistBody,
    required this.khatmaTitle,
    required this.khatmaBody,
    required this.randomAthkarTitle,
  });

  factory ReminderNotificationContent.of(AppLocalizations l10n) =>
      ReminderNotificationContent(
        kahfTitle: l10n.notificationKahfTitle,
        kahfBody: l10n.notificationKahfBody,
        morningTitle: l10n.notificationMorningAthkarTitle,
        morningBody: l10n.notificationMorningAthkarBody,
        eveningTitle: l10n.notificationEveningAthkarTitle,
        eveningBody: l10n.notificationEveningAthkarBody,
        quranTitle: l10n.notificationQuranTitle,
        quranBody: l10n.notificationQuranBody,
        checklistTitle: l10n.notificationChecklistTitle,
        checklistBody: l10n.notificationChecklistBody,
        khatmaTitle: l10n.notificationKhatmaTitle,
        khatmaBody: l10n.notificationKhatmaBody,
        randomAthkarTitle: l10n.notificationRandomAthkarTitle,
      );

  /// Uses the app language saved by the localization cubit.
  static Future<ReminderNotificationContent> load() async =>
      ReminderNotificationContent.of(await loadLocalizations());

  static Future<AppLocalizations> loadLocalizations() async {
    String? code;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      code =
          preferences.getString('app_locale') ??
          preferences.getString('locale');
    } catch (error) {
      debugPrint('Reminder language unavailable: $error');
    }
    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == code,
    );
    return lookupAppLocalizations(Locale(supported ? code! : 'en'));
  }

  final String kahfTitle;
  final String kahfBody;
  final String morningTitle;
  final String morningBody;
  final String eveningTitle;
  final String eveningBody;
  final String quranTitle;
  final String quranBody;
  final String checklistTitle;
  final String checklistBody;
  final String khatmaTitle;
  final String khatmaBody;
  final String randomAthkarTitle;
}
