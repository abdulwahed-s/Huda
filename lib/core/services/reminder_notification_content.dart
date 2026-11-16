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
    this.randomAthkarTexts = arabicAthkarTexts,
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
        randomAthkarTexts: _athkarTexts(l10n),
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
  final List<String> randomAthkarTexts;

  static const arabicAthkarTexts = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    'رَبِّ زِدْنِي عِلْمًا',
    'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
  ];

  /// Isolate each line's direction so Arabic and the translated meaning keep
  /// their own punctuation order in native notification renderers.
  static List<String> _athkarTexts(AppLocalizations l10n) {
    if (l10n.localeName.split(RegExp('[-_]')).first == 'ar') {
      return arabicAthkarTexts;
    }
    final meanings = [
      l10n.notificationAthkarMeaning01,
      l10n.notificationAthkarMeaning02,
      l10n.notificationAthkarMeaning03,
      l10n.notificationAthkarMeaning04,
      l10n.notificationAthkarMeaning05,
      l10n.notificationAthkarMeaning06,
      l10n.notificationAthkarMeaning07,
      l10n.notificationAthkarMeaning08,
      l10n.notificationAthkarMeaning09,
      l10n.notificationAthkarMeaning10,
      l10n.notificationAthkarMeaning11,
      l10n.notificationAthkarMeaning12,
      l10n.notificationAthkarMeaning13,
      l10n.notificationAthkarMeaning14,
      l10n.notificationAthkarMeaning15,
      l10n.notificationAthkarMeaning16,
      l10n.notificationAthkarMeaning17,
      l10n.notificationAthkarMeaning18,
      l10n.notificationAthkarMeaning19,
      l10n.notificationAthkarMeaning20,
    ];
    return List.unmodifiable([
      for (var i = 0; i < arabicAthkarTexts.length; i++)
        '\u2067${arabicAthkarTexts[i]}\u2069\n\u2068${meanings[i]}\u2069',
    ]);
  }
}
