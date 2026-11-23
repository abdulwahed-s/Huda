import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ms'),
    Locale('ru'),
    Locale('tr'),
    Locale('ur'),
  ];

  /// Title of the update-available dialog
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// Body shown in the update dialog when the store provides no release notes
  ///
  /// In en, this message translates to:
  /// **'A new version of Huda is available with the latest features and improvements.'**
  String get updateAvailableBody;

  /// Primary button that opens the store to update the app
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// Secondary button to dismiss the update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Title of the update-source chooser
  ///
  /// In en, this message translates to:
  /// **'Choose where to update'**
  String get chooseUpdateSource;

  /// Name of the F-Droid app store
  ///
  /// In en, this message translates to:
  /// **'F-Droid'**
  String get fdroidStore;

  /// Description of the F-Droid update source
  ///
  /// In en, this message translates to:
  /// **'Open Huda\'s official F-Droid package page'**
  String get fdroidUpdateSourceDescription;

  /// Title of the FOSS crash-reporting consent dialog
  ///
  /// In en, this message translates to:
  /// **'Help improve Huda?'**
  String get crashReportingConsentTitle;

  /// Explanation shown before enabling FOSS crash reporting
  ///
  /// In en, this message translates to:
  /// **'Share automatic crash reports to help us find and fix problems in the FOSS edition.'**
  String get crashReportingConsentDescription;

  /// Button that grants FOSS crash-reporting consent
  ///
  /// In en, this message translates to:
  /// **'Allow crash reports'**
  String get crashReportingConsentAllow;

  /// Button that declines FOSS crash-reporting consent
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get crashReportingConsentDecline;

  /// Title of the FOSS crash-reporting setting
  ///
  /// In en, this message translates to:
  /// **'Crash reporting'**
  String get crashReportingSettingsTitle;

  /// Description of the FOSS crash-reporting setting
  ///
  /// In en, this message translates to:
  /// **'Automatically send crash and device details to help improve Huda'**
  String get crashReportingSettingsDescription;

  /// Heading above the list of data included in a crash report
  ///
  /// In en, this message translates to:
  /// **'What is shared'**
  String get crashReportingSharedDataTitle;

  /// Data included in an automatic crash report
  ///
  /// In en, this message translates to:
  /// **'Crash details and stack traces, device model, manufacturer, Android version, and Huda version.'**
  String get crashReportingSharedDataDescription;

  /// Privacy reassurance in the FOSS crash-reporting consent dialog
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent until you allow it. You can change this anytime in Settings.'**
  String get crashReportingPrivacyNote;

  /// Message shown on the error screen when FOSS crash reporting is disabled
  ///
  /// In en, this message translates to:
  /// **'Automatic crash reporting is disabled. You can enable it in Settings.'**
  String get crashReportingDisabledDescription;

  /// Hint text for the city search field
  ///
  /// In en, this message translates to:
  /// **'Search city (e.g., New York)...'**
  String get searchCityHint;

  /// Empty-state hint shown before a city search is entered
  ///
  /// In en, this message translates to:
  /// **'Type a city name above'**
  String get typeCityNameHint;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Huda'**
  String get appTitle;

  /// Settings tab title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Text size setting label
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// Reset button text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// Urdu language option
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get urdu;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// Malay language option
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get malay;

  /// Bengali language option
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bengali;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// Color theme setting label
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// Prayer times screen title
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// Qiblah direction screen title
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblahDirection;

  /// Tasbih screen title
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// Hadith screen title
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadith;

  /// Hadith chapters screen title
  ///
  /// In en, this message translates to:
  /// **'Hadith Chapters'**
  String get hadithChapters;

  /// Hadith details screen title
  ///
  /// In en, this message translates to:
  /// **'Hadith Details'**
  String get hadithDetails;

  /// Books screen title
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// Bookmarks tab label
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Start button label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Stop button label
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Restart button label
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Button label for copying text
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyText;

  /// Clear all bookmarks action
  ///
  /// In en, this message translates to:
  /// **'Clear All Bookmarks'**
  String get clearAllBookmarks;

  /// Download feature coming soon message
  ///
  /// In en, this message translates to:
  /// **'Download feature coming soon!'**
  String get downloadFeatureComingSoon;

  /// Failed to share image error message
  ///
  /// In en, this message translates to:
  /// **'Failed to share image'**
  String get failedToShareImage;

  /// Add event dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// Edit event dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// Receive notification option
  ///
  /// In en, this message translates to:
  /// **'Receive Notification'**
  String get receiveNotification;

  /// Notification description
  ///
  /// In en, this message translates to:
  /// **'Get notified about this event'**
  String get getNotifiedAboutEvent;

  /// All day event option
  ///
  /// In en, this message translates to:
  /// **'All Day Event'**
  String get allDayEvent;

  /// Hijri Calendar screen title
  ///
  /// In en, this message translates to:
  /// **'Hijri Calendar'**
  String get hijriCalendar;

  /// Title of the one-time Hijri calendar adjustment dialog
  ///
  /// In en, this message translates to:
  /// **'Adjust Hijri calendar'**
  String get hijriAdjustmentTitle;

  /// Explanation shown in the one-time Hijri calendar adjustment dialog
  ///
  /// In en, this message translates to:
  /// **'Choose how Huda displays Hijri dates.'**
  String get hijriAdjustmentDescription;

  /// Tooltip for changing the Hijri calendar adjustment
  ///
  /// In en, this message translates to:
  /// **'Calendar adjustment'**
  String get hijriAdjustmentAction;

  /// Description of automatic Hijri calendar adjustment
  ///
  /// In en, this message translates to:
  /// **'Uses the official Umm al-Qura calendar.'**
  String get hijriAutomaticAdjustmentDescription;

  /// Heading for manual Hijri calendar adjustment choices
  ///
  /// In en, this message translates to:
  /// **'Manual adjustment'**
  String get hijriManualAdjustment;

  /// Description of manual Hijri calendar adjustment
  ///
  /// In en, this message translates to:
  /// **'Move the Hijri date forward or backward by up to two days.'**
  String get hijriManualAdjustmentDescription;

  /// Selected date label
  ///
  /// In en, this message translates to:
  /// **'Selected Date'**
  String get selectedDate;

  /// Message when no events exist for selected date
  ///
  /// In en, this message translates to:
  /// **'No events for this date'**
  String get noEventsForThisDate;

  /// First Islamic month
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get muharram;

  /// Second Islamic month
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get safar;

  /// Third Islamic month
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-awwal'**
  String get rabiAlAwwal;

  /// Fourth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-thani'**
  String get rabiAlThani;

  /// Fifth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Jumada al-awwal'**
  String get jumadaAlAwwal;

  /// Sixth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Jumada al-thani'**
  String get jumadaAlThani;

  /// Seventh Islamic month
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get rajab;

  /// Eighth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Sha\'ban'**
  String get shaban;

  /// Ninth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadan;

  /// Tenth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get shawwal;

  /// Eleventh Islamic month
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Qi\'dah'**
  String get dhuAlQidah;

  /// Twelfth Islamic month
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Hijjah'**
  String get dhuAlHijjah;

  /// Fifth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// Event title label
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Start time validation message
  ///
  /// In en, this message translates to:
  /// **'Start time is required'**
  String get startTimeRequired;

  /// End time validation message
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeAfterStart;

  /// Start time prefix
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPrefix;

  /// End time prefix
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endPrefix;

  /// All day time display
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get allDay;

  /// End time validation message
  ///
  /// In en, this message translates to:
  /// **'End time is required'**
  String get endTimeRequired;

  /// Notification label
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notify;

  /// Library screen title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// All tab label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Read more button text
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// Read less button text
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get readLess;

  /// Section header for audio description
  ///
  /// In en, this message translates to:
  /// **'About this Audio'**
  String get aboutThisAudio;

  /// Page label
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pageOf;

  /// First page button
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get first;

  /// Previous page button
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Last page button
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get last;

  /// Jump to page label
  ///
  /// In en, this message translates to:
  /// **'Jump to:'**
  String get jumpTo;

  /// Go button text
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// Language selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// Search languages placeholder
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get searchLanguages;

  /// Save event button text
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get saveEvent;

  /// Save changes button text
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Select button text
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Fajr prayer name
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// Dhuhr prayer name
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// Asr prayer name
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// Maghrib prayer name
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// Isha prayer name
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// Reset counter dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Counter'**
  String get resetCounter;

  /// Note type label and dialog field label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Dhikr button label in Tasbih screen
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get dhikr;

  /// Minus button label in Tasbih screen
  ///
  /// In en, this message translates to:
  /// **'Minus'**
  String get minus;

  /// Add Dhikr dialog title in Tasbih screen
  ///
  /// In en, this message translates to:
  /// **'Add Dhikr'**
  String get addDhikr;

  /// Empty state message in Tasbih screen
  ///
  /// In en, this message translates to:
  /// **'No Dhikr yet'**
  String get noDhikrYet;

  /// Text field hint in Tasbih add dhikr dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your dhikr here...'**
  String get enterDhikrHint;

  /// Vibrate mode text
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get vibrate;

  /// Silent mode text
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get silent;

  /// Tasbih: screen-reader hint on the counter; the whole counter area counts a tap
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to count'**
  String get tasbihTapToCount;

  /// Tasbih: screen-reader hint on the counter on desktop (mouse and keyboard)
  ///
  /// In en, this message translates to:
  /// **'Click or press Space to count'**
  String get tasbihClickToCount;

  /// Tasbih: title of the dhikr list (sheet and side pane)
  ///
  /// In en, this message translates to:
  /// **'Your dhikr'**
  String get tasbihYourDhikr;

  /// Tasbih: message when the dhikr list is empty
  ///
  /// In en, this message translates to:
  /// **'Add a dhikr to start counting.'**
  String get tasbihEmptyMessage;

  /// Tasbih: error when the saved dhikr list cannot be read
  ///
  /// In en, this message translates to:
  /// **'Your dhikr list couldn\'t be loaded.'**
  String get tasbihLoadError;

  /// Tasbih: shown in place of a dhikr that was just removed, next to Undo
  ///
  /// In en, this message translates to:
  /// **'Dhikr removed'**
  String get tasbihDhikrRemoved;

  /// Button that brings back something just removed
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Tasbih: reset dialog message; only the selected dhikr's count is reset
  ///
  /// In en, this message translates to:
  /// **'Its count goes back to 0. Your other dhikr keep their counts.'**
  String get tasbihResetMessage;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Open settings button text
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Title shown when compass accuracy is low
  ///
  /// In en, this message translates to:
  /// **'Compass needs calibration'**
  String get calibrateCompass;

  /// Instruction to calibrate the compass via figure-8 motion
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a figure-8 motion to improve accuracy'**
  String get calibrateCompassInstruction;

  /// Clear all confirmation button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Continue reading button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueReading;

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Huda'**
  String get huda;

  /// Widget management title
  ///
  /// In en, this message translates to:
  /// **'Widget Management'**
  String get widgetManagement;

  /// Label above the next-prayer name
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayer;

  /// Hijri date widget title
  ///
  /// In en, this message translates to:
  /// **'Hijri Date'**
  String get hijriDate;

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Today text
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Sunrise prayer time label
  ///
  /// In en, this message translates to:
  /// **'SUNRISE'**
  String get sunrise;

  /// No internet connection error title
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// Audio tab: offline and no audio downloaded
  ///
  /// In en, this message translates to:
  /// **'No internet connection. No offline audio available.'**
  String get offlineAudioUnavailable;

  /// Tafsir tab: offline and no tafsir downloaded
  ///
  /// In en, this message translates to:
  /// **'No internet connection. No offline tafsir available.'**
  String get offlineTafsirUnavailable;

  /// Translation tab: offline and no translation downloaded
  ///
  /// In en, this message translates to:
  /// **'No internet connection. No offline translation available.'**
  String get offlineTranslationUnavailable;

  /// No internet connection with settings instruction
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network settings and try again.'**
  String get noInternetSettings;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// Too many requests error message
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again later.'**
  String get tooManyRequests;

  /// Success message when tafsir is downloaded
  ///
  /// In en, this message translates to:
  /// **'Tafsir downloaded successfully!'**
  String get tafsirDownloadSuccess;

  /// Success message when translation is downloaded
  ///
  /// In en, this message translates to:
  /// **'Translation downloaded successfully!'**
  String get translationDownloadSuccess;

  /// Error message for tafsir loading
  ///
  /// In en, this message translates to:
  /// **'Tafsir error: {message}'**
  String tafsirError(String message);

  /// Error message for translation loading
  ///
  /// In en, this message translates to:
  /// **'Translation error: {message}'**
  String translationError(String message);

  /// Surat Al-Kahf title
  ///
  /// In en, this message translates to:
  /// **'Surat Al-Kahf'**
  String get suratAlKahf;

  /// Morning and evening athkar notification title
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Athkar'**
  String get morningEveningAthkar;

  /// Random athkar notification title
  ///
  /// In en, this message translates to:
  /// **'Random Athkar'**
  String get randomAthkar;

  /// Frequency in minutes
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} minutes'**
  String everyMinutes(String minutes, Object frequency);

  /// Quran reading reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Quran Reading Reminder'**
  String get quranReadingReminder;

  /// Debug button label
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// Acknowledgment button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Athkar frequency dialog title
  ///
  /// In en, this message translates to:
  /// **'Athkar Frequency'**
  String get athkarFrequency;

  /// Question in athkar frequency dialog
  ///
  /// In en, this message translates to:
  /// **'How often would you like to receive random Athkar?'**
  String get howOftenReceiveAthkar;

  /// Shown when the system did not accept a scheduled reminder
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t schedule this reminder. Please try again.'**
  String get notificationScheduleFailed;

  /// Status when notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabled;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Search bookmarks hint
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks...'**
  String get searchBookmarksHint;

  /// Chat message input hint
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessageHint;

  /// Search athkar hint
  ///
  /// In en, this message translates to:
  /// **'Search athkar...'**
  String get searchAthkarHint;

  /// Exit application dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitDialog;

  /// Exit application confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitConfirmation;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Failed to load error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// Permission denied error message
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// Book name form label
  ///
  /// In en, this message translates to:
  /// **'Book Name'**
  String get bookName;

  /// Athkar screen title
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get athkar;

  /// Number of search results found
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String searchResultsFound(int count);

  /// No results found message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Try different search terms suggestion
  ///
  /// In en, this message translates to:
  /// **'Try different search terms'**
  String get tryDifferentSearch;

  /// Welcome message for Huda AI in English
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huda AI'**
  String get welcomeToHudaAI;

  /// Introduction message explaining AI capabilities
  ///
  /// In en, this message translates to:
  /// **'Ask me any question about Islam, and I\'ll provide answers based on the Qur\'an and authentic Sunnah.'**
  String get aiIntroMessage;

  /// Verification advice
  ///
  /// In en, this message translates to:
  /// **'Always cross-check AI responses with the Qur\'an and Sunnah.'**
  String get verifySourcesSubtitle;

  /// Prompt for example questions
  ///
  /// In en, this message translates to:
  /// **'Try asking:'**
  String get tryAsking;

  /// Example question about five pillars
  ///
  /// In en, this message translates to:
  /// **'What are the five pillars of Islam?'**
  String get exampleQuestion1;

  /// Example question about prayer concentration
  ///
  /// In en, this message translates to:
  /// **'How can I improve my khushu in prayer?'**
  String get exampleQuestion2;

  /// Example question about bedtime duas
  ///
  /// In en, this message translates to:
  /// **'What should I say before going to sleep?'**
  String get exampleQuestion3;

  /// Example question about hadith
  ///
  /// In en, this message translates to:
  /// **'Tell me a hadith about kindness.'**
  String get exampleQuestion4;

  /// Loading message when AI is processing
  ///
  /// In en, this message translates to:
  /// **'Huda AI is thinking...'**
  String get hudaAIThinking;

  /// AI processing status message
  ///
  /// In en, this message translates to:
  /// **'Analyzing your question with Islamic sources'**
  String get analyzingQuestion;

  /// Disclaimer for AI generated responses
  ///
  /// In en, this message translates to:
  /// **'AI generated content. Please verify with authentic sources.'**
  String get aiGeneratedDisclaimer;

  /// Confirmation message when text is copied
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get messageCopied;

  /// App name for Huda AI
  ///
  /// In en, this message translates to:
  /// **'Huda AI'**
  String get hudaAI;

  /// Bookmark type label
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// Star type label
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// Bookmark color selection title
  ///
  /// In en, this message translates to:
  /// **'Bookmark Color'**
  String get bookmarkColor;

  /// Note section title
  ///
  /// In en, this message translates to:
  /// **'Your Note'**
  String get yourNote;

  /// Edit note button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// Add note dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// Placeholder text for note input
  ///
  /// In en, this message translates to:
  /// **'Write your personal note or reflection about this ayah...'**
  String get noteHint;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Include tafsir option
  ///
  /// In en, this message translates to:
  /// **'Include Tafsir'**
  String get includeTafsir;

  /// Generating content status
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Share as image button text
  ///
  /// In en, this message translates to:
  /// **'Share as Image'**
  String get shareAsImage;

  /// Tafsir section label
  ///
  /// In en, this message translates to:
  /// **'Tafsir:'**
  String get tafsirLabel;

  /// Tagline shown under the app name in shared images
  ///
  /// In en, this message translates to:
  /// **'Islamic Companion App'**
  String get shareImageTagline;

  /// Translation not available message
  ///
  /// In en, this message translates to:
  /// **'Translation not available'**
  String get translationNotAvailable;

  /// Tafsir not available message
  ///
  /// In en, this message translates to:
  /// **'Tafsir not available'**
  String get tafsirNotAvailable;

  /// Unknown surah name
  ///
  /// In en, this message translates to:
  /// **'Unknown Surah'**
  String get unknownSurah;

  /// Localized attribution and download link appended to all shared content
  ///
  /// In en, this message translates to:
  /// **'Shared via Huda - Islamic Companion App\nDownload Huda: http://huda.awrs.me/download'**
  String get sharedViaHuda;

  /// Success message for copy
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Unknown location text
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Ayah number format
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String ayahNumber(int number);

  /// Loading audio status
  ///
  /// In en, this message translates to:
  /// **'Loading audio...'**
  String get loadingAudio;

  /// Language filter hint
  ///
  /// In en, this message translates to:
  /// **'Filter by language'**
  String get filterByLanguage;

  /// All languages option
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get allLanguages;

  /// Unknown reader name
  ///
  /// In en, this message translates to:
  /// **'Unknown Reader'**
  String get unknownReader;

  /// Tafsir section title
  ///
  /// In en, this message translates to:
  /// **'Tafsir (Commentary)'**
  String get tafsirCommentary;

  /// Tafsir source selection hint
  ///
  /// In en, this message translates to:
  /// **'Select tafsir source'**
  String get selectTafsirSource;

  /// None option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No tafsir sources message
  ///
  /// In en, this message translates to:
  /// **'No tafsir sources available'**
  String get noTafsirAvailable;

  /// Translation section title
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// Translation source selection hint
  ///
  /// In en, this message translates to:
  /// **'Select translation source'**
  String get selectTranslationSource;

  /// No translation sources message
  ///
  /// In en, this message translates to:
  /// **'No translation sources available for selected language'**
  String get noTranslationAvailable;

  /// Translation language filter hint
  ///
  /// In en, this message translates to:
  /// **'Filter translation language'**
  String get filterTranslationLanguage;

  /// Preview label
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Audio tab label
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// Tafsir tab label
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// Share tab label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Widget tab label
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get widget;

  /// Ayah text section title
  ///
  /// In en, this message translates to:
  /// **'Ayah Text'**
  String get ayahText;

  /// Audio controls section title
  ///
  /// In en, this message translates to:
  /// **'Audio Controls'**
  String get audioControls;

  /// Reader selection section title
  ///
  /// In en, this message translates to:
  /// **'Reader Selection'**
  String get readerSelection;

  /// Audio downloads section title
  ///
  /// In en, this message translates to:
  /// **'Audio Downloads'**
  String get audioDownloads;

  /// Audio settings section title
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audioSettings;

  /// Included in all downloads status
  ///
  /// In en, this message translates to:
  /// **'Included in All'**
  String get includedInAll;

  /// Surah downloaded status
  ///
  /// In en, this message translates to:
  /// **'Surah Downloaded'**
  String get surahDownloaded;

  /// Downloading status
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Download surah button
  ///
  /// In en, this message translates to:
  /// **'Download Surah'**
  String get downloadSurah;

  /// All downloaded status
  ///
  /// In en, this message translates to:
  /// **'All Downloaded'**
  String get allDownloaded;

  /// Download all button
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// Checking status message
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// Button text for reading PDF files
  ///
  /// In en, this message translates to:
  /// **'Read PDF'**
  String get readPdf;

  /// Button text for opening files
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Book details section title
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// Attachments section title
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Offline status message
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get youreOffline;

  /// Share as PDF option
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get shareAsPdf;

  /// Share in message option
  ///
  /// In en, this message translates to:
  /// **'Share in Message'**
  String get shareInMessage;

  /// Title for the book sharing dialog
  ///
  /// In en, this message translates to:
  /// **'Share “{title}”'**
  String shareBookTitle(String title);

  /// Subject line for a shared book
  ///
  /// In en, this message translates to:
  /// **'Check out this book: {title}'**
  String shareBookSubject(String title);

  /// Progress message while preparing a PDF to share
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF for sharing...'**
  String get preparingPdfForSharing;

  /// Repeat count shown in shared Athkar text
  ///
  /// In en, this message translates to:
  /// **'Repeat count: {count}'**
  String athkarShareRepeatCount(int count);

  /// Friday schedule with time
  ///
  /// In en, this message translates to:
  /// **'Every Friday at {time}'**
  String everyFridayAtTime(String time);

  /// Kahf reminder description
  ///
  /// In en, this message translates to:
  /// **'Weekly reminder to read Surat Al-Kahf on Friday for blessings and protection.'**
  String get weeklyReminderKahf;

  /// Morning and evening athkar title
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Athkar'**
  String get morningEveningAthkarTitle;

  /// Morning evening athkar description
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for morning and evening remembrance of Allah.'**
  String get dailyRemindersAthkar;

  /// Random athkar title
  ///
  /// In en, this message translates to:
  /// **'Random Athkar'**
  String get randomAthkarTitle;

  /// Random athkar description
  ///
  /// In en, this message translates to:
  /// **'Periodic reminders with random Athkar throughout the day.'**
  String get periodicRemindersAthkar;

  /// Quran reading reminder title
  ///
  /// In en, this message translates to:
  /// **'Quran Reading Reminder'**
  String get quranReadingReminderTitle;

  /// Daily schedule at specific time
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyAtTime(String time);

  /// Quran reminder description
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to read and reflect on the Holy Quran.'**
  String get dailyReminderQuran;

  /// Minutes unit
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Minutes input example
  ///
  /// In en, this message translates to:
  /// **'e.g., 30, 60, 120'**
  String get minutesExample;

  /// Minutes unit
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// Recommended minutes range
  ///
  /// In en, this message translates to:
  /// **'Recommended: 30-120 minutes for balanced reminders'**
  String get recommendedMinutes;

  /// Valid number error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number between 10-1440 minutes'**
  String get validNumberMinutes;

  /// Quran time picker title
  ///
  /// In en, this message translates to:
  /// **'Select Quran Reminder Time'**
  String get selectQuranReminderTime;

  /// Kahf time picker title
  ///
  /// In en, this message translates to:
  /// **'Select Kahf Friday Time'**
  String get selectKahfFridayTime;

  /// Athkar times dialog title
  ///
  /// In en, this message translates to:
  /// **'Athkar Times'**
  String get athkarTimes;

  /// Morning label
  ///
  /// In en, this message translates to:
  /// **'Morning: '**
  String get morning;

  /// Evening label
  ///
  /// In en, this message translates to:
  /// **'Evening: '**
  String get evening;

  /// Morning athkar time picker title
  ///
  /// In en, this message translates to:
  /// **'Select Morning Athkar Time'**
  String get selectMorningAthkarTime;

  /// Evening athkar time picker title
  ///
  /// In en, this message translates to:
  /// **'Select Evening Athkar Time'**
  String get selectEveningAthkarTime;

  /// PDF viewer title
  ///
  /// In en, this message translates to:
  /// **'PDF Viewer'**
  String get pdfViewer;

  /// Go to page tooltip
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get goToPage;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Table of contents tab label
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get contents;

  /// Pages tab label
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// Markers tab label
  ///
  /// In en, this message translates to:
  /// **'Markers'**
  String get markers;

  /// Go to page dialog title
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get goToPageTitle;

  /// Page number input instruction
  ///
  /// In en, this message translates to:
  /// **'Enter page number (1 to {pageCount})'**
  String enterPageNumber(String pageCount);

  /// Page number input hint
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageNumber;

  /// Search input hint
  ///
  /// In en, this message translates to:
  /// **'Search in document...'**
  String get searchInDocument;

  /// Search results count
  ///
  /// In en, this message translates to:
  /// **'{current} of {total} matches'**
  String matchesCount(String current, String total);

  /// Page number label
  ///
  /// In en, this message translates to:
  /// **'Page {pageNumber}'**
  String pageLabel(String pageNumber);

  /// Empty table of contents message
  ///
  /// In en, this message translates to:
  /// **'No table of contents'**
  String get noTableOfContents;

  /// Bookmark updated success message
  ///
  /// In en, this message translates to:
  /// **'Bookmark updated'**
  String get bookmarkUpdated;

  /// Notes tab label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Stars tab label
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// Error message when bookmarks fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading bookmarks'**
  String get errorLoadingBookmarks;

  /// Empty bookmarks message
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// Empty bookmarks instruction
  ///
  /// In en, this message translates to:
  /// **'Start bookmarking your favorite verses'**
  String get startBookmarkingFavoriteVerses;

  /// Empty notes message
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// Empty notes instruction
  ///
  /// In en, this message translates to:
  /// **'Add notes to your favorite verses'**
  String get addNotesToFavoriteVerses;

  /// Empty starred verses message
  ///
  /// In en, this message translates to:
  /// **'No starred verses yet'**
  String get noStarredVersesYet;

  /// Empty starred verses instruction
  ///
  /// In en, this message translates to:
  /// **'Star your most important verses'**
  String get starImportantVerses;

  /// Browse Quran button text
  ///
  /// In en, this message translates to:
  /// **'Browse Quran'**
  String get browseQuran;

  /// Total stats label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Clear all bookmarks confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all bookmarks? This action cannot be undone.'**
  String get clearAllBookmarksConfirmation;

  /// Location label for prayer times
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Status when countdown is stopped
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// Error message when widget update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating widget: {error}'**
  String errorUpdatingWidget(String error);

  /// sahih
  ///
  /// In en, this message translates to:
  /// **'sahih'**
  String get sahih;

  /// daif
  ///
  /// In en, this message translates to:
  /// **'daif'**
  String get daif;

  /// hasan
  ///
  /// In en, this message translates to:
  /// **'hasan'**
  String get hasan;

  /// No description provided for @bukhari.
  ///
  /// In en, this message translates to:
  /// **'Sahih al-Bukhari'**
  String get bukhari;

  /// No description provided for @muslim.
  ///
  /// In en, this message translates to:
  /// **'Sahih Muslim'**
  String get muslim;

  /// No description provided for @tirmidhi.
  ///
  /// In en, this message translates to:
  /// **'Jami\' at-Tirmidhi'**
  String get tirmidhi;

  /// No description provided for @ahmad.
  ///
  /// In en, this message translates to:
  /// **'Musnad Ahmad'**
  String get ahmad;

  /// No description provided for @contains.
  ///
  /// In en, this message translates to:
  /// **'contains'**
  String get contains;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @hadithCollections.
  ///
  /// In en, this message translates to:
  /// **'Hadith Collections'**
  String get hadithCollections;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'info'**
  String get info;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'notification'**
  String get notification;

  /// No description provided for @sampleTextPreview.
  ///
  /// In en, this message translates to:
  /// **'I seek Allah’s forgiveness and turn to Him in repentance.'**
  String get sampleTextPreview;

  /// Small widget size
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get normal;

  /// Large widget size
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In en, this message translates to:
  /// **'extra large'**
  String get extraLarge;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @quranKit.
  ///
  /// In en, this message translates to:
  /// **'Quran Kit'**
  String get quranKit;

  /// No description provided for @continueHome.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueHome;

  /// Heading above the Quran reading, listening, and radio continuation controls
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get continueActivityPrompt;

  /// No description provided for @noRecentActivityHome.
  ///
  /// In en, this message translates to:
  /// **'No Recent Activity'**
  String get noRecentActivityHome;

  /// No description provided for @chooseThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme Color'**
  String get chooseThemeColor;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize your app experience'**
  String get themeDescription;

  /// No description provided for @themeInfo.
  ///
  /// In en, this message translates to:
  /// **'Your selected theme will be applied throughout the entire app experience'**
  String get themeInfo;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'purple'**
  String get purple;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get green;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get blue;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get red;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'orange'**
  String get orange;

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'teal'**
  String get teal;

  /// No description provided for @indigo.
  ///
  /// In en, this message translates to:
  /// **'indigo'**
  String get indigo;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'pink'**
  String get pink;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get yellow;

  /// No description provided for @brown.
  ///
  /// In en, this message translates to:
  /// **'brown'**
  String get brown;

  /// No description provided for @cream.
  ///
  /// In en, this message translates to:
  /// **'cream'**
  String get cream;

  /// No description provided for @goldTheme.
  ///
  /// In en, this message translates to:
  /// **'gold'**
  String get goldTheme;

  /// No description provided for @settingsPureBlack.
  ///
  /// In en, this message translates to:
  /// **'Pure black'**
  String get settingsPureBlack;

  /// No description provided for @settingsPureBlackDescription.
  ///
  /// In en, this message translates to:
  /// **'A black background in dark mode, for OLED screens'**
  String get settingsPureBlackDescription;

  /// No description provided for @supportAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportAndFeedback;

  /// No description provided for @shareYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'General Feedback'**
  String get shareYourThoughts;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Share a comment about your experience'**
  String get feedbackDescription;

  /// No description provided for @feedbackAndIssueActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback or report a problem'**
  String get feedbackAndIssueActionTitle;

  /// No description provided for @feedbackAndIssueActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem, suggest an improvement, or share a comment'**
  String get feedbackAndIssueActionSubtitle;

  /// No description provided for @rateOurApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Our App'**
  String get rateOurApp;

  /// No description provided for @rateAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Help others discover this app'**
  String get rateAppDescription;

  /// No description provided for @batteryOptimizationExemptionGranted.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization exemption granted'**
  String get batteryOptimizationExemptionGranted;

  /// No description provided for @batteryOptimizationExemptionDenied.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization exemption denied'**
  String get batteryOptimizationExemptionDenied;

  /// No description provided for @notificationsWillWorkReliably.
  ///
  /// In en, this message translates to:
  /// **'Notifications will work reliably'**
  String get notificationsWillWorkReliably;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @islamicChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Islamic Checklist'**
  String get islamicChecklistTitle;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @noTasksForDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day'**
  String get noTasksForDay;

  /// No description provided for @fajrPrayer.
  ///
  /// In en, this message translates to:
  /// **'Fajr Prayer'**
  String get fajrPrayer;

  /// No description provided for @dhuhrPrayer.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr Prayer'**
  String get dhuhrPrayer;

  /// No description provided for @asrPrayer.
  ///
  /// In en, this message translates to:
  /// **'Asr Prayer'**
  String get asrPrayer;

  /// No description provided for @maghribPrayer.
  ///
  /// In en, this message translates to:
  /// **'Maghrib Prayer'**
  String get maghribPrayer;

  /// No description provided for @ishaPrayer.
  ///
  /// In en, this message translates to:
  /// **'Isha Prayer'**
  String get ishaPrayer;

  /// No description provided for @readingQuran.
  ///
  /// In en, this message translates to:
  /// **'Reading Quran'**
  String get readingQuran;

  /// No description provided for @athkarSabah.
  ///
  /// In en, this message translates to:
  /// **'Morning Athkar'**
  String get athkarSabah;

  /// No description provided for @athkarMasaa.
  ///
  /// In en, this message translates to:
  /// **'Evening Athkar'**
  String get athkarMasaa;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyEvery2Days.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get frequencyEvery2Days;

  /// No description provided for @frequencyEvery3Days.
  ///
  /// In en, this message translates to:
  /// **'Every 3 days'**
  String get frequencyEvery3Days;

  /// No description provided for @frequencyEvery4Days.
  ///
  /// In en, this message translates to:
  /// **'Every 4 days'**
  String get frequencyEvery4Days;

  /// No description provided for @frequencyEvery5Days.
  ///
  /// In en, this message translates to:
  /// **'Every 5 days'**
  String get frequencyEvery5Days;

  /// No description provided for @frequencyEvery6Days.
  ///
  /// In en, this message translates to:
  /// **'Every 6 days'**
  String get frequencyEvery6Days;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @morningAthkar.
  ///
  /// In en, this message translates to:
  /// **'Morning Athkar'**
  String get morningAthkar;

  /// No description provided for @addCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Item'**
  String get addCustomItem;

  /// No description provided for @congratsMessage1.
  ///
  /// In en, this message translates to:
  /// **'May Allah reward you with goodness'**
  String get congratsMessage1;

  /// No description provided for @congratsMessage2.
  ///
  /// In en, this message translates to:
  /// **'May Allah bless you'**
  String get congratsMessage2;

  /// No description provided for @congratsMessage3.
  ///
  /// In en, this message translates to:
  /// **'O Allah, bless (them/it)'**
  String get congratsMessage3;

  /// No description provided for @congratsMessage4.
  ///
  /// In en, this message translates to:
  /// **'What Allah has willed (has happened)'**
  String get congratsMessage4;

  /// No description provided for @congratsMessage5.
  ///
  /// In en, this message translates to:
  /// **'All praise is due to Allah'**
  String get congratsMessage5;

  /// No description provided for @congratsMessage6.
  ///
  /// In en, this message translates to:
  /// **'Blessed is Allah'**
  String get congratsMessage6;

  /// No description provided for @congratsMessage7.
  ///
  /// In en, this message translates to:
  /// **'May Allah benefit you'**
  String get congratsMessage7;

  /// No description provided for @congratsMessage8.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get congratsMessage8;

  /// No description provided for @congratsMessage9.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept (good deeds) from us and you'**
  String get congratsMessage9;

  /// No description provided for @congratsMessage10.
  ///
  /// In en, this message translates to:
  /// **'May my Lord grant you success'**
  String get congratsMessage10;

  /// No description provided for @congratsMessage11.
  ///
  /// In en, this message translates to:
  /// **'May Allah bless you'**
  String get congratsMessage11;

  /// No description provided for @congratsMessage12.
  ///
  /// In en, this message translates to:
  /// **'May Allah increase you in knowledge'**
  String get congratsMessage12;

  /// No description provided for @congratsMessage13.
  ///
  /// In en, this message translates to:
  /// **'May Allah have mercy on you'**
  String get congratsMessage13;

  /// No description provided for @islamicChecklist.
  ///
  /// In en, this message translates to:
  /// **'Islamic Checklist'**
  String get islamicChecklist;

  /// No description provided for @dailyChecklistReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Checklist Reminder'**
  String get dailyChecklistReminder;

  /// Subtitle for daily checklist reminder
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyChecklistSubtitle(String time);

  /// No description provided for @checklistReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to complete your daily Islamic checklist tasks'**
  String get checklistReminderDescription;

  /// No description provided for @selectChecklistReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Select time for checklist reminder'**
  String get selectChecklistReminderTime;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @enableNotificationsSettings.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in system settings'**
  String get enableNotificationsSettings;

  /// Title for Kahf Friday notification
  ///
  /// In en, this message translates to:
  /// **'🕌 Surat Al-Kahf Reminder'**
  String get notificationKahfTitle;

  /// Body text for Kahf Friday notification
  ///
  /// In en, this message translates to:
  /// **'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.'**
  String get notificationKahfBody;

  /// Title for morning athkar notification
  ///
  /// In en, this message translates to:
  /// **'🌅 Morning Athkar'**
  String get notificationMorningAthkarTitle;

  /// Body text for morning athkar notification
  ///
  /// In en, this message translates to:
  /// **'Start your day with morning Athkar and remembrance of Allah.'**
  String get notificationMorningAthkarBody;

  /// Title for evening athkar notification
  ///
  /// In en, this message translates to:
  /// **'🌅 Evening Athkar'**
  String get notificationEveningAthkarTitle;

  /// Body text for evening athkar notification
  ///
  /// In en, this message translates to:
  /// **'End your day with evening Athkar and gratitude to Allah.'**
  String get notificationEveningAthkarBody;

  /// Title for Quran reading notification
  ///
  /// In en, this message translates to:
  /// **'📖 Quran Reading Reminder'**
  String get notificationQuranTitle;

  /// Body text for Quran reading notification
  ///
  /// In en, this message translates to:
  /// **'Time to read some verses from the Holy Quran and reflect on its guidance.'**
  String get notificationQuranBody;

  /// Title for daily checklist notification
  ///
  /// In en, this message translates to:
  /// **'📋 Daily Checklist Reminder'**
  String get notificationChecklistTitle;

  /// Body text for daily checklist notification
  ///
  /// In en, this message translates to:
  /// **'Time to fill your daily Islamic checklist and track your spiritual progress.'**
  String get notificationChecklistBody;

  /// Title for khatma daily wird notification
  ///
  /// In en, this message translates to:
  /// **'📖 Khatma Daily Reminder'**
  String get notificationKhatmaTitle;

  /// Body text for khatma daily wird notification
  ///
  /// In en, this message translates to:
  /// **'Time to read your daily Quran wird and stay on track with your Khatma.'**
  String get notificationKhatmaBody;

  /// Title for random athkar notification
  ///
  /// In en, this message translates to:
  /// **'🤲 Random Athkar'**
  String get notificationRandomAthkarTitle;

  /// Title for prayer time notification
  ///
  /// In en, this message translates to:
  /// **'🕌 {prayerName} Prayer Time'**
  String notificationPrayerTimeTitle(String prayerName);

  /// Body for prayer time notification
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayerName} prayer. May Allah accept your prayers.'**
  String notificationPrayerTimeBody(String prayerName);

  /// Text when prayer countdown is loading
  ///
  /// In en, this message translates to:
  /// **'Loading prayer times...'**
  String get prayerCountdownLoadingText;

  /// Zakat Calculator screen title
  ///
  /// In en, this message translates to:
  /// **'Zakat Calculator'**
  String get zakatCalculator;

  /// Calculate tab title
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// Results tab title
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// Assets section title
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// Liabilities section title
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilities;

  /// Reset all button text
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// Message when zakat is due
  ///
  /// In en, this message translates to:
  /// **'Zakat is Due'**
  String get zakatIsDue;

  /// Message when no zakat is due
  ///
  /// In en, this message translates to:
  /// **'No Zakat Due'**
  String get noZakatDue;

  /// Total assets label
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// Total debts label
  ///
  /// In en, this message translates to:
  /// **'Total Debts'**
  String get totalDebts;

  /// Net assets label
  ///
  /// In en, this message translates to:
  /// **'Net Assets'**
  String get netAssets;

  /// Nisab threshold label
  ///
  /// In en, this message translates to:
  /// **'Nisab Threshold ({type})'**
  String nisabThreshold(String type);

  /// Currency label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Nisab settings section title
  ///
  /// In en, this message translates to:
  /// **'Nisab Settings'**
  String get nisabSettings;

  /// Gold price input label
  ///
  /// In en, this message translates to:
  /// **'Gold Price per Gram'**
  String get goldPricePerGram;

  /// Silver price input label
  ///
  /// In en, this message translates to:
  /// **'Silver Price per Gram'**
  String get silverPricePerGram;

  /// Nisab description text
  ///
  /// In en, this message translates to:
  /// **'Nisab is the minimum threshold of wealth that makes Zakat obligatory. It can be calculated based on either gold (87.48g) or silver (612.36g) values.'**
  String get nisabDescription;

  /// Asset breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Asset Breakdown'**
  String get assetBreakdown;

  /// Nisab calculation method selection title
  ///
  /// In en, this message translates to:
  /// **'Nisab Calculation Based On'**
  String get nisabCalculationBasedOn;

  /// Gold option
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// Silver option
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// Gold nisab amount in grams
  ///
  /// In en, this message translates to:
  /// **'87.48 grams'**
  String get goldGrams;

  /// Silver nisab amount in grams
  ///
  /// In en, this message translates to:
  /// **'612.36 grams'**
  String get silverGrams;

  /// About Zakat dialog title
  ///
  /// In en, this message translates to:
  /// **'About Zakat'**
  String get aboutZakat;

  /// Full Zakat description in info dialog
  ///
  /// In en, this message translates to:
  /// **'Zakat is one of the five pillars of Islam and is an obligatory charity. It is calculated as 2.5% of qualifying wealth that has been held for at least one lunar year (hawl).\n\nNisab is the minimum threshold of wealth that makes Zakat obligatory. It can be calculated based on either:\n• Gold: 87.48 grams (20 mithqal)\n• Silver: 612.36 grams (200 dirhams)\n\nThis calculator helps you determine if your wealth reaches the nisab threshold and calculates the exact amount of Zakat due.'**
  String get zakatDescription;

  /// Cash and bank balances asset category
  ///
  /// In en, this message translates to:
  /// **'Cash & Bank Balances'**
  String get cashAndBankBalances;

  /// Gold asset category
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get goldAssets;

  /// Silver asset category
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silverAssets;

  /// Business assets category
  ///
  /// In en, this message translates to:
  /// **'Business Assets'**
  String get businessAssets;

  /// Investments asset category
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get investmentsAssets;

  /// Receivables asset category
  ///
  /// In en, this message translates to:
  /// **'Money Owed to You'**
  String get moneyOwedToYou;

  /// Debts and liabilities category
  ///
  /// In en, this message translates to:
  /// **'Debts & Liabilities'**
  String get debtsAndLiabilities;

  /// Cash asset category description
  ///
  /// In en, this message translates to:
  /// **'Savings accounts, checking accounts, cash on hand, digital wallets'**
  String get cashDescription;

  /// Gold asset category description
  ///
  /// In en, this message translates to:
  /// **'Value of gold jewelry, coins, and bars (market value)'**
  String get goldDescription;

  /// Silver asset category description
  ///
  /// In en, this message translates to:
  /// **'Value of silver jewelry, coins, and bars (market value)'**
  String get silverDescription;

  /// Business assets category description
  ///
  /// In en, this message translates to:
  /// **'Inventory, business cash, profits held in business'**
  String get businessDescription;

  /// Investments category description
  ///
  /// In en, this message translates to:
  /// **'Stocks, bonds, mutual funds, retirement accounts (if zakatable)'**
  String get investmentsDescription;

  /// Receivables category description
  ///
  /// In en, this message translates to:
  /// **'Money owed to you that you expect to receive'**
  String get receivablesDescription;

  /// Debts category description
  ///
  /// In en, this message translates to:
  /// **'Credit card debts, loans, bills due within the year'**
  String get debtsDescription;

  /// No description provided for @feedbackAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackAppBarTitle;

  /// No description provided for @feedbackEmptyWarning.
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback before sending'**
  String get feedbackEmptyWarning;

  /// No description provided for @feedbackSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your feedback has been sent.'**
  String get feedbackSuccessMessage;

  /// No description provided for @feedbackHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Huda by sharing your thoughts, suggestions, or reporting any issues you\'ve encountered.'**
  String get feedbackHeroSubtitle;

  /// No description provided for @feedbackFormTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get feedbackFormTitle;

  /// No description provided for @feedbackFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one option, then write your message.'**
  String get feedbackFormSubtitle;

  /// No description provided for @feedbackHintText.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts, suggestions, or report issues...'**
  String get feedbackHintText;

  /// No description provided for @feedbackSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedbackSending;

  /// No description provided for @feedbackSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackSendButton;

  /// No description provided for @feedbackPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get feedbackPrivacyTitle;

  /// No description provided for @feedbackPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your message and basic app and device details are sent securely. Your email is included only if you enter it.'**
  String get feedbackPrivacyDescription;

  /// No description provided for @detailedFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest an Improvement'**
  String get detailedFeedbackTitle;

  /// No description provided for @detailedFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share an idea for Huda'**
  String get detailedFeedbackSubtitle;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportAnIssue;

  /// No description provided for @issueDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us improve by reporting any problems'**
  String get issueDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @shareAsText.
  ///
  /// In en, this message translates to:
  /// **'Share as Text'**
  String get shareAsText;

  /// No description provided for @shareDhikr.
  ///
  /// In en, this message translates to:
  /// **'Share Dhikr'**
  String get shareDhikr;

  /// No description provided for @generatingImage.
  ///
  /// In en, this message translates to:
  /// **'Generating image...'**
  String get generatingImage;

  /// No description provided for @rateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Huda App'**
  String get rateAppTitle;

  /// No description provided for @rateExperienceQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your experience with our app?'**
  String get rateExperienceQuestion;

  /// No description provided for @helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve:'**
  String get helpUsImprove;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'What can we do better?'**
  String get feedbackHint;

  /// No description provided for @rateButton.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateButton;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @dontAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Ask Again'**
  String get dontAskAgain;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectRating;

  /// No description provided for @provideFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please provide feedback for improvement'**
  String get provideFeedback;

  /// No description provided for @thankYouRedirect.
  ///
  /// In en, this message translates to:
  /// **'Thank you! You\'ll be redirected to the store.'**
  String get thankYouRedirect;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback! We\'ll work on improvements.'**
  String get thankYouFeedback;

  /// No description provided for @mawdu.
  ///
  /// In en, this message translates to:
  /// **'Fabricated (Mawdu\')'**
  String get mawdu;

  /// No description provided for @shadh.
  ///
  /// In en, this message translates to:
  /// **'Irregular (Shadh)'**
  String get shadh;

  /// No description provided for @munkar.
  ///
  /// In en, this message translates to:
  /// **'Rejected (Munkar)'**
  String get munkar;

  /// No description provided for @gharib.
  ///
  /// In en, this message translates to:
  /// **'Strange (Gharib)'**
  String get gharib;

  /// No description provided for @chain.
  ///
  /// In en, this message translates to:
  /// **'in chain'**
  String get chain;

  /// No description provided for @noChapters.
  ///
  /// In en, this message translates to:
  /// **'No Chapters Available'**
  String get noChapters;

  /// No description provided for @newContent.
  ///
  /// In en, this message translates to:
  /// **'New content will be added soon.\nCheck back later for updates.'**
  String get newContent;

  /// Label for Meccan (Makkiyah) surahs
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// Label for Medinan (Madaniyah) surahs
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @ayahs.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahs;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @loopThisAyah.
  ///
  /// In en, this message translates to:
  /// **'Loop this ayah'**
  String get loopThisAyah;

  /// No description provided for @autoplayNextAyah.
  ///
  /// In en, this message translates to:
  /// **'Autoplay next ayah'**
  String get autoplayNextAyah;

  /// Title for memorization mode
  ///
  /// In en, this message translates to:
  /// **'Memorization Mode'**
  String get memorizationMode;

  /// Description of memorization mode
  ///
  /// In en, this message translates to:
  /// **'Test your memorization by hiding ayahs and reciting them. The app will listen to your recitation and reveal the ayahs as you recite correctly.'**
  String get memorizationDescription;

  /// Disclaimer about speech recognition
  ///
  /// In en, this message translates to:
  /// **'Speech recognition quality depends on your device capabilities.'**
  String get speechRecognitionDisclaimer;

  /// Button to start memorization
  ///
  /// In en, this message translates to:
  /// **'Start Memorization'**
  String get startMemorization;

  /// Button to stop memorization
  ///
  /// In en, this message translates to:
  /// **'Stop Memorization'**
  String get stopMemorization;

  /// Status when app is listening
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// Status when microphone is idle
  ///
  /// In en, this message translates to:
  /// **'Microphone idle'**
  String get microphoneIdle;

  /// Instruction to recite
  ///
  /// In en, this message translates to:
  /// **'Recite the ayah to reveal it'**
  String get reciteToReveal;

  /// Beta label
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get beta;

  /// Message when surah is memorized
  ///
  /// In en, this message translates to:
  /// **'You have successfully memorized this Surah.'**
  String get surahMemorized;

  /// No description provided for @counseling.
  ///
  /// In en, this message translates to:
  /// **'Counseling'**
  String get counseling;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Introduction text for counseling mode
  ///
  /// In en, this message translates to:
  /// **'Share your feelings, and let Huda guide you with Islamic wisdom.'**
  String get counselingIntro;

  /// Guidance card title
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidanceTitle;

  /// Quran card title
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// Duaa card title
  ///
  /// In en, this message translates to:
  /// **'Duaa'**
  String get duaaTitle;

  /// Example question for anxiety
  ///
  /// In en, this message translates to:
  /// **'I feel anxious'**
  String get exampleFeelAnxious;

  /// Example question for overwhelmed
  ///
  /// In en, this message translates to:
  /// **'I feel overwhelmed'**
  String get exampleFeelOverwhelmed;

  /// Example question for gratitude
  ///
  /// In en, this message translates to:
  /// **'Feeling grateful'**
  String get exampleFeelingGrateful;

  /// Example question for seeking peace
  ///
  /// In en, this message translates to:
  /// **'Seeking peace'**
  String get exampleSeekingPeace;

  /// Title for guidance section in counseling view
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidance;

  /// Title for Quranic wisdom section in counseling view
  ///
  /// In en, this message translates to:
  /// **'Quranic Wisdom'**
  String get quranicWisdom;

  /// Title for Duaa section in counseling view
  ///
  /// In en, this message translates to:
  /// **'Duaa'**
  String get duaa;

  /// Title for add widget section
  ///
  /// In en, this message translates to:
  /// **'Add Widget to Home Screen'**
  String get addWidgetToHomeScreen;

  /// Add widget button text
  ///
  /// In en, this message translates to:
  /// **'Add Widget'**
  String get addWidget;

  /// Title for widget instructions section
  ///
  /// In en, this message translates to:
  /// **'How to add the widget'**
  String get howToAddWidget;

  /// Android widget step 1
  ///
  /// In en, this message translates to:
  /// **'Long press on an empty area of your home screen'**
  String get androidWidgetStep1;

  /// Android widget step 2
  ///
  /// In en, this message translates to:
  /// **'Tap on \'Widgets\' from the menu'**
  String get androidWidgetStep2;

  /// Android widget step 3
  ///
  /// In en, this message translates to:
  /// **'Find \'Huda\' in the widget list'**
  String get androidWidgetStep3;

  /// Android widget step 4
  ///
  /// In en, this message translates to:
  /// **'Drag and drop the widget to your home screen'**
  String get androidWidgetStep4;

  /// iOS widget step 1
  ///
  /// In en, this message translates to:
  /// **'Long press on an empty area of your home screen'**
  String get iosWidgetStep1;

  /// iOS widget step 2
  ///
  /// In en, this message translates to:
  /// **'Tap the \'+\' button in the top left corner'**
  String get iosWidgetStep2;

  /// iOS widget step 3
  ///
  /// In en, this message translates to:
  /// **'Search for \'Huda\' in the widget gallery'**
  String get iosWidgetStep3;

  /// iOS widget step 4
  ///
  /// In en, this message translates to:
  /// **'Choose a widget size and tap \'Add Widget\''**
  String get iosWidgetStep4;

  /// Generic widget step 1
  ///
  /// In en, this message translates to:
  /// **'Long press on your home screen and look for \'Widgets\''**
  String get genericWidgetStep1;

  /// Generic widget step 2
  ///
  /// In en, this message translates to:
  /// **'Find \'Huda\' widget and add it to your home screen'**
  String get genericWidgetStep2;

  /// macOS widget gallery step 1
  ///
  /// In en, this message translates to:
  /// **'Control-click the desktop and choose Edit Widgets.'**
  String get macWidgetStep1;

  /// macOS widget gallery step 2
  ///
  /// In en, this message translates to:
  /// **'Search for Huda, then choose Quran Verse or Prayer Times.'**
  String get macWidgetStep2;

  /// macOS widget gallery step 3
  ///
  /// In en, this message translates to:
  /// **'Click a widget to add it, or drag it onto the desktop.'**
  String get macWidgetStep3;

  /// Title for Sahur Alarm section
  ///
  /// In en, this message translates to:
  /// **'Sahur Alarm'**
  String get sahurAlarmTitle;

  /// Description for Sahur Alarm
  ///
  /// In en, this message translates to:
  /// **'Wake up for Sahur before Fajr prayer.'**
  String get sahurAlarmDescription;

  /// Exact time option for Sahur Alarm
  ///
  /// In en, this message translates to:
  /// **'Exact Time'**
  String get exactTime;

  /// Minutes before Fajr option for Sahur alarm
  ///
  /// In en, this message translates to:
  /// **'Minutes before Fajr'**
  String get minutesBeforeFajr;

  /// Subtitle for exact time sahur alarm
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String atExactTime(String time);

  /// Subtitle for mins before fajr sahur alarm
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins before Fajr'**
  String minsBeforeFajr(int minutes);

  /// Title shown on the alarm ring screen when Sahur alarm is ringing
  ///
  /// In en, this message translates to:
  /// **'Sahur Alarm'**
  String get sahurAlarmRinging;

  /// Button label to stop the ringing alarm
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopAlarm;

  /// Body text of the notification when the Sahur alarm rings
  ///
  /// In en, this message translates to:
  /// **'Time to wake up for Sahur'**
  String get sahurAlarmNotificationBody;

  /// Miqaat Lock feature title
  ///
  /// In en, this message translates to:
  /// **'Miqaat Lock'**
  String get miqaatLock;

  /// Enable toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Miqaat Lock'**
  String get enableMiqaatLock;

  /// Locked apps section title
  ///
  /// In en, this message translates to:
  /// **'Locked Apps'**
  String get lockedApps;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No apps selected'**
  String get noAppsSelected;

  /// Add apps button
  ///
  /// In en, this message translates to:
  /// **'Add Apps'**
  String get addApps;

  /// Time slots section title
  ///
  /// In en, this message translates to:
  /// **'Time Slots'**
  String get timeSlots;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No time slots configured'**
  String get noTimeSlotsConfigured;

  /// Add time slot button
  ///
  /// In en, this message translates to:
  /// **'Add Time Slot'**
  String get addTimeSlot;

  /// Edit time slot dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Time Slot'**
  String get editTimeSlot;

  /// Session duration section title
  ///
  /// In en, this message translates to:
  /// **'Session Duration'**
  String get sessionDuration;

  /// Session duration explanation
  ///
  /// In en, this message translates to:
  /// **'Required time to spend in Huda (e.g., reading Quran) to unlock your apps.'**
  String get sessionDurationDescription;

  /// Custom duration option
  ///
  /// In en, this message translates to:
  /// **'Custom Duration'**
  String get customDuration;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// App selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Apps'**
  String get selectApps;

  /// Search apps placeholder
  ///
  /// In en, this message translates to:
  /// **'Search apps...'**
  String get searchApps;

  /// Loading apps message
  ///
  /// In en, this message translates to:
  /// **'Loading apps...'**
  String get loadingApps;

  /// No apps found message
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// Label input label
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get label;

  /// Label input hint
  ///
  /// In en, this message translates to:
  /// **'e.g., Fajr Time, Work Hours'**
  String get labelHint;

  /// Time range section title
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRange;

  /// Weekday selection title
  ///
  /// In en, this message translates to:
  /// **'Repeat On'**
  String get repeatOn;

  /// Weekday selection hint
  ///
  /// In en, this message translates to:
  /// **'Leave empty to repeat everyday'**
  String get leaveEmptyForEveryday;

  /// Everyday label
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get everyday;

  /// Monday day name
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday day name
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday day name
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday day name
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday day name
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday day name
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday day name
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Permissions banner title
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// Permissions banner description
  ///
  /// In en, this message translates to:
  /// **'Grant the following permissions to enable Miqaat Lock'**
  String get permissionsRequiredDescription;

  /// Accessibility permission title
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service'**
  String get accessibilityService;

  /// Accessibility permission description
  ///
  /// In en, this message translates to:
  /// **'Required to detect app launches'**
  String get accessibilityServiceDescription;

  /// Overlay permission title
  ///
  /// In en, this message translates to:
  /// **'Display Over Other Apps'**
  String get overlayPermission;

  /// Overlay permission description
  ///
  /// In en, this message translates to:
  /// **'Required to show lock screen'**
  String get overlayPermissionDescription;

  /// iOS Screen Time permission title
  ///
  /// In en, this message translates to:
  /// **'Screen Time Access'**
  String get screenTimeAccess;

  /// iOS Screen Time permission description
  ///
  /// In en, this message translates to:
  /// **'Required to manage app restrictions'**
  String get screenTimeAccessDescription;

  /// Check permissions button
  ///
  /// In en, this message translates to:
  /// **'Check Permissions'**
  String get checkPermissions;

  /// Days remaining until Ramadan starts
  ///
  /// In en, this message translates to:
  /// **'{days} days until Ramadan'**
  String daysUntilRamadan(int days);

  /// Ramadan day label e.g. Ramadan 3
  ///
  /// In en, this message translates to:
  /// **'Ramadan {day}'**
  String ramadanDayLabel(int day);

  /// Fasting duration label
  ///
  /// In en, this message translates to:
  /// **'Duration of fasting: {hours} hours and {minutes} minutes'**
  String durationOfFasting(int hours, int minutes);

  /// Iftar duration label
  ///
  /// In en, this message translates to:
  /// **'Duration of iftar: {hours} hours and {minutes} minutes'**
  String durationOfIftar(int hours, int minutes);

  /// Imsaak label on progress bar
  ///
  /// In en, this message translates to:
  /// **'Imsaak'**
  String get imsaakLabel;

  /// Iftar label on progress bar
  ///
  /// In en, this message translates to:
  /// **'Iftar'**
  String get iftarLabel;

  /// Fasted status label
  ///
  /// In en, this message translates to:
  /// **'fasted'**
  String get fastedStatus;

  /// Missed fasting status label
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get missedStatus;

  /// Qadhaa info dialog title
  ///
  /// In en, this message translates to:
  /// **'About Qadaa (Making up missed fasts)'**
  String get qadhaaInfoTitle;

  /// No description provided for @qadhaaInfoQ1Title.
  ///
  /// In en, this message translates to:
  /// **'What is Qadaa?'**
  String get qadhaaInfoQ1Title;

  /// No description provided for @qadhaaInfoQ1Body.
  ///
  /// In en, this message translates to:
  /// **'Qadaa is fasting the days a Muslim broke their fast during Ramadan due to a valid Islamic excuse, such as illness, travel, menstruation, or postpartum bleeding. They must be made up before the start of the following Ramadan.'**
  String get qadhaaInfoQ1Body;

  /// No description provided for @qadhaaInfoQ2Title.
  ///
  /// In en, this message translates to:
  /// **'The Ruling on Qadaa'**
  String get qadhaaInfoQ2Title;

  /// No description provided for @qadhaaInfoQ2Body1.
  ///
  /// In en, this message translates to:
  /// **'Allah the Almighty said:'**
  String get qadhaaInfoQ2Body1;

  /// No description provided for @qadhaaInfoQ2Verse.
  ///
  /// In en, this message translates to:
  /// **'\"And whoever of you is ill or on a journey - then an equal number of other days.\" [Al-Baqarah: 184]'**
  String get qadhaaInfoQ2Verse;

  /// No description provided for @qadhaaInfoQ2Body2.
  ///
  /// In en, this message translates to:
  /// **'Therefore, it is obligatory for whoever broke their fast in Ramadan with an excuse to make up those days.'**
  String get qadhaaInfoQ2Body2;

  /// No description provided for @qadhaaInfoQ3Title.
  ///
  /// In en, this message translates to:
  /// **'When must Qadaa be done?'**
  String get qadhaaInfoQ3Title;

  /// No description provided for @qadhaaInfoQ3Body.
  ///
  /// In en, this message translates to:
  /// **'The missed days of Ramadan must be made up before the beginning of the next Ramadan. It is permissible to make them up at any time of the year, except on the days of the two Eids and the days of Tashreeq. It is best to hasten in making them up and not to delay.'**
  String get qadhaaInfoQ3Body;

  /// No description provided for @qadhaaInfoQ4Title.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get qadhaaInfoQ4Title;

  /// No description provided for @qadhaaInfoQ4Body1.
  ///
  /// In en, this message translates to:
  /// **'During Ramadan: Tap on the day you broke your fast to log it.'**
  String get qadhaaInfoQ4Body1;

  /// No description provided for @qadhaaInfoQ4Body2.
  ///
  /// In en, this message translates to:
  /// **'After Ramadan: Tap on the logged day to confirm you have made it up.'**
  String get qadhaaInfoQ4Body2;

  /// What's New dialog title
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNewTitle;

  /// What's New version badge
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersion(String version);

  /// What's New dialog button
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get whatsNewExploreButton;

  /// What's New v1.5.3 feature 1
  ///
  /// In en, this message translates to:
  /// **'Ramadan fasting tracker with a daily qadhaa log'**
  String get whatsNew153Feature1;

  /// What's New v1.5.3 feature 2
  ///
  /// In en, this message translates to:
  /// **'Miqaat Lock to block distracting apps during prayer times'**
  String get whatsNew153Feature2;

  /// What's New v1.5.3 feature 3
  ///
  /// In en, this message translates to:
  /// **'Qadhaa tracker to log and make up missed fasting days'**
  String get whatsNew153Feature3;

  /// What's new feature 1 for v2.0.0
  ///
  /// In en, this message translates to:
  /// **'Miqaat Lock: Block distracting apps during your custom time slots'**
  String get whatsNew200Feature1;

  /// What's new feature 2 for v2.0.0
  ///
  /// In en, this message translates to:
  /// **'Ramadan Page: Qadhaa tracker to log and make up missed fasting days'**
  String get whatsNew200Feature2;

  /// What's new feature 3 for v2.0.0
  ///
  /// In en, this message translates to:
  /// **'Sahur Alarm: Choose a fixed time, or have it automatically ring right before Fajr.'**
  String get whatsNew200Feature3;

  /// What's new feature 4 for v2.0.0
  ///
  /// In en, this message translates to:
  /// **'UI improvements'**
  String get whatsNew200Feature4;

  /// What's new feature 5 for v2.0.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes'**
  String get whatsNew200Feature5;

  /// What's new feature 1 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Similar Ayahs: Discover ayahs with similar themes and meanings across the Quran'**
  String get whatsNew300Feature1;

  /// What's new feature 2 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Khatma Tracker: Plan and track your Quran reading with daily reminders'**
  String get whatsNew300Feature2;

  /// What's new feature 3 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Mushaf Layout: Read the Quran in the traditional Mushaf page layout'**
  String get whatsNew300Feature3;

  /// What's new feature 4 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Quran Audio: Listen to recitations from various reciters with download support'**
  String get whatsNew300Feature4;

  /// What's new feature 5 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Quran Radio: Live Quran radio stations for continuous listening'**
  String get whatsNew300Feature5;

  /// What's new feature 6 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Adjustment: Fine-tune prayer time offsets for more accurate notifications'**
  String get whatsNew300Feature6;

  /// What's new feature 7 for v3.0.0
  ///
  /// In en, this message translates to:
  /// **'UI/UX improvements, responsive design, and enhanced experience'**
  String get whatsNew300Feature7;

  /// What's new feature 1 for v3.1.0 — iOS variant (includes lock screen)
  ///
  /// In en, this message translates to:
  /// **'Prayer Times Widget: Home screen & lock screen widget with a live countdown to your next prayer'**
  String get whatsNew310Feature1iOS;

  /// What's new feature 1 for v3.1.0 — Android variant
  ///
  /// In en, this message translates to:
  /// **'Prayer Times Widget: Home screen widget with a live countdown to your next prayer'**
  String get whatsNew310Feature1Android;

  /// What's new feature 2 for v3.1.0
  ///
  /// In en, this message translates to:
  /// **'UI/UX improvements'**
  String get whatsNew310Feature2;

  /// What's new feature 3 for v3.1.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes'**
  String get whatsNew310Feature3;

  /// What's new feature 1 for v3.3.0
  ///
  /// In en, this message translates to:
  /// **'Continue Reading relocated: Tap the Quran card on the home screen to expand it and find your reading progress'**
  String get whatsNew330Feature1;

  /// What's new feature 2 for v3.3.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes and improvements'**
  String get whatsNew330Feature2;

  /// What's new feature 1 for v3.4.0
  ///
  /// In en, this message translates to:
  /// **'Audios: Browse and listen to all types of Islamic audios with offline download and sleep timer support'**
  String get whatsNew340Feature1;

  /// What's new feature 2 for v3.4.0
  ///
  /// In en, this message translates to:
  /// **'Reciter & Radio Tracking: Your last played reciter and radio station are now saved — resume them from the home screen'**
  String get whatsNew340Feature2;

  /// What's new feature 3 for v3.4.0
  ///
  /// In en, this message translates to:
  /// **'Book Progress: Your last read book is now tracked — continue from where you left off from the books page'**
  String get whatsNew340Feature3;

  /// What's new feature 4 for v3.4.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes and improvements'**
  String get whatsNew340Feature4;

  /// What's new feature 1 for v3.5.0
  ///
  /// In en, this message translates to:
  /// **'Custom App Font: Change the app font from settings to suit your preference'**
  String get whatsNew350Feature1;

  /// What's new feature 2 for v3.5.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes and performance improvements'**
  String get whatsNew350Feature2;

  /// What's new feature 3 for v3.5.0
  ///
  /// In en, this message translates to:
  /// **'UI Touch-ups: A fresh, polished look on several screens'**
  String get whatsNew350Feature3;

  /// What's new feature 1 for v3.7.0
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Improvements: more accurate prayer times with new calculation methods including Oman, Algeria, and more'**
  String get whatsNew370Feature1;

  /// What's new feature 2 for v3.7.0
  ///
  /// In en, this message translates to:
  /// **'Qiblah Compass: improved compass behavior and Qiblah accuracy'**
  String get whatsNew370Feature2;

  /// What's new feature 3 for v3.7.0
  ///
  /// In en, this message translates to:
  /// **'Bug fixes and performance improvements'**
  String get whatsNew370Feature3;

  /// What's new feature 1 for v4.0.0
  ///
  /// In en, this message translates to:
  /// **'Customize your Home screen: choose a theme, reorder sections, and select which features appear'**
  String get whatsNew400Feature1;

  /// What's new feature 2 for v4.0.0
  ///
  /// In en, this message translates to:
  /// **'Improved Hijri calendar accuracy'**
  String get whatsNew400Feature2;

  /// What's new feature 3 for v4.0.0
  ///
  /// In en, this message translates to:
  /// **'Prayer time notifications now cover more days for more reliable reminders'**
  String get whatsNew400Feature3;

  /// What's new feature 4 for v4.0.0
  ///
  /// In en, this message translates to:
  /// **'Visual refinements throughout the app'**
  String get whatsNew400Feature4;

  /// What's new feature 5 for v4.0.0
  ///
  /// In en, this message translates to:
  /// **'A smoother, more intuitive experience'**
  String get whatsNew400Feature5;

  /// What's new feature 1 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Redesigned Prayer and Quran widgets with improved customization, reliability, and new iOS Lock Screen options'**
  String get whatsNew420Feature1;

  /// What's new feature 2 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Added custom Fajr, Maghrib, and Isha calculation angles'**
  String get whatsNew420Feature2;

  /// What's new feature 3 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Prayer times, notifications, and widgets can now update automatically while traveling'**
  String get whatsNew420Feature3;

  /// What's new feature 4 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Huda AI now saves searchable conversation history locally'**
  String get whatsNew420Feature4;

  /// What's new feature 5 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Improved Home customization'**
  String get whatsNew420Feature5;

  /// What's new feature 6 for v4.2.0
  ///
  /// In en, this message translates to:
  /// **'Redesigned the feedback and issue-reporting experience'**
  String get whatsNew420Feature6;

  /// What's new feature 1 for v4.3.0
  ///
  /// In en, this message translates to:
  /// **'Prayer times and widgets are more reliable.'**
  String get whatsNew430Feature1;

  /// What's new feature 2 for v4.3.0
  ///
  /// In en, this message translates to:
  /// **'A smoother, more polished experience throughout the app.'**
  String get whatsNew430Feature2;

  /// What's new feature 1 for v5.0.0
  ///
  /// In en, this message translates to:
  /// **'A fresh new look across the whole app.'**
  String get whatsNew500Feature1;

  /// What's new feature 2 for v5.0.0
  ///
  /// In en, this message translates to:
  /// **'Choose your Adhan and set alerts for each prayer.'**
  String get whatsNew500Feature2;

  /// What's new feature 3 for v5.0.0
  ///
  /// In en, this message translates to:
  /// **'Set Iqamah times for your mosque.'**
  String get whatsNew500Feature3;

  /// What's new feature 4 for v5.0.0
  ///
  /// In en, this message translates to:
  /// **'Read the Quran in Hafs, Tajweed, or IndoPak pages.'**
  String get whatsNew500Feature4;

  /// What's new feature 5 for v5.0.0 (iOS)
  ///
  /// In en, this message translates to:
  /// **'Prayer alarms can now play the full Adhan.'**
  String get whatsNew500Feature5iOS;

  /// What's new feature 5 for v5.0.0 (Android)
  ///
  /// In en, this message translates to:
  /// **'Add prayer times to your Samsung Lock Screen.'**
  String get whatsNew500Feature5Android;

  /// What's new feature 5 for v5.0.0 (macOS and Windows)
  ///
  /// In en, this message translates to:
  /// **'Prayer times now live in your menu bar or taskbar.'**
  String get whatsNew500Feature5Desktop;

  /// Shows the number of available downloaded books
  ///
  /// In en, this message translates to:
  /// **'Showing {count} downloaded books'**
  String showingDownloadedBooks(int count);

  /// Message shown when a book is downloaded successfully
  ///
  /// In en, this message translates to:
  /// **'Book downloaded successfully!'**
  String get bookDownloadedSuccessfully;

  /// Success message when apps are selected
  ///
  /// In en, this message translates to:
  /// **'Apps selected successfully'**
  String get iosAppsSelectedSuccessfully;

  /// Error message when app selection fails
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String iosAppSelectionError(String error);

  /// Title for Screen Time Protection on iOS
  ///
  /// In en, this message translates to:
  /// **'Screen Time Protection'**
  String get iosScreenTimeProtection;

  /// Text showing number of apps and categories selected on iOS
  ///
  /// In en, this message translates to:
  /// **'{appCount} app(s) + {categoryCount} categor(ies) selected'**
  String iosAppsAndCategoriesSelected(int appCount, int categoryCount);

  /// Text showing 1 app selected on iOS
  ///
  /// In en, this message translates to:
  /// **'{appCount} app selected'**
  String iosAppSelected(int appCount);

  /// Text showing multiple apps selected on iOS
  ///
  /// In en, this message translates to:
  /// **'{appCount} apps selected'**
  String iosAppsSelected(int appCount);

  /// Empty state title for downloaded books
  ///
  /// In en, this message translates to:
  /// **'No Downloaded Books'**
  String get noDownloadedBooks;

  /// Empty state subtitle for downloaded books
  ///
  /// In en, this message translates to:
  /// **'Download books when online to access them offline'**
  String get downloadBooksWhenOnlineToAccessThemOffline;

  /// Title for accessibility service dialog
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service Required'**
  String get accessibilityServiceRequiredDialogTitle;

  /// Description for accessibility service dialog
  ///
  /// In en, this message translates to:
  /// **'Miqaat Lock requires the AccessibilityService API to detect app launches and display the lock screen.'**
  String get accessibilityServiceRequiredDialogDesc;

  /// Privacy text for accessibility service dialog
  ///
  /// In en, this message translates to:
  /// **'We do not use this service to collect, store, or share any personal or sensitive user data.'**
  String get accessibilityServiceRequiredDialogPrivacy;

  /// Agree button text
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// Quran audio screen title
  ///
  /// In en, this message translates to:
  /// **'Quran Audio'**
  String get quranAudio;

  /// Search reciters placeholder
  ///
  /// In en, this message translates to:
  /// **'Search reciters...'**
  String get searchReciters;

  /// Verses count label
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get verses;

  /// Offline empty state description
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to browse and download Quran recitations'**
  String get connectToDownload;

  /// Quran radio screen title
  ///
  /// In en, this message translates to:
  /// **'Quran Radio'**
  String get quranRadio;

  /// Search hint for radio stations
  ///
  /// In en, this message translates to:
  /// **'Search radio stations...'**
  String get searchRadio;

  /// Title for the Khatma (Quran completion) page
  ///
  /// In en, this message translates to:
  /// **'Quran Khatma'**
  String get khatmaTitle;

  /// Description on the empty Khatma page
  ///
  /// In en, this message translates to:
  /// **'Set your daily portion or duration to complete the Quran, and track your Khatma throughout the year.'**
  String get khatmaDescription;

  /// Button to start a new Khatma
  ///
  /// In en, this message translates to:
  /// **'Start New Khatma'**
  String get khatmaStartNew;

  /// Title for the new Khatma step
  ///
  /// In en, this message translates to:
  /// **'New Khatma'**
  String get khatmaNewTitle;

  /// Badge label for suggested program
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get khatmaSuggested;

  /// Daily portion subtitle: one Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Juz'**
  String get khatmaDailyWirdJuz;

  /// Daily portion subtitle: one Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Rub\''**
  String get khatmaDailyWirdRubu;

  /// Daily portion subtitle: two Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: two Rub\''**
  String get khatmaDailyWirdTwoRubu;

  /// Daily portion subtitle: 3 Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 3 Rub\''**
  String get khatmaDailyWird3Rubu;

  /// Daily portion subtitle: one Hizb
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Hizb'**
  String get khatmaDailyWirdHizb;

  /// Daily portion subtitle: 1.5 Hizb
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 1.5 Hizb'**
  String get khatmaDailyWirdHizbAndHalf;

  /// Daily portion subtitle: 1.5 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 1.5 Juz'**
  String get khatmaDailyWirdJuzAndHalf;

  /// Daily portion subtitle: two Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: two Juz'**
  String get khatmaDailyWirdTwoJuz;

  /// Daily portion subtitle: 3 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 3 Juz'**
  String get khatmaDailyWird3Juz;

  /// Daily portion subtitle: 5 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 5 Juz'**
  String get khatmaDailyWird5Juz;

  /// Daily portion subtitle: 10 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 10 Juz'**
  String get khatmaDailyWird10Juz;

  /// Title for start-from selection step
  ///
  /// In en, this message translates to:
  /// **'Start Khatma From'**
  String get khatmaStartFromTitle;

  /// Subtitle for starting from the beginning
  ///
  /// In en, this message translates to:
  /// **'Start from Al-Fatihah'**
  String get khatmaFromBeginningSubtitle;

  /// Subtitle for starting from a specific portion
  ///
  /// In en, this message translates to:
  /// **'Choose a day from the portions list'**
  String get khatmaSpecificWirdSubtitle;

  /// Progress indicator showing current day out of total days
  ///
  /// In en, this message translates to:
  /// **'Day {current} of {total}'**
  String khatmaDayOf(int current, int total);

  /// Relative day label: tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get khatmaTomorrow;

  /// Relative day label: in two days
  ///
  /// In en, this message translates to:
  /// **'In two days'**
  String get khatmaInTwoDays;

  /// Relative day label: in N days (3-10)
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String khatmaInDays(int count);

  /// Relative day label: in N days (>10)
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String khatmaInManyDays(int count);

  /// Relative day label: yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get khatmaYesterday;

  /// Relative day label: two days ago
  ///
  /// In en, this message translates to:
  /// **'Two days ago'**
  String get khatmaTwoDaysAgo;

  /// Relative day label: N days ago (3-10)
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String khatmaDaysAgo(int count);

  /// Relative day label: N days ago (>10)
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String khatmaManyDaysAgo(int count);

  /// Legend label for the Khatma ring
  ///
  /// In en, this message translates to:
  /// **'Khatma'**
  String get khatmaLegendKhatma;

  /// Legend label for commitment ring
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get khatmaCommitment;

  /// Stats label for days remaining
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get khatmaDaysRemaining;

  /// Stats label for pages read
  ///
  /// In en, this message translates to:
  /// **'Pages Read'**
  String get khatmaPagesRead;

  /// Stats label for pages remaining
  ///
  /// In en, this message translates to:
  /// **'Remaining (p.)'**
  String get khatmaPagesRemaining;

  /// Label for the daily wird of a specific day
  ///
  /// In en, this message translates to:
  /// **'Day {day} Portion'**
  String khatmaDailyWirdOf(int day);

  /// Start of today's wird: from surah and verse
  ///
  /// In en, this message translates to:
  /// **'From {surah}: {verse}'**
  String khatmaFromSurah(String surah, int verse);

  /// End of today's wird: to surah and verse
  ///
  /// In en, this message translates to:
  /// **'To {surah}: {verse}'**
  String khatmaToSurah(String surah, int verse);

  /// Button to mark today's wird as done
  ///
  /// In en, this message translates to:
  /// **'I completed this portion'**
  String get khatmaMarkDone;

  /// Section label for daily reminder
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get khatmaDailyReminderSection;

  /// Title for the daily wird reminder tile
  ///
  /// In en, this message translates to:
  /// **'Daily Portion'**
  String get khatmaDailyWirdTitle;

  /// Title for the all wirds list
  ///
  /// In en, this message translates to:
  /// **'All Portions'**
  String get khatmaAllWirds;

  /// Title for delete Khatma option and dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Khatma'**
  String get khatmaDeleteTitle;

  /// Subtitle for delete Khatma option
  ///
  /// In en, this message translates to:
  /// **'Clear all progress data'**
  String get khatmaDeleteSubtitle;

  /// Congratulations message on Khatma completion
  ///
  /// In en, this message translates to:
  /// **'May Allah bless you!'**
  String get khatmaCongrats;

  /// Completion message body
  ///
  /// In en, this message translates to:
  /// **'You have successfully completed this Khatma'**
  String get khatmaCompletedMsg;

  /// Button to repeat the same Khatma program
  ///
  /// In en, this message translates to:
  /// **'Repeat this Khatma'**
  String get khatmaRepeat;

  /// Confirmation dialog content for deleting Khatma
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the current Khatma and erase all your progress data?'**
  String get khatmaDeleteConfirmContent;

  /// Daily portion subtitle with pages count
  ///
  /// In en, this message translates to:
  /// **'Daily portion: ~{pages} pages'**
  String khatmaDailyWirdPages(int pages);

  /// Label for the Surahs tab and section title
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahsLabel;

  /// Subtitle showing total surah count
  ///
  /// In en, this message translates to:
  /// **'114 Surahs'**
  String get surahIndexSubtitle;

  /// Placeholder text for the surah search field
  ///
  /// In en, this message translates to:
  /// **'Search for a surah...'**
  String get searchSurahHint;

  /// Empty state message when surah search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get surahNoResults;

  /// Verse count label on each surah card
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String verseCountLabel(int count);

  /// Tab bar label for the memorization (Hifz) tab
  ///
  /// In en, this message translates to:
  /// **'Memorize'**
  String get tabMemorization;

  /// Reading mode: scrollable list
  ///
  /// In en, this message translates to:
  /// **'Scroll List'**
  String get readingModeScrollList;

  /// Reading mode: mushaf page-by-page
  ///
  /// In en, this message translates to:
  /// **'Mushaf layout'**
  String get readingModeMushaf;

  /// Reading mode: tajweed mushaf
  ///
  /// In en, this message translates to:
  /// **'Mushaf Al-Tajweed layout'**
  String get readingModeTajweed;

  /// Reading mode: IndoPak 15-line (Qudratullah) Mushaf pages
  ///
  /// In en, this message translates to:
  /// **'IndoPak Mushaf'**
  String get readingModeIndopak;

  /// Mushaf flip direction: horizontal
  ///
  /// In en, this message translates to:
  /// **'Horizontal Flip'**
  String get mushafFlipHorizontal;

  /// Mushaf flip direction: vertical
  ///
  /// In en, this message translates to:
  /// **'Vertical Flip'**
  String get mushafFlipVertical;

  /// Mushaf display mode: single page
  ///
  /// In en, this message translates to:
  /// **'Single Page'**
  String get mushafDisplaySingle;

  /// Mushaf display mode: double page
  ///
  /// In en, this message translates to:
  /// **'Double Page'**
  String get mushafDisplayDouble;

  /// Mushaf display mode: zoomed
  ///
  /// In en, this message translates to:
  /// **'Zoomed'**
  String get mushafDisplayZoomed;

  /// Mushaf page header juz label
  ///
  /// In en, this message translates to:
  /// **'Juz {name}'**
  String mushafJuzHeader(String name);

  /// Error fallback label in mushaf view
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String mushafPageNumber(int number);

  /// Settings section header for reading mode
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get settingsReadingMode;

  /// Settings section header for flip direction
  ///
  /// In en, this message translates to:
  /// **'Flip Direction'**
  String get settingsFlipDirection;

  /// Settings section header for Quran font
  ///
  /// In en, this message translates to:
  /// **'Quran Font'**
  String get settingsQuranFont;

  /// Settings section header for the app-wide UI font
  ///
  /// In en, this message translates to:
  /// **'App Font'**
  String get settingsAppFont;

  /// Settings subtitle describing the app-wide UI font picker
  ///
  /// In en, this message translates to:
  /// **'Font used across the app interface'**
  String get settingsAppFontDescription;

  /// App font option that uses the device's default font
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsSystemFont;

  /// Subtitle for the system default font option
  ///
  /// In en, this message translates to:
  /// **'Uses your device\'s default font'**
  String get settingsSystemFontDescription;

  /// Surah number badge in the app bar
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String surahNumberBadge(int number);

  /// Font download progress: extracting state
  ///
  /// In en, this message translates to:
  /// **'Extracting…'**
  String get fontExtractingLabel;

  /// Font download progress: loading state
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get fontLoadingLabel;

  /// Title shown in the Mushaf reader when its page images need to be downloaded
  ///
  /// In en, this message translates to:
  /// **'Mushaf pages'**
  String get mushafPackTitle;

  /// Explains why the Mushaf page images must be downloaded, including after the update from page fonts
  ///
  /// In en, this message translates to:
  /// **'The Mushaf now uses page images for smoother page turning. Download them once to keep reading in this layout.'**
  String get mushafPackBody;

  /// Button that downloads the Mushaf page images
  ///
  /// In en, this message translates to:
  /// **'Download ({size})'**
  String mushafPackDownload(String size);

  /// Next surah navigation button label
  ///
  /// In en, this message translates to:
  /// **'Next Surah'**
  String get nextSurah;

  /// Previous surah navigation button label
  ///
  /// In en, this message translates to:
  /// **'Previous Surah'**
  String get previousSurah;

  /// Message when no similar ayahs are found
  ///
  /// In en, this message translates to:
  /// **'No similar ayahs found'**
  String get noSimilarAyahsFound;

  /// Header showing how many similar ayahs an ayah key has
  ///
  /// In en, this message translates to:
  /// **'{ayahKey} has {count, plural, one{1 similar ayah} other{{count} similar ayahs}}'**
  String similarAyahsCountLabel(String ayahKey, int count);

  /// Match statistics for a similar ayah
  ///
  /// In en, this message translates to:
  /// **'Matches {matchedWordsCount} words · {coverage}% coverage · Score: {score}'**
  String similarAyahsMatchStats(int matchedWordsCount, int coverage, int score);

  /// Tab label for the Quran-verse widget
  ///
  /// In en, this message translates to:
  /// **'Quran Verse'**
  String get quranVerseWidget;

  /// Tab label for the prayer-times widget
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimesWidget;

  /// Button text to add the prayer widget
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get addPrayerWidget;

  /// No description provided for @prayerWidgetTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Prayer time format'**
  String get prayerWidgetTimeFormat;

  /// No description provided for @prayerWidgetTwelveHour.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get prayerWidgetTwelveHour;

  /// No description provided for @prayerWidgetTwentyFourHour.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get prayerWidgetTwentyFourHour;

  /// Section title for design picker
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// Name of the hero/big-countdown widget design
  ///
  /// In en, this message translates to:
  /// **'Spotlight'**
  String get designHero;

  /// Description of the hero design
  ///
  /// In en, this message translates to:
  /// **'Atmospheric next-prayer focus with a precise countdown and calm celestial schedule.'**
  String get designHeroDescription;

  /// Name of the compact design
  ///
  /// In en, this message translates to:
  /// **'Almanac'**
  String get designCompact;

  /// Description of the compact design
  ///
  /// In en, this message translates to:
  /// **'Editorial date and prayer schedule with clear next-prayer highlighting and night times.'**
  String get designCompactDescription;

  /// Section title for widget size picker
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Medium widget size
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// Lock screen widget category
  ///
  /// In en, this message translates to:
  /// **'Lock screen'**
  String get lockScreen;

  /// Section title for background customization
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// Custom background color picker label
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// Toggle for translucent glass background
  ///
  /// In en, this message translates to:
  /// **'Glass effect'**
  String get glassify;

  /// Toggle for rounded corners
  ///
  /// In en, this message translates to:
  /// **'Rounded corners'**
  String get rounded;

  /// Section title for content customization
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// Picker label for content/text color
  ///
  /// In en, this message translates to:
  /// **'Content color'**
  String get contentColor;

  /// Slider label for content scaling
  ///
  /// In en, this message translates to:
  /// **'Content size'**
  String get contentSize;

  /// Section title for region/locale customization
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// Numerals selector label
  ///
  /// In en, this message translates to:
  /// **'Numerals'**
  String get numerals;

  /// Automatic / follow system option
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// Section title for advanced settings
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// Button text to reset prayer widget customization
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetWidgetCustomization;

  /// Button to manually refresh the prayer widget
  ///
  /// In en, this message translates to:
  /// **'Refresh prayer widget'**
  String get forcePrayerWidgetUpdate;

  /// Snackbar text after a forced refresh
  ///
  /// In en, this message translates to:
  /// **'Prayer widget refreshed'**
  String get prayerWidgetUpdated;

  /// Loading indicator label during refresh
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get prayerWidgetUpdating;

  /// Section title for the pre-made visual theme gallery
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get widgetTheme;

  /// Label for the auto/follow-app visual theme
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeAuto;

  /// Label for the Ocean visual theme
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// Label for the Sunset visual theme
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get themeSunset;

  /// Label for the Forest visual theme
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// Label for the Midnight visual theme
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// Label for the Sandstone visual theme
  ///
  /// In en, this message translates to:
  /// **'Sandstone'**
  String get themeSandstone;

  /// Label for the Rose visual theme
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get themeRose;

  /// Label for the Lavender visual theme
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get themeLavender;

  /// Label for the Charcoal visual theme
  ///
  /// In en, this message translates to:
  /// **'Charcoal'**
  String get themeCharcoal;

  /// Label for the Amber visual theme
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themeAmber;

  /// Label for the Arctic visual theme
  ///
  /// In en, this message translates to:
  /// **'Arctic'**
  String get themeArctic;

  /// Label for the Burgundy visual theme
  ///
  /// In en, this message translates to:
  /// **'Burgundy'**
  String get themeBurgundy;

  /// Label for the Sage visual theme
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get themeSage;

  /// Title for the Ramadan special event card
  ///
  /// In en, this message translates to:
  /// **'Ramadan Mubarak'**
  String get eventRamadan;

  /// Title for the first day of Ramadan in the Hijri calendar
  ///
  /// In en, this message translates to:
  /// **'First Day of Ramadan'**
  String get calendarEventFirstDayRamadan;

  /// Title for Eid al-Fitr in the Hijri calendar
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get calendarEventEidAlFitr;

  /// Title for Eid al-Adha in the Hijri calendar
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get calendarEventEidAlAdha;

  /// Title for the last ten nights of Ramadan event card
  ///
  /// In en, this message translates to:
  /// **'The Last Ten Nights'**
  String get eventLastTenRamadan;

  /// Title for the Eid al-Fitr event card
  ///
  /// In en, this message translates to:
  /// **'Eid Fitr Mubarak'**
  String get eventEidAlFitr;

  /// Title for the Eid al-Adha event card
  ///
  /// In en, this message translates to:
  /// **'Eid Adha Mubarak'**
  String get eventEidAlAdha;

  /// Title for the Day of Arafah event card
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah'**
  String get eventDayOfArafah;

  /// Title for the first ten days of Dhul Hijjah event card
  ///
  /// In en, this message translates to:
  /// **'First Ten Days of Dhu al-Hijjah'**
  String get eventFirstTenDhulHijjah;

  /// Title for the Day of Ashura event card
  ///
  /// In en, this message translates to:
  /// **'Day of Ashura'**
  String get eventAshura;

  /// Title for the Days of Tashreeq event card
  ///
  /// In en, this message translates to:
  /// **'Days of Tashreeq'**
  String get eventDaysTashreeq;

  /// Subtitle for the Ramadan event card
  ///
  /// In en, this message translates to:
  /// **'The month of fasting, night prayer, and Quran recitation'**
  String get eventRamadanSubtitle;

  /// Subtitle for the last ten nights of Ramadan event card
  ///
  /// In en, this message translates to:
  /// **'Seek Laylat al-Qadr in these blessed nights'**
  String get eventLastTenRamadanSubtitle;

  /// Subtitle for the Eid al-Fitr event card
  ///
  /// In en, this message translates to:
  /// **'Celebrate the completion of Ramadan with joy and gratitude'**
  String get eventEidAlFitrSubtitle;

  /// Subtitle for the Eid al-Adha event card
  ///
  /// In en, this message translates to:
  /// **'The Festival of Sacrifice — a day of devotion and generosity'**
  String get eventEidAlAdhaSubtitle;

  /// Subtitle for the Day of Arafah event card
  ///
  /// In en, this message translates to:
  /// **'The best day upon which the sun has risen'**
  String get eventDayOfArafahSubtitle;

  /// Subtitle for the first ten days of Dhul Hijjah event card
  ///
  /// In en, this message translates to:
  /// **'The most beloved days to Allah for righteous deeds'**
  String get eventFirstTenDhulHijjahSubtitle;

  /// Subtitle for the Day of Ashura event card
  ///
  /// In en, this message translates to:
  /// **'A day of fasting and remembrance of Allah\'s mercy'**
  String get eventAshuraSubtitle;

  /// Subtitle for the Days of Tashreeq event card
  ///
  /// In en, this message translates to:
  /// **'Days of eating, drinking, and remembrance of Allah'**
  String get eventDaysTashreeqSubtitle;

  /// Arabic text of Quran 2:185 for Ramadan dialog
  ///
  /// In en, this message translates to:
  /// **'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ هُدًى لِّلنَّاسِ وَبَيِّنَاتٍ مِّنَ الْهُدَىٰ وَالْفُرْقَانِ'**
  String get eventRamadanArabic;

  /// Translation of Quran 2:185
  ///
  /// In en, this message translates to:
  /// **'The month of Ramadan in which the Quran was revealed, a guidance for the people and clear proofs of guidance and criterion.'**
  String get eventRamadanTranslation;

  /// Source reference for Ramadan ayah
  ///
  /// In en, this message translates to:
  /// **'Quran 2:185'**
  String get eventRamadanSource;

  /// Arabic text of Quran 97:1-3 for Last Ten Nights dialog
  ///
  /// In en, this message translates to:
  /// **'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ · وَمَا أَدْرَاكَ مَا لَيْلَةُ الْقَدْرِ · لَيْلَةُ الْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ'**
  String get eventLastTenRamadanArabic;

  /// Translation of Quran 97:1-3
  ///
  /// In en, this message translates to:
  /// **'Indeed, We sent it down during the Night of Decree. And what can make you know what is the Night of Decree? The Night of Decree is better than a thousand months.'**
  String get eventLastTenRamadanTranslation;

  /// Source reference for Last Ten Nights ayah
  ///
  /// In en, this message translates to:
  /// **'Quran 97:1-3'**
  String get eventLastTenRamadanSource;

  /// Arabic text of hadith for Eid al-Fitr dialog
  ///
  /// In en, this message translates to:
  /// **'لِلصَّائِمِ فَرْحَتَانِ: فَرْحَةٌ عِندَ فِطْرِهِ، وَفَرْحَةٌ عِندَ لِقَاءِ رَبِّهِ'**
  String get eventEidAlFitrArabic;

  /// Translation of Eid al-Fitr hadith
  ///
  /// In en, this message translates to:
  /// **'The fasting person has two moments of joy: one when breaking the fast, and one when meeting his Lord.'**
  String get eventEidAlFitrTranslation;

  /// Source reference for Eid al-Fitr hadith
  ///
  /// In en, this message translates to:
  /// **'Bukhari & Muslim'**
  String get eventEidAlFitrSource;

  /// Arabic text of Quran 22:37 for Eid al-Adha dialog
  ///
  /// In en, this message translates to:
  /// **'لَن يَنَالَ اللَّهَ لُحُومُهَا وَلَا دِمَاؤُهَا وَلَٰكِن يَنَالُهُ التَّقْوَىٰ مِنكُمْ'**
  String get eventEidAlAdhaArabic;

  /// Translation of Quran 22:37
  ///
  /// In en, this message translates to:
  /// **'Their meat will not reach Allah, nor will their blood, but what reaches Him is piety from you.'**
  String get eventEidAlAdhaTranslation;

  /// Source reference for Eid al-Adha ayah
  ///
  /// In en, this message translates to:
  /// **'Quran 22:37'**
  String get eventEidAlAdhaSource;

  /// Arabic text of hadith for Day of Arafah dialog
  ///
  /// In en, this message translates to:
  /// **'صِيَامُ يَوْمِ عَرَفَةَ أَحْتَسِبُ عَلَى اللَّهِ أَن يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ وَالسَّنَةَ الَّتِي بَعْدَهُ'**
  String get eventDayOfArafahArabic;

  /// Translation of Day of Arafah hadith
  ///
  /// In en, this message translates to:
  /// **'Fasting on the Day of Arafah, I hope from Allah that it will expiate the sins of the year before and the year after.'**
  String get eventDayOfArafahTranslation;

  /// Source reference for Day of Arafah hadith
  ///
  /// In en, this message translates to:
  /// **'Sahih Muslim'**
  String get eventDayOfArafahSource;

  /// Arabic text of hadith for First Ten Dhul Hijjah dialog
  ///
  /// In en, this message translates to:
  /// **'مَا مِنْ أَيَّامٍ الْعَمَلُ الصَّالِحُ فِيهِنَّ أَحَبُّ إِلَى اللَّهِ مِنْ هَذِهِ الأَيَّامِ'**
  String get eventFirstTenDhulHijjahArabic;

  /// Translation of First Ten Dhul Hijjah hadith
  ///
  /// In en, this message translates to:
  /// **'There are no days in which righteous deeds are more beloved to Allah than these days.'**
  String get eventFirstTenDhulHijjahTranslation;

  /// Source reference for First Ten Dhul Hijjah hadith
  ///
  /// In en, this message translates to:
  /// **'Sahih al-Bukhari'**
  String get eventFirstTenDhulHijjahSource;

  /// Arabic text of hadith for Ashura dialog
  ///
  /// In en, this message translates to:
  /// **'صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَن يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ'**
  String get eventAshuraArabic;

  /// Translation of Ashura hadith
  ///
  /// In en, this message translates to:
  /// **'Fasting on the Day of Ashura, I hope from Allah that it will expiate the sins of the year before it.'**
  String get eventAshuraTranslation;

  /// Source reference for Ashura hadith
  ///
  /// In en, this message translates to:
  /// **'Sahih Muslim'**
  String get eventAshuraSource;

  /// Arabic text of Quran 2:203 for Days of Tashreeq dialog
  ///
  /// In en, this message translates to:
  /// **'وَاذْكُرُوا اللَّهَ فِي أَيَّامٍ مَّعْدُودَاتٍ'**
  String get eventDaysTashreeqArabic;

  /// Translation of Quran 2:203
  ///
  /// In en, this message translates to:
  /// **'And remember Allah during the appointed days.'**
  String get eventDaysTashreeqTranslation;

  /// Source reference for Days of Tashreeq ayah
  ///
  /// In en, this message translates to:
  /// **'Quran 2:203'**
  String get eventDaysTashreeqSource;

  /// Guidance text for Ramadan dialog
  ///
  /// In en, this message translates to:
  /// **'Fast from dawn to sunset, pray Tarawih at night, recite the Quran abundantly, give charity, increase in supplication, and seek forgiveness from Allah.'**
  String get eventRamadanGuidance;

  /// Guidance text for Last Ten Ramadan dialog
  ///
  /// In en, this message translates to:
  /// **'Seek Laylat al-Qadr especially on the odd nights. Increase your night prayers and perform I\'tikaf if possible. Recite often: Allahumma innaka \'Afuwwun tuhibbul-\'afwa fa\'fu \'anni.'**
  String get eventLastTenRamadanGuidance;

  /// Guidance text for Eid al-Fitr dialog
  ///
  /// In en, this message translates to:
  /// **'Pay Zakat al-Fitr before the Eid prayer. Perform the Eid prayer in congregation, recite the Takbir, wear your best clothes, and spread joy among family and neighbors.'**
  String get eventEidAlFitrGuidance;

  /// Guidance text for Eid al-Adha dialog
  ///
  /// In en, this message translates to:
  /// **'Perform the Eid prayer, offer the Udhiyah sacrifice after it, and recite the Takbir after every obligatory prayer. Share the meat with family, neighbors, and those in need.'**
  String get eventEidAlAdhaGuidance;

  /// Guidance text for Day of Arafah dialog
  ///
  /// In en, this message translates to:
  /// **'Fast this blessed day if you are not performing Hajj. Make abundant supplication, for it is the day Allah frees the most people from the Fire. Increase in Dhikr and recite La ilaha illAllah wahdahu la sharika lah.'**
  String get eventDayOfArafahGuidance;

  /// Guidance text for First Ten Dhul Hijjah dialog
  ///
  /// In en, this message translates to:
  /// **'Fast the first nine days, especially the Day of Arafah. Increase in righteous deeds, and recite the Takbir, Tahlil, and Tahmid abundantly throughout these days.'**
  String get eventFirstTenDhulHijjahGuidance;

  /// Guidance text for Ashura dialog
  ///
  /// In en, this message translates to:
  /// **'Fast on the 10th of Muharram, and add the 9th alongside it to follow the Sunnah. Remember that the Prophet fasted this day in gratitude to Allah for saving Musa from Pharaoh.'**
  String get eventAshuraGuidance;

  /// Guidance text for Days of Tashreeq dialog
  ///
  /// In en, this message translates to:
  /// **'Remember Allah abundantly and recite the Takbir after every obligatory prayer. These are days of eating, drinking, and gratitude. Fasting is not permitted on these days except for the pilgrim who cannot afford the sacrifice.'**
  String get eventDaysTashreeqGuidance;

  /// Title for the recurring White Days fasting reminder
  ///
  /// In en, this message translates to:
  /// **'The Sunnah of Fasting the White Days'**
  String get eventWhiteDaysFasting;

  /// Title for the recurring Monday and Thursday fasting reminder
  ///
  /// In en, this message translates to:
  /// **'The Sunnah of Monday–Thursday Fasting'**
  String get eventMondayThursdayFasting;

  /// Title when White Days and Monday or Thursday fasting overlap
  ///
  /// In en, this message translates to:
  /// **'White Days Coinciding with Monday or Thursday'**
  String get eventWhiteDaysMondayThursdayFasting;

  /// Concise subtitle for the White Days fasting reminder
  ///
  /// In en, this message translates to:
  /// **'Fasting the 13th, 14th, and 15th of every Hijri month.'**
  String get eventWhiteDaysFastingSubtitle;

  /// Concise subtitle for the Monday and Thursday fasting reminder
  ///
  /// In en, this message translates to:
  /// **'A voluntary fast on the two days when deeds are presented.'**
  String get eventMondayThursdayFastingSubtitle;

  /// Concise subtitle for the combined fasting reminder
  ///
  /// In en, this message translates to:
  /// **'A White Day that falls on a Monday or Thursday.'**
  String get eventWhiteDaysMondayThursdayFastingSubtitle;

  /// Arabic hadith text for the White Days fasting reminder
  ///
  /// In en, this message translates to:
  /// **'كَانَ يَأْمُرُنَا أَنْ نَصُومَ الْبِيضَ ثَلَاثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ'**
  String get eventWhiteDaysFastingArabic;

  /// Translation of the White Days hadith
  ///
  /// In en, this message translates to:
  /// **'He used to command us to fast the white days: the thirteenth, fourteenth, and fifteenth of the month.'**
  String get eventWhiteDaysFastingTranslation;

  /// Source for the White Days hadith
  ///
  /// In en, this message translates to:
  /// **'Sunan Abi Dawud 2449'**
  String get eventWhiteDaysFastingSource;

  /// Guidance for the White Days fasting dialog
  ///
  /// In en, this message translates to:
  /// **'Observe the White Days—the 13th, 14th, and 15th of the Hijri month—in accordance with the Sunnah of the Prophet ﷺ.'**
  String get eventWhiteDaysFastingGuidance;

  /// Arabic hadith text for the Monday and Thursday fasting reminder
  ///
  /// In en, this message translates to:
  /// **'تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ'**
  String get eventMondayThursdayFastingArabic;

  /// Translation of the Monday and Thursday fasting hadith
  ///
  /// In en, this message translates to:
  /// **'Deeds are presented on Monday and Thursday, and I love for my deeds to be presented while I am fasting.'**
  String get eventMondayThursdayFastingTranslation;

  /// Source for the Monday and Thursday fasting hadith
  ///
  /// In en, this message translates to:
  /// **'Jami at-Tirmidhi 747'**
  String get eventMondayThursdayFastingSource;

  /// Guidance for the Monday and Thursday fasting dialog
  ///
  /// In en, this message translates to:
  /// **'Fast as many Mondays and Thursdays as you are able, following the Sunnah of the Prophet ﷺ; deeds are presented on these days, and he loved for his deeds to be presented while he was fasting.'**
  String get eventMondayThursdayFastingGuidance;

  /// Arabic source text for the combined fasting reminder
  ///
  /// In en, this message translates to:
  /// **'كَانَ يَأْمُرُنَا أَنْ نَصُومَ الْبِيضَ ثَلَاثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ · تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ'**
  String get eventWhiteDaysMondayThursdayFastingArabic;

  /// Translation for the combined fasting reminder
  ///
  /// In en, this message translates to:
  /// **'The White Days are the 13th, 14th, and 15th of the Hijri month; deeds are presented on Monday and Thursday.'**
  String get eventWhiteDaysMondayThursdayFastingTranslation;

  /// Sources for the combined fasting reminder
  ///
  /// In en, this message translates to:
  /// **'Sunan Abi Dawud 2449 · Jami at-Tirmidhi 747'**
  String get eventWhiteDaysMondayThursdayFastingSource;

  /// Guidance for the combined fasting dialog
  ///
  /// In en, this message translates to:
  /// **'When a White Day falls on Monday or Thursday, make the most of it by observing the voluntary fast in accordance with the Sunnah of the Prophet ﷺ, and increase in supplication and remembrance.'**
  String get eventWhiteDaysMondayThursdayFastingGuidance;

  /// No description provided for @audios.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audios;

  /// No description provided for @audiobooks.
  ///
  /// In en, this message translates to:
  /// **'Islamic Audios'**
  String get audiobooks;

  /// No description provided for @audiobook.
  ///
  /// In en, this message translates to:
  /// **'Islamic Audio'**
  String get audiobook;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// chapter
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapter(int number);

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// No description provided for @continueBook.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueBook;

  /// resumePage
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String resumePage(int number);

  /// resumeChapter
  ///
  /// In en, this message translates to:
  /// **'Resume Chapter {number}'**
  String resumeChapter(int number);

  /// No description provided for @continueRadio.
  ///
  /// In en, this message translates to:
  /// **'Continue Radio'**
  String get continueRadio;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @endOfChapter.
  ///
  /// In en, this message translates to:
  /// **'End of Chapter'**
  String get endOfChapter;

  /// sleepTimerMinutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String sleepTimerMinutes(int minutes);

  /// No description provided for @downloadAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Download Islamic Audio'**
  String get downloadAudiobook;

  /// No description provided for @audiobookDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get audiobookDownloaded;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @noOfflineAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded Islamic audios'**
  String get noOfflineAudiobooks;

  /// chapterProgress
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String chapterProgress(int current, int total);

  /// AI chat error shown when there is no internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get chatErrorNoConnection;

  /// AI chat error shown when the user is rate limited (too many requests)
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Please wait a moment and try again.'**
  String get chatErrorRateLimit;

  /// AI chat error shown when the server is unavailable or returns an error
  ///
  /// In en, this message translates to:
  /// **'We\'re having trouble reaching the server. Please try again in a moment.'**
  String get chatErrorServer;

  /// AI chat error shown when a request is blocked by content safety policies
  ///
  /// In en, this message translates to:
  /// **'This request couldn\'t be completed due to content safety guidelines. Please rephrase and try again.'**
  String get chatErrorSafety;

  /// Generic AI chat error shown for unexpected failures
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get chatErrorGeneric;

  /// Hint for the optional email field in feedback forms
  ///
  /// In en, this message translates to:
  /// **'Email (optional — for a reply)'**
  String get emailOptional;

  /// Snackbar shown when error details are copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Error details copied to clipboard'**
  String get errorDetailsCopied;

  /// Button to restart the app on the error screen
  ///
  /// In en, this message translates to:
  /// **'Restart App'**
  String get restartAppButton;

  /// Copy button label on the error screen
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// Validation message when the feedback message is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a message before sending'**
  String get pleaseEnterMessage;

  /// Title of the feedback section on the error screen
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get helpUsImproveTitle;

  /// Prompt asking the user what they were doing when the error occurred
  ///
  /// In en, this message translates to:
  /// **'What were you doing when this error occurred? Your feedback helps us fix these issues faster.'**
  String get errorFeedbackPrompt;

  /// Hint for the error feedback message field
  ///
  /// In en, this message translates to:
  /// **'I was trying to...'**
  String get errorFeedbackHint;

  /// Thank you title shown after feedback is submitted
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get feedbackThankYou;

  /// Confirmation message shown after feedback is submitted
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been sent. We\'ll use it to improve the app.'**
  String get feedbackThankYouMessage;

  /// Hint for the screenshot feedback description field
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or feedback...'**
  String get describeIssueHint;

  /// Title for the prayer time settings bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Settings'**
  String get prayerSettingsTitle;

  /// Subtitle for the prayer time settings bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Method, madhab and fine-tuning'**
  String get prayerSettingsSubtitle;

  /// Prayer calculation method section title
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get prayerCalculationMethod;

  /// No description provided for @prayerCustomAnglesTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom angles'**
  String get prayerCustomAnglesTitle;

  /// No description provided for @prayerCustomAnglesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the Fajr, Maghrib, and Isha sun angles.'**
  String get prayerCustomAnglesSubtitle;

  /// No description provided for @prayerAngleRangeExclusive.
  ///
  /// In en, this message translates to:
  /// **'Enter an angle greater than 0° and up to 30°.'**
  String get prayerAngleRangeExclusive;

  /// No description provided for @prayerAngleRangeInclusive.
  ///
  /// In en, this message translates to:
  /// **'Enter an angle from 0° to 30°.'**
  String get prayerAngleRangeInclusive;

  /// No description provided for @prayerMaghribZeroMeansSunset.
  ///
  /// In en, this message translates to:
  /// **'0° means Maghrib is at sunset.'**
  String get prayerMaghribZeroMeansSunset;

  /// Asr madhab selection section title
  ///
  /// In en, this message translates to:
  /// **'Asr Method (Madhab)'**
  String get prayerAsrMethod;

  /// High latitude rule section title
  ///
  /// In en, this message translates to:
  /// **'High Latitude Rule'**
  String get prayerHighLatitudeRule;

  /// Prayer time manual adjustment section title
  ///
  /// In en, this message translates to:
  /// **'Time Adjustment'**
  String get prayerTimeAdjustment;

  /// Instruction for changing prayer time offsets
  ///
  /// In en, this message translates to:
  /// **'Tap + or - to adjust minutes'**
  String get prayerAdjustmentSubtitle;

  /// Automatic prayer calculation method option
  ///
  /// In en, this message translates to:
  /// **'Automatic (by country)'**
  String get prayerMethodAuto;

  /// No high latitude rule option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get prayerHighLatitudeNone;

  /// Middle of the night high latitude rule option
  ///
  /// In en, this message translates to:
  /// **'Middle of the Night'**
  String get prayerHighLatitudeMiddleOfTheNight;

  /// One-seventh high latitude rule option
  ///
  /// In en, this message translates to:
  /// **'One-Seventh of the Night'**
  String get prayerHighLatitudeSeventhOfTheNight;

  /// Twilight angle high latitude rule option
  ///
  /// In en, this message translates to:
  /// **'Twilight Angle'**
  String get prayerHighLatitudeTwilightAngle;

  /// Shafi madhab option
  ///
  /// In en, this message translates to:
  /// **'Shafi'**
  String get prayerMadhabShafi;

  /// Hanafi madhab option
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get prayerMadhabHanafi;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura'**
  String get prayerMethodUmmAlQura;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get prayerMethodMuslimWorldLeague;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority of Survey'**
  String get prayerMethodEgyptian;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get prayerMethodKarachi;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'North America (ISNA)'**
  String get prayerMethodNorthAmerica;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'UAE (GAIAE)'**
  String get prayerMethodEmirates;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get prayerMethodDubai;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Qatar Calendar House'**
  String get prayerMethodQatar;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get prayerMethodKuwait;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Oman'**
  String get prayerMethodOman;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Muscat, Oman'**
  String get prayerMethodOmanMuscat;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get prayerMethodJordan;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Palestine'**
  String get prayerMethodPalestine;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Syria (Hashemi)'**
  String get prayerMethodSyria;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Iraq'**
  String get prayerMethodIraq;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Morocco (Habous)'**
  String get prayerMethodMorocco;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Azrou, Morocco'**
  String get prayerMethodAzrou;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get prayerMethodAlgeria;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get prayerMethodTunisia;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Libya'**
  String get prayerMethodLibya;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Sudan'**
  String get prayerMethodSudan;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get prayerMethodTurkey;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Southeast Asia'**
  String get prayerMethodMalaysia;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get prayerMethodMalaysia2;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get prayerMethodIndonesia;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Kazakhstan'**
  String get prayerMethodKazakhstan;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Tajikistan'**
  String get prayerMethodTajikistan;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Maldives'**
  String get prayerMethodMaldives;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get prayerMethodSouthKorea;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'UOIF'**
  String get prayerMethodUoif;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Paris'**
  String get prayerMethodParis;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Toulouse'**
  String get prayerMethodToulouse;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Lyon'**
  String get prayerMethodLyon;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Orleans'**
  String get prayerMethodOrleans;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Moscow'**
  String get prayerMethodMoscow;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Czech Republic'**
  String get prayerMethodCzech;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Switzerland (Geneva)'**
  String get prayerMethodSwitzerland;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Fribourg, Switzerland'**
  String get prayerMethodFribourg;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Belgium'**
  String get prayerMethodBelgium;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Luxembourg'**
  String get prayerMethodLuxembourg;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get prayerMethodAustria;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'London'**
  String get prayerMethodLondon;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Birmingham'**
  String get prayerMethodBirmingham;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Blackburn'**
  String get prayerMethodBlackburn;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Aachen'**
  String get prayerMethodAachen;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Munich'**
  String get prayerMethodMunchen;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Potsdam'**
  String get prayerMethodPotsdam;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Nuremberg'**
  String get prayerMethodNurnberg;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Rotterdam'**
  String get prayerMethodRotterdam;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Dordrecht'**
  String get prayerMethodDordrecht;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Eindhoven'**
  String get prayerMethodEindhoven;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Montreal'**
  String get prayerMethodMontreal;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Windsor'**
  String get prayerMethodWindsor;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Calgary'**
  String get prayerMethodCalgary;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Mississauga'**
  String get prayerMethodMississauga;

  /// Prayer calculation method option label
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get prayerMethodOther;

  /// Apply button label in the prayer time settings sheet
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get prayerSettingsApply;

  /// No description provided for @customizeHome.
  ///
  /// In en, this message translates to:
  /// **'Customize Home'**
  String get customizeHome;

  /// No description provided for @editHome.
  ///
  /// In en, this message translates to:
  /// **'Edit Home'**
  String get editHome;

  /// No description provided for @homeTheme.
  ///
  /// In en, this message translates to:
  /// **'Home theme'**
  String get homeTheme;

  /// No description provided for @homeStyle.
  ///
  /// In en, this message translates to:
  /// **'Home style'**
  String get homeStyle;

  /// No description provided for @themeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// No description provided for @themePrayerToday.
  ///
  /// In en, this message translates to:
  /// **'Path of Prayer'**
  String get themePrayerToday;

  /// No description provided for @themeQuranJourney.
  ///
  /// In en, this message translates to:
  /// **'Quran Journey'**
  String get themeQuranJourney;

  /// No description provided for @themeClassicDescription.
  ///
  /// In en, this message translates to:
  /// **'A familiar grid with all your tools.'**
  String get themeClassicDescription;

  /// No description provided for @themePrayerTodayDescription.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and the next prayer first.'**
  String get themePrayerTodayDescription;

  /// No description provided for @themeQuranJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'Quran reading and Khatma progress first.'**
  String get themeQuranJourneyDescription;

  /// No description provided for @onHome.
  ///
  /// In en, this message translates to:
  /// **'On Home'**
  String get onHome;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @moveToHome.
  ///
  /// In en, this message translates to:
  /// **'Move to Home'**
  String get moveToHome;

  /// No description provided for @moveToViewMore.
  ///
  /// In en, this message translates to:
  /// **'Move to View More'**
  String get moveToViewMore;

  /// No description provided for @homeSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get homeSections;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @restoreDefaultLayout.
  ///
  /// In en, this message translates to:
  /// **'Restore default layout'**
  String get restoreDefaultLayout;

  /// No description provided for @restoreDefaultLayoutMessage.
  ///
  /// In en, this message translates to:
  /// **'This restores the order and places tools in their default sections for this home style.'**
  String get restoreDefaultLayoutMessage;

  /// No description provided for @viewMoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'Move less-used tools here to keep Home simple.'**
  String get viewMoreEmpty;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Home customization changes have not been applied.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @todaysAyah.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Ayah'**
  String get todaysAyah;

  /// No description provided for @khatmaProgress.
  ///
  /// In en, this message translates to:
  /// **'Khatma progress'**
  String get khatmaProgress;

  /// No description provided for @noActiveKhatma.
  ///
  /// In en, this message translates to:
  /// **'No active Khatma plan'**
  String get noActiveKhatma;

  /// No description provided for @prayerSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your location to show prayer times'**
  String get prayerSetupRequired;

  /// No description provided for @gregorianDate.
  ///
  /// In en, this message translates to:
  /// **'Gregorian Date'**
  String get gregorianDate;

  /// No description provided for @quranTools.
  ///
  /// In en, this message translates to:
  /// **'Quran tools'**
  String get quranTools;

  /// No description provided for @sectionDateAndPrayer.
  ///
  /// In en, this message translates to:
  /// **'Date and next prayer'**
  String get sectionDateAndPrayer;

  /// No description provided for @sectionPrayerSchedule.
  ///
  /// In en, this message translates to:
  /// **'Daily prayer schedule'**
  String get sectionPrayerSchedule;

  /// No description provided for @sectionDailyAyah.
  ///
  /// In en, this message translates to:
  /// **'Daily ayah'**
  String get sectionDailyAyah;

  /// No description provided for @sectionContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get sectionContinueReading;

  /// No description provided for @sectionKhatmaProgress.
  ///
  /// In en, this message translates to:
  /// **'Khatma progress'**
  String get sectionKhatmaProgress;

  /// No description provided for @sectionQuranTools.
  ///
  /// In en, this message translates to:
  /// **'Quran tools'**
  String get sectionQuranTools;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChangesAction;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @customizeHomeHint.
  ///
  /// In en, this message translates to:
  /// **'Press and drag any card to reorder. Use the button to move a tool between Home and View More.'**
  String get customizeHomeHint;

  /// No description provided for @homeChangesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your home changes. Try again.'**
  String get homeChangesSaveFailed;

  /// Fallback title for an unknown configured Islamic occasion
  ///
  /// In en, this message translates to:
  /// **'A Blessed Occasion'**
  String get eventSpecialOccasion;

  /// Fallback subtitle for an unknown configured Islamic occasion
  ///
  /// In en, this message translates to:
  /// **'A meaningful day in the Islamic calendar'**
  String get eventSpecialOccasionSubtitle;

  /// Respectful generic guidance for an unknown configured Islamic occasion
  ///
  /// In en, this message translates to:
  /// **'Mark this day with remembrance, gratitude, and reliable guidance specific to the occasion.'**
  String get eventSpecialOccasionGuidance;

  /// Accessible status label for routine neutral feedback
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get snackbarNeutral;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get enableNotifications;

  /// No description provided for @batteryOptimizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Android battery optimization can delay reminders. Allow Huda to run without optimization for more reliable alerts.'**
  String get batteryOptimizationDescription;

  /// No description provided for @batteryOptimizationExactAlarmDescription.
  ///
  /// In en, this message translates to:
  /// **'Android battery optimization can delay reminders. Allow Huda to run without optimization for more reliable alerts; on Android 12 and later, this also enables exact-time scheduling.'**
  String get batteryOptimizationExactAlarmDescription;

  /// No description provided for @keepRemindersReliable.
  ///
  /// In en, this message translates to:
  /// **'Allow reliable reminders'**
  String get keepRemindersReliable;

  /// No description provided for @prayerTimesPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Get prayer-time alerts'**
  String get prayerTimesPermissionTitle;

  /// No description provided for @prayerTimesPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to receive each prayer-time alert, even when Huda is closed.'**
  String get prayerTimesPermissionDescription;

  /// No description provided for @calendarPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Get calendar event reminders'**
  String get calendarPermissionTitle;

  /// No description provided for @calendarPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to be reminded about the Hijri calendar events you choose.'**
  String get calendarPermissionDescription;

  /// No description provided for @remindersPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable your reminders'**
  String get remindersPermissionTitle;

  /// No description provided for @remindersPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for the Quran, Athkar, Sahur, and other reminders you enable.'**
  String get remindersPermissionDescription;

  /// No description provided for @khatmaPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your Khatma on track'**
  String get khatmaPermissionTitle;

  /// No description provided for @khatmaPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to receive your daily wird reminder at the time you choose.'**
  String get khatmaPermissionDescription;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders on time'**
  String get batteryOptimizationTitle;

  /// No description provided for @notificationsReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on'**
  String get notificationsReadyTitle;

  /// No description provided for @notificationsReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your enabled reminders are ready to be delivered.'**
  String get notificationsReadyDescription;

  /// No description provided for @batteryOptimizationReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is off'**
  String get batteryOptimizationReadyTitle;

  /// No description provided for @batteryOptimizationReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Huda can run more reliably in the background.'**
  String get batteryOptimizationReadyDescription;

  /// No description provided for @exactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Use exact alarms instead'**
  String get exactAlarmTitle;

  /// No description provided for @exactAlarmDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep battery optimization on and allow exact alarms for precise scheduling. Battery restrictions may still delay delivery.'**
  String get exactAlarmDescription;

  /// No description provided for @allowExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get allowExactAlarms;

  /// No description provided for @exactAlarmsReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact-time scheduling is ready'**
  String get exactAlarmsReadyTitle;

  /// No description provided for @exactAlarmsReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Huda can schedule prayer alerts and reminders for their exact time.'**
  String get exactAlarmsReadyDescription;

  /// No description provided for @quranWidgetTypography.
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get quranWidgetTypography;

  /// No description provided for @ayahAutoFit.
  ///
  /// In en, this message translates to:
  /// **'Ayah Auto Fit'**
  String get ayahAutoFit;

  /// No description provided for @translationAutoFit.
  ///
  /// In en, this message translates to:
  /// **'Translation Auto Fit'**
  String get translationAutoFit;

  /// No description provided for @ayahTextSize.
  ///
  /// In en, this message translates to:
  /// **'Ayah size'**
  String get ayahTextSize;

  /// No description provided for @translationTextSize.
  ///
  /// In en, this message translates to:
  /// **'Translation size'**
  String get translationTextSize;

  /// No description provided for @boldAyah.
  ///
  /// In en, this message translates to:
  /// **'Bold ayah'**
  String get boldAyah;

  /// No description provided for @boldTranslation.
  ///
  /// In en, this message translates to:
  /// **'Bold translation'**
  String get boldTranslation;

  /// No description provided for @translationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translation language'**
  String get translationLanguage;

  /// No description provided for @translationLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language shown below the Arabic ayah.'**
  String get translationLanguageDescription;

  /// No description provided for @translationSource.
  ///
  /// In en, this message translates to:
  /// **'Translation by {source}'**
  String translationSource(String source);

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @quranWidgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Quran widget refreshed'**
  String get quranWidgetUpdated;

  /// No description provided for @forceQuranWidgetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Show another ayah'**
  String get forceQuranWidgetUpdate;

  /// No description provided for @quranWidgetUpdating.
  ///
  /// In en, this message translates to:
  /// **'Refreshing widget…'**
  String get quranWidgetUpdating;

  /// No description provided for @arabicTranslationHidden.
  ///
  /// In en, this message translates to:
  /// **'Arabic app language uses an Arabic-only widget.'**
  String get arabicTranslationHidden;

  /// No description provided for @aiHistory.
  ///
  /// In en, this message translates to:
  /// **'Huda AI history'**
  String get aiHistory;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get searchConversations;

  /// No description provided for @noChatHistory.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet'**
  String get noChatHistory;

  /// No description provided for @noHistoryResults.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations'**
  String get noHistoryResults;

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get clearAllHistory;

  /// No description provided for @clearAllHistoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all Huda AI conversations? This cannot be undone.'**
  String get clearAllHistoryConfirmation;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deleteChat;

  /// No description provided for @deleteChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This cannot be undone.'**
  String get deleteChatConfirmation;

  /// No description provided for @aiResponseGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get aiResponseGenerating;

  /// No description provided for @aiResponseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get aiResponseInterrupted;

  /// No description provided for @aiResponseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get aiResponseFailed;

  /// No description provided for @aiStorageWarning.
  ///
  /// In en, this message translates to:
  /// **'Huda AI history could not be saved on this device. This conversation will remain available until the app closes.'**
  String get aiStorageWarning;

  /// No description provided for @aiBusyOtherConversation.
  ///
  /// In en, this message translates to:
  /// **'Huda AI is answering another conversation.'**
  String get aiBusyOtherConversation;

  /// No description provided for @chatErrorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The response was interrupted. Try again to continue.'**
  String get chatErrorInterrupted;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @travelPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get travelPermissionRequired;

  /// No description provided for @travelAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get travelAllowLocation;

  /// No description provided for @travelTurnOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get travelTurnOnLocation;

  /// No description provided for @travelAllowAllTheTime.
  ///
  /// In en, this message translates to:
  /// **'Allow all the time'**
  String get travelAllowAllTheTime;

  /// No description provided for @travelBackgroundPermissionInstructions.
  ///
  /// In en, this message translates to:
  /// **'To update prayer times while Huda is closed, open the app\'s location permissions and select “{optionLabel}”.'**
  String travelBackgroundPermissionInstructions(String optionLabel);

  /// No description provided for @prayerNotificationIssueMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish scheduling your prayer notifications. Your prayer times are still available.'**
  String get prayerNotificationIssueMessage;

  /// No description provided for @prayerNotificationRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get prayerNotificationRetry;

  /// No description provided for @prayerNotificationsScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications are ready'**
  String get prayerNotificationsScheduledTitle;

  /// No description provided for @prayerNotificationsScheduledUntil.
  ///
  /// In en, this message translates to:
  /// **'Scheduled through {date}'**
  String prayerNotificationsScheduledUntil(String date);

  /// No description provided for @prayerNotificationsCoverageReminder.
  ///
  /// In en, this message translates to:
  /// **'Open Huda before then to extend the schedule.'**
  String get prayerNotificationsCoverageReminder;

  /// No description provided for @prayerNotificationsIosReminder.
  ///
  /// In en, this message translates to:
  /// **'Open Huda occasionally so we can keep your prayer notifications scheduled.'**
  String get prayerNotificationsIosReminder;

  /// No description provided for @prayerNotificationsCoverageExpired.
  ///
  /// In en, this message translates to:
  /// **'Your notification schedule has ended. Tap retry to renew it.'**
  String get prayerNotificationsCoverageExpired;

  /// No description provided for @prayerNotificationSettingsChanged.
  ///
  /// In en, this message translates to:
  /// **'Your prayer notification settings changed. Tap retry to update the schedule.'**
  String get prayerNotificationSettingsChanged;

  /// No description provided for @prayerNotificationSyncBusy.
  ///
  /// In en, this message translates to:
  /// **'Prayer notification scheduling is busy right now. Please try again shortly.'**
  String get prayerNotificationSyncBusy;

  /// No description provided for @prayerNotificationSyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer notification scheduling is temporarily unavailable.'**
  String get prayerNotificationSyncUnavailable;

  /// No description provided for @prayerNotificationSyncVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify the prayer notification schedule. Please try again.'**
  String get prayerNotificationSyncVerificationFailed;

  /// No description provided for @ayahAudioRange.
  ///
  /// In en, this message translates to:
  /// **'Choose ayahs'**
  String get ayahAudioRange;

  /// No description provided for @audioFromAyah.
  ///
  /// In en, this message translates to:
  /// **'From ayah'**
  String get audioFromAyah;

  /// No description provided for @audioToAyah.
  ///
  /// In en, this message translates to:
  /// **'To ayah'**
  String get audioToAyah;

  /// No description provided for @audioRepeatRange.
  ///
  /// In en, this message translates to:
  /// **'Repeat selection'**
  String get audioRepeatRange;

  /// No description provided for @audioRangeEndHint.
  ///
  /// In en, this message translates to:
  /// **'Playback stops after the last selected ayah.'**
  String get audioRangeEndHint;

  /// No description provided for @downloadAyah.
  ///
  /// In en, this message translates to:
  /// **'Download ayah'**
  String get downloadAyah;

  /// No description provided for @ayahDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Ayah downloaded'**
  String get ayahDownloaded;

  /// No description provided for @audioRangeRepeatHint.
  ///
  /// In en, this message translates to:
  /// **'The selected ayahs repeat until you stop playback.'**
  String get audioRangeRepeatHint;

  /// Current ayah and total number of ayahs in the mini audio player
  ///
  /// In en, this message translates to:
  /// **'Ayah {current} of {total}'**
  String playingAyahOfTotal(int current, int total);

  /// No description provided for @prayerNotificationsBridgedUntil.
  ///
  /// In en, this message translates to:
  /// **'Notifications are updated through {date}. Later ones may still follow your previous settings or location. Come back when you have internet to update them.'**
  String prayerNotificationsBridgedUntil(String date);

  /// No description provided for @prayerIssueLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Location access'**
  String get prayerIssueLocationAccess;

  /// No description provided for @prayerCountryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which country are you in?'**
  String get prayerCountryQuestion;

  /// No description provided for @prayerCountryQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Your country couldn\'t be confirmed automatically, for example near a border. Choose it to use the right calculation method.'**
  String get prayerCountryQuestionHint;

  /// No description provided for @prayerCountryNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get prayerCountryNotSure;

  /// No description provided for @prayerCalendarShare.
  ///
  /// In en, this message translates to:
  /// **'Share prayer calendar'**
  String get prayerCalendarShare;

  /// No description provided for @prayerCalendarOneDay.
  ///
  /// In en, this message translates to:
  /// **'One day'**
  String get prayerCalendarOneDay;

  /// No description provided for @prayerCalendarOneMonth.
  ///
  /// In en, this message translates to:
  /// **'One month'**
  String get prayerCalendarOneMonth;

  /// No description provided for @prayerCalendarWholeYear.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get prayerCalendarWholeYear;

  /// No description provided for @prayerCalendarGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate and share'**
  String get prayerCalendarGenerate;

  /// No description provided for @prayerCalendarPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing page {current} of {total}…'**
  String prayerCalendarPreparing(Object current, Object total);

  /// No description provided for @prayerCalendarError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate or share the prayer calendar. Please try again.'**
  String get prayerCalendarError;

  /// No description provided for @prayerCalendarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Verified prayer times are needed before sharing.'**
  String get prayerCalendarUnavailable;

  /// No description provided for @prayerCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer time calendar'**
  String get prayerCalendarTitle;

  /// No description provided for @prayerCalendarDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get prayerCalendarDate;

  /// No description provided for @prayerCalendarDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get prayerCalendarDay;

  /// No description provided for @prayerCalendarTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get prayerCalendarTimeZone;

  /// No description provided for @prayerCalendarGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String prayerCalendarGenerated(Object date);

  /// No description provided for @prayerCalendarPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String prayerCalendarPage(Object page, Object total);

  /// No description provided for @prayerCalendarShareText.
  ///
  /// In en, this message translates to:
  /// **'Prayer times for {period} in {location}'**
  String prayerCalendarShareText(Object location, Object period);

  /// No description provided for @prayerCalendarSunriseColumn.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerCalendarSunriseColumn;

  /// No description provided for @prayerNotificationsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications are off'**
  String get prayerNotificationsOffTitle;

  /// No description provided for @prayerNotificationsOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off, so no prayer alerts are scheduled. Turn them on to get an alert at each prayer time.'**
  String get prayerNotificationsOffMessage;

  /// No description provided for @prayerNotificationsTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get prayerNotificationsTurnOn;

  /// No description provided for @prayerNotificationsWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications are waiting'**
  String get prayerNotificationsWaitingTitle;

  /// No description provided for @prayerNotificationsWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts will be scheduled once your location is verified.'**
  String get prayerNotificationsWaitingMessage;

  /// No description provided for @prayerNotificationsNoneScheduled.
  ///
  /// In en, this message translates to:
  /// **'No prayer notifications are scheduled yet. Tap retry to schedule them.'**
  String get prayerNotificationsNoneScheduled;

  /// No description provided for @prayerSetupStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String prayerSetupStepLabel(int step, int total);

  /// No description provided for @prayerSetupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get prayerSetupLocationTitle;

  /// No description provided for @prayerSetupLocationIntro.
  ///
  /// In en, this message translates to:
  /// **'Huda needs your location to calculate prayer times for where you are.'**
  String get prayerSetupLocationIntro;

  /// No description provided for @prayerSetupLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this device. Turn them on — prayer times load automatically when you come back.'**
  String get prayerSetupLocationServicesOff;

  /// No description provided for @prayerSetupUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get prayerSetupUseMyLocation;

  /// No description provided for @prayerSetupSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search for a city'**
  String get prayerSetupSearchCity;

  /// No description provided for @prayerSetupAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get prayerSetupAlertsTitle;

  /// No description provided for @prayerSetupAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'An alert at each prayer time, even when Huda is closed.'**
  String get prayerSetupAlertsHint;

  /// No description provided for @prayerSetupReliableTitle.
  ///
  /// In en, this message translates to:
  /// **'Reliable reminders'**
  String get prayerSetupReliableTitle;

  /// No description provided for @prayerTimelineNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get prayerTimelineNext;

  /// No description provided for @prayerTimelineNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get prayerTimelineNow;

  /// No description provided for @prayerHeroStarted.
  ///
  /// In en, this message translates to:
  /// **'Prayer time started'**
  String get prayerHeroStarted;

  /// No description provided for @prayerTimesProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional times'**
  String get prayerTimesProvisional;

  /// No description provided for @prayerMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get prayerMoreOptions;

  /// No description provided for @prayerOffsetBadge.
  ///
  /// In en, this message translates to:
  /// **'{offset} min'**
  String prayerOffsetBadge(String offset);

  /// No description provided for @prayerSetupAlertsIntro.
  ///
  /// In en, this message translates to:
  /// **'Get a gentle alert at every prayer time, even when Huda is closed.'**
  String get prayerSetupAlertsIntro;

  /// No description provided for @prayerSetupAlertsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow prayer alerts'**
  String get prayerSetupAlertsAllow;

  /// No description provided for @prayerSetupAlertsDeclined.
  ///
  /// In en, this message translates to:
  /// **'Without notifications, Huda can\'t remind you when it\'s time to pray. Prayer times still show here, and you can turn alerts on later.'**
  String get prayerSetupAlertsDeclined;

  /// No description provided for @prayerSetupContinueWithoutAlerts.
  ///
  /// In en, this message translates to:
  /// **'Continue without alerts'**
  String get prayerSetupContinueWithoutAlerts;

  /// No description provided for @prayerSetupAlertsOn.
  ///
  /// In en, this message translates to:
  /// **'Alerts are on'**
  String get prayerSetupAlertsOn;

  /// No description provided for @prayerSetupReliableIntro.
  ///
  /// In en, this message translates to:
  /// **'Android can hold back alerts to save battery. Let Huda run without battery restrictions so every alert arrives on time.'**
  String get prayerSetupReliableIntro;

  /// No description provided for @prayerSetupReliableOn.
  ///
  /// In en, this message translates to:
  /// **'Alerts will arrive on time'**
  String get prayerSetupReliableOn;

  /// No description provided for @prayerHeroRemaining.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get prayerHeroRemaining;

  /// No description provided for @prayerSunriseLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunriseLabel;

  /// No description provided for @prayerCalendarFormatImage.
  ///
  /// In en, this message translates to:
  /// **'Shared as an image'**
  String get prayerCalendarFormatImage;

  /// No description provided for @prayerCalendarFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'Shared as a PDF document'**
  String get prayerCalendarFormatPdf;

  /// No description provided for @prayerHeroStartedAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{Started just now} =1{Started 1 min ago} other{Started {minutes} min ago}}'**
  String prayerHeroStartedAgo(int minutes);

  /// No description provided for @macPrayerMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Bar Prayer Times'**
  String get macPrayerMenuTitle;

  /// No description provided for @macPrayerMenuDescription.
  ///
  /// In en, this message translates to:
  /// **'Show prayer times and a countdown after closing Huda.'**
  String get macPrayerMenuDescription;

  /// No description provided for @macPrayerMenuStyle.
  ///
  /// In en, this message translates to:
  /// **'Menu bar label'**
  String get macPrayerMenuStyle;

  /// No description provided for @macPrayerMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Prayer Settings…'**
  String get macPrayerMenuSettings;

  /// No description provided for @macPrayerMenuQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Huda'**
  String get macPrayerMenuQuit;

  /// No description provided for @macPrayerMenuNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Open Huda Prayer Times to set your location.'**
  String get macPrayerMenuNeedsSetup;

  /// No description provided for @macPrayerMenuVerifyLocation.
  ///
  /// In en, this message translates to:
  /// **'Verify location in Huda'**
  String get macPrayerMenuVerifyLocation;

  /// No description provided for @macPrayerMenuNameCountdown.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {time}'**
  String macPrayerMenuNameCountdown(String prayer, String time);

  /// No description provided for @macPrayerMenuIconOnly.
  ///
  /// In en, this message translates to:
  /// **'Icon only'**
  String get macPrayerMenuIconOnly;

  /// No description provided for @macPrayerMenuError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the menu bar. Try again.'**
  String get macPrayerMenuError;

  /// No description provided for @macPrayerMenuHourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get macPrayerMenuHourShort;

  /// No description provided for @macPrayerMenuMinuteShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get macPrayerMenuMinuteShort;

  /// No description provided for @windowsPrayerTaskbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Windows Prayer Countdown'**
  String get windowsPrayerTaskbarTitle;

  /// No description provided for @windowsPrayerTaskbarDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep the prayer countdown running after closing Huda. Quit Huda from the tray to stop it for this session.'**
  String get windowsPrayerTaskbarDescription;

  /// No description provided for @windowsPrayerShowTaskbar.
  ///
  /// In en, this message translates to:
  /// **'Show taskbar countdown'**
  String get windowsPrayerShowTaskbar;

  /// No description provided for @windowsPrayerStartup.
  ///
  /// In en, this message translates to:
  /// **'Start with Windows'**
  String get windowsPrayerStartup;

  /// No description provided for @windowsPrayerSeconds.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get windowsPrayerSeconds;

  /// No description provided for @windowsPrayerStartupDisabled.
  ///
  /// In en, this message translates to:
  /// **'Startup is disabled in Windows settings.'**
  String get windowsPrayerStartupDisabled;

  /// No description provided for @windowsPrayerOpenStartupSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Windows startup settings'**
  String get windowsPrayerOpenStartupSettings;

  /// No description provided for @windowsPrayerPlacementUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The countdown cannot be placed on this taskbar. The tray popup is available when its icon is enabled.'**
  String get windowsPrayerPlacementUnavailable;

  /// No description provided for @windowsPrayerHelperUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Windows countdown companion is unavailable. Repair or update your Huda installation.'**
  String get windowsPrayerHelperUnavailable;

  /// No description provided for @windowsPrayerOpenHuda.
  ///
  /// In en, this message translates to:
  /// **'Open Huda'**
  String get windowsPrayerOpenHuda;

  /// No description provided for @windowsPrayerCalendarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ramadan calendar data is unavailable for this date.'**
  String get windowsPrayerCalendarUnavailable;

  /// No description provided for @windowsPrayerNoNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'No upcoming prayer time is available.'**
  String get windowsPrayerNoNextPrayer;

  /// No description provided for @windowsPrayerStartupEffectiveEnabled.
  ///
  /// In en, this message translates to:
  /// **'Windows startup: enabled'**
  String get windowsPrayerStartupEffectiveEnabled;

  /// No description provided for @windowsPrayerStartupEffectiveDisabled.
  ///
  /// In en, this message translates to:
  /// **'Windows startup: disabled'**
  String get windowsPrayerStartupEffectiveDisabled;

  /// No description provided for @windowsPrayerStyle.
  ///
  /// In en, this message translates to:
  /// **'Taskbar label'**
  String get windowsPrayerStyle;

  /// No description provided for @windowsPrayerPreview.
  ///
  /// In en, this message translates to:
  /// **'Taskbar preview'**
  String get windowsPrayerPreview;

  /// No description provided for @windowsPrayerStyleCountdown.
  ///
  /// In en, this message translates to:
  /// **'Prayer name and countdown'**
  String get windowsPrayerStyleCountdown;

  /// No description provided for @windowsPrayerStyleClock.
  ///
  /// In en, this message translates to:
  /// **'Prayer name and time'**
  String get windowsPrayerStyleClock;

  /// No description provided for @windowsPrayerTransparentBackground.
  ///
  /// In en, this message translates to:
  /// **'Transparent background'**
  String get windowsPrayerTransparentBackground;

  /// No description provided for @windowsPrayerShowIcon.
  ///
  /// In en, this message translates to:
  /// **'Show Huda logo'**
  String get windowsPrayerShowIcon;

  /// No description provided for @windowsPrayerTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get windowsPrayerTextColor;

  /// No description provided for @windowsPrayerTextColorAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic (Windows taskbar)'**
  String get windowsPrayerTextColorAutomatic;

  /// No description provided for @windowsPrayerTextColorLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get windowsPrayerTextColorLight;

  /// No description provided for @windowsPrayerTextColorDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get windowsPrayerTextColorDark;

  /// No description provided for @windowsPrayerTextColorApp.
  ///
  /// In en, this message translates to:
  /// **'App color'**
  String get windowsPrayerTextColorApp;

  /// No description provided for @windowsPrayerTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get windowsPrayerTextSize;

  /// No description provided for @windowsPrayerTextSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get windowsPrayerTextSizeSmall;

  /// No description provided for @windowsPrayerTextSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get windowsPrayerTextSizeMedium;

  /// No description provided for @windowsPrayerTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get windowsPrayerTextSizeLarge;

  /// No description provided for @windowsPrayerResetAppearance.
  ///
  /// In en, this message translates to:
  /// **'Reset appearance'**
  String get windowsPrayerResetAppearance;

  /// No description provided for @windowsPrayerError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the Windows countdown. Try again.'**
  String get windowsPrayerError;

  /// No description provided for @windowsPrayerFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get windowsPrayerFocusMode;

  /// No description provided for @windowsPrayerStopAdhan.
  ///
  /// In en, this message translates to:
  /// **'Stop Adhan'**
  String get windowsPrayerStopAdhan;

  /// No description provided for @windowsPrayerDismissFocus.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get windowsPrayerDismissFocus;

  /// No description provided for @windowsPrayerFocusMessage.
  ///
  /// In en, this message translates to:
  /// **'It is time to pray. Take a break.'**
  String get windowsPrayerFocusMessage;

  /// No description provided for @windowsPrayerFocusExitHint.
  ///
  /// In en, this message translates to:
  /// **'Dismiss or press Escape at any time.'**
  String get windowsPrayerFocusExitHint;

  /// No description provided for @windowsPrayerNextNotification.
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer} in {duration}'**
  String windowsPrayerNextNotification(String prayer, String duration);

  /// No description provided for @windowsPrayerFocusLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Focus ends when the timer reaches zero.'**
  String get windowsPrayerFocusLockedHint;

  /// No description provided for @windowsPrayerFocusVerseReference.
  ///
  /// In en, this message translates to:
  /// **'An-Nisa · 4:103'**
  String get windowsPrayerFocusVerseReference;

  /// No description provided for @windowsPrayerFocusTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get windowsPrayerFocusTimeRemaining;

  /// No description provided for @macPrayerLoginSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Login Items Settings'**
  String get macPrayerLoginSettings;

  /// No description provided for @macPrayerEmergencyExit.
  ///
  /// In en, this message translates to:
  /// **'Emergency exit'**
  String get macPrayerEmergencyExit;

  /// No description provided for @macPrayerApplyError.
  ///
  /// In en, this message translates to:
  /// **'Could not apply macOS prayer settings. Refresh and try again.'**
  String get macPrayerApplyError;

  /// No description provided for @macPrayerVerse.
  ///
  /// In en, this message translates to:
  /// **'﴿ إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَٰبًا مَّوْقُوتًا ﴾'**
  String get macPrayerVerse;

  /// No description provided for @iosPrayerAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder'**
  String get iosPrayerAdvanceTitle;

  /// No description provided for @iosPrayerAdvanceBody.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {minutes} minutes.'**
  String iosPrayerAdvanceBody(String prayer, String minutes);

  /// No description provided for @iosPrayerRenewalTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend prayer alerts'**
  String get iosPrayerRenewalTitle;

  /// No description provided for @iosPrayerRenewalBody.
  ///
  /// In en, this message translates to:
  /// **'Open Huda to extend your scheduled prayer alerts.'**
  String get iosPrayerRenewalBody;

  /// No description provided for @linuxPrayerTrayTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer panel'**
  String get linuxPrayerTrayTitle;

  /// No description provided for @linuxPrayerTrayDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep prayer times in the GNOME top panel when Huda is closed.'**
  String get linuxPrayerTrayDescription;

  /// No description provided for @linuxPrayerTrayStartAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Start at login'**
  String get linuxPrayerTrayStartAtLogin;

  /// No description provided for @linuxRemindersReady.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive even when Huda is closed'**
  String get linuxRemindersReady;

  /// Shown on Linux when reminders depend on the background prayer service that may not start at login.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive only while Huda’s background service runs. Turn on “Start at login” in Prayer Times to keep them after restarting.'**
  String get linuxRemindersNeedService;

  /// No description provided for @windowsRemindersReady.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive even when Huda is closed'**
  String get windowsRemindersReady;

  /// Shown on Windows when reminders will run out unless renewed; date is a formatted day.
  ///
  /// In en, this message translates to:
  /// **'Reminders are queued until {date}'**
  String windowsRemindersQueuedUntil(String date);

  /// No description provided for @windowsRemindersNeedStartup.
  ///
  /// In en, this message translates to:
  /// **'Turn on “Start with Windows” so Huda renews them without being opened.'**
  String get windowsRemindersNeedStartup;

  /// No description provided for @windowsRemindersOpenHuda.
  ///
  /// In en, this message translates to:
  /// **'Open Huda before then to keep them going.'**
  String get windowsRemindersOpenHuda;

  /// No description provided for @linuxPrayerTrayInstall.
  ///
  /// In en, this message translates to:
  /// **'Set up prayer panel'**
  String get linuxPrayerTrayInstall;

  /// No description provided for @linuxPrayerTrayInstallHelp.
  ///
  /// In en, this message translates to:
  /// **'One-time setup is needed for the prayer panel.'**
  String get linuxPrayerTrayInstallHelp;

  /// No description provided for @linuxPrayerTrayExtensionMissing.
  ///
  /// In en, this message translates to:
  /// **'Panel extension is not installed.'**
  String get linuxPrayerTrayExtensionMissing;

  /// No description provided for @linuxPrayerTrayExtensionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Panel extension is disabled.'**
  String get linuxPrayerTrayExtensionDisabled;

  /// No description provided for @linuxPrayerTrayExtensionIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Update the panel extension for this GNOME version.'**
  String get linuxPrayerTrayExtensionIncompatible;

  /// No description provided for @linuxPrayerTrayAvailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer panel is ready.'**
  String get linuxPrayerTrayAvailable;

  /// No description provided for @linuxPrayerTrayServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer display is unavailable. Open Huda to restart it.'**
  String get linuxPrayerTrayServiceUnavailable;

  /// No description provided for @linuxPrayerTrayCalculationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are unavailable. Check your location and calculation settings.'**
  String get linuxPrayerTrayCalculationUnavailable;

  /// No description provided for @linuxPrayerTrayQuitExplanation.
  ///
  /// In en, this message translates to:
  /// **'Quit Huda and the prayer panel for this session. Existing prayer notifications continue.'**
  String get linuxPrayerTrayQuitExplanation;

  /// No description provided for @linuxPrayerTrayStopped.
  ///
  /// In en, this message translates to:
  /// **'Prayer panel is stopped.'**
  String get linuxPrayerTrayStopped;

  /// No description provided for @linuxPrayerTrayError.
  ///
  /// In en, this message translates to:
  /// **'Prayer panel settings could not be applied.'**
  String get linuxPrayerTrayError;

  /// No description provided for @linuxPrayerTrayRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart prayer panel'**
  String get linuxPrayerTrayRestart;

  /// No description provided for @linuxPrayerTrayCopyCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get linuxPrayerTrayCopyCommand;

  /// No description provided for @linuxPrayerTrayCommandCopied.
  ///
  /// In en, this message translates to:
  /// **'Command copied. Paste it in Terminal and press Enter.'**
  String get linuxPrayerTrayCommandCopied;

  /// No description provided for @linuxPrayerTrayUpdateStep.
  ///
  /// In en, this message translates to:
  /// **'Update Huda to a release that supports your GNOME version before reinstalling the panel.'**
  String get linuxPrayerTrayUpdateStep;

  /// No description provided for @linuxPanelIntro.
  ///
  /// In en, this message translates to:
  /// **'See the next prayer in your top bar, with adhan alerts even when Huda is closed. One-time setup, about a minute.'**
  String get linuxPanelIntro;

  /// No description provided for @linuxPanelCopyStep.
  ///
  /// In en, this message translates to:
  /// **'Copy the setup command'**
  String get linuxPanelCopyStep;

  /// No description provided for @linuxPanelTerminalStep.
  ///
  /// In en, this message translates to:
  /// **'Open Terminal (Ctrl+Alt+T), paste it with Ctrl+Shift+V and press Enter'**
  String get linuxPanelTerminalStep;

  /// No description provided for @linuxPanelAutoStep.
  ///
  /// In en, this message translates to:
  /// **'That’s it. Huda notices by itself when the panel is on.'**
  String get linuxPanelAutoStep;

  /// No description provided for @linuxPanelWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the panel…'**
  String get linuxPanelWaiting;

  /// No description provided for @linuxPanelLogoutHint.
  ///
  /// In en, this message translates to:
  /// **'If Terminal asks you to log out, log out and back in. The panel then turns on by itself, so you can continue now.'**
  String get linuxPanelLogoutHint;

  /// No description provided for @linuxPanelReady.
  ///
  /// In en, this message translates to:
  /// **'The prayer panel is on. Look at the top of your screen.'**
  String get linuxPanelReady;

  /// No description provided for @linuxPanelAfterLogin.
  ///
  /// In en, this message translates to:
  /// **'Turns on after your next login'**
  String get linuxPanelAfterLogin;

  /// No description provided for @linuxPrayerExperienceQuitInfo.
  ///
  /// In en, this message translates to:
  /// **'Closing the window keeps background reminders running. Quit Huda stops prayer reminders, Adhan and Focus until you reopen Huda.'**
  String get linuxPrayerExperienceQuitInfo;

  /// No description provided for @linuxPrayerExperienceCommitmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Normal Dismiss is hidden until the timer ends. Emergency exit, Escape and Quit Huda remain available. Previews always allow immediate exit.'**
  String get linuxPrayerExperienceCommitmentInfo;

  /// No description provided for @samsungLockWidgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Samsung lock screen widgets'**
  String get samsungLockWidgetsTitle;

  /// No description provided for @samsungLockWidgetsInstructions.
  ///
  /// In en, this message translates to:
  /// **'On Samsung One UI 8, touch and hold your lock screen, tap Add widgets, and select Huda. Choose a prayer countdown or Quran verse, then tap Done.'**
  String get samsungLockWidgetsInstructions;

  /// No description provided for @samsungLockWidgetsHint.
  ///
  /// In en, this message translates to:
  /// **'The lock screen has limited space. Choose the widgets that suit you.'**
  String get samsungLockWidgetsHint;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Sends a notification in about 10 seconds through the same path as your reminders. You can close Huda while you wait.'**
  String get testNotificationDescription;

  /// No description provided for @testNotificationSend.
  ///
  /// In en, this message translates to:
  /// **'Send test'**
  String get testNotificationSend;

  /// No description provided for @testNotificationContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Huda test notification'**
  String get testNotificationContentTitle;

  /// No description provided for @testNotificationContentBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications from Huda are working.'**
  String get testNotificationContentBody;

  /// No description provided for @testNotificationArrivesSoon.
  ///
  /// In en, this message translates to:
  /// **'A test notification arrives in about 10 seconds. You can close Huda.'**
  String get testNotificationArrivesSoon;

  /// No description provided for @testNotificationMayBeLate.
  ///
  /// In en, this message translates to:
  /// **'A test notification is on its way. Exact alarms are off, so it may arrive a few minutes late.'**
  String get testNotificationMayBeLate;

  /// No description provided for @testNotificationNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Huda. Turn them on, then try again.'**
  String get testNotificationNotificationsOff;

  /// No description provided for @testNotificationServiceNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Huda’s background service isn’t running, so notifications can’t arrive. Start it from Prayer Times, then try again.'**
  String get testNotificationServiceNotRunning;

  /// No description provided for @testNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'The test notification couldn’t be scheduled. Please try again.'**
  String get testNotificationFailed;

  /// Button in a sheet that explains a permission, before the system prompt is shown.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permissionExplainerContinue;

  /// Declines a permission explanation or hides a prayer readiness step.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionExplainerNotNow;

  /// No description provided for @permissionExplainerNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get permissionExplainerNotificationsTitle;

  /// No description provided for @permissionExplainerNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Huda needs notifications to remind you at the times you choose. Your device will ask you next.'**
  String get permissionExplainerNotificationsMessage;

  /// Heading of the card on Prayer Times that walks through what prayer alerts still need.
  ///
  /// In en, this message translates to:
  /// **'Get prayer alerts ready'**
  String get prayerReadyTitle;

  /// Heading when more than one readiness step is left.
  ///
  /// In en, this message translates to:
  /// **'Get prayer alerts ready · {count} steps'**
  String prayerReadyStepsLeft(int count);

  /// No description provided for @prayerReadyNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications for Huda are turned off. Turn them on in Settings, then come back here.'**
  String get prayerReadyNotificationsBlocked;

  /// No description provided for @prayerReadyChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts are muted'**
  String get prayerReadyChannelsTitle;

  /// No description provided for @prayerReadyChannelsMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on, but Android is blocking Huda\'s prayer alert category. Turn it on so each prayer can alert you.'**
  String get prayerReadyChannelsMessage;

  /// No description provided for @prayerReadyExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts right on time'**
  String get prayerReadyExactTitle;

  /// No description provided for @prayerReadyExactMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow Huda to set alarms so each prayer alert arrives exactly on time instead of a few minutes late.'**
  String get prayerReadyExactMessage;

  /// No description provided for @prayerReadyAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get prayerReadyAllow;

  /// No description provided for @prayerReadyAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow prayer alarms'**
  String get prayerReadyAlarmTitle;

  /// No description provided for @prayerReadyAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'Prayer Alarm plays the adhan like an alarm, even in silent mode. Your iPhone needs your permission for that.'**
  String get prayerReadyAlarmMessage;

  /// No description provided for @prayerReadyBannersTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Huda\'s notifications'**
  String get prayerReadyBannersTitle;

  /// No description provided for @prayerReadyBannersMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed, but macOS is set not to show them. Choose Banners or Alerts for Huda in Notification settings.'**
  String get prayerReadyBannersMessage;

  /// No description provided for @prayerReadyLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Let Huda start at login'**
  String get prayerReadyLoginTitle;

  /// No description provided for @prayerReadyLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'The adhan plays from Huda in the menu bar. Let it start when you log in so it keeps working after a restart.'**
  String get prayerReadyLoginMessage;

  /// No description provided for @prayerReadyWindowsStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Huda with Windows'**
  String get prayerReadyWindowsStartupTitle;

  /// No description provided for @prayerReadyWindowsStartupMessage.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s background helper plays the adhan and keeps reminders coming. Let it start with Windows so they continue after a restart.'**
  String get prayerReadyWindowsStartupMessage;

  /// No description provided for @prayerReadyLinuxStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Huda at login'**
  String get prayerReadyLinuxStartupTitle;

  /// No description provided for @prayerReadyLinuxStartupMessage.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s background service delivers prayer alerts and reminders. Let it start when you log in so they continue after a restart.'**
  String get prayerReadyLinuxStartupMessage;

  /// No description provided for @prayerReadyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get prayerReadyTurnOn;

  /// No description provided for @travelExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Update times when you travel'**
  String get travelExplainerTitle;

  /// No description provided for @travelExplainerMessage.
  ///
  /// In en, this message translates to:
  /// **'When you arrive in a new city, Huda updates prayer times and alerts by itself. To notice the move while Huda is closed, your device will ask to allow location all the time.'**
  String get travelExplainerMessage;

  /// Title of the prayer alert settings sheet and its summary card.
  ///
  /// In en, this message translates to:
  /// **'Adhan & alerts'**
  String get prayerAlertTitle;

  /// No description provided for @prayerAlertMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get prayerAlertMasterTitle;

  /// No description provided for @prayerAlertMasterOff.
  ///
  /// In en, this message translates to:
  /// **'No alerts at prayer times'**
  String get prayerAlertMasterOff;

  /// No description provided for @prayerAlertPrayersOn.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 prayers'**
  String prayerAlertPrayersOn(int count);

  /// Shown while changes made in the sheet are being applied.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get prayerAlertSaving;

  /// No description provided for @prayerAlertSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get prayerAlertSaved;

  /// No description provided for @prayerAlertNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get prayerAlertNotSaved;

  /// No description provided for @prayerAlertRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying…'**
  String get prayerAlertRetrying;

  /// No description provided for @prayerAlertUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get prayerAlertUndo;

  /// No description provided for @prayerAlertFailureCompanion.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s Windows helper isn\'t running, so the adhan can\'t be set. Start Huda\'s taskbar helper, then try again.'**
  String get prayerAlertFailureCompanion;

  /// No description provided for @prayerAlertFailureService.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s background service isn\'t answering. Try again in a moment.'**
  String get prayerAlertFailureService;

  /// No description provided for @prayerAlertFailureSchedule.
  ///
  /// In en, this message translates to:
  /// **'The new settings couldn\'t be scheduled. Your previous alerts are still set.'**
  String get prayerAlertFailureSchedule;

  /// No description provided for @prayerAlertFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your changes couldn\'t be saved.'**
  String get prayerAlertFailureUnknown;

  /// No description provided for @prayerAlertStartupWarning.
  ///
  /// In en, this message translates to:
  /// **'Saved, but macOS didn\'t let Huda start at login. Check Login Items in System Settings.'**
  String get prayerAlertStartupWarning;

  /// No description provided for @prayerAlertSectionStyle.
  ///
  /// In en, this message translates to:
  /// **'How prayers alert you'**
  String get prayerAlertSectionStyle;

  /// No description provided for @prayerAlertSectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get prayerAlertSectionSound;

  /// No description provided for @prayerAlertSectionPrayers.
  ///
  /// In en, this message translates to:
  /// **'Each prayer'**
  String get prayerAlertSectionPrayers;

  /// No description provided for @prayerAlertSectionBefore.
  ///
  /// In en, this message translates to:
  /// **'Before the prayer'**
  String get prayerAlertSectionBefore;

  /// No description provided for @prayerAlertSectionTest.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get prayerAlertSectionTest;

  /// No description provided for @prayerAlertSectionFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get prayerAlertSectionFocus;

  /// No description provided for @prayerAlertSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get prayerAlertSectionMore;

  /// No description provided for @prayerAlertStyleOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prayerAlertStyleOff;

  /// No description provided for @prayerAlertStyleOffHint.
  ///
  /// In en, this message translates to:
  /// **'No alert for this prayer'**
  String get prayerAlertStyleOffHint;

  /// No description provided for @prayerAlertStyleSilent.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get prayerAlertStyleSilent;

  /// No description provided for @prayerAlertStyleSilentHint.
  ///
  /// In en, this message translates to:
  /// **'A notification without the adhan'**
  String get prayerAlertStyleSilentHint;

  /// No description provided for @prayerAlertStyleShort.
  ///
  /// In en, this message translates to:
  /// **'Short adhan'**
  String get prayerAlertStyleShort;

  /// No description provided for @prayerAlertStyleShortHint.
  ///
  /// In en, this message translates to:
  /// **'A notification with the opening of the adhan'**
  String get prayerAlertStyleShortHint;

  /// No description provided for @prayerAlertStyleFull.
  ///
  /// In en, this message translates to:
  /// **'Full adhan'**
  String get prayerAlertStyleFull;

  /// No description provided for @prayerAlertStyleFullHint.
  ///
  /// In en, this message translates to:
  /// **'The adhan plays; you can stop it any time'**
  String get prayerAlertStyleFullHint;

  /// No description provided for @prayerAlertStyleAlarm.
  ///
  /// In en, this message translates to:
  /// **'Prayer alarm'**
  String get prayerAlertStyleAlarm;

  /// No description provided for @prayerAlertStyleAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Rings like an alarm, even in silent mode'**
  String get prayerAlertStyleAlarmHint;

  /// No description provided for @prayerAlertStyleFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get prayerAlertStyleFocus;

  /// No description provided for @prayerAlertStyleFocusHint.
  ///
  /// In en, this message translates to:
  /// **'A calm full-screen moment to pause for prayer'**
  String get prayerAlertStyleFocusHint;

  /// No description provided for @prayerAlertRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get prayerAlertRecording;

  /// No description provided for @prayerAlertVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get prayerAlertVolume;

  /// No description provided for @prayerAlertLength.
  ///
  /// In en, this message translates to:
  /// **'Plays for'**
  String get prayerAlertLength;

  /// No description provided for @prayerAlertLengthWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole adhan'**
  String get prayerAlertLengthWhole;

  /// No description provided for @prayerAlertLengthSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String prayerAlertLengthSeconds(String seconds);

  /// No description provided for @prayerAlertLengthMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String prayerAlertLengthMinutes(String minutes);

  /// No description provided for @prayerAlertFadeIn.
  ///
  /// In en, this message translates to:
  /// **'Fade in'**
  String get prayerAlertFadeIn;

  /// No description provided for @prayerAlertNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prayerAlertNone;

  /// No description provided for @prayerAlertSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a recording'**
  String get prayerAlertSoundTitle;

  /// No description provided for @prayerAlertSoundDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded: {size}'**
  String prayerAlertSoundDownloaded(String size);

  /// No description provided for @prayerAlertSoundBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get prayerAlertSoundBuiltIn;

  /// No description provided for @prayerAlertSoundReady.
  ///
  /// In en, this message translates to:
  /// **'Ready offline'**
  String get prayerAlertSoundReady;

  /// No description provided for @prayerAlertSoundSize.
  ///
  /// In en, this message translates to:
  /// **'{size} to download'**
  String prayerAlertSoundSize(String size);

  /// No description provided for @prayerAlertSoundDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get prayerAlertSoundDownload;

  /// No description provided for @prayerAlertSoundDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String prayerAlertSoundDownloading(int percent);

  /// No description provided for @prayerAlertSoundCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get prayerAlertSoundCancel;

  /// No description provided for @prayerAlertSoundRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get prayerAlertSoundRemove;

  /// No description provided for @prayerAlertSoundInUse.
  ///
  /// In en, this message translates to:
  /// **'Used by {prayers}. Choose another recording for them first.'**
  String prayerAlertSoundInUse(String prayers);

  /// No description provided for @prayerAlertSoundOutdated.
  ///
  /// In en, this message translates to:
  /// **'Showing the saved list. Couldn\'t check for new recordings.'**
  String get prayerAlertSoundOutdated;

  /// No description provided for @prayerAlertSoundListFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the recordings.'**
  String get prayerAlertSoundListFailed;

  /// No description provided for @prayerAlertSoundPlay.
  ///
  /// In en, this message translates to:
  /// **'Play a sample'**
  String get prayerAlertSoundPlay;

  /// No description provided for @prayerAlertSoundStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get prayerAlertSoundStop;

  /// No description provided for @prayerAlertSoundSelectAfter.
  ///
  /// In en, this message translates to:
  /// **'Will be used once downloaded'**
  String get prayerAlertSoundSelectAfter;

  /// No description provided for @prayerAlertDownloadNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Try again when you\'re online.'**
  String get prayerAlertDownloadNetwork;

  /// No description provided for @prayerAlertDownloadServer.
  ///
  /// In en, this message translates to:
  /// **'The download server isn\'t available right now. Try again later.'**
  String get prayerAlertDownloadServer;

  /// No description provided for @prayerAlertDownloadIntegrity.
  ///
  /// In en, this message translates to:
  /// **'The download was damaged. Try again.'**
  String get prayerAlertDownloadIntegrity;

  /// No description provided for @prayerAlertDownloadStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage. Free up some space and try again.'**
  String get prayerAlertDownloadStorage;

  /// No description provided for @prayerAlertSameAsAll.
  ///
  /// In en, this message translates to:
  /// **'Same as all prayers'**
  String get prayerAlertSameAsAll;

  /// No description provided for @prayerAlertCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get prayerAlertCustom;

  /// No description provided for @prayerAlertReset.
  ///
  /// In en, this message translates to:
  /// **'Reset {prayer} to the default'**
  String prayerAlertReset(String prayer);

  /// No description provided for @prayerAlertMoreFor.
  ///
  /// In en, this message translates to:
  /// **'More for {prayer}'**
  String prayerAlertMoreFor(String prayer);

  /// No description provided for @prayerAlertDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get prayerAlertDefault;

  /// No description provided for @prayerAlertDefaultAdhan.
  ///
  /// In en, this message translates to:
  /// **'Default Adhan'**
  String get prayerAlertDefaultAdhan;

  /// No description provided for @prayerAlertOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get prayerAlertOn;

  /// No description provided for @prayerAlertBeforeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String prayerAlertBeforeMinutes(String minutes);

  /// No description provided for @prayerAlertBeforeHint.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder so you can get ready'**
  String get prayerAlertBeforeHint;

  /// No description provided for @prayerAlertBeforeSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get prayerAlertBeforeSound;

  /// No description provided for @prayerAlertBeforeSilent.
  ///
  /// In en, this message translates to:
  /// **'No sound'**
  String get prayerAlertBeforeSilent;

  /// No description provided for @prayerAlertBeforeShort.
  ///
  /// In en, this message translates to:
  /// **'Short sound'**
  String get prayerAlertBeforeShort;

  /// No description provided for @prayerAlertFallback.
  ///
  /// In en, this message translates to:
  /// **'When an alarm can\'t be set'**
  String get prayerAlertFallback;

  /// No description provided for @prayerAlertTestHint.
  ///
  /// In en, this message translates to:
  /// **'Arrives in about 10 seconds with this prayer\'s settings. You can leave Huda.'**
  String get prayerAlertTestHint;

  /// No description provided for @prayerAlertTestHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Arrives in about 10 seconds with this prayer\'s settings. Keep Huda open until then.'**
  String get prayerAlertTestHintDesktop;

  /// No description provided for @prayerAlertTestSend.
  ///
  /// In en, this message translates to:
  /// **'Send test'**
  String get prayerAlertTestSend;

  /// No description provided for @prayerAlertTestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Arrives in {seconds} s'**
  String prayerAlertTestWaiting(String seconds);

  /// No description provided for @prayerAlertTestScheduled.
  ///
  /// In en, this message translates to:
  /// **'Test sent. It should arrive in a few seconds.'**
  String get prayerAlertTestScheduled;

  /// No description provided for @prayerAlertTestShown.
  ///
  /// In en, this message translates to:
  /// **'Test shown. Did you hear and see it?'**
  String get prayerAlertTestShown;

  /// No description provided for @prayerAlertTestNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Huda, so the test can\'t arrive.'**
  String get prayerAlertTestNotificationsOff;

  /// No description provided for @prayerAlertTestExactOff.
  ///
  /// In en, this message translates to:
  /// **'Huda can\'t set on-time alarms, so alerts may be late. Allow them first.'**
  String get prayerAlertTestExactOff;

  /// No description provided for @prayerAlertTestPrayerOff.
  ///
  /// In en, this message translates to:
  /// **'Alerts are off for this prayer.'**
  String get prayerAlertTestPrayerOff;

  /// No description provided for @prayerAlertTestAlarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow prayer alarms first, then try again.'**
  String get prayerAlertTestAlarmPermission;

  /// No description provided for @prayerAlertTestServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s background helper isn\'t running, so the test can\'t play.'**
  String get prayerAlertTestServiceOff;

  /// No description provided for @prayerAlertTestAudioMissing.
  ///
  /// In en, this message translates to:
  /// **'The chosen recording couldn\'t play, so the built-in adhan was used.'**
  String get prayerAlertTestAudioMissing;

  /// No description provided for @prayerAlertTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The test couldn\'t be sent. Try again.'**
  String get prayerAlertTestFailed;

  /// No description provided for @prayerAlertFocusDuration.
  ///
  /// In en, this message translates to:
  /// **'Lasts'**
  String get prayerAlertFocusDuration;

  /// No description provided for @prayerAlertFocusAudio.
  ///
  /// In en, this message translates to:
  /// **'Play the adhan during Focus'**
  String get prayerAlertFocusAudio;

  /// No description provided for @prayerAlertFocusCommitment.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be closed early'**
  String get prayerAlertFocusCommitment;

  /// No description provided for @prayerAlertFocusCommitmentHint.
  ///
  /// In en, this message translates to:
  /// **'Focus ends when its time is up. Esc still closes it in an emergency.'**
  String get prayerAlertFocusCommitmentHint;

  /// No description provided for @prayerAlertFocusFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get prayerAlertFocusFullScreen;

  /// No description provided for @prayerAlertSummaryOff.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts are off'**
  String get prayerAlertSummaryOff;

  /// No description provided for @prayerAlertSummaryMixed.
  ///
  /// In en, this message translates to:
  /// **'Different for some prayers'**
  String get prayerAlertSummaryMixed;

  /// No description provided for @prayerAlertStopAdhan.
  ///
  /// In en, this message translates to:
  /// **'Stop adhan'**
  String get prayerAlertStopAdhan;

  /// No description provided for @prayerAlertEndFocus.
  ///
  /// In en, this message translates to:
  /// **'End Focus'**
  String get prayerAlertEndFocus;

  /// No description provided for @prayerAlertOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get prayerAlertOnThisDevice;

  /// No description provided for @prayerAlertBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get prayerAlertBack;

  /// No description provided for @prayerAlertClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get prayerAlertClose;

  /// No description provided for @prayerAlertNeedsCompanion.
  ///
  /// In en, this message translates to:
  /// **'Needs Huda running in the background'**
  String get prayerAlertNeedsCompanion;

  /// No description provided for @prayerAlertToggleAlarmScreen.
  ///
  /// In en, this message translates to:
  /// **'Alarm screen'**
  String get prayerAlertToggleAlarmScreen;

  /// No description provided for @prayerAlertToggleAlarmScreenHint.
  ///
  /// In en, this message translates to:
  /// **'Shows a full-screen alarm when the adhan starts'**
  String get prayerAlertToggleAlarmScreenHint;

  /// No description provided for @prayerAlertToggleFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip to stop'**
  String get prayerAlertToggleFlip;

  /// No description provided for @prayerAlertToggleFlipHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the phone face down to stop the adhan'**
  String get prayerAlertToggleFlipHint;

  /// No description provided for @prayerAlertToggleVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get prayerAlertToggleVibrate;

  /// No description provided for @prayerAlertToggleRinger.
  ///
  /// In en, this message translates to:
  /// **'Follow silent mode'**
  String get prayerAlertToggleRinger;

  /// No description provided for @prayerAlertToggleRingerHint.
  ///
  /// In en, this message translates to:
  /// **'No adhan sound while the phone is on silent or vibrate'**
  String get prayerAlertToggleRingerHint;

  /// No description provided for @prayerAlertToggleHeadset.
  ///
  /// In en, this message translates to:
  /// **'Stop when headphones disconnect'**
  String get prayerAlertToggleHeadset;

  /// No description provided for @prayerAlertToggleMissed.
  ///
  /// In en, this message translates to:
  /// **'Show prayers missed while the phone was off'**
  String get prayerAlertToggleMissed;

  /// No description provided for @prayerAlertToggleTimeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Time Sensitive'**
  String get prayerAlertToggleTimeSensitive;

  /// No description provided for @prayerAlertToggleTimeSensitiveHint.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts come through Focus and Do Not Disturb'**
  String get prayerAlertToggleTimeSensitiveHint;

  /// No description provided for @prayerAlertToggleLockedAudio.
  ///
  /// In en, this message translates to:
  /// **'Play while the screen is locked'**
  String get prayerAlertToggleLockedAudio;

  /// No description provided for @prayerAlertToggleQuiet.
  ///
  /// In en, this message translates to:
  /// **'Pause the adhan and Focus'**
  String get prayerAlertToggleQuiet;

  /// No description provided for @prayerAlertToggleQuietHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications still arrive, silently'**
  String get prayerAlertToggleQuietHint;

  /// No description provided for @prayerAlertToggleBackground.
  ///
  /// In en, this message translates to:
  /// **'Keep Huda running in the background'**
  String get prayerAlertToggleBackground;

  /// No description provided for @prayerAlertToggleBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Needed for the adhan and Focus after Huda\'s window is closed'**
  String get prayerAlertToggleBackgroundHint;

  /// No description provided for @prayerAlertToggleStartAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Start at login'**
  String get prayerAlertToggleStartAtLogin;

  /// Android: one adhan style; how long it plays is chosen under Sound.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get prayerAlertStyleAdhan;

  /// No description provided for @prayerAlertStyleAdhanHint.
  ///
  /// In en, this message translates to:
  /// **'The adhan plays; choose how long under Sound'**
  String get prayerAlertStyleAdhanHint;

  /// No description provided for @prayerAlertLengthOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening only'**
  String get prayerAlertLengthOpening;

  /// macOS: the notification's own sound, up to 30 seconds, works even when Huda is closed.
  ///
  /// In en, this message translates to:
  /// **'Adhan in the notification'**
  String get prayerAlertStyleNotificationAdhan;

  /// No description provided for @prayerAlertStyleNotificationAdhanHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 30 seconds with the notification; works even when Huda is closed'**
  String get prayerAlertStyleNotificationAdhanHint;

  /// Title of the Android prayer countdown card and notification
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown'**
  String get prayerCountdownTitle;

  /// Explains the Android prayer countdown notification
  ///
  /// In en, this message translates to:
  /// **'A quiet notification that counts down to the next prayer. It keeps going after a restart, without opening Huda.'**
  String get prayerCountdownDescription;

  /// Status: the countdown notification is showing
  ///
  /// In en, this message translates to:
  /// **'Showing in your notifications'**
  String get prayerCountdownShowing;

  /// Status: the countdown is on but Android is not showing it
  ///
  /// In en, this message translates to:
  /// **'On, but not showing right now'**
  String get prayerCountdownNotShowing;

  /// Status: the countdown is off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prayerCountdownOff;

  /// Label above the countdown style choices
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get prayerCountdownStyle;

  /// Countdown style with a progress bar between prayers
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get prayerCountdownStyleProgress;

  /// Countdown style with the day's prayer times
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get prayerCountdownStyleTimetable;

  /// Countdown style with one line
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get prayerCountdownStyleMinimal;

  /// Option: show the countdown on the lock screen
  ///
  /// In en, this message translates to:
  /// **'Show on the lock screen'**
  String get prayerCountdownLockScreen;

  /// Timetable option: include sunrise in the times
  ///
  /// In en, this message translates to:
  /// **'Include sunrise'**
  String get prayerCountdownShowSunrise;

  /// Android 16 option: Android's template, so the timer shows in the status bar and the notification header
  ///
  /// In en, this message translates to:
  /// **'Show the countdown in the status bar'**
  String get prayerCountdownLiveUpdate;

  /// Problem: Huda's notifications are off
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Huda.'**
  String get prayerCountdownNotificationsOff;

  /// Problem: the countdown notification channel is off
  ///
  /// In en, this message translates to:
  /// **'The “Prayer countdown” notification category is turned off.'**
  String get prayerCountdownChannelOff;

  /// Problem: Android Live Updates are off for Huda
  ///
  /// In en, this message translates to:
  /// **'Live Updates are turned off for Huda.'**
  String get prayerCountdownLiveUpdateOff;

  /// Problem: no location, so no prayer times to count down to
  ///
  /// In en, this message translates to:
  /// **'Set your location to show the countdown.'**
  String get prayerCountdownNeedsLocation;

  /// Error when the countdown settings could not be saved
  ///
  /// In en, this message translates to:
  /// **'The countdown setting couldn’t be saved.'**
  String get prayerCountdownSaveFailed;

  /// Status when countdown is active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Explains what turning on the status-bar countdown changes
  ///
  /// In en, this message translates to:
  /// **'Android Live Update. The timer moves to the top of the notification instead of the text.'**
  String get prayerCountdownLiveUpdateHint;

  /// Starts a check that the phone recognizes a flip, without playing anything.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get prayerAlertFlipTry;

  /// No description provided for @prayerAlertFlipHold.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone as you normally do…'**
  String get prayerAlertFlipHold;

  /// No description provided for @prayerAlertFlipNow.
  ///
  /// In en, this message translates to:
  /// **'Now turn it face down'**
  String get prayerAlertFlipNow;

  /// No description provided for @prayerAlertFlipDetected.
  ///
  /// In en, this message translates to:
  /// **'Flip detected. The adhan would stop.'**
  String get prayerAlertFlipDetected;

  /// No description provided for @prayerAlertFlipMissed.
  ///
  /// In en, this message translates to:
  /// **'No flip seen. Try again.'**
  String get prayerAlertFlipMissed;

  /// No description provided for @prayerAlertFlipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t detect a flip.'**
  String get prayerAlertFlipUnavailable;

  /// macOS Full adhan tile: choosing it turns on running in the menu bar and starting at login.
  ///
  /// In en, this message translates to:
  /// **'Huda plays the whole adhan; it keeps running in the menu bar and starts at login'**
  String get prayerAlertStyleMacFullHint;

  /// No description provided for @prayerAlertStyleMacFocusHint.
  ///
  /// In en, this message translates to:
  /// **'A calm full-screen moment for prayer; Huda keeps running in the menu bar and starts at login'**
  String get prayerAlertStyleMacFocusHint;

  /// No description provided for @macPrayerMenuNameElapsed.
  ///
  /// In en, this message translates to:
  /// **'{prayer} {time}'**
  String macPrayerMenuNameElapsed(String prayer, String time);

  /// No description provided for @prayerIqamahTitle.
  ///
  /// In en, this message translates to:
  /// **'Iqamah time'**
  String get prayerIqamahTitle;

  /// No description provided for @prayerIqamahExplanation.
  ///
  /// In en, this message translates to:
  /// **'After the adhan, the countdown shows time since the prayer started for this long.'**
  String get prayerIqamahExplanation;

  /// No description provided for @prayerIqamahMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String prayerIqamahMinutes(String minutes);

  /// No description provided for @prayerIqamahReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get prayerIqamahReset;

  /// No description provided for @prayerIqamahOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prayerIqamahOff;

  /// No description provided for @prayerIqamahSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save or sync Iqamah settings. Please try again.'**
  String get prayerIqamahSaveError;

  /// No description provided for @notificationAthkarMeaning01.
  ///
  /// In en, this message translates to:
  /// **'Glory be to Allah and praise be to Him'**
  String get notificationAthkarMeaning01;

  /// No description provided for @notificationAthkarMeaning02.
  ///
  /// In en, this message translates to:
  /// **'There is no power or strength except through Allah'**
  String get notificationAthkarMeaning02;

  /// No description provided for @notificationAthkarMeaning03.
  ///
  /// In en, this message translates to:
  /// **'I seek forgiveness from Allah, the Almighty'**
  String get notificationAthkarMeaning03;

  /// No description provided for @notificationAthkarMeaning04.
  ///
  /// In en, this message translates to:
  /// **'All praise is for Allah, Lord of all worlds'**
  String get notificationAthkarMeaning04;

  /// No description provided for @notificationAthkarMeaning05.
  ///
  /// In en, this message translates to:
  /// **'There is no god but Allah alone, with no partner'**
  String get notificationAthkarMeaning05;

  /// No description provided for @notificationAthkarMeaning06.
  ///
  /// In en, this message translates to:
  /// **'Glory be to Allah, the Magnificent'**
  String get notificationAthkarMeaning06;

  /// No description provided for @notificationAthkarMeaning07.
  ///
  /// In en, this message translates to:
  /// **'O Allah, bless Muhammad and the family of Muhammad'**
  String get notificationAthkarMeaning07;

  /// No description provided for @notificationAthkarMeaning08.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, grant us good in this world and in the Hereafter, and protect us from the punishment of the Fire'**
  String get notificationAthkarMeaning08;

  /// No description provided for @notificationAthkarMeaning09.
  ///
  /// In en, this message translates to:
  /// **'Glory be to Allah'**
  String get notificationAthkarMeaning09;

  /// No description provided for @notificationAthkarMeaning10.
  ///
  /// In en, this message translates to:
  /// **'All praise is for Allah'**
  String get notificationAthkarMeaning10;

  /// No description provided for @notificationAthkarMeaning11.
  ///
  /// In en, this message translates to:
  /// **'There is no god but Allah'**
  String get notificationAthkarMeaning11;

  /// No description provided for @notificationAthkarMeaning12.
  ///
  /// In en, this message translates to:
  /// **'Allah is the Greatest'**
  String get notificationAthkarMeaning12;

  /// No description provided for @notificationAthkarMeaning13.
  ///
  /// In en, this message translates to:
  /// **'Glory be to Allah, all praise is for Allah, there is no god but Allah, and Allah is the Greatest'**
  String get notificationAthkarMeaning13;

  /// No description provided for @notificationAthkarMeaning14.
  ///
  /// In en, this message translates to:
  /// **'Glory be to Allah and praise be to Him; glory be to Allah, the Magnificent'**
  String get notificationAthkarMeaning14;

  /// No description provided for @notificationAthkarMeaning15.
  ///
  /// In en, this message translates to:
  /// **'My Lord, forgive me and accept my repentance. You are the Accepter of repentance, the Merciful'**
  String get notificationAthkarMeaning15;

  /// No description provided for @notificationAthkarMeaning16.
  ///
  /// In en, this message translates to:
  /// **'My Lord, increase me in knowledge'**
  String get notificationAthkarMeaning16;

  /// No description provided for @notificationAthkarMeaning17.
  ///
  /// In en, this message translates to:
  /// **'There is no god but You. Glory be to You. I have indeed been among the wrongdoers'**
  String get notificationAthkarMeaning17;

  /// No description provided for @notificationAthkarMeaning18.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I am in need of whatever good You send down to me'**
  String get notificationAthkarMeaning18;

  /// No description provided for @notificationAthkarMeaning19.
  ///
  /// In en, this message translates to:
  /// **'O Allah, I ask You for guidance, piety, chastity, and contentment'**
  String get notificationAthkarMeaning19;

  /// No description provided for @notificationAthkarMeaning20.
  ///
  /// In en, this message translates to:
  /// **'O Allah, You are Pardoning and love to pardon, so pardon me'**
  String get notificationAthkarMeaning20;

  /// No description provided for @sahurNotificationOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'On iOS before 26, Sahur plays a notification sound for about 30 seconds, once. It does not loop.'**
  String get sahurNotificationOnlyDescription;

  /// Shown on a retry button after the person taps it, while the retry runs.
  ///
  /// In en, this message translates to:
  /// **'Retrying…'**
  String get stateRetrying;

  /// Shown while automatic background work (a refresh or sync) runs.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get stateUpdating;

  /// Under the offline message when the screen still shows content saved on the device.
  ///
  /// In en, this message translates to:
  /// **'Showing what\'s saved on this device.'**
  String get stateOfflineSaved;

  /// Athkar: eyebrow above the list title, the book the athkar come from (Hisn al-Muslim)
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim'**
  String get athkarSource;

  /// Athkar: section of the chapters read every day (waking, morning and evening, after prayer, sleep)
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get athkarDaily;

  /// Athkar: section with all the other chapters
  ///
  /// In en, this message translates to:
  /// **'For every occasion'**
  String get athkarOccasions;

  /// Athkar chapter: how many of its dhikr are done
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String athkarProgress(int done, int total);

  /// Athkar: how many times a dhikr is said, before counting starts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Once} other{{count} times}}'**
  String athkarRepeatTimes(int count);

  /// Athkar: repetitions left for a dhikr while counting
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String athkarLeft(int count);

  /// Athkar: screen-reader hint on a dhikr card
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get athkarTapToCount;

  /// Athkar: title when every dhikr of a chapter is done
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get athkarAllDone;

  /// Athkar: message under 'All done'
  ///
  /// In en, this message translates to:
  /// **'May Allah accept it from you.'**
  String get athkarAllDoneMessage;

  /// Athkar: button that resets every dhikr of the chapter
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get athkarStartAgain;

  /// Athkar: toast after a dhikr's count is reset, next to Undo
  ///
  /// In en, this message translates to:
  /// **'Count reset'**
  String get athkarCountReset;

  /// Athkar: error message when the athkar can't be loaded
  ///
  /// In en, this message translates to:
  /// **'The athkar couldn\'t be loaded.'**
  String get athkarLoadError;

  /// Athkar: toast when a dhikr's audio can't play
  ///
  /// In en, this message translates to:
  /// **'This recitation couldn\'t be played.'**
  String get athkarAudioError;

  /// Athkar: clears the chapter search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get athkarClearSearch;

  /// Athkar: label of a dhikr's play button
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get athkarListen;

  /// Share sheet: saves the share image to the device's photos
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get shareSaveImage;

  /// Share sheet: toast after the image is saved
  ///
  /// In en, this message translates to:
  /// **'Saved to your photos'**
  String get shareImageSaved;

  /// Share sheet: toast when saving images isn't implemented on this platform yet
  ///
  /// In en, this message translates to:
  /// **'Saving images isn\'t available on this device yet.'**
  String get shareSaveUnavailable;

  /// Share sheet: Save image tile after the image is saved on a desktop (Downloads folder)
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get shareImageSavedDownloads;

  /// Share sheet: banner when saving the image failed on a platform that supports saving
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the image. Try again.'**
  String get shareSaveFailed;

  /// Share sheet: tick box that adds the dhikr's translation to the share image and text
  ///
  /// In en, this message translates to:
  /// **'Include translation'**
  String get shareIncludeTranslation;

  /// Hadith: section heading for the Kutub al-Sittah (Bukhari, Muslim, Nasa'i, Abu Dawud, Tirmidhi, Ibn Majah)
  ///
  /// In en, this message translates to:
  /// **'The Six Books'**
  String get hadithSixBooks;

  /// Hadith: section heading for the other collections
  ///
  /// In en, this message translates to:
  /// **'More collections'**
  String get hadithMoreCollections;

  /// Hadith: how many hadith a collection or book has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hadith} other{{count} hadith}}'**
  String hadithCount(int count);

  /// Hadith: how many books a collection has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String hadithBookCount(int count);

  /// Hadith: the hadith numbers a book covers
  ///
  /// In en, this message translates to:
  /// **'Hadith {start}–{end}'**
  String hadithRange(String start, String end);

  /// Hadith: a hadith's number, read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Hadith {number}'**
  String hadithNumber(String number);

  /// Hadith: hint in the field that filters a collection's books
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get hadithSearchBooks;

  /// Hadith: wide windows, the reader pane before a book is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose a book to start reading'**
  String get hadithChooseBook;

  /// Hadith: which page of a book's hadith is shown
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String hadithPageOf(int page, int total);

  /// Hadith: error message when collections, books or hadith can't be loaded
  ///
  /// In en, this message translates to:
  /// **'The hadith couldn\'t be loaded.'**
  String get hadithLoadError;

  /// Hadith: title of the share sheet for one hadith
  ///
  /// In en, this message translates to:
  /// **'Share hadith'**
  String get hadithShare;

  /// Hadith: eyebrow over an open book's title, its number in the collection
  ///
  /// In en, this message translates to:
  /// **'Book {number}'**
  String hadithBookNumber(String number);

  /// Hadith: an open book with no hadith
  ///
  /// In en, this message translates to:
  /// **'This book has no hadith yet.'**
  String get hadithBookEmpty;

  /// Hadith: error message when a collection's books can't be loaded
  ///
  /// In en, this message translates to:
  /// **'This collection\'s books couldn\'t be loaded.'**
  String get hadithBooksLoadError;

  /// Hadith: wide windows, the index row that shows the collection's title page and introduction
  ///
  /// In en, this message translates to:
  /// **'About this collection'**
  String get hadithAbout;

  /// Zakat: eyebrow above the amount of zakat to pay
  ///
  /// In en, this message translates to:
  /// **'Zakat due'**
  String get zakatDueLabel;

  /// Zakat: label under the nisab pan of the balance
  ///
  /// In en, this message translates to:
  /// **'Nisab'**
  String get zakatNisab;

  /// Zakat: how the amount due was found (2.5% of net assets)
  ///
  /// In en, this message translates to:
  /// **'2.5% of {amount}'**
  String zakatRateOf(String amount);

  /// Zakat: how far net assets are above the nisab
  ///
  /// In en, this message translates to:
  /// **'{amount} above the nisab'**
  String zakatAboveNisab(String amount);

  /// Zakat: how far net assets are below the nisab
  ///
  /// In en, this message translates to:
  /// **'{amount} below the nisab'**
  String zakatBelowNisab(String amount);

  /// Zakat: result title before any amount is entered
  ///
  /// In en, this message translates to:
  /// **'Enter what you own'**
  String get zakatEmptyTitle;

  /// Zakat: result message before any amount is entered
  ///
  /// In en, this message translates to:
  /// **'Add your savings, gold and other assets to see whether they reach the nisab.'**
  String get zakatEmptyMessage;

  /// Zakat: app bar action that clears every entered amount (with Undo)
  ///
  /// In en, this message translates to:
  /// **'Clear amounts'**
  String get zakatClearAmounts;

  /// Zakat: toast after clearing the amounts, with Undo
  ///
  /// In en, this message translates to:
  /// **'Amounts cleared'**
  String get zakatAmountsCleared;

  /// Zakat: phones, the result strip at the bottom that scrolls back to the result
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get zakatShowResult;

  /// Zakat: under the metal price, the nisab weight (e.g. 87.48 grams)
  ///
  /// In en, this message translates to:
  /// **'Nisab is {weight}'**
  String zakatNisabIs(String weight);

  /// Zakat: error message when the calculation fails
  ///
  /// In en, this message translates to:
  /// **'The calculation couldn\'t be completed.'**
  String get zakatCalcError;

  /// Zakat: where the metal price comes from (the market feed) and its day
  ///
  /// In en, this message translates to:
  /// **'Market price · {date}'**
  String zakatPriceMarket(String date);

  /// Zakat: the metal price was typed by the person, not the market price
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get zakatPriceYours;

  /// Zakat: while the market prices update automatically
  ///
  /// In en, this message translates to:
  /// **'Updating gold and silver prices…'**
  String get zakatPriceUpdating;

  /// Zakat: the market prices could not be updated; the date of the prices still used
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update gold and silver prices. Using prices from {date}.'**
  String zakatPriceFailed(String date);

  /// Zakat: button that replaces a typed metal price with the market price
  ///
  /// In en, this message translates to:
  /// **'Use market price'**
  String get zakatUseMarketPrice;

  /// Zakat: note for currencies whose world rate can be far from the local gold market
  ///
  /// In en, this message translates to:
  /// **'Gold prices in {currency} can differ from world prices. Check your local price and enter it if needed.'**
  String zakatLocalPriceNote(String currency);

  /// Zakat: a metal price per gram
  ///
  /// In en, this message translates to:
  /// **'{price} per gram'**
  String zakatPerGram(String price);

  /// Zakat: hint of the search field in the currency picker
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get zakatCurrencySearch;

  /// Zakat: currency picker section of suggested currencies
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get zakatCurrencySuggested;

  /// Zakat: currency picker section of every other currency
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get zakatCurrencyAll;

  /// Zakat: currency picker search found nothing
  ///
  /// In en, this message translates to:
  /// **'No currency matches “{query}”'**
  String zakatCurrencyNoMatch(String query);

  /// Zakat: toast after a currency change replaced the gold or silver price the person typed
  ///
  /// In en, this message translates to:
  /// **'Your prices were replaced with market prices in {currency}.'**
  String zakatTypedPricesReplaced(String currency);

  /// Onboarding: welcome step title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huda'**
  String get setupWelcomeTitle;

  /// Onboarding: welcome step sentence
  ///
  /// In en, this message translates to:
  /// **'Let\'s set Huda up for you. It takes about a minute.'**
  String get setupWelcomeMessage;

  /// Onboarding: appearance step title
  ///
  /// In en, this message translates to:
  /// **'Choose your look'**
  String get setupLookTitle;

  /// Onboarding: appearance step explanation
  ///
  /// In en, this message translates to:
  /// **'Light or dark, and a color. You can change both later in Settings.'**
  String get setupLookMessage;

  /// Onboarding: light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get setupThemeLight;

  /// Onboarding: dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get setupThemeDark;

  /// Onboarding: theme follows the device setting
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get setupThemeSystem;

  /// Onboarding: focus step title (sets the Home theme)
  ///
  /// In en, this message translates to:
  /// **'What will you use Huda for most?'**
  String get setupFocusTitle;

  /// Onboarding: focus step explanation
  ///
  /// In en, this message translates to:
  /// **'Home puts it first. You can change this anytime from Home.'**
  String get setupFocusMessage;

  /// Onboarding: focus option
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get setupFocusPrayer;

  /// Onboarding: focus option
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get setupFocusQuran;

  /// Onboarding: focus option
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get setupFocusEverything;

  /// Onboarding: shown while the location is being found
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get setupLocating;

  /// Onboarding: proof that prayer times loaded
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer} at {time}'**
  String setupNextPrayer(String prayer, String time);

  /// Onboarding: Asr step explanation
  ///
  /// In en, this message translates to:
  /// **'Schools differ on when Asr begins. Choose the one you follow.'**
  String get setupAsrMessage;

  /// Onboarding: the majority Asr calculation
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get setupAsrStandard;

  /// Onboarding: schools that use the standard Asr
  ///
  /// In en, this message translates to:
  /// **'Shafi\'i, Maliki and Hanbali'**
  String get setupAsrStandardSchools;

  /// Onboarding: what the Hanafi Asr means
  ///
  /// In en, this message translates to:
  /// **'Asr begins later'**
  String get setupAsrHanafiNote;

  /// Onboarding: marks the pre-selected suggestion
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get setupSuggested;

  /// Onboarding summary: alerts stay off
  ///
  /// In en, this message translates to:
  /// **'Alerts are off'**
  String get setupAlertsOff;

  /// Onboarding: reliability step title
  ///
  /// In en, this message translates to:
  /// **'Make alerts reliable'**
  String get setupReliableTitle;

  /// Onboarding: which reliability item of how many
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String setupReliableCount(int current, int total);

  /// Onboarding: Quran reading mode step title
  ///
  /// In en, this message translates to:
  /// **'How do you read the Quran?'**
  String get setupMushafTitle;

  /// Onboarding: Quran reading mode explanation
  ///
  /// In en, this message translates to:
  /// **'Pick a layout. You can switch anytime in the reader\'s settings.'**
  String get setupMushafMessage;

  /// Onboarding: what the scroll list reading mode is
  ///
  /// In en, this message translates to:
  /// **'Ayah by ayah, with translation'**
  String get setupScrollListHint;

  /// Onboarding: download size of a Mushaf
  ///
  /// In en, this message translates to:
  /// **'{size} download'**
  String setupMushafSize(String size);

  /// Onboarding: this Mushaf is already downloaded
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get setupMushafReady;

  /// Onboarding: switch to download the chosen Mushaf now
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get setupDownloadNow;

  /// Onboarding: the Mushaf downloads in the background
  ///
  /// In en, this message translates to:
  /// **'Downloads in the background ({size}).'**
  String setupDownloadWifi(String size);

  /// Onboarding: on mobile data the Mushaf waits
  ///
  /// In en, this message translates to:
  /// **'You\'re on mobile data, so it will download when you open the Quran.'**
  String get setupDownloadCellular;

  /// Onboarding: daily reminders step title
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get setupRemindersTitle;

  /// Onboarding: daily reminders explanation
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders at the usual times. Each stays off until you turn it on.'**
  String get setupRemindersMessage;

  /// Onboarding: a reminder could not be scheduled
  ///
  /// In en, this message translates to:
  /// **'That reminder couldn\'t be turned on. Try again from Reminders.'**
  String get setupReminderFailed;

  /// Onboarding summary: how many reminders are on
  ///
  /// In en, this message translates to:
  /// **'{count} of 3 on'**
  String setupRemindersOn(int count);

  /// Onboarding: summary step title
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get setupSummaryTitle;

  /// Onboarding: summary explanation
  ///
  /// In en, this message translates to:
  /// **'Tap a step to change it.'**
  String get setupSummaryMessage;

  /// Onboarding summary: a step that was skipped
  ///
  /// In en, this message translates to:
  /// **'Skipped · set it up anytime'**
  String get setupSkippedLater;

  /// Onboarding: finishes setup and opens Home
  ///
  /// In en, this message translates to:
  /// **'Start using Huda'**
  String get setupStart;

  /// Onboarding: the location could not be found (not a permission problem)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location'**
  String get setupLocationFailedTitle;

  /// Onboarding: title of the permissions step (location and notifications)
  ///
  /// In en, this message translates to:
  /// **'What Huda needs'**
  String get setupPermissionsTitle;

  /// Onboarding: short name of the permissions step in the summary
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get setupPermissionsLabel;

  /// Onboarding: explanation at the top of the permissions step
  ///
  /// In en, this message translates to:
  /// **'Two permissions let Huda work for you. You can change them anytime in your device\'s settings.'**
  String get setupPermissionsMessage;

  /// Onboarding: why Huda needs location
  ///
  /// In en, this message translates to:
  /// **'To calculate prayer times and the Qibla for where you are.'**
  String get setupPermissionLocationWhy;

  /// Onboarding: why Huda needs notifications
  ///
  /// In en, this message translates to:
  /// **'To call the adhan at each prayer time and send the reminders you choose.'**
  String get setupPermissionNotificationsWhy;

  /// Onboarding: button that opens the system notification prompt
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get setupAllowNotifications;

  /// Onboarding: a permission was granted
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get setupPermissionAllowed;

  /// Onboarding: a permission was refused
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get setupPermissionNotAllowed;

  /// Onboarding: a permission hasn't been requested yet
  ///
  /// In en, this message translates to:
  /// **'Not asked yet'**
  String get setupPermissionNotAsked;

  /// Onboarding: the system permission prompt is open
  ///
  /// In en, this message translates to:
  /// **'Asking…'**
  String get setupPermissionAsking;

  /// Onboarding: title of the location step, which shows today's prayer times
  ///
  /// In en, this message translates to:
  /// **'Your prayer times'**
  String get setupTimesTitle;

  /// Onboarding: line under the city with today's five prayer times
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayer times, calculated for where you are.'**
  String get setupTimesToday;

  /// Onboarding: title of the prayer alerts (adhan) step
  ///
  /// In en, this message translates to:
  /// **'The call to prayer'**
  String get setupAdhanTitle;

  /// Onboarding: adhan step explanation once alerts are on
  ///
  /// In en, this message translates to:
  /// **'At each prayer time Huda calls the adhan, even when the app is closed.'**
  String get setupAdhanMessage;

  /// Onboarding: how Asr is told for the majority schools (shadow length = object)
  ///
  /// In en, this message translates to:
  /// **'When a shadow equals its object'**
  String get setupAsrShadowOnce;

  /// Onboarding: how Asr is told in the Hanafi school (shadow length = twice the object)
  ///
  /// In en, this message translates to:
  /// **'When a shadow is twice its object'**
  String get setupAsrShadowTwice;

  /// Onboarding: time stamp on the preview of a prayer alert
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get setupNow;

  /// Onboarding: skips only the current step; the app asks again later
  ///
  /// In en, this message translates to:
  /// **'Skip this step'**
  String get setupSkipStep;

  /// Onboarding: ends setup now and opens Home; skipped steps are asked later
  ///
  /// In en, this message translates to:
  /// **'Skip all'**
  String get setupSkipAll;

  /// Onboarding: title of the step that picks the calculation method and the Asr school
  ///
  /// In en, this message translates to:
  /// **'How are your prayer times calculated?'**
  String get setupCalcTitle;

  /// Onboarding: short name of the calculation step in the summary
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get setupCalcLabel;

  /// Onboarding: explanation on the calculation step
  ///
  /// In en, this message translates to:
  /// **'Automatic uses your country\'s method. Choose another only if your mosque follows it.'**
  String get setupCalcMessage;

  /// Onboarding: label above the common calculation methods
  ///
  /// In en, this message translates to:
  /// **'Or choose a method'**
  String get setupMethodOther;

  /// Onboarding: label above the alert styles (notification, short adhan, full adhan)
  ///
  /// In en, this message translates to:
  /// **'How each prayer alerts you'**
  String get setupAlertStyleLabel;

  /// Onboarding: note under the alert styles
  ///
  /// In en, this message translates to:
  /// **'You can choose the adhan voice and more later in Prayer settings.'**
  String get setupAdhanVoiceLater;

  /// Onboarding: the alert style could not be saved
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this choice.'**
  String get setupAlertSaveFailed;

  /// Onboarding: confirmation title before Skip all ends setup
  ///
  /// In en, this message translates to:
  /// **'Skip the rest of setup?'**
  String get setupSkipAllTitle;

  /// Onboarding: confirmation message before Skip all ends setup
  ///
  /// In en, this message translates to:
  /// **'Huda opens now. It will ask about anything skipped later, where it\'s needed.'**
  String get setupSkipAllMessage;

  /// Onboarding: cancels Skip all and stays in setup
  ///
  /// In en, this message translates to:
  /// **'Keep setting up'**
  String get setupKeepSettingUp;

  /// Onboarding: the method Automatic resolves to for the person's country
  ///
  /// In en, this message translates to:
  /// **'Uses {method}'**
  String setupMethodUses(String method);

  /// Onboarding: hint of the field that filters the calculation methods
  ///
  /// In en, this message translates to:
  /// **'Search methods'**
  String get setupMethodSearch;

  /// Hint in the Quran home search field; it finds surahs by name or number and ayat by their words
  ///
  /// In en, this message translates to:
  /// **'Search surahs or ayat'**
  String get quranSearchHint;

  /// Error on Quran home when the surah index fails to build
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the surah index.'**
  String get quranLoadError;

  /// Section label above ayat found by their words in the Quran search
  ///
  /// In en, this message translates to:
  /// **'Ayat'**
  String get quranAyatSection;

  /// Reader button and sheet title for how the Quran is shown: reading mode, Mushaf layout, font
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get quranDisplay;

  /// Reader overflow button (Memorize, Khatma)
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get quranMore;

  /// Ayah sheet tab listing ayat with similar wording (mutashabihat)
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get quranSimilarTab;

  /// Error in the Quran reader when a surah fails to build
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this surah.'**
  String get quranSurahLoadError;

  /// Toast after deleting a bookmark, with an Undo action
  ///
  /// In en, this message translates to:
  /// **'Bookmark deleted'**
  String get quranBookmarkDeleted;

  /// Button in the ayah sheet when the ayah ends today's khatma portion (wird)
  ///
  /// In en, this message translates to:
  /// **'I\'ve finished today\'s wird'**
  String get quranWirdDone;

  /// Ayah sheet status while offline content is read from the device
  ///
  /// In en, this message translates to:
  /// **'Loading what\'s saved on this device…'**
  String get quranOfflineLoading;

  /// Mark beside the ayah where today's khatma portion starts (read out by screen readers)
  ///
  /// In en, this message translates to:
  /// **'Today\'s wird starts here'**
  String get quranWirdStartsHere;

  /// Mark beside the ayah where today's khatma portion ends (read out by screen readers)
  ///
  /// In en, this message translates to:
  /// **'Today\'s wird ends here'**
  String get quranWirdEndsHere;

  /// Ayah sheet, Audio tab: the list of reciters failed to load; a Retry follows
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the reciters.'**
  String get quranRecitersError;

  /// Quran Display sheet, under the Zoomed switch for Mushaf pages
  ///
  /// In en, this message translates to:
  /// **'Pages fill the width and scroll; two pages scroll together.'**
  String get quranZoomHint;

  /// Quran Display sheet: heading over the Mushaf page choices (one or two pages, Zoomed)
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get quranPages;

  /// Under the Zoomed switch on a portrait screen: one page already fills the width, so zoom changes little here; it helps on wider screens
  ///
  /// In en, this message translates to:
  /// **'One page already fills this screen\'s width; Zoomed helps on wider screens.'**
  String get quranZoomFillsAlready;

  /// Quran Display sheet, under the One/Two pages choice on a portrait screen: Two pages is off here and opens in landscape
  ///
  /// In en, this message translates to:
  /// **'Two pages open when the screen is turned sideways.'**
  String get quranTwoPagesSideways;

  /// Khatma setup: heading above the pace tiles (how many days the khatma takes)
  ///
  /// In en, this message translates to:
  /// **'Choose your pace'**
  String get khatmaChoosePace;

  /// Khatma setup: button to pick the day (portion) to start from instead of Al-Fatihah
  ///
  /// In en, this message translates to:
  /// **'Start from another day'**
  String get khatmaStartFromDay;

  /// Khatma pace tile: the unit after the large number of days (the number is shown separately)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String khatmaPaceUnit(int count);

  /// Khatma pace tile: how many pages a day the pace reads
  ///
  /// In en, this message translates to:
  /// **'{pages, plural, =1{1 page a day} other{{pages} pages a day}}'**
  String khatmaPagesADay(int pages);

  /// Khatma daily reminder: the row that shows and changes the reminder time
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get khatmaReminderTime;

  /// Khatma setup: the day the chosen plan would finish if started today (date already formatted, e.g. "Tue, Dec 2")
  ///
  /// In en, this message translates to:
  /// **'Finish on {date}'**
  String khatmaFinishOn(String date);

  /// Khatma completed: the unit under the number of juz read (30); the number is shown separately
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{juz}}'**
  String khatmaStatJuz(int count);

  /// Khatma completed: the unit under the number of pages read (604); the number is shown separately
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{page} other{pages}}'**
  String khatmaStatPages(int count);

  /// Number of surahs in a recitation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 surah} other{{count} surahs}}'**
  String quranAudioSurahCount(int count);

  /// How many surahs of a recitation are saved on the device
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String quranAudioDownloadedCount(int count);

  /// Progress of downloading a whole recitation
  ///
  /// In en, this message translates to:
  /// **'Downloading {done} of {total}'**
  String quranAudioDownloadingCount(int done, int total);

  /// Tooltip: play a recitation from its first surah
  ///
  /// In en, this message translates to:
  /// **'Play from the beginning'**
  String get quranAudioPlayFromStart;

  /// Banner while offline: only downloaded recitations are listed
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing downloaded recitations.'**
  String get quranAudioOfflineNote;

  /// Title when the reciters couldn't be loaded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the reciters'**
  String get quranAudioLoadFailed;

  /// Wide windows: the pane before a recitation is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose a recitation'**
  String get quranAudioChooseTitle;

  /// Wide windows: what to do in the empty recitation pane
  ///
  /// In en, this message translates to:
  /// **'Pick a reciter\'s recitation to see its surahs and play them.'**
  String get quranAudioChooseMessage;

  /// Player: which surah of the recitation is playing
  ///
  /// In en, this message translates to:
  /// **'Surah {index} of {total}'**
  String quranAudioSurahOfTotal(int index, int total);

  /// Player: shuffle the surahs
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get quranAudioShuffle;

  /// Player: repeat is off (tap to repeat all)
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get quranAudioRepeatOff;

  /// Player: repeating the whole recitation
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get quranAudioRepeatAll;

  /// Player: repeating the current surah
  ///
  /// In en, this message translates to:
  /// **'Repeat this surah'**
  String get quranAudioRepeatOne;

  /// Player: jump back 10 seconds
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get quranAudioBack10;

  /// Player: jump forward 10 seconds
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get quranAudioForward10;

  /// Player: label of the seek control
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get quranAudioPosition;

  /// Mini player: open the full player
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get quranAudioOpenPlayer;

  /// A surah is being prepared to play
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get quranAudioPreparing;

  /// Player: go back to the list, playback continues
  ///
  /// In en, this message translates to:
  /// **'Hide player'**
  String get quranAudioHidePlayer;

  /// Every surah of the recitation is saved on the device
  ///
  /// In en, this message translates to:
  /// **'All downloaded'**
  String get quranAudioAllDownloaded;

  /// A radio station is playing live
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get radioLive;

  /// The radio station is paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get radioPaused;

  /// The radio station is connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get radioConnecting;

  /// Title when the radio stations couldn't be loaded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the stations'**
  String get radioLoadFailed;

  /// Tooltip of a prayer's bell on Prayer Times; opens that prayer's alert settings.
  ///
  /// In en, this message translates to:
  /// **'Alerts for {prayer}'**
  String prayerAlertFor(String prayer);

  /// Prayer Times problem card title: settings couldn't be saved on the device.
  ///
  /// In en, this message translates to:
  /// **'Your latest changes weren\'t saved'**
  String get prayerFixSavingTitle;

  /// Prayer Times problem card message for a save failure.
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t save your prayer settings on this device. Tap Retry to save them again.'**
  String get prayerFixSavingMessage;

  /// Prayer Times problem card title: calculation failed after a change.
  ///
  /// In en, this message translates to:
  /// **'Today\'s times couldn\'t be recalculated'**
  String get prayerFixCalculationTitle;

  /// Prayer Times problem card message for a calculation failure.
  ///
  /// In en, this message translates to:
  /// **'The times shown may not include your latest change. Tap Retry to calculate them again.'**
  String get prayerFixCalculationMessage;

  /// Prayer Times info card title: the place's rules couldn't be confirmed (e.g. near a border).
  ///
  /// In en, this message translates to:
  /// **'Times may differ by a few minutes'**
  String get prayerFixCheckTitle;

  /// Prayer Times info card message when the place isn't verified.
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t confirm which local rules apply here, for example near a border or the coast. The times are calculated, but may differ slightly from your local mosque.'**
  String get prayerFixCheckMessage;

  /// Button: try verifying the place again.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get prayerFixCheckAction;

  /// Prayer Times info card title: the home widget didn't get the new times.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget not updated'**
  String get prayerFixWidgetTitle;

  /// Prayer Times info card message for a widget update failure.
  ///
  /// In en, this message translates to:
  /// **'The times here are correct, but your widget may still show older ones. Tap Retry to update it.'**
  String get prayerFixWidgetMessage;

  /// Title while a retry the user tapped is running.
  ///
  /// In en, this message translates to:
  /// **'Trying again…'**
  String get prayerRetryingTitle;

  /// Added to an alert status message when older alerts still use the previous place.
  ///
  /// In en, this message translates to:
  /// **'Alerts already scheduled may follow your previous place until they\'re replaced.'**
  String get prayerAlertsPreviousPlace;

  /// Alert status message while the user's retry runs.
  ///
  /// In en, this message translates to:
  /// **'Scheduling your prayer alerts again.'**
  String get prayerAlertsRetryingMessage;

  /// Alert status title while Huda reschedules alerts on its own.
  ///
  /// In en, this message translates to:
  /// **'Updating your alerts…'**
  String get prayerAlertsUpdatingTitle;

  /// Alert status message while Huda reschedules alerts on its own.
  ///
  /// In en, this message translates to:
  /// **'Scheduling the next prayer alerts. Your times are already up to date.'**
  String get prayerAlertsUpdatingMessage;

  /// Alert status title after scheduling failed.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts aren\'t scheduled'**
  String get prayerAlertsNotScheduledTitle;

  /// Alert status message: scheduled, but Android may deliver late without exact alarms.
  ///
  /// In en, this message translates to:
  /// **'Alerts may arrive a few minutes late. Allow exact alarms to get each one on time.'**
  String get prayerAlertsLateNote;

  /// Alert status title on a device that can't show prayer alerts.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts aren\'t available here'**
  String get prayerAlertsUnsupportedTitle;

  /// Alert status message on a device that can't show prayer alerts.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t show prayer alerts. Every prayer time is still here on this page.'**
  String get prayerAlertsUnsupportedMessage;

  /// Alert status message: a one-time online step is needed.
  ///
  /// In en, this message translates to:
  /// **'Huda needs to go online once to finish moving your alerts to this device. Connect to the internet, then tap Retry.'**
  String get prayerAlertsNeedsOnline;

  /// Alert status message while offline; it finishes automatically.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Huda will finish setting up your alerts by itself when you\'re back online.'**
  String get prayerAlertsNeedsOnlineOffline;

  /// Alert status message: no room left for scheduled alerts.
  ///
  /// In en, this message translates to:
  /// **'Huda\'s other reminders are using every alert this device allows. Turn a few reminders off, then tap Retry.'**
  String get prayerAlertsNoRoom;

  /// Alert status message: the device's own scheduling failed.
  ///
  /// In en, this message translates to:
  /// **'This device didn\'t accept the alert schedule. Tap Retry. If it keeps happening, restart Huda.'**
  String get prayerAlertsLocalFailure;

  /// Prayer Times first-run heading asking for a place.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get prayerWhereTitle;

  /// Prayer Times first-run message.
  ///
  /// In en, this message translates to:
  /// **'Prayer times depend on where you are. Use this device\'s location, or choose your city.'**
  String get prayerWhereMessage;

  /// Prayer Times first-run message on devices without location.
  ///
  /// In en, this message translates to:
  /// **'Prayer times depend on where you are. Choose your city to see them.'**
  String get prayerWhereMessageCityOnly;

  /// Button: search for and pick a city.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get prayerChooseCity;

  /// Why no place: the user declined location.
  ///
  /// In en, this message translates to:
  /// **'Location access wasn\'t allowed. Allow it, or choose your city instead.'**
  String get prayerProblemDenied;

  /// Why no place: location access is blocked for the app.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off for Huda. Turn it on in Settings, or choose your city instead.'**
  String get prayerProblemBlocked;

  /// Why no place: device location services are off.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this device. Turn them on, or choose your city instead.'**
  String get prayerProblemServicesOff;

  /// Why no place: the device has no location provider.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t share its location. Choose your city instead.'**
  String get prayerProblemNoDeviceLocation;

  /// Why no place: no location fix arrived in time.
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t get your location in time. Try again, perhaps near a window, or choose your city.'**
  String get prayerProblemNoFix;

  /// Why no place: the time zone couldn't be found.
  ///
  /// In en, this message translates to:
  /// **'Huda found the place but couldn\'t work out its time zone. Check your internet connection and try again, or choose a nearby city.'**
  String get prayerProblemTimeZone;

  /// Why no place: the coordinates weren't usable.
  ///
  /// In en, this message translates to:
  /// **'That place couldn\'t be used. Try again, or choose a different city.'**
  String get prayerProblemPlaceInvalid;

  /// Why no place: saving failed.
  ///
  /// In en, this message translates to:
  /// **'The place couldn\'t be saved on this device. Try again.'**
  String get prayerProblemSaveFailed;

  /// Why no place: calculation failed.
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t calculate prayer times for this place. Try again, or choose a different city.'**
  String get prayerProblemCalculation;

  /// Why no place: anything else.
  ///
  /// In en, this message translates to:
  /// **'Something stopped Huda from using this place. Try again, or choose your city instead.'**
  String get prayerProblemUnknown;

  /// Title of the prayer Location sheet.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get prayerLocationTitle;

  /// Location mode: follow the device's location.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get prayerLocationAutomatic;

  /// Location mode: a city the user picked.
  ///
  /// In en, this message translates to:
  /// **'A city I choose'**
  String get prayerLocationChosen;

  /// Explains the Automatic location mode.
  ///
  /// In en, this message translates to:
  /// **'Times follow this device\'s location.'**
  String get prayerLocationAutomaticHint;

  /// Explains the chosen-city location mode.
  ///
  /// In en, this message translates to:
  /// **'Times stay on the city you choose, wherever you are.'**
  String get prayerLocationChosenHint;

  /// Button: read the device's location now.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get prayerLocationUpdateNow;

  /// Shown while the place or times update.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get prayerLocationUpdating;

  /// Button: choose a different city.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get prayerLocationChangeCity;

  /// Switch: update the place in the background when the user moves.
  ///
  /// In en, this message translates to:
  /// **'Follow me when I travel'**
  String get prayerLocationTravel;

  /// Explains the travel switch.
  ///
  /// In en, this message translates to:
  /// **'When you arrive somewhere new, Huda updates the times and alerts by itself, even while it\'s closed.'**
  String get prayerLocationTravelHint;

  /// Travel switch note when only while-in-use permission is granted.
  ///
  /// In en, this message translates to:
  /// **'Huda can only follow you while it\'s open. Allow location all the time to follow you while it\'s closed.'**
  String get prayerLocationTravelForegroundOnly;

  /// Travel switch note when location permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Allow location so Huda can follow you when you travel.'**
  String get prayerLocationTravelNeedsPermission;

  /// Screen reader label of the place on the prayer sky card.
  ///
  /// In en, this message translates to:
  /// **'Location: {place}. Tap to change.'**
  String prayerLocationRowSemantics(String place);

  /// Title above a problem with a found or chosen place (time zone, saving, calculation).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use this place'**
  String get prayerProblemPlaceTitle;

  /// On the prayer time settings card: how many prayer times have a minute offset.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time adjusted} other{{number} times adjusted}}'**
  String prayerSettingsAdjusted(int count, String number);

  /// Qiblah dial: the letter for north
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get qiblahNorthShort;

  /// Qiblah dial: the letter for east
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get qiblahEastShort;

  /// Qiblah dial: the letter for south
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get qiblahSouthShort;

  /// Qiblah dial: the letter for west
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get qiblahWestShort;

  /// Qiblah: the Qibla's bearing, above the turn instruction. {degrees} comes formatted with its degree sign ("119°", "±4°").
  ///
  /// In en, this message translates to:
  /// **'Qibla {degrees} from north'**
  String qiblahFromNorth(String degrees);

  /// Qiblah: turn the phone clockwise
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get qiblahTurnRight;

  /// Qiblah: turn the phone counter-clockwise
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get qiblahTurnLeft;

  /// Qiblah: the phone faces the Qibla
  ///
  /// In en, this message translates to:
  /// **'You\'re facing the Qibla'**
  String get qiblahFacing;

  /// Qiblah: under "You're facing the Qibla"
  ///
  /// In en, this message translates to:
  /// **'Hold steady: the Kaaba is straight ahead.'**
  String get qiblahFacingHint;

  /// Qiblah: while the location and the first heading are on their way
  ///
  /// In en, this message translates to:
  /// **'Finding the Qibla…'**
  String get qiblahFinding;

  /// Qiblah: the device has no compass sensor
  ///
  /// In en, this message translates to:
  /// **'No compass on this device'**
  String get qiblahNoCompassTitle;

  /// Qiblah without a compass: how to find it from north. {degrees} comes formatted with its degree sign ("119°", "±4°").
  ///
  /// In en, this message translates to:
  /// **'Face north, then turn {degrees} clockwise. The dial shows the Kaaba with north at the top.'**
  String qiblahNoCompassMessage(String degrees);

  /// Qiblah: asking for location permission
  ///
  /// In en, this message translates to:
  /// **'Find the Qibla from where you are'**
  String get qiblahAllowTitle;

  /// Qiblah: why location is needed
  ///
  /// In en, this message translates to:
  /// **'Huda uses your location on this device to work out the direction of the Kaaba.'**
  String get qiblahAllowMessage;

  /// Qiblah: button that asks for location permission
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get qiblahAllowLocation;

  /// Qiblah: location services are off on the device
  ///
  /// In en, this message translates to:
  /// **'Location is off'**
  String get qiblahLocationOffTitle;

  /// Qiblah: why to turn on location services
  ///
  /// In en, this message translates to:
  /// **'Turn on location services so Huda can work out the Qibla from where you are.'**
  String get qiblahLocationOffMessage;

  /// Qiblah: opens the device location settings
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get qiblahTurnOnLocation;

  /// Qiblah: location permission was permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for Huda'**
  String get qiblahBlockedTitle;

  /// Qiblah: how to allow location again
  ///
  /// In en, this message translates to:
  /// **'Allow location for Huda in Settings, then come back here.'**
  String get qiblahBlockedMessage;

  /// Qiblah: the location or compass failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the Qibla'**
  String get qiblahErrorTitle;

  /// Qiblah: what to do after a failure
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t get your location. Check that location is on, then try again.'**
  String get qiblahErrorMessage;

  /// Qiblah: under the unlit dial while the location and first heading are on their way
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat while Huda finds the Qibla.'**
  String get qiblahHoldFlat;

  /// Qiblah: how to use the compass
  ///
  /// In en, this message translates to:
  /// **'Turn until the Kaaba reaches the mark at the top.'**
  String get qiblahTurnHint;

  /// Qiblah: the magnetic field is far from normal
  ///
  /// In en, this message translates to:
  /// **'Magnetic interference nearby. Move away from metal, magnets and electronics.'**
  String get qiblahInterference;

  /// Qiblah: the phone is held tilted
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat'**
  String get qiblahTilted;

  /// Qiblah: where the bearing is measured from, and the distance to the Kaaba
  ///
  /// In en, this message translates to:
  /// **'{place} · {distance} km to the Kaaba'**
  String qiblahPlaceDistance(String place, String distance);

  /// Qiblah: the distance to the Kaaba, when the place has no name
  ///
  /// In en, this message translates to:
  /// **'{distance} km to the Kaaba'**
  String qiblahDistance(String distance);

  /// Qiblah: a fresh location fix is on its way
  ///
  /// In en, this message translates to:
  /// **'Updating your location…'**
  String get qiblahUpdatingLocation;

  /// Qiblah: a fresh fix failed; an older location is in use
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your location. If you\'ve moved, the Qibla may be off.'**
  String get qiblahLocationStale;

  /// Qiblah: tooltip of the button that takes a fresh location fix
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get qiblahUpdateLocation;

  /// Reminders: eyebrow over the next reminder on the day dial
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get remindersNextReminder;

  /// Reminders: when the next reminder fires today; time is a localized time of day
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String remindersNextToday(String time);

  /// Reminders: when the next reminder fires tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String remindersNextTomorrow(String time);

  /// Reminders: when the next reminder fires on a later weekday (day is the weekday name)
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String remindersNextOnDay(String day, String time);

  /// Reminders: day dial caption when nothing is on
  ///
  /// In en, this message translates to:
  /// **'No reminders are on'**
  String get remindersNoneOnTitle;

  /// Reminders: day dial hint when nothing is on
  ///
  /// In en, this message translates to:
  /// **'Turn one on below and it takes its place on your day.'**
  String get remindersNoneOnMessage;

  /// Reminders: screen reader label of the day dial; reminders is a comma-separated list of title and time
  ///
  /// In en, this message translates to:
  /// **'Your reminders today: {reminders}'**
  String remindersDialLabel(String reminders);

  /// Reminders: screen reader label of the day dial with nothing today
  ///
  /// In en, this message translates to:
  /// **'No reminders today'**
  String get remindersDialEmptyLabel;

  /// Reminders: section with the Sahur alarm and the daily checklist
  ///
  /// In en, this message translates to:
  /// **'Daily routine'**
  String get remindersRoutineSection;

  /// Reminders: section with the test notification and desktop delivery status
  ///
  /// In en, this message translates to:
  /// **'Check delivery'**
  String get remindersDeliverySection;

  /// Reminders: status line while a reminder is being scheduled
  ///
  /// In en, this message translates to:
  /// **'Scheduling…'**
  String get remindersScheduling;

  /// Reminders: screen reader label of a reminder's time chip
  ///
  /// In en, this message translates to:
  /// **'Change time, {time}'**
  String remindersChangeTime(String time);

  /// Qiblah: compass accuracy is high
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy: good'**
  String get qiblahAccuracyGood;

  /// Qiblah: compass accuracy is medium
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy: fair'**
  String get qiblahAccuracyFair;

  /// Qiblah: compass accuracy is low
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy: weak'**
  String get qiblahAccuracyPoor;

  /// Reminders: the page title
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// Reminders: the evening Athkar reminder, by itself
  ///
  /// In en, this message translates to:
  /// **'Evening Athkar'**
  String get eveningAthkar;

  /// Reminders: time until the next reminder
  ///
  /// In en, this message translates to:
  /// **'in {hours} h {minutes} min'**
  String remindersInHoursMinutes(String hours, String minutes);

  /// Reminders: time until the next reminder (whole hours)
  ///
  /// In en, this message translates to:
  /// **'in {hours} h'**
  String remindersInHours(String hours);

  /// Reminders: time until the next reminder (under an hour)
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String remindersInMinutes(String minutes);

  /// Reminders, iOS: Sahur can't ring because AlarmKit permission is denied
  ///
  /// In en, this message translates to:
  /// **'Alarms are off for Huda. Allow them in Settings so the Sahur alarm can ring.'**
  String get remindersSahurAlarmsDenied;

  /// Reminders, iOS 25 and earlier: Sahur can't sound because notifications are off
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Huda. Allow them in Settings so the Sahur alarm can sound.'**
  String get remindersSahurNotificationsOff;

  /// Reminders, iOS 25 and earlier: Sahur can't be heard because notification sounds are off
  ///
  /// In en, this message translates to:
  /// **'Notification sounds are off for Huda. Turn them on in Settings so you can hear the Sahur alarm.'**
  String get remindersSahurSoundOff;

  /// Reminders: Sahur before Fajr has no prayer times to count from
  ///
  /// In en, this message translates to:
  /// **'Minutes before Fajr needs your prayer times. Set your location in Prayer Times, or use an exact time.'**
  String get remindersSahurNeedsPrayerTimes;

  /// Reminders: switch the Sahur alarm to an exact time
  ///
  /// In en, this message translates to:
  /// **'Use exact time'**
  String get remindersUseExactTime;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Which Hijri dates should Huda show?'**
  String get calendarChooseTitle;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Huda follows the official Umm al-Qura calendar. If the moon is sighted differently where you live, move the dates by a day or two.'**
  String get calendarChooseMessage;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Use Umm al-Qura'**
  String get calendarUseUmmAlQura;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Adjust days'**
  String get calendarAdjustDays;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Your events'**
  String get calendarYourEvents;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get calendarEventDeleted;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get calendarEventColor;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String calendarEventsCount(int count);

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the change. Try again.'**
  String get calendarAdjustmentFailed;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Today\'s fast'**
  String get ramadanTodaysFast;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Iftar {when}'**
  String ramadanIftarIn(String when);

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Imsaak {when}'**
  String ramadanImsakIn(String when);

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Your fasts'**
  String get ramadanYourFasts;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Ramadan {year}'**
  String ramadanYearLabel(String year);

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to make up} =1{1 day to make up} other{{count} days to make up}}'**
  String ramadanToMakeUp(int count);

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get ramadanClearDay;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get ramadanNotMarked;

  /// Ramadan page, outside Ramadan with nothing marked yet: what last Ramadan's tracker is for.
  ///
  /// In en, this message translates to:
  /// **'Mark each day of last Ramadan as fasted or missed, and the days you need to make up are counted for you.'**
  String get ramadanNightsIntro;

  /// Ramadan page: button that opens last Ramadan's days to mark them.
  ///
  /// In en, this message translates to:
  /// **'Mark your fasts'**
  String get ramadanMarkFasts;

  /// Ramadan page: tooltip of the button that unfolds last Ramadan's days.
  ///
  /// In en, this message translates to:
  /// **'Show the days'**
  String get ramadanShowDays;

  /// Ramadan page: tooltip of the button that folds last Ramadan's days.
  ///
  /// In en, this message translates to:
  /// **'Hide the days'**
  String get ramadanHideDays;

  /// Calendar / Ramadan redesign.
  ///
  /// In en, this message translates to:
  /// **'Ramadan times need your location. Set it in Prayer Times, then try again.'**
  String get ramadanLocationError;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Languages couldn\'t load.'**
  String get booksLanguagesError;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'No languages match “{query}”.'**
  String booksNoLanguageMatches(String query);

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String booksPageOf(int page, int total);

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the library. Check your connection and try again.'**
  String get booksLoadError;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'This book isn\'t available in that language.'**
  String get booksLanguageUnavailable;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this book.'**
  String get booksDetailError;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Show the original'**
  String get booksShowOriginal;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see this book. Downloaded books open offline.'**
  String get booksDetailOffline;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the book.'**
  String get booksDownloadFailed;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Remove this download?'**
  String get booksRemoveDownloadTitle;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'The book stays in the library. You can download it again when you\'re online.'**
  String get booksRemoveDownloadBody;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get booksRemove;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get booksRemoveDownload;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Download removed'**
  String get booksDownloadRemoved;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the book.'**
  String get booksShareFailed;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get booksRoleAuthor;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get booksRoleTranslator;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get booksRoleEditor;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get booksRolePublisher;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get booksRoleSource;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Prepared by'**
  String get booksRoleOther;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String booksDownloading(int percent);

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Downloaded · opens offline'**
  String get booksDownloadedNote;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {date}'**
  String booksDownloadedOn(String date);

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Other formats'**
  String get booksOtherFormats;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Also in'**
  String get booksAlsoIn;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get booksHighlights;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get booksHighlight;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'This book has no contents list. Search or browse its pages instead.'**
  String get booksContentsHint;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get booksNoMatches;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet'**
  String get booksNoHighlights;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Select text on a page, then pick an ink.'**
  String get booksHighlightsHint;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Highlight removed'**
  String get booksHighlightRemoved;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get booksZoomIn;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get booksZoomOut;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Opening the book…'**
  String get booksOpening;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this book'**
  String get booksReaderError;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get booksReaderErrorMessage;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Contents and search'**
  String get booksReaderPanel;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Scroll down the pages'**
  String get booksScrollDown;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Scroll across the pages'**
  String get booksScrollAcross;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get booksInkRed;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get booksInkGreen;

  /// Books redesign.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get booksInkOrange;

  /// audiobooksChapterCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String audiobooksChapterCount(int count);

  /// audiobooksShowingDownloaded
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Showing 1 downloaded recording} other{Showing {count} downloaded recordings}}'**
  String audiobooksShowingDownloaded(int count);

  /// audiobooksLoadError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the audio library. Check your connection and try again.'**
  String get audiobooksLoadError;

  /// audiobooksDetailError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this recording. Check your connection and try again.'**
  String get audiobooksDetailError;

  /// audiobooksDetailOffline
  ///
  /// In en, this message translates to:
  /// **'This recording isn\'t downloaded. Connect to the internet to listen to it.'**
  String get audiobooksDetailOffline;

  /// audiobooksDownloadWhenOnline
  ///
  /// In en, this message translates to:
  /// **'Download recordings while you\'re online to listen to them here.'**
  String get audiobooksDownloadWhenOnline;

  /// audiobooksRemoveDownloadBody
  ///
  /// In en, this message translates to:
  /// **'The recording stays in the library. You can download it again when you\'re online.'**
  String get audiobooksRemoveDownloadBody;

  /// audiobooksDownloadFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the recording.'**
  String get audiobooksDownloadFailed;

  /// audiobooksDownloadingPercent
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String audiobooksDownloadingPercent(String percent);

  /// audiobooksCancelDownload
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get audiobooksCancelDownload;

  /// audiobooksBack15
  ///
  /// In en, this message translates to:
  /// **'Back 15 seconds'**
  String get audiobooksBack15;

  /// audiobooksForward15
  ///
  /// In en, this message translates to:
  /// **'Forward 15 seconds'**
  String get audiobooksForward15;

  /// audiobooksForward30
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get audiobooksForward30;

  /// audiobooksPreviousChapter
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get audiobooksPreviousChapter;

  /// audiobooksNextChapter
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get audiobooksNextChapter;

  /// audiobooksSleepPausesIn
  ///
  /// In en, this message translates to:
  /// **'Pauses in {time}'**
  String audiobooksSleepPausesIn(String time);

  /// audiobooksSleepEndOfChapter
  ///
  /// In en, this message translates to:
  /// **'Pauses at the end of this chapter'**
  String get audiobooksSleepEndOfChapter;

  /// audiobooksSleepOff
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get audiobooksSleepOff;

  /// audiobooksStartFailed
  ///
  /// In en, this message translates to:
  /// **'This recording couldn\'t start. Check your connection, then open it again.'**
  String get audiobooksStartFailed;

  /// No description provided for @hudaAiYouAsked.
  ///
  /// In en, this message translates to:
  /// **'You asked'**
  String get hudaAiYouAsked;

  /// No description provided for @hudaAiYouShared.
  ///
  /// In en, this message translates to:
  /// **'You shared'**
  String get hudaAiYouShared;

  /// No description provided for @hudaAiCounselingHint.
  ///
  /// In en, this message translates to:
  /// **'Share what\'s on your heart…'**
  String get hudaAiCounselingHint;

  /// No description provided for @hudaAiShareAnswer.
  ///
  /// In en, this message translates to:
  /// **'Share answer'**
  String get hudaAiShareAnswer;

  /// No description provided for @hudaAiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get hudaAiSend;

  /// No description provided for @hudaAiWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get hudaAiWriting;

  /// No description provided for @hudaAiCounselHeading.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your heart?'**
  String get hudaAiCounselHeading;

  /// No description provided for @hudaAiSeekCounsel.
  ///
  /// In en, this message translates to:
  /// **'Seek counsel'**
  String get hudaAiSeekCounsel;

  /// No description provided for @hudaAiAnotherFeeling.
  ///
  /// In en, this message translates to:
  /// **'Share another feeling'**
  String get hudaAiAnotherFeeling;

  /// No description provided for @checklistDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String checklistDoneOf(int done, int total);

  /// No description provided for @checklistAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get checklistAllDone;

  /// No description provided for @checklistStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day in a row} other{{count} days in a row}}'**
  String checklistStreak(int count);

  /// No description provided for @checklistStreakStart.
  ///
  /// In en, this message translates to:
  /// **'Finish every item today to start a streak'**
  String get checklistStreakStart;

  /// No description provided for @checklistPastNote.
  ///
  /// In en, this message translates to:
  /// **'Past days stay as they were'**
  String get checklistPastNote;

  /// No description provided for @checklistFutureNote.
  ///
  /// In en, this message translates to:
  /// **'You can check this day off when it comes'**
  String get checklistFutureNote;

  /// No description provided for @checklistGroupPrayers.
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get checklistGroupPrayers;

  /// No description provided for @checklistGroupQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get checklistGroupQuran;

  /// No description provided for @checklistGroupAthkar.
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get checklistGroupAthkar;

  /// No description provided for @checklistGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get checklistGroupOther;

  /// No description provided for @checklistPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get checklistPreviousDay;

  /// No description provided for @checklistNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get checklistNextDay;

  /// No description provided for @checklistRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed “{title}”'**
  String checklistRemoved(String title);

  /// No description provided for @checklistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your checklist couldn’t be opened'**
  String get checklistLoadError;

  /// No description provided for @checklistEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing is planned for this day.'**
  String get checklistEmptyMessage;

  /// No description provided for @checklistNewItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get checklistNewItem;

  /// No description provided for @checklistItemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get checklistItemName;

  /// No description provided for @checklistItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example, read Surah Al-Mulk'**
  String get checklistItemNameHint;

  /// No description provided for @checklistItemGroup.
  ///
  /// In en, this message translates to:
  /// **'Goes under'**
  String get checklistItemGroup;

  /// No description provided for @checklistItemRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get checklistItemRepeats;

  /// No description provided for @checklistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get checklistAdd;

  /// No description provided for @miqaatGateOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Your apps open as usual.'**
  String get miqaatGateOff;

  /// No description provided for @miqaatGateNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access below to turn it on.'**
  String get miqaatGateNeedsAccess;

  /// No description provided for @miqaatGateNoWindows.
  ///
  /// In en, this message translates to:
  /// **'Add a time window to begin.'**
  String get miqaatGateNoWindows;

  /// No description provided for @miqaatGateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Next window: {when}'**
  String miqaatGateWaiting(String when);

  /// No description provided for @miqaatGateLocked.
  ///
  /// In en, this message translates to:
  /// **'Spend {remaining} more in Huda to open your apps.'**
  String miqaatGateLocked(String remaining);

  /// No description provided for @miqaatGateDone.
  ///
  /// In en, this message translates to:
  /// **'Goal met. Your apps are open until the next window.'**
  String get miqaatGateDone;

  /// No description provided for @miqaatStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get miqaatStatusOff;

  /// No description provided for @miqaatStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get miqaatStatusWaiting;

  /// No description provided for @miqaatStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked now'**
  String get miqaatStatusLocked;

  /// No description provided for @miqaatStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get miqaatStatusOpen;

  /// No description provided for @miqaatMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String miqaatMinutesShort(int minutes);

  /// No description provided for @miqaatProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {goal} min'**
  String miqaatProgress(int done, int goal);

  /// No description provided for @miqaatSlotCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max}'**
  String miqaatSlotCount(int count, int max);

  /// No description provided for @miqaatRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String miqaatRemoved(String name);

  /// No description provided for @miqaatWindowRemoved.
  ///
  /// In en, this message translates to:
  /// **'Window removed'**
  String get miqaatWindowRemoved;

  /// No description provided for @miqaatCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get miqaatCheckAgain;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTextSizeRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative to your device\'s text size'**
  String get settingsTextSizeRelative;

  /// No description provided for @settingsHapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHapticFeedback;

  /// No description provided for @settingsHapticFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Gentle vibrations when you count, switch or finish something'**
  String get settingsHapticFeedbackDescription;

  /// No description provided for @settingsWidgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A verse and prayer times on your home screen'**
  String get settingsWidgetsSubtitle;

  /// No description provided for @widgetPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get widgetPreview;

  /// No description provided for @widgetResetDone.
  ///
  /// In en, this message translates to:
  /// **'Widget reset to its defaults'**
  String get widgetResetDone;

  /// No description provided for @widgetResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Put this widget\'s theme, text and layout back to the defaults?'**
  String get widgetResetConfirm;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'This part of Huda stopped working. Restarting the app usually fixes it.'**
  String get errorScreenMessage;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'Sending a report to the team…'**
  String get errorReportSending;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'A report was sent to the team.'**
  String get errorReportSent;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'The report couldn\'t be sent.'**
  String get errorReportFailed;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get errorTechnicalDetails;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'Your note couldn\'t be sent. Try again.'**
  String get errorFeedbackFailed;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'Huda couldn\'t start'**
  String get bootFailedTitle;

  /// System screens (error screen / startup failure).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while getting ready. Try again, or restart the app.'**
  String get bootFailedMessage;

  /// No description provided for @windowsPrayerShowTray.
  ///
  /// In en, this message translates to:
  /// **'Show tray icon'**
  String get windowsPrayerShowTray;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'ms',
    'ru',
    'tr',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ms':
      return AppLocalizationsMs();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
