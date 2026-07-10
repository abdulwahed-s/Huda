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
    Locale('ur')
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

  /// Title of the manual location search dialog
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocationTitle;

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
  /// **'Qiblah Direction'**
  String get qiblahDirection;

  /// Tasbih screen title
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// Title for Islamic notifications screen
  ///
  /// In en, this message translates to:
  /// **'Islamic Notifications'**
  String get islamicNotifications;

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

  /// Widget management screen title
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget Management'**
  String get homeScreenWidgetManagement;

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

  /// Button label for sharing text
  ///
  /// In en, this message translates to:
  /// **'Share Text'**
  String get shareText;

  /// Refresh location button text
  ///
  /// In en, this message translates to:
  /// **'Refresh Location'**
  String get refreshLocation;

  /// Auto-update setting description
  ///
  /// In en, this message translates to:
  /// **'Auto-update when app is closed'**
  String get autoUpdateWhenAppClosed;

  /// Background updates status message
  ///
  /// In en, this message translates to:
  /// **'Background updates disabled.'**
  String get backgroundUpdatesDisabled;

  /// Clear custom verses button text
  ///
  /// In en, this message translates to:
  /// **'Clear All Custom Verses'**
  String get clearAllCustomVerses;

  /// Clear all bookmarks action
  ///
  /// In en, this message translates to:
  /// **'Clear All Bookmarks'**
  String get clearAllBookmarks;

  /// Success message for verse removal
  ///
  /// In en, this message translates to:
  /// **'Verse removed from widget'**
  String get verseRemovedFromWidget;

  /// Success message for clearing all verses
  ///
  /// In en, this message translates to:
  /// **'All custom verses cleared'**
  String get allCustomVersesCleared;

  /// Download feature coming soon message
  ///
  /// In en, this message translates to:
  /// **'Download feature coming soon!'**
  String get downloadFeatureComingSoon;

  /// Prayer countdown service started message
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service started'**
  String get prayerCountdownServiceStarted;

  /// Prayer countdown service stopped message
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service stopped'**
  String get prayerCountdownServiceStopped;

  /// Prayer countdown service restarted message
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service restarted'**
  String get prayerCountdownServiceRestarted;

  /// Failed to share text error message
  ///
  /// In en, this message translates to:
  /// **'Failed to share text'**
  String get failedToShareText;

  /// Failed to share image error message
  ///
  /// In en, this message translates to:
  /// **'Failed to share image'**
  String get failedToShareImage;

  /// Tafsir downloaded success message
  ///
  /// In en, this message translates to:
  /// **'Tafsir downloaded successfully!'**
  String get tafsirDownloadedSuccessfully;

  /// Translation downloaded success message
  ///
  /// In en, this message translates to:
  /// **'Translation downloaded successfully!'**
  String get translationDownloadedSuccessfully;

  /// Unknown state error message
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get unknownState;

  /// Delete event dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

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

  /// Choose color button text
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get chooseColor;

  /// Hijri Calendar screen title
  ///
  /// In en, this message translates to:
  /// **'Hijri Calendar'**
  String get hijriCalendar;

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

  /// Instruction to add events
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add an event'**
  String get tapPlusButtonToAddEvent;

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

  /// First Gregorian month
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// Second Gregorian month
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// Third Gregorian month
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// Fourth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// Fifth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// Sixth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// Seventh Gregorian month
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// Eighth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// Ninth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// Tenth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// Eleventh Gregorian month
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// Twelfth Gregorian month
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

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

  /// Event color label
  ///
  /// In en, this message translates to:
  /// **'Event Color:'**
  String get eventColor;

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

  /// Filtered results label
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

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

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWentWrong;

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

  /// Pick color dialog title
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

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

  /// Reset counter confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the counter to 0?'**
  String get resetCounterConfirmation;

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

  /// Loading message for qiblah direction
  ///
  /// In en, this message translates to:
  /// **'Finding Qiblah Direction...'**
  String get findingQiblahDirection;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Location permission dialog title
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// Open settings button text
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Status when aligned with qiblah
  ///
  /// In en, this message translates to:
  /// **'Aligned with Qiblah'**
  String get alignedWithQiblah;

  /// Status when finding direction
  ///
  /// In en, this message translates to:
  /// **'Finding Direction...'**
  String get findingDirection;

  /// Message when perfectly aligned with qiblah
  ///
  /// In en, this message translates to:
  /// **'🕋 Perfect! You are facing the Qiblah direction'**
  String get perfectQiblahAlignment;

  /// Instruction for aligning with qiblah
  ///
  /// In en, this message translates to:
  /// **'Rotate your device until the arrow points toward Mecca'**
  String get rotateDeviceInstruction;

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

  /// Athkar collection title
  ///
  /// In en, this message translates to:
  /// **'Athkar Collection'**
  String get athkarCollection;

  /// Number of selected athkar groups
  ///
  /// In en, this message translates to:
  /// **'{count} selected athkar groups'**
  String selectedAthkarGroups(int count);

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryArabic;

  /// Error message when verse removal fails
  ///
  /// In en, this message translates to:
  /// **'Error removing verse'**
  String get errorRemovingVerse;

  /// Clear all confirmation button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Error message for clearing verses
  ///
  /// In en, this message translates to:
  /// **'Error clearing verses'**
  String get errorClearingVerses;

  /// Test now button label
  ///
  /// In en, this message translates to:
  /// **'Test Now'**
  String get testNow;

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

  /// Quran surahs screen title
  ///
  /// In en, this message translates to:
  /// **'Quran Surahs'**
  String get quranSurahs;

  /// Widget management title
  ///
  /// In en, this message translates to:
  /// **'Widget Management'**
  String get widgetManagement;

  /// Current widgets section title
  ///
  /// In en, this message translates to:
  /// **'Current Widgets'**
  String get currentWidgets;

  /// Available widgets section title
  ///
  /// In en, this message translates to:
  /// **'Available Widgets'**
  String get availableWidgets;

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

  /// Athkar counter widget title
  ///
  /// In en, this message translates to:
  /// **'Athkar Counter'**
  String get athkarCounter;

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

  /// No prayer times message
  ///
  /// In en, this message translates to:
  /// **'No prayer times available'**
  String get noPrayerTimesAvailable;

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

  /// Connection check message
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get pleaseCheckConnection;

  /// Offline content loading error
  ///
  /// In en, this message translates to:
  /// **'Cannot load {section} while offline.\nPlease check your internet connection.'**
  String cannotLoadOffline(String section);

  /// No internet and no offline content message
  ///
  /// In en, this message translates to:
  /// **'No internet connection. No offline content available.'**
  String get noInternetOfflineUnavailable;

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

  /// Loading athkar message
  ///
  /// In en, this message translates to:
  /// **'Loading Athkar...'**
  String get loadingAthkar;

  /// Press for details text
  ///
  /// In en, this message translates to:
  /// **'Press for details'**
  String get pressForDetails;

  /// Connection timeout error message
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please check your internet connection and try again.'**
  String get connectionTimedOut;

  /// Server timeout error message
  ///
  /// In en, this message translates to:
  /// **'Server took too long to respond. Please try again.'**
  String get serverTimeout;

  /// Response timeout error message
  ///
  /// In en, this message translates to:
  /// **'Response timeout. Please check your connection and try again.'**
  String get responseTimeout;

  /// SSL certificate error message
  ///
  /// In en, this message translates to:
  /// **'There\'s a problem with the security certificate. Please try again later or contact support.'**
  String get certificateError;

  /// No internet connection with settings instruction
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network settings and try again.'**
  String get noInternetSettings;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// Bad request error message
  ///
  /// In en, this message translates to:
  /// **'Bad request. Please check your input.'**
  String get badRequest;

  /// Request timeout error message
  ///
  /// In en, this message translates to:
  /// **'Request timeout. Please try again.'**
  String get requestTimeout;

  /// Conflict error message
  ///
  /// In en, this message translates to:
  /// **'Conflict occurred. Please resolve and try again.'**
  String get conflictError;

  /// Validation failed error message
  ///
  /// In en, this message translates to:
  /// **'Validation failed. Please check your input.'**
  String get validationFailed;

  /// Too many requests error message
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again later.'**
  String get tooManyRequests;

  /// No internet and no cached translation error
  ///
  /// In en, this message translates to:
  /// **'No internet connection and no cached translation available'**
  String get noInternetCachedTranslation;

  /// No internet and no cached data error
  ///
  /// In en, this message translates to:
  /// **'No internet connection and no cached data available'**
  String get noInternetCachedData;

  /// No internet and no cached tafsir error
  ///
  /// In en, this message translates to:
  /// **'No internet connection and no cached tafsir available'**
  String get noInternetCachedTafsir;

  /// Confirmation message for clearing all custom verses
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all custom verses from your widget? This action cannot be undone.'**
  String get clearAllCustomVersesConfirmation;

  /// Chat error message
  ///
  /// In en, this message translates to:
  /// **'Sorry, I encountered an error. Please try again.'**
  String get chatError;

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

  /// Generic error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String unknownError(String message);

  /// Error message when text sharing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share text'**
  String get failedShareText;

  /// Error message when image sharing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share image'**
  String get failedShareImage;

  /// Success message when prayer countdown service starts
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service started'**
  String get prayerCountdownStarted;

  /// Success message when prayer countdown service stops
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service stopped'**
  String get prayerCountdownStopped;

  /// Error message when service fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start service: {error}'**
  String failedStartService(String error);

  /// Error message when service fails to stop
  ///
  /// In en, this message translates to:
  /// **'Failed to stop service: {error}'**
  String failedStopService(String error);

  /// Success message when prayer countdown service restarts
  ///
  /// In en, this message translates to:
  /// **'Prayer countdown service restarted'**
  String get prayerCountdownRestarted;

  /// Error message when service fails to restart
  ///
  /// In en, this message translates to:
  /// **'Failed to restart service: {error}'**
  String failedRestartService(String error);

  /// Section header for Islamic reminders
  ///
  /// In en, this message translates to:
  /// **'Islamic Reminders'**
  String get islamicReminders;

  /// Surat Al-Kahf title
  ///
  /// In en, this message translates to:
  /// **'Surat Al-Kahf'**
  String get suratAlKahf;

  /// Friday notification subtitle
  ///
  /// In en, this message translates to:
  /// **'Every Friday at {time}'**
  String everyFridayAt(String time);

  /// Morning and evening athkar notification title
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Athkar'**
  String get morningEveningAthkar;

  /// Daily athkar times subtitle
  ///
  /// In en, this message translates to:
  /// **'{morningTime} & {eveningTime} daily'**
  String dailyAthkarTimes(String morningTime, String eveningTime);

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

  /// Daily notification time
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyAt(String time);

  /// Debug button label
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// Reinitialize button label
  ///
  /// In en, this message translates to:
  /// **'Reinit'**
  String get reinit;

  /// Test limits button label
  ///
  /// In en, this message translates to:
  /// **'Test Limits'**
  String get testLimits;

  /// Loading message for coverage check
  ///
  /// In en, this message translates to:
  /// **'Checking coverage...'**
  String get checkingCoverage;

  /// Refresh coverage button label
  ///
  /// In en, this message translates to:
  /// **'Refresh Coverage'**
  String get refreshCoverage;

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

  /// Test notification message
  ///
  /// In en, this message translates to:
  /// **'Test notification scheduled for 10 seconds from now!'**
  String get testNotificationScheduled;

  /// Debug info message
  ///
  /// In en, this message translates to:
  /// **'Check console for debug info'**
  String get checkConsoleDebugInfo;

  /// Force reinit success message
  ///
  /// In en, this message translates to:
  /// **'Force re-initialized notifications'**
  String get forceReInitializedNotifications;

  /// Test limits result message
  ///
  /// In en, this message translates to:
  /// **'Check console for limit test results'**
  String get checkConsoleLimitTestResults;

  /// Coverage display with days and count
  ///
  /// In en, this message translates to:
  /// **'Coverage: ~{days} days ({count} notifications)'**
  String coverageDaysNotifications(String days, String count);

  /// Status when notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabled;

  /// Status when notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// Instruction to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Tap to enable notification permissions'**
  String get tapToEnableNotifications;

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

  /// Books screen title
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksScreen;

  /// PDF screen title
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdfScreen;

  /// Tooltip for prayer times button
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimesTooltip;

  /// Tooltip for qiblah direction button
  ///
  /// In en, this message translates to:
  /// **'Qiblah Direction'**
  String get qiblahTooltip;

  /// Tooltip for tasbih counter button
  ///
  /// In en, this message translates to:
  /// **'Tasbih Counter'**
  String get tasbihTooltip;

  /// Tooltip for islamic notifications button
  ///
  /// In en, this message translates to:
  /// **'Islamic Notifications'**
  String get islamicNotificationsTooltip;

  /// Tooltip for hadith button
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadithTooltip;

  /// Tooltip for hadith chapters button
  ///
  /// In en, this message translates to:
  /// **'Hadith Chapters'**
  String get hadithChaptersTooltip;

  /// Tooltip for hadith details button
  ///
  /// In en, this message translates to:
  /// **'Hadith Details'**
  String get hadithDetailsTooltip;

  /// Tooltip for books button
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksTooltip;

  /// Tooltip for bookmarks button
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTooltip;

  /// Tooltip for hijri calendar button
  ///
  /// In en, this message translates to:
  /// **'Hijri Calendar'**
  String get hijriCalendarTooltip;

  /// Tooltip for home screen widget management button
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget Management'**
  String get homeScreenWidgetManagementTooltip;

  /// Tooltip for quran surahs button
  ///
  /// In en, this message translates to:
  /// **'Quran Surahs'**
  String get quranSurahsTooltip;

  /// Tooltip for settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Tooltip for athkar details button
  ///
  /// In en, this message translates to:
  /// **'Athkar Details'**
  String get athkarDetailsTooltip;

  /// Tooltip for zoom in button
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomInTooltip;

  /// Tooltip for zoom out button
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOutTooltip;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Book name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter book name'**
  String get enterBookNameHint;

  /// Author name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter author name'**
  String get enterAuthorNameHint;

  /// Description input hint
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescriptionHint;

  /// Notes input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your notes here...'**
  String get enterNotesHint;

  /// Search books hint
  ///
  /// In en, this message translates to:
  /// **'Search books...'**
  String get searchBooksHint;

  /// Search bookmarks hint
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks...'**
  String get searchBookmarksHint;

  /// Search hadith hint
  ///
  /// In en, this message translates to:
  /// **'Search hadith...'**
  String get searchHadithHint;

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

  /// Confirm delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteConfirmation;

  /// Delete bookmark dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Bookmark'**
  String get deleteBookmark;

  /// Delete bookmark confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this bookmark? This action cannot be undone.'**
  String get deleteBookmarkConfirmation;

  /// Confirm clear all dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear All'**
  String get confirmClearAll;

  /// Clear all confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all items? This action cannot be undone.'**
  String get clearAllConfirmation;

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

  /// Permission dialog title
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionDialog;

  /// Permission dialog message
  ///
  /// In en, this message translates to:
  /// **'This feature requires permission to access your device. Please grant permission to continue.'**
  String get permissionMessage;

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

  /// Loading failed error message
  ///
  /// In en, this message translates to:
  /// **'Loading failed. Please try again.'**
  String get loadingFailed;

  /// File not found error message
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

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

  /// Author name form label
  ///
  /// In en, this message translates to:
  /// **'Author Name'**
  String get authorName;

  /// Download started status message
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// Download complete status message
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// Operation complete status message
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationComplete;

  /// Athkar screen title
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get athkar;

  /// Error message when athkar fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading Athkar'**
  String get athkarLoadingError;

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

  /// Click for details action text
  ///
  /// In en, this message translates to:
  /// **'Click for details'**
  String get clickForDetails;

  /// Subtitle for Huda AI
  ///
  /// In en, this message translates to:
  /// **'Islamic Assistant'**
  String get islamicAssistant;

  /// Welcome message for Huda AI in English
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huda AI'**
  String get welcomeToHudaAI;

  /// Welcome message for Huda AI
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huda'**
  String get welcomeToHudaArabic;

  /// Introduction message explaining AI capabilities
  ///
  /// In en, this message translates to:
  /// **'Ask me any question about Islam, and I\'ll provide answers based on the Qur\'an and authentic Sunnah.'**
  String get aiIntroMessage;

  /// AI Assistant info card title
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// AI Assistant disclaimer
  ///
  /// In en, this message translates to:
  /// **'Provides answers based on Islamic teachings but should not be considered a definitive source.'**
  String get aiAssistantSubtitle;

  /// Verification info card title
  ///
  /// In en, this message translates to:
  /// **'Verify with authentic sources'**
  String get verifySourcesTitle;

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

  /// Share message header
  ///
  /// In en, this message translates to:
  /// **'Islamic Q&A from Huda AI'**
  String get islamicQAFromHuda;

  /// Attribution in shared content
  ///
  /// In en, this message translates to:
  /// **'Generated by Huda AI - Islamic Assistant'**
  String get generatedByHudaAI;

  /// Verification reminder in shared content
  ///
  /// In en, this message translates to:
  /// **'Please verify with authentic Islamic sources.'**
  String get verifyWithSources;

  /// Header for shared Q&A content
  ///
  /// In en, this message translates to:
  /// **'Islamic Q&A from Huda AI'**
  String get shareQAFromHuda;

  /// Subject line for shared content
  ///
  /// In en, this message translates to:
  /// **'Islamic Knowledge from Huda AI'**
  String get islamicKnowledgeSubject;

  /// App name for Huda AI
  ///
  /// In en, this message translates to:
  /// **'Huda AI'**
  String get hudaAI;

  /// Title for bookmark section
  ///
  /// In en, this message translates to:
  /// **'Bookmark Ayah'**
  String get bookmarkAyah;

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

  /// Reference format for surah and ayah
  ///
  /// In en, this message translates to:
  /// **'Surah {surahName} - Ayah {ayahNumber}'**
  String surahAyahReference(String surahName, String ayahNumber);

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

  /// Share and copy section title
  ///
  /// In en, this message translates to:
  /// **'Share & Copy'**
  String get shareCopy;

  /// Share options title
  ///
  /// In en, this message translates to:
  /// **'Share Options'**
  String get shareOptions;

  /// Include translation option
  ///
  /// In en, this message translates to:
  /// **'Include Translation'**
  String get includeTranslation;

  /// Include tafsir option
  ///
  /// In en, this message translates to:
  /// **'Include Tafsir'**
  String get includeTafsir;

  /// Include reference option
  ///
  /// In en, this message translates to:
  /// **'Include Reference'**
  String get includeReference;

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

  /// App name for sharing
  ///
  /// In en, this message translates to:
  /// **'Huda - Quran App'**
  String get hudaQuranApp;

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

  /// Translation section label
  ///
  /// In en, this message translates to:
  /// **'Translation:'**
  String get translationLabel;

  /// Footer for shared content
  ///
  /// In en, this message translates to:
  /// **'Shared via Huda - Quran App'**
  String get sharedViaHuda;

  /// Success message for copy
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Error message for copy failure
  ///
  /// In en, this message translates to:
  /// **'Failed to copy to clipboard'**
  String get failedToCopy;

  /// Subject line for sharing
  ///
  /// In en, this message translates to:
  /// **'Ayah from {surahName}'**
  String ayahFromSurah(String surahName);

  /// Fallback subject for sharing
  ///
  /// In en, this message translates to:
  /// **'Ayah from Quran'**
  String get ayahFromQuran;

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

  /// Audio loading error message
  ///
  /// In en, this message translates to:
  /// **'Unable to load audio for this reader'**
  String get unableToLoadAudio;

  /// Reader selection title
  ///
  /// In en, this message translates to:
  /// **'Select Reader'**
  String get selectReader;

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

  /// No readers available message
  ///
  /// In en, this message translates to:
  /// **'No readers available'**
  String get noReadersAvailable;

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

  /// Add to home widget button
  ///
  /// In en, this message translates to:
  /// **'Add to Home Widget'**
  String get addToHomeWidget;

  /// Widget tab description
  ///
  /// In en, this message translates to:
  /// **'Add this ayah to your home screen widget collection'**
  String get addToWidgetDescription;

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

  /// Unable to load audio message
  ///
  /// In en, this message translates to:
  /// **'Unable to load audio for this reader'**
  String get unableLoadAudio;

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

  /// Already in widget status
  ///
  /// In en, this message translates to:
  /// **'Already in Widget'**
  String get alreadyInWidget;

  /// Add to widget button
  ///
  /// In en, this message translates to:
  /// **'Add to Widget'**
  String get addToWidget;

  /// Widget tab info message
  ///
  /// In en, this message translates to:
  /// **'This will add the selected ayah to your home screen widget collection for easy access.'**
  String get addToWidgetInfo;

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

  /// Default text for books without titles
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// Default text when book description is missing
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// Attachments section title
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Default text when attachment description is missing
  ///
  /// In en, this message translates to:
  /// **'No Description'**
  String get noDescription;

  /// Section title for language selection
  ///
  /// In en, this message translates to:
  /// **'Other Languages'**
  String get otherLanguages;

  /// Offline status message
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get youreOffline;

  /// Error message for unavailable language
  ///
  /// In en, this message translates to:
  /// **'The selected language is not available'**
  String get theSelectedLanguageNotAvailable;

  /// Share dialog title
  ///
  /// In en, this message translates to:
  /// **'Share Book'**
  String get shareBook;

  /// Share confirmation question
  ///
  /// In en, this message translates to:
  /// **'Share \"{title}\" with others?'**
  String shareBookQuestion(String title);

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

  /// Error message for language loading failure
  ///
  /// In en, this message translates to:
  /// **'Error loading languages: {error}'**
  String errorLoadingLanguages(String error);

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

  /// Daily schedule with morning and evening times
  ///
  /// In en, this message translates to:
  /// **'{morningTime} & {eveningTime} daily'**
  String dailyTimesSchedule(String morningTime, String eveningTime);

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

  /// Debug section title
  ///
  /// In en, this message translates to:
  /// **'Debug & Testing'**
  String get debugTesting;

  /// Number of pending notifications
  ///
  /// In en, this message translates to:
  /// **'Pending notifications: {count}'**
  String pendingNotificationsCount(String count);

  /// Background notifications info
  ///
  /// In en, this message translates to:
  /// **'All notifications work in background and survive app restarts.'**
  String get notificationsWorkBackground;

  /// Coverage section title
  ///
  /// In en, this message translates to:
  /// **'Notification Coverage'**
  String get notificationCoverage;

  /// Auto renewal active status
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal: Active'**
  String get autoRenewalActive;

  /// Auto renewal inactive status
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal: Inactive'**
  String get autoRenewalInactive;

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

  /// Customization info
  ///
  /// In en, this message translates to:
  /// **'All notification times are fully customizable. Tap the settings button next to each notification type to set your preferred time.'**
  String get notificationTimesCustomizable;

  /// Smart scheduling info
  ///
  /// In en, this message translates to:
  /// **'Random Athkar uses smart scheduling: immediate coverage for 12+ hours, then background completion for full 7-day coverage.'**
  String get randomAthkarSmartScheduling;

  /// Background work info
  ///
  /// In en, this message translates to:
  /// **'All notifications work when the app is closed and survive device reboots.'**
  String get notificationsWorkClosed;

  /// PDF viewer title
  ///
  /// In en, this message translates to:
  /// **'PDF Viewer'**
  String get pdfViewer;

  /// Layout toggle tooltip
  ///
  /// In en, this message translates to:
  /// **'Switch layout'**
  String get switchLayout;

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

  /// PDF loading message
  ///
  /// In en, this message translates to:
  /// **'Loading PDF...'**
  String get loadingPdf;

  /// PDF loading error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF'**
  String get failedToLoadPdf;

  /// Empty table of contents message
  ///
  /// In en, this message translates to:
  /// **'No table of contents'**
  String get noTableOfContents;

  /// Empty markers message
  ///
  /// In en, this message translates to:
  /// **'No markers yet'**
  String get noMarkersYet;

  /// Markers instruction message
  ///
  /// In en, this message translates to:
  /// **'Select text and use the color buttons to add markers'**
  String get selectTextForMarkers;

  /// Bookmarks page title
  ///
  /// In en, this message translates to:
  /// **'My Bookmarks'**
  String get myBookmarks;

  /// Bookmark added success message
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// Bookmark removed success message
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

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

  /// Navigate to verse button text
  ///
  /// In en, this message translates to:
  /// **'Go to Verse'**
  String get goToVerse;

  /// Navigate to verse confirmation question
  ///
  /// In en, this message translates to:
  /// **'Navigate to this verse in the Quran reader?'**
  String get navigateToVerseQuestion;

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

  /// Next prayer countdown format
  ///
  /// In en, this message translates to:
  /// **'Next: {prayerName} in {time}'**
  String nextPrayerCountdown(String prayerName, String time);

  /// Title for persistent prayer countdown widget
  ///
  /// In en, this message translates to:
  /// **'Persistent Prayer Countdown'**
  String get persistentPrayerCountdown;

  /// Status when countdown is active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Status when countdown is stopped
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// Description when persistent notification is running
  ///
  /// In en, this message translates to:
  /// **'A persistent notification is showing in your status bar with countdown to next prayer. It cannot be dismissed and updates every second.'**
  String get persistentNotificationRunning;

  /// Description when persistent notification is stopped
  ///
  /// In en, this message translates to:
  /// **'The persistent countdown notification is currently stopped.'**
  String get persistentNotificationStopped;

  /// Information about persistent notification feature
  ///
  /// In en, this message translates to:
  /// **'This creates a single persistent notification that updates its content without spam. Different from your prayer time notifications.'**
  String get persistentNotificationInfo;

  /// Success message when countdown starts
  ///
  /// In en, this message translates to:
  /// **'Persistent countdown started'**
  String get persistentCountdownStarted;

  /// Success message when countdown stops
  ///
  /// In en, this message translates to:
  /// **'Persistent countdown stopped'**
  String get persistentCountdownStopped;

  /// Success message when countdown restarts
  ///
  /// In en, this message translates to:
  /// **'Persistent countdown restarted'**
  String get persistentCountdownRestarted;

  /// Error message when failing to start countdown
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {error}'**
  String failedToStart(String error);

  /// Error message when failing to stop countdown
  ///
  /// In en, this message translates to:
  /// **'Failed to stop: {error}'**
  String failedToStop(String error);

  /// Error message when failing to restart countdown
  ///
  /// In en, this message translates to:
  /// **'Failed to restart: {error}'**
  String failedToRestart(String error);

  /// Title for home screen widget section
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget'**
  String get homeScreenWidget;

  /// Description of home screen widget functionality
  ///
  /// In en, this message translates to:
  /// **'Display inspiring Islamic verses on your home screen'**
  String get displayInspiringVerses;

  /// Title for widget control section
  ///
  /// In en, this message translates to:
  /// **'Widget Control'**
  String get widgetControl;

  /// Description for immediate widget update
  ///
  /// In en, this message translates to:
  /// **'Update your widget content immediately'**
  String get updateWidgetContentImmediately;

  /// Text shown while widget is being updated
  ///
  /// In en, this message translates to:
  /// **'Updating Widget...'**
  String get updatingWidget;

  /// Button text to force update widget
  ///
  /// In en, this message translates to:
  /// **'Force Update Widget'**
  String get forceUpdateWidget;

  /// Success message when widget is updated
  ///
  /// In en, this message translates to:
  /// **'Home screen widget updated successfully!'**
  String get homeScreenWidgetUpdatedSuccessfully;

  /// Error message when widget update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating widget: {error}'**
  String errorUpdatingWidget(String error);

  /// Title for custom verses section
  ///
  /// In en, this message translates to:
  /// **'Custom Verses'**
  String get customVerses;

  /// Tooltip for refresh verses button
  ///
  /// In en, this message translates to:
  /// **'Refresh verses'**
  String get refreshVerses;

  /// Text showing number of verses added
  ///
  /// In en, this message translates to:
  /// **'{count} verse{count, plural, one{} other{s}} added'**
  String versesAdded(int count);

  /// Text shown while loading verses
  ///
  /// In en, this message translates to:
  /// **'Loading verses...'**
  String get loadingVerses;

  /// Title when no custom verses are found
  ///
  /// In en, this message translates to:
  /// **'No Custom Verses Yet'**
  String get noCustomVersesYet;

  /// Instructions for adding verses to widget
  ///
  /// In en, this message translates to:
  /// **'Visit the Surah screen to add verses to your widget'**
  String get visitSurahScreenToAddVerses;

  /// Success message when ayah is added to widget
  ///
  /// In en, this message translates to:
  /// **'Ayah added to widget'**
  String get ayahAddedToWidget;

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

  /// No description provided for @dawood.
  ///
  /// In en, this message translates to:
  /// **'Sunan Abi Dawud'**
  String get dawood;

  /// No description provided for @majah.
  ///
  /// In en, this message translates to:
  /// **'Sahih Ibn Majah'**
  String get majah;

  /// No description provided for @nasa.
  ///
  /// In en, this message translates to:
  /// **'Sunan an-Nasa\'i'**
  String get nasa;

  /// No description provided for @masabih.
  ///
  /// In en, this message translates to:
  /// **'Mishkat al-Masabih'**
  String get masabih;

  /// No description provided for @ahmad.
  ///
  /// In en, this message translates to:
  /// **'Musnad Ahmad'**
  String get ahmad;

  /// No description provided for @sahiha.
  ///
  /// In en, this message translates to:
  /// **'Silsilah al-Sahihah'**
  String get sahiha;

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

  /// No description provided for @hadithBanner.
  ///
  /// In en, this message translates to:
  /// **'Explore authentic sayings and teachings of Prophet Muhammad ﷺ'**
  String get hadithBanner;

  /// No description provided for @nextPrayerCountDown.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayerCountDown;

  /// No description provided for @persistentPrayerCountdownDescription.
  ///
  /// In en, this message translates to:
  /// **'Background Notification Service'**
  String get persistentPrayerCountdownDescription;

  /// No description provided for @persistentPrayerCountdownStopped.
  ///
  /// In en, this message translates to:
  /// **'Service is currently stopped'**
  String get persistentPrayerCountdownStopped;

  /// No description provided for @persistentPrayerCountdownRunning.
  ///
  /// In en, this message translates to:
  /// **'Service is running in background'**
  String get persistentPrayerCountdownRunning;

  /// No description provided for @persistentPrayerCountdownServiceControls.
  ///
  /// In en, this message translates to:
  /// **'Service Control'**
  String get persistentPrayerCountdownServiceControls;

  /// No description provided for @persistentNotificationInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About This Service'**
  String get persistentNotificationInfoTitle;

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

  /// No description provided for @shareTextHudaAI.
  ///
  /// In en, this message translates to:
  /// **'Contributed by Huda AI - The Islamic Smart Assistant'**
  String get shareTextHudaAI;

  /// No description provided for @bookmarksYourCollection.
  ///
  /// In en, this message translates to:
  /// **'Your Collection'**
  String get bookmarksYourCollection;

  /// No description provided for @bookmarksSavedVerses.
  ///
  /// In en, this message translates to:
  /// **'saved verses'**
  String get bookmarksSavedVerses;

  /// No description provided for @adjustTextSizeForBetterReadability.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size for better readability'**
  String get adjustTextSizeForBetterReadability;

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

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Islamic Companion'**
  String get homeTitle;

  /// No description provided for @continueHome.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueHome;

  /// No description provided for @noRecentActivityHome.
  ///
  /// In en, this message translates to:
  /// **'No Recent Activity'**
  String get noRecentActivityHome;

  /// No description provided for @resumeReading.
  ///
  /// In en, this message translates to:
  /// **'Resume your Quran reading'**
  String get resumeReading;

  /// No description provided for @noRecentActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Start reading the quran to see your progress'**
  String get noRecentActivityDescription;

  /// No description provided for @bookmarkTip.
  ///
  /// In en, this message translates to:
  /// **'Tap verses to bookmark them'**
  String get bookmarkTip;

  /// No description provided for @darkmode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkmode;

  /// No description provided for @lightmode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightmode;

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

  /// No description provided for @supportAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportAndFeedback;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us make the app better'**
  String get supportDescription;

  /// No description provided for @shareYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get shareYourThoughts;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts with us'**
  String get feedbackDescription;

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

  /// No description provided for @batteryOptimizationExemptionActive.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization Disabled'**
  String get batteryOptimizationExemptionActive;

  /// No description provided for @batteryOptimizationExemptionInactive.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization Active'**
  String get batteryOptimizationExemptionInactive;

  /// No description provided for @notificationsWillWorkReliably.
  ///
  /// In en, this message translates to:
  /// **'Notifications will work reliably'**
  String get notificationsWillWorkReliably;

  /// No description provided for @notificationsMayBeDelayedOrMissed.
  ///
  /// In en, this message translates to:
  /// **'Notifications may be delayed or missed'**
  String get notificationsMayBeDelayedOrMissed;

  /// No description provided for @notificationsActive.
  ///
  /// In en, this message translates to:
  /// **'All notifications are working properly'**
  String get notificationsActive;

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

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @consecutiveDays.
  ///
  /// In en, this message translates to:
  /// **'consecutive days'**
  String get consecutiveDays;

  /// No description provided for @noTasksForDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day'**
  String get noTasksForDay;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteTaskConfirmation;

  /// No description provided for @completedPercentage.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completedPercentage;

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

  /// No description provided for @itemTypePrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get itemTypePrayer;

  /// No description provided for @itemTypeQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran Reading'**
  String get itemTypeQuran;

  /// No description provided for @itemTypeAthkar.
  ///
  /// In en, this message translates to:
  /// **'Athkar & Dhikr'**
  String get itemTypeAthkar;

  /// No description provided for @itemTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get itemTypeCustom;

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

  /// No description provided for @nightAthkar.
  ///
  /// In en, this message translates to:
  /// **'Night Athkar'**
  String get nightAthkar;

  /// No description provided for @addCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Item'**
  String get addCustomItem;

  /// No description provided for @itemTitle.
  ///
  /// In en, this message translates to:
  /// **'Item Title'**
  String get itemTitle;

  /// No description provided for @enterItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter item title...'**
  String get enterItemTitle;

  /// No description provided for @itemType.
  ///
  /// In en, this message translates to:
  /// **'Item Type'**
  String get itemType;

  /// No description provided for @repetitionFrequency.
  ///
  /// In en, this message translates to:
  /// **'Repetition Frequency'**
  String get repetitionFrequency;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @itemTypePrayerShort.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get itemTypePrayerShort;

  /// No description provided for @itemTypeQuranShort.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get itemTypeQuranShort;

  /// No description provided for @itemTypeAthkarShort.
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get itemTypeAthkarShort;

  /// No description provided for @dayStreakSuffix.
  ///
  /// In en, this message translates to:
  /// **'-Day Streak!'**
  String dayStreakSuffix(num count);

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

  /// No description provided for @optimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get optimize;

  /// No description provided for @loadingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Loading preferences...'**
  String get loadingPreferences;

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

  /// Title for prayer countdown notification
  ///
  /// In en, this message translates to:
  /// **'{prefix} Next {prayerName} in {timeText}'**
  String prayerCountdownTitle(
      String prefix, String prayerName, String timeText);

  /// Title for urgent prayer countdown notification
  ///
  /// In en, this message translates to:
  /// **'{prefix} {prayerName} in {timeText}'**
  String prayerCountdownUrgentTitle(
      String prefix, String prayerName, String timeText);

  /// Context message for Fajr prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Dawn prayer - start your day with prayer 🤲'**
  String get prayerCountdownFajrContext;

  /// Context message for Dhuhr prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Midday prayer - take a blessed break ☀️'**
  String get prayerCountdownDhuhrContext;

  /// Context message for Asr prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Afternoon prayer - remember Allah 📿'**
  String get prayerCountdownAsrContext;

  /// Context message for Maghrib prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Sunset prayer - end the day in gratitude 🤲'**
  String get prayerCountdownMaghribContext;

  /// Context message for Isha prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Night prayer - peaceful end to your day 🌙'**
  String get prayerCountdownIshaContext;

  /// Default context message for prayer countdown
  ///
  /// In en, this message translates to:
  /// **'Stay prepared for prayer time 🕌'**
  String get prayerCountdownDefaultContext;

  /// Urgency message for critical prayer countdown (< 5 min)
  ///
  /// In en, this message translates to:
  /// **'Prayer time is very near - prepare now!'**
  String get prayerCountdownCriticalUrgency;

  /// Urgency message for high prayer countdown (< 15 min)
  ///
  /// In en, this message translates to:
  /// **'Get ready for prayer soon'**
  String get prayerCountdownHighUrgency;

  /// Urgency message for medium prayer countdown (< 30 min)
  ///
  /// In en, this message translates to:
  /// **'Prayer time approaching'**
  String get prayerCountdownMediumUrgency;

  /// Title when prayer countdown is loading
  ///
  /// In en, this message translates to:
  /// **'🕌 Prayer Countdown'**
  String get prayerCountdownLoadingTitle;

  /// Text when prayer countdown is loading
  ///
  /// In en, this message translates to:
  /// **'Loading prayer times...'**
  String get prayerCountdownLoadingText;

  /// Text when prayer countdown has an error
  ///
  /// In en, this message translates to:
  /// **'Error calculating prayer time'**
  String get prayerCountdownErrorText;

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

  /// Currency settings section title
  ///
  /// In en, this message translates to:
  /// **'Currency Settings'**
  String get currencySettings;

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

  /// Metal prices section title
  ///
  /// In en, this message translates to:
  /// **'Metal Prices'**
  String get metalPrices;

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

  /// Nisab info card title
  ///
  /// In en, this message translates to:
  /// **'What is Nisab?'**
  String get whatIsNisab;

  /// Nisab description text
  ///
  /// In en, this message translates to:
  /// **'Nisab is the minimum threshold of wealth that makes Zakat obligatory. It can be calculated based on either gold (87.48g) or silver (612.36g) values.'**
  String get nisabDescription;

  /// Quick summary section title
  ///
  /// In en, this message translates to:
  /// **'Quick Summary'**
  String get quickSummary;

  /// Zakat due label in summary
  ///
  /// In en, this message translates to:
  /// **'Zakat Due:'**
  String get zakatDue;

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
  /// **'Zakat is one of the five pillars of Islam and is an obligatory charity. It is calculated as 2.5% of qualifying wealth that has been held for at least one lunar year (hawl).\\n\\nNisab is the minimum threshold of wealth that makes Zakat obligatory. It can be calculated based on either:\\n• Gold: 87.48 grams (20 mithqal)\\n• Silver: 612.36 grams (200 dirhams)\\n\\nThis calculator helps you determine if your wealth reaches the nisab threshold and calculates the exact amount of Zakat due.'**
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

  /// Hint text for amount input fields
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get hintAmount;

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

  /// No description provided for @feedbackHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'We Value Your Opinion'**
  String get feedbackHeroTitle;

  /// No description provided for @feedbackHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Huda by sharing your thoughts, suggestions, or reporting any issues you\'ve encountered.'**
  String get feedbackHeroSubtitle;

  /// No description provided for @feedbackFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get feedbackFormTitle;

  /// No description provided for @feedbackFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please be as detailed as possible. Your feedback helps us make Huda better for everyone.'**
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
  /// **'Your feedback is sent securely and helps us improve the app. No personal information is shared with third parties.'**
  String get feedbackPrivacyDescription;

  /// No description provided for @detailedFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed Feedback'**
  String get detailedFeedbackTitle;

  /// No description provided for @detailedFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share detailed thoughts and suggestions'**
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

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huda'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Huda - Your all-in-one Islamic app with everything a Muslim needs in a single place.'**
  String get onboardingWelcomeDescription;

  /// No description provided for @onboardingPrayerTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get onboardingPrayerTimesTitle;

  /// No description provided for @onboardingPrayerTimesDescription.
  ///
  /// In en, this message translates to:
  /// **'Never miss a prayer with precise prayer times based on your location. Get notifications and track your daily prayers.'**
  String get onboardingPrayerTimesDescription;

  /// No description provided for @onboardingQuranTitle.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get onboardingQuranTitle;

  /// No description provided for @onboardingQuranDescription.
  ///
  /// In en, this message translates to:
  /// **'Read, listen, and memorize the Holy Quran with beautiful recitations, translations, and tafsir.'**
  String get onboardingQuranDescription;

  /// No description provided for @onboardingAthkarTitle.
  ///
  /// In en, this message translates to:
  /// **'Athkar & Duas'**
  String get onboardingAthkarTitle;

  /// No description provided for @onboardingAthkarDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily remembrance and supplications to strengthen your faith.'**
  String get onboardingAthkarDescription;

  /// No description provided for @onboardingQiblahTitle.
  ///
  /// In en, this message translates to:
  /// **'Qiblah Direction'**
  String get onboardingQiblahTitle;

  /// No description provided for @onboardingQiblahDescription.
  ///
  /// In en, this message translates to:
  /// **'Find the accurate direction of the Holy Kaaba from anywhere in the world.'**
  String get onboardingQiblahDescription;

  /// No description provided for @onboardingMultilingualTitle.
  ///
  /// In en, this message translates to:
  /// **'Multilingual Support'**
  String get onboardingMultilingualTitle;

  /// No description provided for @onboardingMultilingualDescription.
  ///
  /// In en, this message translates to:
  /// **'Access the app in multiple languages to make your Islamic journey more personal and easy to understand.'**
  String get onboardingMultilingualDescription;

  /// No description provided for @onboardingBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic Books'**
  String get onboardingBooksTitle;

  /// No description provided for @onboardingBooksDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore a vast library of authentic Islamic books for deep knowledge and spiritual growth.'**
  String get onboardingBooksDescription;

  /// No description provided for @onboardingHadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith Collection'**
  String get onboardingHadithTitle;

  /// No description provided for @onboardingHadithDescription.
  ///
  /// In en, this message translates to:
  /// **'Read from trusted sources including Sahih Bukhari, Sahih Muslim, Sunan Abu Dawood, and more.'**
  String get onboardingHadithDescription;

  /// No description provided for @onboardingAITitle.
  ///
  /// In en, this message translates to:
  /// **'Huda AI Assistant'**
  String get onboardingAITitle;

  /// No description provided for @onboardingAIDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask Islamic questions and get reliable answers with our AI-powered assistant for Islamic guidance.'**
  String get onboardingAIDescription;

  /// No description provided for @onboardingHijriTitle.
  ///
  /// In en, this message translates to:
  /// **'Hijri Calendar'**
  String get onboardingHijriTitle;

  /// No description provided for @onboardingHijriDescription.
  ///
  /// In en, this message translates to:
  /// **'View the full Islamic calendar with Gregorian date conversion to stay connected with important dates.'**
  String get onboardingHijriDescription;

  /// No description provided for @onboardingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic Daily Checklist'**
  String get onboardingChecklistTitle;

  /// No description provided for @onboardingChecklistDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your daily prayers, worship, and good deeds with an easy-to-use checklist.'**
  String get onboardingChecklistDescription;

  /// No description provided for @onboardingJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin Your Journey'**
  String get onboardingJourneyTitle;

  /// No description provided for @onboardingJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything you need for your Islamic journey is here. Start exploring and strengthen your connection with Allah.'**
  String get onboardingJourneyDescription;

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

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in your device settings.'**
  String get locationServicesDisabled;

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

  /// No description provided for @noHadithsFound.
  ///
  /// In en, this message translates to:
  /// **'No Hadiths Found'**
  String get noHadithsFound;

  /// No description provided for @noHadithsFoundChapter.
  ///
  /// In en, this message translates to:
  /// **'This chapter doesn\'t contain any hadiths at the moment.'**
  String get noHadithsFoundChapter;

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

  /// Title for counseling mode
  ///
  /// In en, this message translates to:
  /// **'Counseling Mode'**
  String get counselingMode;

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

  /// Guidance card subtitle
  ///
  /// In en, this message translates to:
  /// **'Personalized Islamic guidance'**
  String get guidanceSubtitle;

  /// Quran card title
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// Quran card subtitle
  ///
  /// In en, this message translates to:
  /// **'Relevant Quranic wisdom'**
  String get quranSubtitle;

  /// Duaa card title
  ///
  /// In en, this message translates to:
  /// **'Duaa'**
  String get duaaTitle;

  /// Duaa card subtitle
  ///
  /// In en, this message translates to:
  /// **'Heartfelt supplications'**
  String get duaaSubtitle;

  /// Text prompting users to try example questions
  ///
  /// In en, this message translates to:
  /// **'Try expressing:'**
  String get tryExpressing;

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

  /// Instructions for adding widget
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add the Huda widget directly to your home screen. This displays beautiful Quranic verses that update automatically.'**
  String get addWidgetInstructions;

  /// Add widget button text
  ///
  /// In en, this message translates to:
  /// **'Add Widget'**
  String get addWidget;

  /// Message for non-Android platforms
  ///
  /// In en, this message translates to:
  /// **'This feature is only available on Android'**
  String get featureOnlyAvailableOnAndroid;

  /// Message when pin widget is not supported
  ///
  /// In en, this message translates to:
  /// **'Pin widget is not supported on this device'**
  String get pinWidgetNotSupported;

  /// Error message for adding widget
  ///
  /// In en, this message translates to:
  /// **'Error adding widget'**
  String get errorAddingWidget;

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

  /// Placeholder for minutes input
  ///
  /// In en, this message translates to:
  /// **'Minutes (e.g., 30)'**
  String get sahurMinutesPlaceholder;

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

  /// Subtitle when Sahur alarm is disabled
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get sahurAlarmNotSet;

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

  /// Title for the system notification shown when the app is killed.
  ///
  /// In en, this message translates to:
  /// **'Your alarms may not ring'**
  String get alarmKilledTitle;

  /// Body for the system notification shown when the app is killed.
  ///
  /// In en, this message translates to:
  /// **'You killed the app. Please reopen so your alarms can be rescheduled.'**
  String get alarmKilledBody;

  /// Button label to snooze the ringing alarm for 5 minutes
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snoozeAlarm;

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

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Lock apps during times of worship to minimize distractions.'**
  String get miqaatLockDescription;

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

  /// Duration picker title
  ///
  /// In en, this message translates to:
  /// **'Select Duration'**
  String get selectDuration;

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

  /// iOS app selection title
  ///
  /// In en, this message translates to:
  /// **'iOS App Selection'**
  String get iosAppSelectionTitle;

  /// iOS app selection explanation
  ///
  /// In en, this message translates to:
  /// **'Due to iOS privacy restrictions, app selection is managed through Screen Time settings. Enable Screen Time access to manage app restrictions.'**
  String get iosAppSelectionDescription;

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

  /// Start session button
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// Active session indicator
  ///
  /// In en, this message translates to:
  /// **'Session Active'**
  String get sessionActive;

  /// Remaining time label
  ///
  /// In en, this message translates to:
  /// **'Remaining Time'**
  String get remainingTime;

  /// Lock screen title
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLocked;

  /// Lock screen message
  ///
  /// In en, this message translates to:
  /// **'This app is locked during your focus time. Start a session to unlock temporarily.'**
  String get focusTimeMessage;

  /// Go back button
  ///
  /// In en, this message translates to:
  /// **'Go Back Home'**
  String get goBackHome;

  /// Ramadan page title
  ///
  /// In en, this message translates to:
  /// **'Ramadan Qadhaa'**
  String get ramadanTracker;

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

  /// Remaining time for iftar
  ///
  /// In en, this message translates to:
  /// **'remaining for Iftar Less than {hours} hours'**
  String remainingForIftar(int hours);

  /// Remaining time for imsaak
  ///
  /// In en, this message translates to:
  /// **'remaining for Imsaak Less than {hours} hours'**
  String remainingForImsaak(int hours);

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

  /// Qadhaa days section title
  ///
  /// In en, this message translates to:
  /// **'Qadhaa Days'**
  String get qadhaaDays;

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

  /// Indicates that the app is currently in offline mode
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

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

  /// Message shown when a book download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// Instruction to select apps using Screen Time on iOS
  ///
  /// In en, this message translates to:
  /// **'Tap below to select apps using Screen Time'**
  String get iosTapToSelectApps;

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

  /// Button text to select apps using Screen Time on iOS
  ///
  /// In en, this message translates to:
  /// **'Select Apps (Screen Time)'**
  String get iosSelectAppsScreenTime;

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

  /// Button to check connection
  ///
  /// In en, this message translates to:
  /// **'Check Connection'**
  String get checkConnection;

  /// Number of files for offline book
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String filesCount(int count);

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

  /// Search surah placeholder
  ///
  /// In en, this message translates to:
  /// **'Search surah...'**
  String get searchSurah;

  /// Verses count label
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get verses;

  /// Offline empty state title when no audio is downloaded
  ///
  /// In en, this message translates to:
  /// **'No downloaded content'**
  String get noDownloadedContent;

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

  /// Now playing label in radio player bar
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

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

  /// One month Khatma program title
  ///
  /// In en, this message translates to:
  /// **'One Month Khatma (29 days)'**
  String get khatmaOneMonthProgram;

  /// Subtitle for the one-month Khatma program
  ///
  /// In en, this message translates to:
  /// **'Daily portion: ~21 pages'**
  String get khatmaDailyWird21Pages;

  /// Section label for other programs
  ///
  /// In en, this message translates to:
  /// **'Other Programs'**
  String get khatmaOtherPrograms;

  /// Title for meaning-based Khatma program
  ///
  /// In en, this message translates to:
  /// **'Khatma by Meaning'**
  String get khatmaBySemanticTitle;

  /// Subtitle for meaning-based Khatma program
  ///
  /// In en, this message translates to:
  /// **'Portions with complete meaning'**
  String get khatmaBySemanticSubtitle;

  /// Title for parts-based Khatma program
  ///
  /// In en, this message translates to:
  /// **'Khatma by Juz and Rub\''**
  String get khatmaByPartsTitle;

  /// Subtitle for parts-based Khatma program
  ///
  /// In en, this message translates to:
  /// **'Portions by Juz and Ahzab'**
  String get khatmaByPartsSubtitle;

  /// Title for the program selection step
  ///
  /// In en, this message translates to:
  /// **'Khatma Program'**
  String get khatmaProgramTitle;

  /// Two-month Khatma program title
  ///
  /// In en, this message translates to:
  /// **'Two-Month Khatma (60 days)'**
  String get khatmaTwoMonthsProgram;

  /// One-week Khatma program title
  ///
  /// In en, this message translates to:
  /// **'One-Week Khatma (7 days)'**
  String get khatmaOneWeekProgram;

  /// Section label for monthly Khatma programs
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get khatmaMonthsSection;

  /// 30-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'30-Day Khatma'**
  String get khatma30DaysTitle;

  /// Daily portion subtitle: one Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Juz'**
  String get khatmaDailyWirdJuz;

  /// Section label for other Khatma programs
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get khatmaOtherSection;

  /// 240-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'240-Day Khatma'**
  String get khatma240DaysTitle;

  /// Daily portion subtitle: one Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Rub\''**
  String get khatmaDailyWirdRubu;

  /// 120-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'120-Day Khatma'**
  String get khatma120DaysTitle;

  /// Daily portion subtitle: two Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: two Rub\''**
  String get khatmaDailyWirdTwoRubu;

  /// 80-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'80-Day Khatma'**
  String get khatma80DaysTitle;

  /// Daily portion subtitle: 3 Rub'
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 3 Rub\''**
  String get khatmaDailyWird3Rubu;

  /// 60-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'60-Day Khatma'**
  String get khatma60DaysTitle;

  /// Daily portion subtitle: one Hizb
  ///
  /// In en, this message translates to:
  /// **'Daily portion: one Hizb'**
  String get khatmaDailyWirdHizb;

  /// 40-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'40-Day Khatma'**
  String get khatma40DaysTitle;

  /// Daily portion subtitle: 1.5 Hizb
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 1.5 Hizb'**
  String get khatmaDailyWirdHizbAndHalf;

  /// 20-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'20-Day Khatma'**
  String get khatma20DaysTitle;

  /// Daily portion subtitle: 1.5 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 1.5 Juz'**
  String get khatmaDailyWirdJuzAndHalf;

  /// 15-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'15-Day Khatma'**
  String get khatma15DaysTitle;

  /// Daily portion subtitle: two Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: two Juz'**
  String get khatmaDailyWirdTwoJuz;

  /// 10-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'10-Day Khatma'**
  String get khatma10DaysTitle;

  /// Daily portion subtitle: 3 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 3 Juz'**
  String get khatmaDailyWird3Juz;

  /// 6-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'6-Day Khatma'**
  String get khatma6DaysTitle;

  /// Daily portion subtitle: 5 Juz
  ///
  /// In en, this message translates to:
  /// **'Daily portion: 5 Juz'**
  String get khatmaDailyWird5Juz;

  /// 3-day Khatma program title
  ///
  /// In en, this message translates to:
  /// **'3-Day Khatma'**
  String get khatma3DaysTitle;

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

  /// Option to start from the beginning of the Quran
  ///
  /// In en, this message translates to:
  /// **'Beginning of the Quran'**
  String get khatmaFromBeginning;

  /// Subtitle for starting from the beginning
  ///
  /// In en, this message translates to:
  /// **'Start from Al-Fatihah'**
  String get khatmaFromBeginningSubtitle;

  /// Option to start from a specific portion
  ///
  /// In en, this message translates to:
  /// **'Specific Portion'**
  String get khatmaSpecificWird;

  /// Subtitle for starting from a specific portion
  ///
  /// In en, this message translates to:
  /// **'Choose a day from the portions list'**
  String get khatmaSpecificWirdSubtitle;

  /// Title for the active Khatma statistics page
  ///
  /// In en, this message translates to:
  /// **'Khatma Statistics'**
  String get khatmaStatsTitle;

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

  /// Status: wird completed for today
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get khatmaWirdCompleted;

  /// Status: wird in progress for today
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get khatmaWirdInProgress;

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

  /// Subtitle for the all wirds tile
  ///
  /// In en, this message translates to:
  /// **'View all portions'**
  String get khatmaViewAllWirds;

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

  /// AM time indicator used in reminder time display
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get khatmaAmIndicator;

  /// PM time indicator used in reminder time display
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get khatmaPmIndicator;

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

  /// Mushaf page header surah label
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String mushafSurahHeader(String name);

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

  /// Settings section header for horizontal layout
  ///
  /// In en, this message translates to:
  /// **'Horizontal Layout'**
  String get settingsHorizontalLayout;

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

  /// Scroll to top navigation button label
  ///
  /// In en, this message translates to:
  /// **'To Top'**
  String get scrollToTop;

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

  /// Header subtitle for the prayer-widget tab
  ///
  /// In en, this message translates to:
  /// **'Stay on time for every prayer'**
  String get prayerWidgetTagline;

  /// Title of the section that adds the prayer widget to the home screen
  ///
  /// In en, this message translates to:
  /// **'Add Prayer Widget'**
  String get addPrayerWidgetTitle;

  /// Body of the prayer widget add section
  ///
  /// In en, this message translates to:
  /// **'Pin the Huda Prayer widget to your home screen to see the next prayer with a live countdown. Calculations run on-device using your saved location.'**
  String get addPrayerWidgetDescription;

  /// Button text to add the prayer widget
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get addPrayerWidget;

  /// Button text to open the prayer widget customization page
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customizePrayerWidget;

  /// Title of the prayer widget customization screen
  ///
  /// In en, this message translates to:
  /// **'Customize prayer widget'**
  String get prayerWidgetCustomization;

  /// Label above the in-app preview
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get prayerWidgetPreview;

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
  /// **'Bold next-prayer focus with countdown timer, hero icon and a clean list of all prayers.'**
  String get designHeroDescription;

  /// Name of the compact design
  ///
  /// In en, this message translates to:
  /// **'Almanac'**
  String get designCompact;

  /// Description of the compact design
  ///
  /// In en, this message translates to:
  /// **'Classic cream card with date, day-of-week, full prayer grid and night times.'**
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

  /// Toggle for showing background fill
  ///
  /// In en, this message translates to:
  /// **'Show background'**
  String get enableBackground;

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

  /// Latin/Arabic-numeral option
  ///
  /// In en, this message translates to:
  /// **'Latin (1, 2, 3)'**
  String get latinNumerals;

  /// Arabic-numeral option
  ///
  /// In en, this message translates to:
  /// **'Arabic (١, ٢, ٣)'**
  String get arabicNumerals;

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

  /// Confirmation prompt for resetting customization
  ///
  /// In en, this message translates to:
  /// **'Reset all prayer widget customization to defaults?'**
  String get resetWidgetCustomizationConfirm;

  /// Hint shown when no custom color is selected
  ///
  /// In en, this message translates to:
  /// **'Follow app theme'**
  String get followAppTheme;

  /// Empty-state title shown when no coordinates are saved
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get prayerWidgetEmptyTitle;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Open Huda and grant location access so the widget can compute prayer times for you.'**
  String get prayerWidgetEmptyBody;

  /// Empty-state CTA
  ///
  /// In en, this message translates to:
  /// **'Open Prayer Times'**
  String get prayerWidgetEmptyAction;

  /// Label above the previous-prayer time
  ///
  /// In en, this message translates to:
  /// **'Previous prayer'**
  String get previousPrayer;

  /// Label above the countdown
  ///
  /// In en, this message translates to:
  /// **'Time until next prayer'**
  String get timeUntilNextPrayer;

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

  /// Title for the last ten nights of Ramadan event card
  ///
  /// In en, this message translates to:
  /// **'The Last Ten Nights'**
  String get eventLastTenRamadan;

  /// Title for the Eid al-Fitr event card
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr Mubarak'**
  String get eventEidAlFitr;

  /// Title for the Eid al-Adha event card
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha Mubarak'**
  String get eventEidAlAdha;

  /// Title for the Day of Arafah event card
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah'**
  String get eventDayOfArafah;

  /// Title for the first ten days of Dhul Hijjah event card
  ///
  /// In en, this message translates to:
  /// **'Blessed Ten Days'**
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
  /// **'The month of fasting, prayer, and reflection'**
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

  /// No description provided for @narratedBy.
  ///
  /// In en, this message translates to:
  /// **'Narrated by'**
  String get narratedBy;

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

  /// resumeReciter
  ///
  /// In en, this message translates to:
  /// **'Resume {reciterName}'**
  String resumeReciter(String reciterName);

  /// No description provided for @noReciterActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Start listening to Quran audio to see your progress'**
  String get noReciterActivityDescription;

  /// No description provided for @noRadioActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Listen to Quran radio to see your progress'**
  String get noRadioActivityDescription;

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

  /// Label on audio card showing the language of the audio content
  ///
  /// In en, this message translates to:
  /// **'In {language}'**
  String audioInLanguage(String language);

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

  /// Button to manually search for a location
  ///
  /// In en, this message translates to:
  /// **'Search Manually'**
  String get searchManually;

  /// Message shown when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please allow location access in your device settings.'**
  String get locationPermissionDenied;

  /// Message shown when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please allow location access in your device settings.'**
  String get locationPermissionPermanentlyDenied;

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

  /// Fallback error summary when no message is available
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownErrorOccurred;

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

  /// Title for the screenshot feedback description field
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

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
        'ur'
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
      'that was used.');
}
