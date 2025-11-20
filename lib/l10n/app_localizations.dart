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

  /// Next prayer widget title
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
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

  /// Done button text
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

  /// No search results found message
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

  /// Minutes label
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
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

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'small'**
  String get small;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get normal;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'large'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In en, this message translates to:
  /// **'extra large'**
  String get extraLarge;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'quran'**
  String get quran;

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

  /// No description provided for @meccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @ayahs.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahs;
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
